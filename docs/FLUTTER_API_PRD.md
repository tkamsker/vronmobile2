# BlenderAPI - Flutter Developer PRD

**Product Requirements Document for Flutter Developers**

**Base URL**: `https://blenderapi.stage.motorenflug.at`  
**API Version**: 1.0.0  
**Environment**: Stage

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Flutter Integration Guide](#flutter-integration-guide)
5. [Complete Workflow Examples](#complete-workflow-examples)
6. [Error Handling](#error-handling)
7. [Testing with cURL](#testing-with-curl)

---

## Overview

The BlenderAPI is a session-based 3D processing service that provides:

- **Navigation Mesh Generation**: Convert GLB files to GLB files with embedded navigation meshes for game AI pathfinding
- **Format Conversion**: Convert USDZ files to GLB format with material preservation
- **Real-Time Monitoring**: Server-Sent Events (SSE) for live log streaming
- **Streaming I/O**: Handle large files (up to 500MB) efficiently

### Key Concepts

- **Sessions**: Each processing workflow requires a session. Sessions expire after 1 hour of inactivity.
- **Rate Limiting**: Maximum 3 concurrent sessions per API key
- **File Size Limit**: 500MB per file
- **Processing Timeout**: 15 minutes (900 seconds)

---

## Authentication

All API endpoints (except `/health`) require authentication via API key.

### Header Format

```
X-API-Key: your-api-key-here
```

### Getting an API Key

Contact your administrator to obtain an API key. API keys are configured server-side and must be at least 16 characters long.

### Example

```dart
final headers = {
  'X-API-Key': 'your-api-key-here',
  'Content-Type': 'application/json',
};
```

---

## API Endpoints

### 1. Health Check

**Endpoint**: `GET /health`  
**Authentication**: None required  
**Description**: Check if the API service is running

#### Response

```json
{
  "status": "healthy",
  "active_sessions": 5,
  "cleanup_service": "running"
}
```

#### cURL Example

```bash
curl -X GET https://blenderapi.stage.motorenflug.at/health
```

---

### 2. Create Session

**Endpoint**: `POST /sessions`  
**Authentication**: Required  
**Description**: Create a new processing session. Returns a unique session ID.

#### Request Headers

```
X-API-Key: your-api-key-here
Content-Type: application/json
```

#### Response (201 Created)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "expires_at": "2025-12-29T15:30:00Z"
}
```

#### cURL Example

```bash
curl -X POST https://blenderapi.stage.motorenflug.at/sessions \
  -H "X-API-Key: your-api-key-here" \
  -H "Content-Type: application/json"
```

#### Flutter Example

```dart
Future<SessionCreatedResponse> createSession() async {
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'Content-Type': 'application/json',
    },
  );
  
  if (response.statusCode == 201) {
    return SessionCreatedResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create session: ${response.body}');
  }
}
```

---

### 3. Upload File

**Endpoint**: `POST /sessions/{session_id}/upload`  
**Authentication**: Required  
**Description**: Upload a 3D model file (GLB or USDZ) to a session. Supports streaming for large files.

#### Request Headers

```
X-API-Key: your-api-key-here
X-Asset-Type: model/gltf-binary (for GLB) or model/vnd.usdz+zip (for USDZ)
X-Filename: your-file.glb
Content-Type: application/octet-stream
```

#### Supported Asset Types

- `model/gltf-binary` - For `.glb` files
- `model/vnd.usdz+zip` - For `.usdz` files

#### Request Body

Binary file content (raw bytes)

#### Response (200 OK)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "your-file.glb",
  "size_bytes": 1048576,
  "uploaded_at": "2025-12-29T14:20:00Z"
}
```

#### cURL Example

```bash
# Upload GLB file
curl -X POST https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/upload \
  -H "X-API-Key: your-api-key-here" \
  -H "X-Asset-Type: model/gltf-binary" \
  -H "X-Filename: model.glb" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @model.glb

# Upload USDZ file
curl -X POST https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/upload \
  -H "X-API-Key: your-api-key-here" \
  -H "X-Asset-Type: model/vnd.usdz+zip" \
  -H "X-Filename: model.usdz" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @model.usdz
```

#### Flutter Example

**Important**: The API expects raw binary data in the request body, not multipart form data. Always read the file as bytes first to avoid stream errors:

```dart
Future<UploadResponse> uploadFile(
  String sessionId,
  File file,
  String assetType, // 'model/gltf-binary' or 'model/vnd.usdz+zip'
) async {
  // ✅ Read file as bytes ONCE (avoids "Stream has already been listened to" error)
  final fileBytes = await file.readAsBytes();
  
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/upload'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'X-Asset-Type': assetType,
      'X-Filename': file.path.split('/').last,
      'Content-Type': 'application/octet-stream',
    },
    body: fileBytes, // ✅ Direct bytes, not a stream
  );
  
  if (response.statusCode == 200) {
    return UploadResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Upload failed: ${response.body}');
  }
}
```

**⚠️ Common Error**: If you get `Bad state: Stream has already been listened to`, you're likely using `file.openRead()` or a stream. Always use `file.readAsBytes()` instead.

---

### 4. Generate Navigation Mesh

**Endpoint**: `POST /sessions/{session_id}/navmesh`  
**Authentication**: Required  
**Description**: Generate a navigation mesh for an uploaded GLB file. The output will be a GLB file with embedded navigation mesh.

#### Request Headers

```
X-API-Key: your-api-key-here
Content-Type: application/json
```

#### Request Body

```json
{
  "job_type": "navmesh_generation",
  "input_filename": "model.glb",
  "output_filename": "model_navmesh.glb",
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

**⚠️ Important**: The `job_type` field is **REQUIRED** and must be exactly `"navmesh_generation"` for this endpoint.

#### NavMesh Parameters (All Optional)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cell_size` | float | 0.3 | Cell size for NavMesh (must be > 0) |
| `cell_height` | float | 0.2 | Cell height for NavMesh (must be > 0) |
| `agent_height` | float | 2.0 | Agent height in meters (must be > 0) |
| `agent_radius` | float | 0.6 | Agent radius in meters (must be > 0) |
| `agent_max_climb` | float | 0.9 | Maximum climb height in meters (must be > 0) |
| `agent_max_slope` | float | 45.0 | Maximum slope angle in degrees (0-90) |

#### Response (200 OK)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "job_type": "navmesh_generation",
  "started_at": "2025-12-29T14:25:00Z"
}
```

#### cURL Example

```bash
curl -X POST https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/navmesh \
  -H "X-API-Key: your-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "job_type": "navmesh_generation",
    "input_filename": "model.glb",
    "output_filename": "model_navmesh.glb",
    "navmesh_params": {
      "cell_size": 0.3,
      "cell_height": 0.2,
      "agent_height": 2.0,
      "agent_radius": 0.6,
      "agent_max_climb": 0.9,
      "agent_max_slope": 45.0
    }
  }'
