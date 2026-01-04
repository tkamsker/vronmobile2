# REST API Contract: BlenderAPI NavMesh Generation

**Feature**: 018-combined-scan-navmesh
**Date**: 2026-01-04
**Backend**: ✅ **Already Implemented** (blenderapi microservice)

## Overview

This document defines the REST API contract for navmesh generation using the **existing** BlenderAPI microservice. No new backend development is required - this service is already deployed and tested.

**BlenderAPI Base URLs**:
- **Stage**: `https://blenderapi.stage.motorenflug.at`
- **Production**: `https://blenderapi.motorenflug.at` (or configured URL)

**Authentication**: All requests require these headers:
```http
X-API-Key: <api-key>
X-Device-ID: <uuid>
X-Platform: ios
X-OS-Version: <version>
X-App-Version: <version>
X-Device-Model: <model>
```

---

## Complete Workflow

The blenderapi uses a **session-based** workflow:

```
1. Create Session     → session_id
2. Upload GLB        → file stored in session
3. Start NavMesh     → processing begins
4. Poll Status       → wait for completion
5. Download Result   → get navmesh GLB
6. Delete Session    → cleanup (automatic after 5 min)
```

---

## API Endpoints

### 1. Health Check

**Purpose**: Verify blenderapi service is available.

```http
GET /health
```

**Response** (200 OK):
```json
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2026-01-04T16:30:00Z"
}
```

**Mobile Implementation**:
```dart
Future<bool> checkHealth() async {
  final response = await http.get(
    Uri.parse('$baseUrl/health'),
    headers: {'X-API-Key': apiKey},
  );
  return response.statusCode == 200;
}
```

---

### 2. Create Session

**Purpose**: Initialize a new processing session for navmesh generation.

```http
POST /sessions
Content-Type: application/json
X-API-Key: <api-key>
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8
```

**Request Body**: Empty or `{}`

