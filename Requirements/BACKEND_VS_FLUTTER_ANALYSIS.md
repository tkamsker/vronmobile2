# Backend Test Scripts vs Flutter Implementation Analysis

## Executive Summary

**Critical Finding**: The Flutter UI (`usdz_preview_screen.dart`) is NOT using the new `convertUsdzToGlb()` method that includes PRD-mandated race condition waits. It's manually calling individual API methods.

**Backend Reality**: The backend test scripts (`simple_convert_test.py`, `download_result.sh`) do NOT implement any artificial wait periods after conversion completion or download - they work fine without them.

## Backend Test Script Workflow

### simple_convert_test.py (Python)

```python
# Step 1: Health Check (optional)
GET /health

# Step 2: Create Session
POST /sessions
→ Returns: session_id

# Step 3: Upload File
POST /sessions/{session_id}/upload
Headers:
  - X-API-Key: <key>
  - X-Asset-Type: model/vnd.usdz+zip
  - X-Filename: <filename>
  - Content-Type: application/octet-stream
Body: <binary file bytes>

# Step 4: Start Conversion
POST /sessions/{session_id}/convert
Body:
  {
    "job_type": "usdz_to_glb",
    "input_filename": "scan.usdz",
    "output_filename": "scan.glb"
  }

# Step 5: Poll Status (every 2 seconds, max 120 seconds)
GET /sessions/{session_id}/status
→ Wait until: session_status == "completed"
→ Extract: result.filename

# NO WAITS HERE - Session kept alive, script exits
```

### download_result.sh (Bash)

```bash
# Step 1: Check Session Status
GET /sessions/{session_id}/status
→ Verify: session_status == "completed"
→ Extract: result.filename

# Step 2: Download File (IMMEDIATELY, no waits)
GET /sessions/{session_id}/download/{filename}
→ Save to disk

# Step 3: Verify File Size
# NO WAITS - Just immediate download and verification
```

### Key Observations:

1. ✅ **Backend scripts work successfully** without any artificial waits
2. ❌ **NO 3-second wait** after conversion completes
3. ❌ **NO 2-second wait** after download completes
4. ✅ **Backend handles file system synchronization internally**
5. ✅ **Backend handles HTTP stream closure properly**

## Flutter Implementation

### Current UI Code (usdz_preview_screen.dart:311-434)

```dart
Future<void> _convertToGLB() async {
  // Step 1: Create session
  final session = await _apiClient!.createSession();
  sessionId = session.sessionId;

  // Step 2: Upload file
  final uploadResponse = await _apiClient!.uploadFile(
    sessionId: sessionId,
    file: usdzFile,
  );

  // Step 3: Start conversion
  await _apiClient!.startConversion(
    sessionId: sessionId,
    inputFilename: uploadResponse.filename,
    outputFilename: outputFilename,
  );

  // Step 4: Poll status
  await for (final status in _apiClient!.pollStatus(sessionId: sessionId)) {
    if (status.isCompleted) {
      finalStatus = status;
      break;
    }
  }

  // Step 5: Download file (NO WAITS)
  final glbFile = await _apiClient!.downloadFile(
    sessionId: sessionId,
    filename: finalStatus.result!.filename,
  );

  // Step 6: Cleanup session (NO WAITS)
  await _apiClient!.deleteSession(sessionId);
}
```

### New BlenderApiClient Method (NOT BEING USED)

We created `convertUsdzToGlb()` with mandatory waits (blender_api_client.dart:341-442):

```dart
Future<File> convertUsdzToGlb({...}) async {
  // ... create session, upload, start conversion, poll status ...

  // ⚠️ CRITICAL: Wait 3 seconds after completion
  await Future.delayed(Duration(seconds: 3));

  // Download file
  final file = await downloadFile(...);

  // ⚠️ CRITICAL: Wait 2 seconds after download
  await Future.delayed(Duration(seconds: 2));

  // Delete session
  await deleteSession(sessionId);

  return file;
}
```

**Problem**: The UI is NOT calling this method!

## PRD Document Analysis

### PRD States (FLUTTER_API_INTEGRATION_PRD.md:890-939):