```

#### Flutter Example

```dart
Future<ProcessingStartedResponse> generateNavMesh(
  String sessionId,
  String inputFilename, {
  String? outputFilename,
  NavMeshParameters? navmeshParams,
}) async {
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/navmesh'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'job_type': 'navmesh_generation',
      'input_filename': inputFilename,
      if (outputFilename != null) 'output_filename': outputFilename,
      if (navmeshParams != null) 'navmesh_params': navmeshParams.toJson(),
    }),
  );
  
  if (response.statusCode == 200) {
    return ProcessingStartedResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to start navmesh generation: ${response.body}');
  }
}
```

---

### 5. Convert USDZ to GLB

**Endpoint**: `POST /sessions/{session_id}/convert`  
**Authentication**: Required  
**Description**: Convert a USDZ file to GLB format.

#### Request Headers

```
X-API-Key: your-api-key-here
Content-Type: application/json
```

#### Request Body

```json
{
  "job_type": "usdz_to_glb",
  "input_filename": "model.usdz",
  "output_filename": "model.glb",
  "conversion_params": {
    "apply_scale": false,
    "merge_meshes": false,
    "target_scale": 1.0
  }
}
```

**⚠️ Important**: The `job_type` field is **REQUIRED** and must be exactly `"usdz_to_glb"` for this endpoint. If you get a 422 error saying "Field required" for `job_type`, make sure you're including it in your request body.

#### Conversion Parameters (All Optional)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apply_scale` | boolean | false | Apply scale normalization |
| `merge_meshes` | boolean | false | Merge all meshes into one object |
| `target_scale` | float | 1.0 | Target scale for normalization (must be > 0) |

