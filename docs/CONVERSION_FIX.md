# USDZ to GLB Conversion Fix

**Date**: 2026-01-02
**Issue**: Conversion failing with "Failed to create session: 201"
**Status**: ✅ Fixed

## Problem

The Flutter app was failing to convert USDZ files to GLB with this error:

```
❌ [BLENDER_API] Conversion failed: Exception: Failed to create session: 201 {"session_id":"sess_KWCpw1JfSYbRTSi12DA5xg",...}
```

## Root Cause

The Blender API returns **HTTP 201 (Created)** for successful session creation, which is the correct REST status code for creating new resources. However, the Flutter code was checking for **HTTP 200 (OK)** and treating 201 as an error.

### Code Analysis

**Python test script** (`simple_convert_test.py` line 79):
```python
if response.status_code != 201:
    log(f"FAIL: Session creation failed (status {response.status_code})", Colors.RED)
```

**Flutter service** (before fix):
```dart
if (response.statusCode != 200) {
  throw Exception('Failed to create session: ${response.statusCode} ${response.body}');
}
```

## Solution

### 1. Fixed Status Code Check

**File**: `lib/features/scanning/services/blender_api_service.dart`

Changed session creation to accept HTTP 201:

```dart
// API returns 201 (Created) for successful session creation
if (response.statusCode != 201) {
  throw Exception('Failed to create session: ${response.statusCode} ${response.body}');
}
```

### 2. Fixed Result Field Name

**File**: `lib/features/scanning/services/blender_api_service.dart`

The status polling was looking for `result_metadata` but the API returns `result`:

```dart
// Before (wrong)
final metadata = data['result_metadata'] as Map<String, dynamic>?;

// After (correct)
final result = data['result'] as Map<String, dynamic>?;  // API returns 'result'
```

### 3. Added Device Metadata Headers

To match the Python test script behavior and ensure full API compatibility, added device metadata headers to all API calls:

```dart
Future<Map<String, String>> _getDeviceHeaders() async {
  if (_deviceId == null) {
    _deviceId = const Uuid().v4();

    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _platform = 'ios';
      _osVersion = iosInfo.systemVersion;
      _deviceModel = iosInfo.model;
    }
  }

  return {
    'X-Device-ID': _deviceId ?? 'unknown',
    'X-Platform': _platform ?? 'unknown',
    'X-OS-Version': _osVersion ?? 'unknown',
    'X-App-Version': '1.0.0',
    'X-Device-Model': _deviceModel ?? 'unknown',
  };
}
```

These headers are now included in:
- Session creation
- File upload
- Conversion start
- Status polling
- File download

### 3. Added Required Packages

**File**: `pubspec.yaml`

Added dependencies:
```yaml
device_info_plus: ^11.3.0  # For device metadata
uuid: ^4.5.1               # For device ID generation
```

## Files Changed

1. `lib/features/scanning/services/blender_api_service.dart` - Fixed status code check + added device headers
2. `pubspec.yaml` - Added required packages

## Testing

### Before Fix (Issue 1 - Status Code)
```
flutter: 🔄 [BLENDER_API] Starting USDZ to GLB conversion
flutter: ❌ [BLENDER_API] Conversion failed: Exception: Failed to create session: 201
```

### Before Fix (Issue 2 - Result Field)
```
flutter: ✅ [BLENDER_API] Session created: sess_XXX
flutter: ✅ [BLENDER_API] File uploaded
flutter: ✅ [BLENDER_API] Conversion started
flutter: ❌ [BLENDER_API] Conversion failed: Exception: No result metadata found
```

### After Fix (Expected)
```
flutter: 🔄 [BLENDER_API] Starting USDZ to GLB conversion
flutter: ✅ [BLENDER_API] Session created: sess_XXX
flutter: ✅ [BLENDER_API] File uploaded
flutter: ✅ [BLENDER_API] Conversion started
flutter: ✅ [BLENDER_API] Conversion completed
flutter: ✅ [BLENDER_API] GLB downloaded: /path/to/file.glb
```

## How to Test

1. **Install dependencies**:
   ```bash
   cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Test conversion**:
   - Scan a room with LiDAR
   - Navigate to USDZ preview
   - Click "Convert to GLB" button
   - Watch conversion progress
   - Verify GLB file is created

4. **Verify success**:
   - Check logs for successful session creation (status 201)
   - Check logs for upload, conversion, download success
   - Verify GLB buttons appear after conversion
   - Test "Preview GLB" and "Export GLB" features

## API Status Codes Reference

| Endpoint | Method | Success Code | Notes |
|----------|--------|--------------|-------|
| `/sessions` | POST | 201 | Created - Returns new session ID |
| `/sessions/{id}/upload` | POST | 200 | OK - File uploaded |
| `/sessions/{id}/convert` | POST | 200 | OK - Conversion started |
| `/sessions/{id}/status` | GET | 200 | OK - Returns status |
| `/sessions/{id}/download/{file}` | GET | 200 | OK - Returns file bytes |

## Related Files

- **Blender API Test Script**: `/microservices/blenderapi/simple_convert_test.py`
- **Test & Download Script**: `/microservices/blenderapi/test_and_download.sh`
- **API README**: `/microservices/blenderapi/README.md`
- **Status Document**: `USDZ_TO_GLB_STATUS.md`

## Additional Notes

- The API correctly returns 201 for resource creation (REST best practice)
- Device metadata headers are optional but recommended for analytics/debugging
- Device ID is generated once per app instance and reused for all requests
- API key is currently hardcoded (dev key) - needs production configuration

## Next Steps

- ✅ Fix applied
- 🔄 Test on device with real USDZ file
- 🔄 Verify complete workflow (scan → convert → preview → create project)
- 🔄 Configure production API key
- 🔄 Add persistent device ID storage (optional)