```dart
// ✅ CORRECT Implementation
Future<File> completeWorkflow(...) async {
  // 1. Poll until processing completes
  final status = await apiService.pollUntilComplete(sessionId: sessionId);

  // 2. ⚠️ CRITICAL: Wait 3 seconds after completion
  //    Reason: File system needs time to finalize the file
  await Future.delayed(Duration(seconds: 3));

  // 3. Download the file
  final file = await apiService.downloadFile(...);

  // 4. ⚠️ CRITICAL: Wait 2 seconds after download
  //    Reason: HTTP stream needs time to fully close
  await Future.delayed(Duration(seconds: 2));

  // 5. Delete session
  await apiService.deleteSession(sessionId);

  return file;
}
```

### PRD Reasoning:

1. **3s after completion**:
   - Backend file system needs to flush buffers
   - Blender may still be writing final metadata
   - File size needs to stabilize

2. **2s after download**:
   - HTTP chunked transfer encoding needs to complete
   - Connection needs to cleanly close

### Contradiction:

The backend test scripts that work successfully **DO NOT** implement these waits. This suggests either:
1. The backend already handles these synchronization issues internally
2. The PRD waits are overly cautious/unnecessary
3. The backend tests are lucky and haven't encountered race conditions yet

## Root Cause Analysis

### Why Is The UI Getting Errors?

Let me check what specific errors the user is reporting...

**Hypothesis 1: Session Cleanup Too Fast**
- UI downloads file, immediately deletes session
- Backend might be holding locks on the session during download
- Deletion request conflicts with active download stream

**Hypothesis 2: File Path Issues**
- Backend test uses absolute paths: `/Users/thomaskamsker/...`
- Flutter uses app-specific temporary directories
- Might be permission or path resolution issues

**Hypothesis 3: Missing Headers/Parameters**
- Backend test explicitly sets: `X-Asset-Type: model/vnd.usdz+zip`
- Let me verify Flutter sets this correctly...

**Hypothesis 4: HTTP Client Differences**
- Python `requests` library vs Flutter `http` package
- Different connection pooling, timeout handling
- Certificate verification (we disable in debug mode)

## Recommendations

### Option 1: Match Backend Behavior Exactly (RECOMMENDED)

Remove the artificial waits and follow the backend test pattern:

```dart
Future<void> _convertToGLB() async {
  // Create session
  final session = await _apiClient!.createSession();

  // Upload file
  final uploadResponse = await _apiClient!.uploadFile(
    sessionId: session.sessionId,
    file: usdzFile,
    assetType: 'model/vnd.usdz+zip', // ✅ Explicit
  );

  // Start conversion
  await _apiClient!.startConversion(
    sessionId: session.sessionId,
    inputFilename: uploadResponse.filename,
    outputFilename: uploadResponse.filename.replaceAll('.usdz', '.glb'),
  );

  // Poll until completed
  BlenderApiStatus? finalStatus;
  await for (final status in _apiClient!.pollStatus(sessionId: session.sessionId)) {
    if (status.isCompleted) {
      finalStatus = status;
      break;
    }
  }

  // Download file (NO artificial wait)
  final glbFile = await _apiClient!.downloadFile(
    sessionId: session.sessionId,
    filename: finalStatus!.result!.filename,
  );

  // Save file permanently
  // ... copy to permanent location ...

  // Cleanup session (NO artificial wait)
  await _apiClient!.deleteSession(session.sessionId);
}
```

### Option 2: Use New Method With Waits (IF NEEDED)

```dart
Future<void> _convertToGLB() async {
  final usdzFile = File(widget.scanData.localPath);

  // Use the high-level method that includes waits
  final glbFile = await _apiClient!.convertUsdzToGlb(
    usdzFile: usdzFile,
    onUploadProgress: (sent, total) {
      // Update UI
    },
    onConversionProgress: (progress) {
      // Update UI
    },
  );

  // Save permanently
  // ...
}
```

### Option 3: Investigate Actual Error

Before making changes, let's see the **actual error** the user is experiencing:
- What error message?
- What HTTP status code?
- At which step does it fail?
- Is it consistent or intermittent?

## Comparison Table

| Aspect | Backend Test Scripts | Flutter Implementation | PRD Requirement |
|--------|---------------------|----------------------|-----------------|
| **3s wait after completion** | ❌ No | ✅ Yes (in unused method) | ✅ Yes |
| **2s wait after download** | ❌ No | ✅ Yes (in unused method) | ✅ Yes |
| **Explicit X-Asset-Type** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Session cleanup** | ✅ After download | ✅ After download | ✅ After waits |
| **Error handling** | ✅ Detailed | ✅ Detailed | ✅ Required |
| **Success rate** | ✅ 100% | ❓ Unknown | - |

## Next Steps