#### Response (200 OK)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "job_type": "usdz_to_glb",
  "started_at": "2025-12-29T14:25:00Z"
}
```

#### cURL Example

```bash
curl -X POST https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/convert \
  -H "X-API-Key: your-api-key-here" \
  -H "Content-Type: application/json" \
  -d '{
    "job_type": "usdz_to_glb",
    "input_filename": "model.usdz",
    "output_filename": "model.glb",
    "conversion_params": {
      "apply_scale": false,
      "merge_meshes": false,
      "target_scale": 1.0
    }
  }'
```

#### Flutter Example

```dart
Future<ProcessingStartedResponse> convertUsdzToGlb(
  String sessionId,
  String inputFilename, {
  String? outputFilename,
  ConversionParameters? conversionParams,
}) async {
  final response = await http.post(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/convert'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'job_type': 'usdz_to_glb',
      'input_filename': inputFilename,
      if (outputFilename != null) 'output_filename': outputFilename,
      if (conversionParams != null) 'conversion_params': conversionParams.toJson(),
    }),
  );
  
  if (response.statusCode == 200) {
    return ProcessingStartedResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to start conversion: ${response.body}');
  }
}
```

---

### 6. Check Status

**Endpoint**: `GET /sessions/{session_id}/status`  
**Authentication**: Required  
**Description**: Get the current status of a processing job.

#### Request Headers

```
X-API-Key: your-api-key-here
```

#### Response (200 OK)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "session_status": "processing",
  "processing_stage": "processing",
  "progress": 45,
  "started_at": "2025-12-29T14:25:00Z",
  "completed_at": null,
  "error_message": null,
  "result": null
}
```

#### Status Values

- `session_status`: `pending`, `uploading`, `validating`, `processing`, `completed`, `failed`, `expired`
- `processing_stage`: `pending`, `processing`, `completed`, `failed`
- `progress`: Integer from 0 to 100

#### Response When Completed

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "session_status": "completed",
  "processing_stage": "completed",
  "progress": 100,
  "started_at": "2025-12-29T14:25:00Z",
  "completed_at": "2025-12-29T14:27:30Z",
  "error_message": null,
  "result": {
    "filename": "model_navmesh.glb",
    "size_bytes": 2097152,
    "format": "glb",
    "polygon_count": 12345,
    "mesh_count": 3,
    "material_count": 5
  }
}
```

#### cURL Example

```bash
curl -X GET https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/status \
  -H "X-API-Key: your-api-key-here"
```

#### Flutter Example

```dart
Future<StatusResponse> checkStatus(String sessionId) async {
  final response = await http.get(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/status'),
    headers: {
      'X-API-Key': 'your-api-key-here',
    },
  );
  
  if (response.statusCode == 200) {
    return StatusResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to get status: ${response.body}');
  }
}

// Polling example
Future<void> pollUntilComplete(String sessionId) async {
  while (true) {
    final status = await checkStatus(sessionId);
    
    if (status.sessionStatus == 'completed') {
      print('Processing completed!');
      print('Result: ${status.result?.filename}');
      break;
    } else if (status.sessionStatus == 'failed') {
      throw Exception('Processing failed: ${status.errorMessage}');
    }
    
    print('Progress: ${status.progress}%');
    await Future.delayed(Duration(seconds: 2)); // Poll every 2 seconds
  }
}
```

---

### 7. Download Result

**Endpoint**: `GET /sessions/{session_id}/download/{filename}`  
**Authentication**: Required  
**Description**: Download the processed output file.

#### Request Headers

```
X-API-Key: your-api-key-here
```

#### Response (200 OK)

- **Content-Type**: `model/gltf-binary` (for GLB files)
- **Content-Disposition**: `attachment; filename="model_navmesh.glb"`
- **Body**: Binary file content

#### cURL Example

```bash
curl -X GET https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/download/model_navmesh.glb \
  -H "X-API-Key: your-api-key-here" \
  --output model_navmesh.glb