**Response** (201 Created):
```json
{
  "session_id": "sess_dUBsCnJc-LQ__mL8hfn_WQ",
  "created_at": "2026-01-04T16:30:00Z",
  "expires_at": "2026-01-04T16:35:00Z"
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid API key
- `429 Too Many Requests`: Rate limit exceeded
- `503 Service Unavailable`: Service down

**Mobile Implementation**:
```dart
Future<String> createSession() async {
  final response = await http.post(
    Uri.parse('$baseUrl/sessions'),
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
  );

  if (response.statusCode != 201) {
    throw Exception('Failed to create session: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  return data['session_id'];
}
```

---

### 3. Upload GLB File

**Purpose**: Upload the combined GLB file to the session for navmesh processing.

```http
POST /sessions/{session_id}/upload
Content-Type: application/octet-stream
X-API-Key: <api-key>
X-Asset-Type: model/gltf-binary
X-Filename: combined_scan.glb
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8

<binary GLB data>
```

**Request Headers**:
- `Content-Type`: `application/octet-stream`
- `X-Asset-Type`: `model/gltf-binary` (required)
- `X-Filename`: Original filename (e.g., `combined_scan.glb`)

**Response** (200 OK):
```json
{
  "upload_status": "success",
  "filename": "combined_scan.glb",
  "size_bytes": 15728640,
  "uploaded_at": "2026-01-04T16:30:15Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid file format or missing headers
- `413 Payload Too Large`: File exceeds size limit (typically 100MB)
- `404 Not Found`: Session not found or expired

**Mobile Implementation**:
```dart
Future<void> uploadGLB(String sessionId, File glbFile) async {
  final bytes = await glbFile.readAsBytes();

  final response = await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/upload'),
    headers: {
      'Content-Type': 'application/octet-stream',
      'X-API-Key': apiKey,
      'X-Asset-Type': 'model/gltf-binary',
      'X-Filename': basename(glbFile.path),
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
    body: bytes,
  );

  if (response.statusCode != 200) {
    throw Exception('Upload failed: ${response.statusCode}');
  }
}
```

---

### 4. Start NavMesh Generation

**Purpose**: Initiate navmesh generation from the uploaded GLB file.

```http
POST /sessions/{session_id}/navmesh
Content-Type: application/json
X-API-Key: <api-key>
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8

{
  "job_type": "navmesh_generation",
  "input_filename": "combined_scan.glb",
  "output_filename": "navmesh_combined_scan.glb",
  "navmesh_params": {
    "cell_size": 0.3,
    "cell_height": 0.2,
    "agent_height": 2.0,
    "agent_radius": 0.6,
    "agent_max_climb": 0.9,
    "agent_max_slope": 45.0
  }
}
```

**Request Body**:
```typescript
{
  job_type: "navmesh_generation",        // Required: Job type
  input_filename: string,                // Required: Input GLB filename from upload
  output_filename: string,               // Required: Desired output filename
  navmesh_params: {
    cell_size: number,                   // Grid cell size (meters), default: 0.3
    cell_height: number,                 // Grid cell height (meters), default: 0.2
    agent_height: number,                // Agent height (meters), default: 2.0
    agent_radius: number,                // Agent radius (meters), default: 0.6
    agent_max_climb: number,             // Max climb height (meters), default: 0.9
    agent_max_slope: number              // Max slope angle (degrees), default: 45.0
  }
}
```

**NavMesh Parameters**:
- `cell_size`: Horizontal resolution of the navmesh grid (smaller = more detail, slower)
- `cell_height`: Vertical resolution (how tall cells are)
- `agent_height`: How tall the AI agent is (affects clearance)
- `agent_radius`: How wide the AI agent is (affects path width)
- `agent_max_climb`: Maximum step height the agent can climb
- `agent_max_slope`: Maximum slope angle the agent can walk on

**Response** (200 OK):
```json
{
  "status": "processing",
  "job_id": "job_abc123",
  "started_at": "2026-01-04T16:30:20Z"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid parameters or missing input file
- `404 Not Found`: Session not found or input file not uploaded

**Mobile Implementation**:
```dart
Future<void> startNavMeshGeneration(
  String sessionId,
  String inputFilename,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/navmesh'),
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
    body: jsonEncode({
      'job_type': 'navmesh_generation',
      'input_filename': inputFilename,
      'output_filename': 'navmesh_$inputFilename',
      'navmesh_params': {
        'cell_size': 0.3,
        'cell_height': 0.2,
        'agent_height': 2.0,
        'agent_radius': 0.6,
        'agent_max_climb': 0.9,
        'agent_max_slope': 45.0,
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to start navmesh generation: ${response.statusCode}');
  }
}
```

---

### 5. Poll Session Status

**Purpose**: Check the current status of navmesh generation (poll every 2 seconds).

```http
GET /sessions/{session_id}/status
X-API-Key: <api-key>
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8
```

**Response** (200 OK - Processing):
```json
{
  "session_id": "sess_dUBsCnJc-LQ__mL8hfn_WQ",
  "session_status": "processing",
  "processing_stage": "generating_navmesh",
  "progress": 75,
  "started_at": "2026-01-04T16:30:20Z",
  "estimated_completion": "2026-01-04T16:32:00Z"
}
```

**Response** (200 OK - Completed):
```json
{
  "session_id": "sess_dUBsCnJc-LQ__mL8hfn_WQ",
  "session_status": "completed",
  "processing_stage": "done",
  "progress": 100,
  "started_at": "2026-01-04T16:30:20Z",
  "completed_at": "2026-01-04T16:31:45Z",
  "result": {
    "filename": "navmesh_combined_scan.glb",
    "size_bytes": 1234567,
    "polygon_count": 5000
  }
}
```

**Response** (200 OK - Failed):
```json
{
  "session_id": "sess_dUBsCnJc-LQ__mL8hfn_WQ",
  "session_status": "failed",
  "processing_stage": "navmesh_generation",
  "progress": 45,
  "error_message": "Invalid geometry: non-manifold edges detected",
  "error_code": "INVALID_GEOMETRY",
  "failed_at": "2026-01-04T16:30:45Z"
}
```

**Session Status Values**:
- `pending`: Session created, waiting for upload
- `uploading`: File upload in progress
- `processing`: NavMesh generation in progress
- `completed`: NavMesh ready for download
- `failed`: Generation failed (see error_message)

**Error Codes**:
- `INVALID_GEOMETRY`: GLB contains non-manifold geometry
- `PROCESSING_TIMEOUT`: Generation exceeded time limit (5 minutes)
- `INSUFFICIENT_AREA`: Room too small for navmesh
- `BLENDER_ERROR`: Internal Blender processing error

**Mobile Implementation**:
```dart
Future<SessionStatus> pollStatus(String sessionId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/sessions/$sessionId/status'),
    headers: {
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Status check failed: ${response.statusCode}');
  }

  final data = jsonDecode(response.body);
  return SessionStatus.fromJson(data);
}

// Poll until completed
Future<SessionStatus> waitForCompletion(String sessionId) async {
  const maxAttempts = 150; // 5 minutes (150 * 2 seconds)
  const pollInterval = Duration(seconds: 2);

  for (int i = 0; i < maxAttempts; i++) {
    final status = await pollStatus(sessionId);

    if (status.sessionStatus == 'completed') {
      return status;
    } else if (status.sessionStatus == 'failed') {
      throw Exception('NavMesh generation failed: ${status.errorMessage}');
    }

    await Future.delayed(pollInterval);
  }

  throw TimeoutException('NavMesh generation timeout');
}
```

---

### 6. Download NavMesh Result

**Purpose**: Download the generated navmesh GLB file.

```http
GET /sessions/{session_id}/download/{filename}
X-API-Key: <api-key>
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8
```

**Response** (200 OK):
- **Content-Type**: `application/octet-stream`
- **Body**: Binary GLB file data

**Error Responses**:
- `404 Not Found`: Session or file not found
- `410 Gone`: Session expired (files deleted)

**Mobile Implementation**:
```dart
Future<File> downloadNavMesh(
  String sessionId,
  String filename,
  String savePath,
) async {
  final response = await http.get(
    Uri.parse('$baseUrl/sessions/$sessionId/download/$filename'),
    headers: {
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Download failed: ${response.statusCode}');
  }

  final file = File(savePath);
  await file.writeAsBytes(response.bodyBytes);
  return file;
}
```

---

### 7. Delete Session

**Purpose**: Clean up session and temporary files (optional, auto-deletes after 5 minutes).

```http
DELETE /sessions/{session_id}
X-API-Key: <api-key>
X-Device-ID: <device-uuid>
X-Platform: ios
X-OS-Version: 17.2
X-App-Version: 1.4.2
X-Device-Model: iPad13,8
```

**Response** (202 Accepted):
```json
{
  "status": "deleted",
  "message": "Session marked for deletion, cleanup within 5 minutes"
}
```

**Response** (404 Not Found):
```json
{
  "error": "Session not found or already deleted"
}
```

**Mobile Implementation**:
```dart
Future<void> deleteSession(String sessionId) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/sessions/$sessionId'),
    headers: {
      'X-API-Key': apiKey,
      'X-Device-ID': deviceId,
      'X-Platform': 'ios',
      'X-OS-Version': osVersion,
      'X-App-Version': appVersion,
      'X-Device-Model': deviceModel,
    },
  );

  // 202 Accepted or 404 Not Found are both OK
  if (response.statusCode != 202 && response.statusCode != 404) {
    print('Warning: Session deletion failed: ${response.statusCode}');
  }
}
```

---

## Complete Service Implementation

```dart
class BlenderAPIService {
  final String baseUrl;
  final String apiKey;
  final String deviceId;
  final String platform;
  final String osVersion;
  final String appVersion;
  final String deviceModel;

  BlenderAPIService({
    required this.baseUrl,
    required this.apiKey,
    required this.deviceId,
    this.platform = 'ios',
    required this.osVersion,
    required this.appVersion,
    required this.deviceModel,
  });

  Map<String, String> get _headers => {
    'X-API-Key': apiKey,
    'X-Device-ID': deviceId,
    'X-Platform': platform,
    'X-OS-Version': osVersion,
    'X-App-Version': appVersion,
    'X-Device-Model': deviceModel,
  };

  /// Complete workflow: Upload GLB and generate navmesh
  Future<File> generateNavMesh(
    File glbFile,
    String outputPath, {
    Function(double)? onProgress,
  }) async {
    String? sessionId;

    try {
      // 1. Create session
      onProgress?.call(0.1);
      sessionId = await createSession();

      // 2. Upload GLB
      onProgress?.call(0.2);
      await uploadGLB(sessionId, glbFile);

      // 3. Start navmesh generation
      onProgress?.call(0.3);
      final filename = basename(glbFile.path);
      await startNavMeshGeneration(sessionId, filename);

      // 4. Poll for completion
      final status = await waitForCompletion(
        sessionId,
        onProgressUpdate: (progress) {
          // Map 0-100 to 0.3-0.9 range
          onProgress?.call(0.3 + (progress / 100.0) * 0.6);
        },
      );

      // 5. Download result
      onProgress?.call(0.9);
      final navmeshFile = await downloadNavMesh(
        sessionId,
        status.result!.filename,
        outputPath,
      );

      onProgress?.call(1.0);
      return navmeshFile;

    } finally {
      // 6. Cleanup session
      if (sessionId != null) {
        try {
          await deleteSession(sessionId);
        } catch (e) {
          print('Warning: Session cleanup failed: $e');
        }
      }
    }
  }

  // ... (individual methods from above)
}
```

---

## Error Handling

### Common Error Patterns

```dart
try {
  final navmesh = await blenderAPIService.generateNavMesh(glbFile, outputPath);
} on SocketException {
  // Network error
  showError('No internet connection');
} on TimeoutException {
  // Processing timeout
  showError('NavMesh generation timed out. Please try again.');
} on HttpException catch (e) {
  // HTTP error
  if (e.message.contains('413')) {
    showError('File too large. Maximum size is 100MB.');
  } else if (e.message.contains('INVALID_GEOMETRY')) {
    showError('Invalid 3D model. Please re-scan the rooms.');
  } else {
    showError('NavMesh generation failed: ${e.message}');
  }
} catch (e) {
  // Unknown error
  showError('An unexpected error occurred: $e');
}
```

---

## Testing

### Test Script (from blenderapi repo)

The blenderapi repo includes test scripts:
- `test_navmesh_and_download.sh` - Complete end-to-end test
- `simple_navmesh_test.py` - Python test script
- `download_result.sh` - Download helper

### Manual Testing

```bash
# Test against stage environment
cd /Users/thomaskamsker/Documents/Atom/vron.one/microservices/blenderapi
./test_navmesh_and_download.sh \
  https://blenderapi.stage.motorenflug.at \
  dev-test-key-1234567890 \
  test_assets/test.glb
```

---

## References

- BlenderAPI Repository: `/Users/thomaskamsker/Documents/Atom/vron.one/microservices/blenderapi`
- Test Scripts: `test_navmesh_and_download.sh`, `simple_navmesh_test.py`
- Feature Specification: `specs/018-combined-scan-navmesh/spec.md`
- Research Document: `specs/018-combined-scan-navmesh/research.md`