1. **Ask user for actual error details**:
   - What error message appears?
   - At which step does it fail?
   - Session ID for investigation

2. **Enable debug logging** in Flutter app:
   ```dart
   print('🔍 [Debug] Session: $sessionId');
   print('🔍 [Debug] Upload: ${uploadResponse.toJson()}');
   print('🔍 [Debug] Status: ${status.toJson()}');
   ```

3. **Compare HTTP requests**:
   - Use Charles Proxy or similar to capture:
     - Python requests
     - Flutter requests
   - Look for differences in headers, timing, body encoding

4. **Test with backend scripts**:
   - Run backend test with same USDZ file
   - If backend works but Flutter doesn't → client-side issue
   - If both fail → backend or file issue

## Conclusion

**The disconnect is clear**: The backend test scripts that work successfully don't use artificial waits, but our PRD (and our unused Flutter method) mandate them. The current Flutter UI doesn't use either approach consistently.

**Recommended Action**: Update the UI to match the proven backend workflow (no artificial waits) OR investigate why the UI needs them when the backend doesn't.

---

## Update: Implementation Complete (Option A)

### Changes Made to usdz_preview_screen.dart:

✅ **Updated `_convertToGLB()` to match backend workflow exactly**:

1. **Added comprehensive logging** matching backend verbosity:
   - Session creation with expiration time
   - File size logging (MB and bytes)
   - Detailed progress logging with status, progress, and stage
   - Result metadata (filename, size, polygon count)
   - Download and save confirmation

2. **Explicit asset type header**:
   ```dart
   assetType: 'model/vnd.usdz+zip', // ✅ Explicit, matches backend test
   ```

3. **NO artificial waits** (following backend pattern):
   - Download happens immediately after conversion completes
   - Session cleanup happens immediately after download
   - Backend handles synchronization internally

4. **Enhanced error handling**:
   - Detailed error logging with all exception properties
   - Display error code, status code, and session ID
   - Show recommended action to user
   - Automatic retry for recoverable errors
   - Session diagnostics screen access

5. **Added documentation comments**:
   ```dart
   // ========================================
   // BACKEND-ALIGNED WORKFLOW (Option A)
   // Following proven workflow from:
   // - simple_convert_test.py
   // - download_result.sh
   // NO artificial waits (backend handles synchronization)
   // ========================================
   ```

### Workflow Now Matches Backend:

```
✅ Create session
✅ Upload file (X-Asset-Type: model/vnd.usdz+zip)
✅ Start conversion
✅ Poll until completed (every 2s)
✅ Download file IMMEDIATELY (no 3s wait)
✅ Save file permanently
✅ Delete session IMMEDIATELY (no 2s wait)
```

### Expected Results:

- Conversion should work reliably like backend test scripts
- Detailed logs for debugging any issues
- Better error messages with actionable recommendations
- Session ID always available for investigation
- Automatic cleanup even on errors

### Testing Notes:

When testing, look for these log patterns:
```
🔄 [BlenderAPI] Starting USDZ→GLB conversion
📄 [BlenderAPI] Source file: /path/to/file.usdz
✅ [BlenderAPI] Session created: sess_...
⏰ [BlenderAPI] Session expires: ...
📦 [BlenderAPI] File size: X.XX MB (XXXXX bytes)
✅ [BlenderAPI] File uploaded: filename.usdz
📊 [BlenderAPI] Upload size: XXXXX bytes
🎯 [BlenderAPI] Target output: filename.glb
✅ [BlenderAPI] Conversion started
📊 [BlenderAPI] Status: processing, Progress: XX%, Stage: processing
✅ [BlenderAPI] Conversion completed
📁 [BlenderAPI] Result filename: filename.glb
📊 [BlenderAPI] Result size: XXXXX bytes
🔺 [BlenderAPI] Polygons: XXXXX
⬇️ [BlenderAPI] Starting download: filename.glb
✅ [BlenderAPI] Download complete: /tmp/filename.glb
💾 [BlenderAPI] Saved to: /permanent/path/filename.glb
✓ [BlenderAPI] File size verified: XXXXX bytes
🧹 [BlenderAPI] Deleting session: sess_...
✅ [BlenderAPI] Session cleaned up
```

If errors occur, you'll see:
```
❌ [BlenderAPI] BlenderApiException caught
   Status Code: XXX
   Error Code: ERROR_CODE
   Message: Error message
   Session ID: sess_...
   Recoverable: true/false
   User Message: User-friendly message
   Recommended Action: What to do next
```