```

#### Flutter Example

```dart
Future<File> downloadFile(String sessionId, String filename, String savePath) async {
  final response = await http.get(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/download/$filename'),
    headers: {
      'X-API-Key': 'your-api-key-here',
    },
  );
  
  if (response.statusCode == 200) {
    final file = File(savePath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  } else {
    throw Exception('Download failed: ${response.body}');
  }
}
```

---

### 8. Stream Logs (Server-Sent Events)

**Endpoint**: `GET /sessions/{session_id}/logs/stream`  
**Authentication**: Required  
**Description**: Stream processing logs in real-time using Server-Sent Events (SSE).

#### Request Headers

```
X-API-Key: your-api-key-here
Accept: text/event-stream
```

#### Response

Server-Sent Events stream with the following event types:

- `log`: Log message event
- `complete`: Processing completed event
- `error`: Error event

#### Event Format

```
event: log
data: {"timestamp":"2025-12-29T14:25:30Z","level":"INFO","source":"blender","message":"Processing mesh...","line_number":1}

event: complete
data: {"status":"completed","lines_sent":150}
```

#### cURL Example

```bash
curl -N -X GET https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/logs/stream \
  -H "X-API-Key: your-api-key-here" \
  -H "Accept: text/event-stream"
```

#### Flutter Example

For SSE in Flutter, you'll need a package like `sse_client` or `event_source`:

```dart
import 'package:sse_client/sse_client.dart';

Future<void> streamLogs(String sessionId, Function(String) onLog) async {
  final client = SseClient(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/logs/stream'),
    headers: {
      'X-API-Key': 'your-api-key-here',
      'Accept': 'text/event-stream',
    },
  );
  
  client.stream.listen((event) {
    if (event.event == 'log') {
      final logData = json.decode(event.data);
      onLog('${logData['level']}: ${logData['message']}');
    } else if (event.event == 'complete') {
      final result = json.decode(event.data);
      print('Processing ${result['status']}');
      client.close();
    }
  });
}
```

---

### 9. Get Logs (Non-Streaming)

**Endpoint**: `GET /sessions/{session_id}/logs`  
**Authentication**: Required  
**Description**: Get all processing logs for a session (non-streaming).

#### Request Headers

```
X-API-Key: your-api-key-here
```

#### Response (200 OK)

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "logs": [
    {
      "timestamp": "2025-12-29T14:25:30Z",
      "level": "INFO",
      "source": "blender",
      "message": "Loading GLB file...",
      "line_number": 1
    },
    {
      "timestamp": "2025-12-29T14:25:35Z",
      "level": "INFO",
      "source": "blender",
      "message": "Generating navigation mesh...",
      "line_number": 2
    }
  ],
  "total_lines": 2
}
```

#### cURL Example

```bash
curl -X GET https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000/logs \
  -H "X-API-Key: your-api-key-here"
```

#### Flutter Example

```dart
Future<LogsResponse> getLogs(String sessionId) async {
  final response = await http.get(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId/logs'),
    headers: {
      'X-API-Key': 'your-api-key-here',
    },
  );
  
  if (response.statusCode == 200) {
    return LogsResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to get logs: ${response.body}');
  }
}
```

---

### 10. Delete Session

**Endpoint**: `DELETE /sessions/{session_id}`  
**Authentication**: Required  
**Description**: Manually delete a session and clean up its resources.

#### Request Headers

```
X-API-Key: your-api-key-here
```

#### Response (204 No Content)

No response body.

#### cURL Example

```bash
curl -X DELETE https://blenderapi.stage.motorenflug.at/sessions/550e8400-e29b-41d4-a716-446655440000 \
  -H "X-API-Key: your-api-key-here"
```

#### Flutter Example

```dart
Future<void> deleteSession(String sessionId) async {
  final response = await http.delete(
    Uri.parse('https://blenderapi.stage.motorenflug.at/sessions/$sessionId'),
    headers: {
      'X-API-Key': 'your-api-key-here',
    },
  );
  
  if (response.statusCode != 204) {
    throw Exception('Failed to delete session: ${response.body}');
  }
}
```

---

## Flutter Integration Guide

### 1. Add Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  sse_client: ^1.0.0  # For Server-Sent Events
```

### 2. Create API Client Class

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BlenderApiClient {
  final String baseUrl = 'https://blenderapi.stage.motorenflug.at';
  final String apiKey;
  
  BlenderApiClient(this.apiKey);
  
  Map<String, String> get _headers => {
    'X-API-Key': apiKey,
    'Content-Type': 'application/json',
  };
  
  // Implement all methods from examples above
  Future<SessionCreatedResponse> createSession() async { ... }
  Future<UploadResponse> uploadFile(...) async { ... }
  // ... etc
}
```

### 3. Error Handling

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;
  
  ApiException(this.statusCode, this.message, [this.details]);
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}

Future<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return fromJson(json.decode(response.body));
  } else {
    final error = json.decode(response.body);
    throw ApiException(
      response.statusCode,
      error['message'] ?? 'Unknown error',
      error['details'],
    );
  }
}
```

### 4. File Upload Best Practices

- **Always use `file.readAsBytes()`** - Read the file into memory once, then pass bytes directly
- **Don't use `file.openRead()`** - This creates a single-subscription stream that causes errors
- **Don't use `MultipartRequest`** - The API expects raw binary data, not multipart form data
- Validate file size before upload (max 500MB)
- For progress tracking, see the example in `FLUTTER_STREAM_FIX.md`

```dart
Future<UploadResponse> uploadFileWithProgress(
  String sessionId,
  File file,
  String assetType,
  Function(int sent, int total)? onProgress,
) async {
  // ✅ Read file as bytes first (avoids stream errors)
  final fileBytes = await file.readAsBytes();
  final totalBytes = fileBytes.length;
  
  if (totalBytes > 500 * 1024 * 1024) {
    throw Exception('File size exceeds 500MB limit');
  }
  
  // Call progress callback with total bytes (upload happens atomically)
  if (onProgress != null) {
    onProgress(totalBytes, totalBytes);
  }
  
  // ✅ Use simple http.post with body parameter
  final response = await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/upload'),
    headers: {
      'X-API-Key': apiKey,
      'X-Asset-Type': assetType,
      'X-Filename': file.path.split('/').last,
      'Content-Type': 'application/octet-stream',
    },
    body: fileBytes, // ✅ Direct bytes
  );
  
  if (response.statusCode == 200) {
    return UploadResponse.fromJson(json.decode(response.body));
  } else {
    throw Exception('Upload failed: ${response.body}');
  }
}
```

**Note**: For true progress tracking during upload, you'd need to use `http.Client().send()` with a streamed request, but this is more complex. For most use cases, the simple approach above is sufficient since the upload typically completes quickly.

---

## Complete Workflow Examples

### Workflow 1: Generate Navigation Mesh from GLB

```dart
Future<File> processNavMesh(File inputGlb) async {
  final api = BlenderApiClient('your-api-key-here');
  
  // 1. Create session
  final session = await api.createSession();
  print('Created session: ${session.sessionId}');
  
  // 2. Upload GLB file
  final upload = await api.uploadFile(
    session.sessionId,
    inputGlb,
    'model/gltf-binary',
  );
  print('Uploaded: ${upload.filename} (${upload.sizeBytes} bytes)');
  
  // 3. Start navmesh generation
  final job = await api.generateNavMesh(
    session.sessionId,
    upload.filename,
    outputFilename: 'navmesh_${upload.filename}',
    navmeshParams: NavMeshParameters(
      cellSize: 0.3,
      cellHeight: 0.2,
      agentHeight: 2.0,
      agentRadius: 0.6,
      agentMaxClimb: 0.9,
      agentMaxSlope: 45.0,
    ),
  );
  print('Started processing at ${job.startedAt}');
  
  // 4. Poll for completion
  StatusResponse status;
  do {
    await Future.delayed(Duration(seconds: 2));
    status = await api.checkStatus(session.sessionId);
    print('Progress: ${status.progress}%');
  } while (status.sessionStatus == 'processing');
  
  if (status.sessionStatus == 'completed' && status.result != null) {
    // 5. Download result
    final outputFile = await api.downloadFile(
      session.sessionId,
      status.result!.filename,
      '/path/to/save/${status.result!.filename}',
    );
    print('Downloaded: ${outputFile.path}');
    return outputFile;
  } else {
    throw Exception('Processing failed: ${status.errorMessage}');
  }
}
```

### Workflow 2: Convert USDZ to GLB

```dart
Future<File> convertUsdzToGlb(File inputUsdz) async {
  final api = BlenderApiClient('your-api-key-here');
  
  // 1. Create session
  final session = await api.createSession();
  
  // 2. Upload USDZ file
  final upload = await api.uploadFile(
    session.sessionId,
    inputUsdz,
    'model/vnd.usdz+zip',
  );
  
  // 3. Start conversion
  final job = await api.convertUsdzToGlb(
    session.sessionId,
    upload.filename,
    conversionParams: ConversionParameters(
      applyScale: false,
      mergeMeshes: false,
      targetScale: 1.0,
    ),
  );
  
  // 4. Poll for completion
  StatusResponse status;
  do {
    await Future.delayed(Duration(seconds: 2));
    status = await api.checkStatus(session.sessionId);
  } while (status.sessionStatus == 'processing');
  
  if (status.sessionStatus == 'completed' && status.result != null) {
    // 5. Download result
    return await api.downloadFile(
      session.sessionId,
      status.result!.filename,
      '/path/to/save/${status.result!.filename}',
    );
  } else {
    throw Exception('Conversion failed: ${status.errorMessage}');
  }
}
```

---

## Error Handling

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created (session) |
| 204 | No Content | Resource deleted successfully |
| 400 | Bad Request | Invalid request format or parameters |
| 401 | Unauthorized | Missing or invalid API key |
| 404 | Not Found | Session or file not found |
| 409 | Conflict | Processing already in progress |
| 422 | Unprocessable Entity | File validation failed (e.g., polygon limit exceeded) |
| 429 | Too Many Requests | Rate limit exceeded (max 3 concurrent sessions) |
| 500 | Internal Server Error | Server error |
| 504 | Gateway Timeout | Processing timeout (15 minutes) |

### Error Response Format

```json
{
  "error_code": "INVALID_INPUT",
  "message": "File validation failed: Invalid GLB format",
  "details": {
    "filename": "model.glb",
    "error_type": "InvalidFileFormat"
  }
}
```

### Common Error Scenarios

1. **Invalid API Key**
   ```json
   {
     "detail": "Invalid API key"
   }
   ```

2. **Session Not Found**
   ```json
   {
     "error_code": "NOT_FOUND",
     "message": "Session not found or has expired. Please create a new session with POST /sessions.",
     "details": {
       "session_id": "550e8400-e29b-41d4-a716-446655440000"
     }
   }
   ```

3. **Rate Limit Exceeded**
   ```json
   {
     "error_code": "TOO_MANY_REQUESTS",
     "message": "Maximum concurrent sessions (3) reached for this API key",
     "details": {
       "max_sessions": 3,
       "current_sessions": 3
     }
   }
   ```

4. **File Size Exceeded**
   ```json
   {
     "error_code": "INVALID_INPUT",
     "message": "File size exceeds maximum allowed size of 524288000 bytes",
     "details": {
       "file_size": 600000000,
       "max_size": 524288000
     }
   }
   ```

5. **Missing Required Field (job_type)**
   ```json
   {
     "detail": [{
       "type": "missing",
       "loc": ["body", "job_type"],
       "msg": "Field required",
       "input": {
         "input_filename": "model.usdz",
         "conversion_params": {...}
       }
     }]
   }
   ```
   **Fix**: Always include `"job_type": "usdz_to_glb"` (for conversion) or `"job_type": "navmesh_generation"` (for navmesh) in your request body. See `FLUTTER_JOB_TYPE_FIX.md` for details.

---

## Testing with cURL

### Complete NavMesh Workflow

```bash
# Set your API key
export API_KEY="your-api-key-here"
export BASE_URL="https://blenderapi.stage.motorenflug.at"

# 1. Create session
SESSION_RESPONSE=$(curl -s -X POST $BASE_URL/sessions \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json")
SESSION_ID=$(echo $SESSION_RESPONSE | jq -r '.session_id')
echo "Session ID: $SESSION_ID"

# 2. Upload GLB file
curl -X POST $BASE_URL/sessions/$SESSION_ID/upload \
  -H "X-API-Key: $API_KEY" \
  -H "X-Asset-Type: model/gltf-binary" \
  -H "X-Filename: model.glb" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @model.glb

# 3. Start navmesh generation
curl -X POST $BASE_URL/sessions/$SESSION_ID/navmesh \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "job_type": "navmesh_generation",
    "input_filename": "model.glb",
    "output_filename": "model_navmesh.glb",
    "navmesh_params": {
      "cell_size": 0.3,
      "cell_height": 0.2,
      "agent_height": 2.0,
      "agent_radius": 0.6,
      "agent_max_climb": 0.9,
      "agent_max_slope": 45.0
    }
  }'

# 4. Check status (poll until complete)
while true; do
  STATUS=$(curl -s -X GET $BASE_URL/sessions/$SESSION_ID/status \
    -H "X-API-Key: $API_KEY")
  
  SESSION_STATUS=$(echo $STATUS | jq -r '.session_status')
  PROGRESS=$(echo $STATUS | jq -r '.progress')
  
  echo "Status: $SESSION_STATUS, Progress: $PROGRESS%"
  
  if [ "$SESSION_STATUS" = "completed" ]; then
    FILENAME=$(echo $STATUS | jq -r '.result.filename')
    echo "Processing complete! Output: $FILENAME"
    break
  elif [ "$SESSION_STATUS" = "failed" ]; then
    ERROR=$(echo $STATUS | jq -r '.error_message')
    echo "Processing failed: $ERROR"
    exit 1
  fi
  
  sleep 2
done

# 5. Download result
curl -X GET $BASE_URL/sessions/$SESSION_ID/download/model_navmesh.glb \
  -H "X-API-Key: $API_KEY" \
  --output model_navmesh.glb

echo "Downloaded: model_navmesh.glb"
```

### Complete USDZ to GLB Conversion

```bash
# Set your API key
export API_KEY="your-api-key-here"
export BASE_URL="https://blenderapi.stage.motorenflug.at"

# 1. Create session
SESSION_RESPONSE=$(curl -s -X POST $BASE_URL/sessions \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json")
SESSION_ID=$(echo $SESSION_RESPONSE | jq -r '.session_id')

# 2. Upload USDZ file
curl -X POST $BASE_URL/sessions/$SESSION_ID/upload \
  -H "X-API-Key: $API_KEY" \
  -H "X-Asset-Type: model/vnd.usdz+zip" \
  -H "X-Filename: model.usdz" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @model.usdz

# 3. Start conversion
curl -X POST $BASE_URL/sessions/$SESSION_ID/convert \
  -H "X-API-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "job_type": "usdz_to_glb",
    "input_filename": "model.usdz",
    "conversion_params": {
      "apply_scale": false,
      "merge_meshes": false,
      "target_scale": 1.0
    }
  }'

# 4. Poll for completion
while true; do
  STATUS=$(curl -s -X GET $BASE_URL/sessions/$SESSION_ID/status \
    -H "X-API-Key: $API_KEY")
  
  SESSION_STATUS=$(echo $STATUS | jq -r '.session_status')
  
  if [ "$SESSION_STATUS" = "completed" ]; then
    FILENAME=$(echo $STATUS | jq -r '.result.filename')
    echo "Conversion complete! Output: $FILENAME"
    break
  elif [ "$SESSION_STATUS" = "failed" ]; then
    echo "Conversion failed"
    exit 1
  fi
  
  sleep 2
done

# 5. Download result
FILENAME=$(curl -s -X GET $BASE_URL/sessions/$SESSION_ID/status \
  -H "X-API-Key: $API_KEY" | jq -r '.result.filename')

curl -X GET $BASE_URL/sessions/$SESSION_ID/download/$FILENAME \
  -H "X-API-Key: $API_KEY" \
  --output $FILENAME
```

---

## Additional Resources

- **Interactive API Documentation**: `https://blenderapi.stage.motorenflug.at/docs`
- **Alternative API Docs**: `https://blenderapi.stage.motorenflug.at/redoc`
- **Health Check**: `https://blenderapi.stage.motorenflug.at/health`

---

## Support

For issues or questions:
1. Check the API documentation at `/docs`
2. Review error messages in the response body
3. Check session logs using `/sessions/{id}/logs`
4. Contact your administrator

---

**Last Updated**: December 29, 2025  
**API Version**: 1.0.0

