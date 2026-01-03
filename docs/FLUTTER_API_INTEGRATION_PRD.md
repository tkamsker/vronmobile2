# BlenderAPI - Flutter Integration PRD

**Product Requirements Document for Flutter Developers**

**Version**: 1.1.0  
**Last Updated**: 2025-12-30  
**API Base URL**: `https://blenderapi.stage.motorenflug.at`  
**Status**: Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Authentication](#authentication)
4. [API Endpoints](#api-endpoints)
5. [Flutter Implementation Guide](#flutter-implementation-guide)
6. [Critical Implementation Requirements](#critical-implementation-requirements)
7. [Error Handling](#error-handling)
8. [Testing](#testing)
9. [Best Practices](#best-practices)
10. [Complete Code Examples](#complete-code-examples)

---

## Overview

### What is BlenderAPI?

BlenderAPI is a **session-based 3D processing service** that provides:

- **USDZ to GLB Conversion**: Convert Apple's USDZ files to standard GLB format
- **Navigation Mesh Generation**: Create navigation meshes for game AI pathfinding
- **Real-Time Progress Monitoring**: Track processing status with polling or SSE
- **Session Investigation**: Debug and diagnose processing issues
- **Secure File Handling**: Isolated sessions with automatic cleanup

### Key Capabilities

| Feature | Description | Use Case |
|---------|-------------|----------|
| Format Conversion | USDZ → GLB with material preservation | Cross-platform 3D model compatibility |
| NavMesh Generation | Create walkable mesh for AI pathfinding | Game development, AR navigation |
| Session Isolation | Each session has isolated workspace | Security, multi-tenant support |
| Automatic Cleanup | Sessions expire after 1 hour (TTL) | Resource management |
| Investigation API | Debug failed conversions | Development, support |

### Technical Specifications

- **Max File Size**: 500MB
- **Max Sessions per API Key**: 50 concurrent
- **Session TTL**: 3600 seconds (1 hour)
- **Processing Timeout**: 900 seconds (15 minutes)
- **Rate Limiting**: 60 requests/minute per API key
- **Response Format**: JSON (except file downloads)

---

## Architecture

### Session-Based Workflow

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                    │
└─────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS + API Key
                            ▼
┌─────────────────────────────────────────────────────────┐
│                      BlenderAPI                          │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │  Session   │  │  Processing  │  │  File Storage  │ │
│  │  Manager   │─▶│  Queue       │─▶│  (Workspace)   │ │
│  └────────────┘  └──────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
                  ┌──────────────────┐
                  │  Blender Engine  │
                  │  (Headless)      │
                  └──────────────────┘
```

### Session Lifecycle

```
1. CREATE      → Session initialized (sess_xxx)
   ↓
2. UPLOAD      → File uploaded to session workspace
   ↓
3. PROCESS     → Conversion/generation starts
   ↓
4. POLL        → Check status until completed
   ↓
5. DOWNLOAD    → Retrieve processed file
   ↓
6. DELETE      → Cleanup session (or auto-expire)
```

### File System Structure

```
/data/sessions/{session_id}/
├── input/                    # Uploaded files
│   └── scan.usdz
├── output/                   # Processed results
│   └── scan.glb
├── logs/                     # Processing logs
│   └── blender.log
├── status.json               # Real-time status
├── meta.json                 # Result metadata
└── params.json               # Processing parameters
```

---

## Authentication

### API Key Authentication

All endpoints (except `/health`) require an API key sent in the `X-API-Key` header.

```dart
final headers = {
  'X-API-Key': 'your-api-key-here',
  'Content-Type': 'application/json',
};
```

### Getting an API Key

Contact your administrator to obtain an API key. API keys are:
- At least 16 characters long
- Configured server-side
- Rate-limited per key (60 req/min)
- Session-limited per key (50 concurrent)

### Security Best Practices

```dart
// ✅ DO: Store API key securely
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'blender_api_key', value: apiKey);

// ❌ DON'T: Hardcode API keys in source code
const apiKey = 'dev-test-key'; // NEVER DO THIS IN PRODUCTION
```

---

## API Endpoints

### Summary Table

| Endpoint | Method | Auth | Purpose | Response Time |
|----------|--------|------|---------|---------------|
| `/health` | GET | No | Health check | < 100ms |
| `/sessions` | POST | Yes | Create session | < 200ms |
| `/sessions/{id}/upload` | POST | Yes | Upload file | Depends on size |
| `/sessions/{id}/convert` | POST | Yes | Start USDZ→GLB | < 500ms |
| `/sessions/{id}/navmesh` | POST | Yes | Start NavMesh | < 500ms |
| `/sessions/{id}/status` | GET | Yes | Check progress | < 200ms |
| `/sessions/{id}/download/{file}` | GET | Yes | Download result | Streaming |
| `/sessions/{id}/logs` | GET | Yes | Get logs | < 500ms |
| `/sessions/{id}/logs/stream` | GET | Yes | Stream logs (SSE) | Streaming |
| `/sessions/{id}/investigate` | GET | Yes | Debug session | < 2000ms |
| `/sessions/{id}` | DELETE | Yes | Delete session | < 200ms |

---

## Flutter Implementation Guide

### Prerequisites

Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  path: ^1.8.3
  path_provider: ^2.1.1
  flutter_secure_storage: ^9.0.0
  
  # Optional for SSE streaming
  event_source: ^2.1.0
```

### 1. API Service Setup

Create `lib/services/blender_api_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BlenderApiService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  BlenderApiService({
    this.baseUrl = 'https://blenderapi.stage.motorenflug.at',
  });

  // Get API key from secure storage
  Future<String> _getApiKey() async {
    final apiKey = await _storage.read(key: 'blender_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key not found. Please authenticate first.');
    }
    return apiKey;
  }

  // Build headers with API key
  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? additionalHeaders,
  }) async {
    final apiKey = await _getApiKey();
    return {
      'X-API-Key': apiKey,
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };
  }

  // Generic error handler
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final body = json.decode(response.body);
      final errorCode = body['error_code'] ?? 'UNKNOWN_ERROR';
      final message = body['message'] ?? 'An error occurred';
      throw BlenderApiException(
        statusCode: response.statusCode,
        errorCode: errorCode,
        message: message,
      );
    }
  }
}

// Custom exception class
class BlenderApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;

  BlenderApiException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
  });

  @override
  String toString() => '[$errorCode] $message (HTTP $statusCode)';
}
```

### 2. Health Check

```dart
// Add to BlenderApiService class

Future<HealthResponse> checkHealth() async {
  final response = await http.get(
    Uri.parse('$baseUrl/health'),
  );

  if (response.statusCode == 200) {
    return HealthResponse.fromJson(json.decode(response.body));
  }
  throw Exception('Health check failed: ${response.statusCode}');
}
```

**Model Class:**

```dart
class HealthResponse {
  final String status;
  final int activeSessions;
  final String cleanupService;

  HealthResponse({
    required this.status,
    required this.activeSessions,
    required this.cleanupService,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    return HealthResponse(
      status: json['status'],
      activeSessions: json['active_sessions'],
      cleanupService: json['cleanup_service'],
    );
  }
}
```

### 3. Create Session

```dart
// Add to BlenderApiService class

Future<SessionResponse> createSession() async {
  final headers = await _buildHeaders();
  
  final response = await http.post(
    Uri.parse('$baseUrl/sessions'),
    headers: headers,
  );

  if (response.statusCode == 201) {
    return SessionResponse.fromJson(json.decode(response.body));
  }
  
  _handleError(response);
  throw Exception('Failed to create session');
}
```

**Model Class:**

```dart
class SessionResponse {
  final String sessionId;
  final DateTime expiresAt;

  SessionResponse({
    required this.sessionId,
    required this.expiresAt,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      sessionId: json['session_id'],
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }
}
```

### 4. Upload File

**CRITICAL**: Read file as bytes ONCE to avoid stream errors.

```dart
// Add to BlenderApiService class

Future<UploadResponse> uploadFile({
  required String sessionId,
  required File file,
  required String assetType, // 'model/gltf-binary' or 'model/vnd.usdz+zip'
  Function(int sent, int total)? onProgress,
}) async {
  final apiKey = await _getApiKey();
  final filename = file.path.split('/').last;
  
  // ✅ CRITICAL: Read file bytes ONCE to avoid stream errors
  final fileBytes = await file.readAsBytes();
  
  final response = await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/upload'),
    headers: {
      'X-API-Key': apiKey,
      'X-Asset-Type': assetType,
      'X-Filename': filename,
      'Content-Type': 'application/octet-stream',
    },
    body: fileBytes, // ✅ Direct bytes, not a stream
  );

  if (response.statusCode == 200) {
    return UploadResponse.fromJson(json.decode(response.body));
  }
  
  _handleError(response);
  throw Exception('Upload failed');
}
```

**Model Class:**

```dart
class UploadResponse {
  final String sessionId;
  final String filename;
  final int sizeBytes;
  final DateTime uploadedAt;

  UploadResponse({
    required this.sessionId,
    required this.filename,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      sessionId: json['session_id'],
      filename: json['filename'],
      sizeBytes: json['size_bytes'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
```

### 5. Start Conversion (USDZ → GLB)

```dart
// Add to BlenderApiService class

Future<ProcessingStartedResponse> convertUsdzToGlb({
  required String sessionId,
  required String inputFilename,
  String? outputFilename,
  ConversionParams? params,
}) async {
  final headers = await _buildHeaders();
  
  final body = {
    'job_type': 'usdz_to_glb', // ✅ REQUIRED field
    'input_filename': inputFilename,
    if (outputFilename != null) 'output_filename': outputFilename,
    if (params != null) 'conversion_params': params.toJson(),
  };

  final response = await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/convert'),
    headers: headers,
    body: json.encode(body),
  );

  if (response.statusCode == 200) {
    return ProcessingStartedResponse.fromJson(json.decode(response.body));
  }
  
  _handleError(response);
  throw Exception('Conversion failed to start');
}
```

**Model Classes:**

```dart
class ConversionParams {
  final bool applyScale;
  final bool mergeMeshes;
  final double targetScale;

  ConversionParams({
    this.applyScale = false,
    this.mergeMeshes = false,
    this.targetScale = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'apply_scale': applyScale,
    'merge_meshes': mergeMeshes,
    'target_scale': targetScale,
  };
}

class ProcessingStartedResponse {
  final String sessionId;
  final String jobType;
  final DateTime startedAt;

  ProcessingStartedResponse({
    required this.sessionId,
    required this.jobType,
    required this.startedAt,
  });

  factory ProcessingStartedResponse.fromJson(Map<String, dynamic> json) {
    return ProcessingStartedResponse(
      sessionId: json['session_id'],
      jobType: json['job_type'],
      startedAt: DateTime.parse(json['started_at']),
    );
  }
}
```

### 6. Poll Status

```dart
// Add to BlenderApiService class

Future<StatusResponse> getStatus(String sessionId) async {
  final headers = await _buildHeaders();
  
  final response = await http.get(
    Uri.parse('$baseUrl/sessions/$sessionId/status'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return StatusResponse.fromJson(json.decode(response.body));
  }
  
  _handleError(response);
  throw Exception('Failed to get status');
}

// Helper: Poll until completion
Future<StatusResponse> pollUntilComplete({
  required String sessionId,
  Duration pollInterval = const Duration(seconds: 2),
  Duration timeout = const Duration(minutes: 15),
  Function(StatusResponse)? onProgress,
}) async {
  final stopwatch = Stopwatch()..start();
  
  while (stopwatch.elapsed < timeout) {
    final status = await getStatus(sessionId);
    
    // Callback for progress updates
    onProgress?.call(status);
    
    // Check terminal states
    if (status.sessionStatus == 'completed') {
      return status;
    } else if (status.sessionStatus == 'failed') {
      throw Exception('Processing failed: ${status.errorMessage}');
    }
    
    // Wait before next poll
    await Future.delayed(pollInterval);
  }
  
  throw TimeoutException('Processing timeout after ${timeout.inMinutes} minutes');
}
```

**Model Class:**

```dart
class StatusResponse {
  final String sessionId;
  final String sessionStatus; // pending, processing, completed, failed
  final String processingStage;
  final int progress; // 0-100
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final ResultMetadata? result;

  StatusResponse({
    required this.sessionId,
    required this.sessionStatus,
    required this.processingStage,
    required this.progress,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.result,
  });

  factory StatusResponse.fromJson(Map<String, dynamic> json) {
    return StatusResponse(
      sessionId: json['session_id'],
      sessionStatus: json['session_status'],
      processingStage: json['processing_stage'],
      progress: json['progress'] ?? 0,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      errorMessage: json['error_message'],
      result: json['result'] != null 
          ? ResultMetadata.fromJson(json['result']) 
          : null,
    );
  }
}

class ResultMetadata {
  final String filename;
  final int sizeBytes;
  final String format;
  final int? polygonCount;
  final int? meshCount;
  final int? materialCount;

  ResultMetadata({
    required this.filename,
    required this.sizeBytes,
    required this.format,
    this.polygonCount,
    this.meshCount,
    this.materialCount,
  });

  factory ResultMetadata.fromJson(Map<String, dynamic> json) {
    return ResultMetadata(
      filename: json['filename'],
      sizeBytes: json['size_bytes'],
      format: json['format'],
      polygonCount: json['polygon_count'],
      meshCount: json['mesh_count'],
      materialCount: json['material_count'],
    );
  }
}
```

### 7. Download File

**CRITICAL**: Add delays before download to avoid race conditions.

```dart
// Add to BlenderApiService class

Future<File> downloadFile({
  required String sessionId,
  required String filename,
  required String savePath,
  Function(int received, int total)? onProgress,
}) async {
  final apiKey = await _getApiKey();
  
  final response = await http.get(
    Uri.parse('$baseUrl/sessions/$sessionId/download/$filename'),
    headers: {
      'X-API-Key': apiKey,
    },
  );

  if (response.statusCode == 200) {
    final file = File(savePath);
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
  
  _handleError(response);
  throw Exception('Download failed');
}
```

### 8. Investigation API (NEW)

Debug and diagnose session issues:

```dart
// Add to BlenderApiService class

Future<InvestigationResponse> investigate(String sessionId) async {
  final headers = await _buildHeaders();
  
  final response = await http.get(
    Uri.parse('$baseUrl/sessions/$sessionId/investigate'),
    headers: headers,
  );

  if (response.statusCode == 200) {
    return InvestigationResponse.fromJson(json.decode(response.body));
  }
  
  _handleError(response);
  throw Exception('Investigation failed');
}
```

**Model Classes:**

```dart
class InvestigationResponse {
  final SessionInfo sessionInfo;
  final WorkspaceStructure workspaceStructure;
  final ProcessingData processingData;
  final List<LogSummary> logSummaries;
  final ErrorDetails? errorDetails;

  InvestigationResponse({
    required this.sessionInfo,
    required this.workspaceStructure,
    required this.processingData,
    required this.logSummaries,
    this.errorDetails,
  });

  factory InvestigationResponse.fromJson(Map<String, dynamic> json) {
    return InvestigationResponse(
      sessionInfo: SessionInfo.fromJson(json['session_info']),
      workspaceStructure: WorkspaceStructure.fromJson(json['workspace_structure']),
      processingData: ProcessingData.fromJson(json['processing_data']),
      logSummaries: (json['log_summaries'] as List)
          .map((e) => LogSummary.fromJson(e))
          .toList(),
      errorDetails: json['error_details'] != null
          ? ErrorDetails.fromJson(json['error_details'])
          : null,
    );
  }
}

class SessionInfo {
  final String sessionId;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int ttlRemaining;

  SessionInfo({
    required this.sessionId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.ttlRemaining,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionId: json['session_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      ttlRemaining: json['ttl_remaining'],
    );
  }
}

class WorkspaceStructure {
  final List<FileMetadata> inputFiles;
  final List<FileMetadata> outputFiles;
  final List<FileMetadata> logFiles;
  final int totalSizeBytes;
  final int fileCount;

  WorkspaceStructure({
    required this.inputFiles,
    required this.outputFiles,
    required this.logFiles,
    required this.totalSizeBytes,
    required this.fileCount,
  });

  factory WorkspaceStructure.fromJson(Map<String, dynamic> json) {
    return WorkspaceStructure(
      inputFiles: (json['input_files'] as List)
          .map((e) => FileMetadata.fromJson(e))
          .toList(),
      outputFiles: (json['output_files'] as List)
          .map((e) => FileMetadata.fromJson(e))
          .toList(),
      logFiles: (json['log_files'] as List)
          .map((e) => FileMetadata.fromJson(e))
          .toList(),
      totalSizeBytes: json['total_size_bytes'],
      fileCount: json['file_count'],
    );
  }
}

class FileMetadata {
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;

  FileMetadata({
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      name: json['name'],
      sizeBytes: json['size_bytes'],
      modifiedAt: DateTime.parse(json['modified_at']),
    );
  }
}

class ProcessingData {
  final dynamic statusJson;
  final dynamic metaJson;
  final dynamic paramsJson;

  ProcessingData({
    this.statusJson,
    this.metaJson,
    this.paramsJson,
  });

  factory ProcessingData.fromJson(Map<String, dynamic> json) {
    return ProcessingData(
      statusJson: json['status_json'],
      metaJson: json['meta_json'],
      paramsJson: json['params_json'],
    );
  }
}

class LogSummary {
  final String filename;
  final int sizeBytes;
  final int lineCount;
  final List<String> sampledLines;
  final int errorCount;
  final int warningCount;
  final bool sampleTruncated;

  LogSummary({
    required this.filename,
    required this.sizeBytes,
    required this.lineCount,
    required this.sampledLines,
    required this.errorCount,
    required this.warningCount,
    required this.sampleTruncated,
  });

  factory LogSummary.fromJson(Map<String, dynamic> json) {
    return LogSummary(
      filename: json['filename'],
      sizeBytes: json['size_bytes'],
      lineCount: json['line_count'],
      sampledLines: List<String>.from(json['sampled_lines']),
      errorCount: json['error_count'],
      warningCount: json['warning_count'],
      sampleTruncated: json['sample_truncated'],
    );
  }
}

class ErrorDetails {
  final String errorType;
  final String errorMessage;
  final DateTime timestamp;
  final String? stackTrace;

  ErrorDetails({
    required this.errorType,
    required this.errorMessage,
    required this.timestamp,
    this.stackTrace,
  });

  factory ErrorDetails.fromJson(Map<String, dynamic> json) {
    return ErrorDetails(
      errorType: json['error_type'],
      errorMessage: json['error_message'],
      timestamp: DateTime.parse(json['timestamp']),
      stackTrace: json['stack_trace'],
    );
  }
}
```

### 9. Delete Session

```dart
// Add to BlenderApiService class

Future<void> deleteSession(String sessionId) async {
  final headers = await _buildHeaders();
  
  final response = await http.delete(
    Uri.parse('$baseUrl/sessions/$sessionId'),
    headers: headers,
  );

  if (response.statusCode == 204) {
    return; // Success - no content
  }
  
  if (response.statusCode == 404) {
    // Session already deleted or expired - not an error
    return;
  }
  
  _handleError(response);
  throw Exception('Failed to delete session');
}
```

---

## Critical Implementation Requirements

### ⚠️ RACE CONDITION FIX - MANDATORY WAIT PERIODS

**CRITICAL**: You MUST add delays to prevent race conditions between download and deletion.

```dart
// ✅ CORRECT Implementation
Future<File> completeWorkflow(String sessionId, String filename, String savePath) async {
  // 1. Poll until processing completes
  final status = await apiService.pollUntilComplete(sessionId: sessionId);
  
  // 2. ⚠️ CRITICAL: Wait 3 seconds after completion
  //    Reason: File system needs time to finalize the file
  await Future.delayed(Duration(seconds: 3));
  
  // 3. Download the file
  final file = await apiService.downloadFile(
    sessionId: sessionId,
    filename: filename,
    savePath: savePath,
  );
  
  // 4. ⚠️ CRITICAL: Wait 2 seconds after download
  //    Reason: HTTP stream needs time to fully close
  await Future.delayed(Duration(seconds: 2));
  
  // 5. Delete session
  await apiService.deleteSession(sessionId);
  
  return file;
}

// ❌ WRONG Implementation (causes RuntimeError)
Future<File> completeWorkflowWrong(String sessionId, String filename, String savePath) async {
  final status = await apiService.pollUntilComplete(sessionId: sessionId);
  final file = await apiService.downloadFile(...);
  await apiService.deleteSession(sessionId); // ❌ Too fast! Stream still active
  return file;
}
```

**Why the waits are necessary:**

1. **3s after completion**: 
   - Backend file system needs time to flush buffers
   - Blender may still be writing final metadata
   - File size needs to stabilize

2. **2s after download**:
   - HTTP chunked transfer encoding needs to complete
   - Connection needs to cleanly close
   - Prevents "Content-Length" errors

### Upload File Correctly

**CRITICAL**: Always read file as bytes ONCE.

```dart
// ✅ CORRECT
Future<void> uploadFileCorrect(String sessionId, File file) async {
  final fileBytes = await file.readAsBytes(); // Read ONCE
  
  await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/upload'),
    headers: {...},
    body: fileBytes, // Use bytes directly
  );
}

// ❌ WRONG (causes "Stream has already been listened to" error)
Future<void> uploadFileWrong(String sessionId, File file) async {
  await http.post(
    Uri.parse('$baseUrl/sessions/$sessionId/upload'),
    headers: {...},
    body: file.openRead(), // ❌ Stream - will cause errors
  );
}
```

### Status Polling Best Practices

```dart
// ✅ GOOD: Poll with reasonable interval
await apiService.pollUntilComplete(
  sessionId: sessionId,
  pollInterval: Duration(seconds: 2), // Poll every 2 seconds
  timeout: Duration(minutes: 15),     // Timeout after 15 minutes
  onProgress: (status) {
    print('Progress: ${status.progress}%');
    // Update UI here
  },
);

// ❌ BAD: Poll too frequently (wastes resources, may hit rate limits)
while (true) {
  final status = await getStatus(sessionId);
  await Future.delayed(Duration(milliseconds: 100)); // ❌ Too fast!
}
```

---

## Error Handling

### Standard Error Response

All errors follow this format:

```json
{
  "error_code": "ERROR_TYPE",
  "message": "Human-readable error message",
  "details": {
    "additional": "context"
  }
}
```

### Error Codes

| Code | HTTP | Meaning | Action |
|------|------|---------|--------|
| `UNAUTHORIZED` | 401 | Missing/invalid API key | Check authentication |
| `FORBIDDEN` | 403 | Access denied | Check session ownership |
| `NOT_FOUND` | 404 | Session/file not found | Check session ID |
| `INVALID_INPUT` | 400 | Bad request data | Check request payload |
| `TOO_MANY_REQUESTS` | 429 | Rate limit exceeded | Wait and retry |
| `SESSION_LIMIT_EXCEEDED` | 429 | Too many sessions | Delete old sessions |
| `FILE_TOO_LARGE` | 413 | File > 500MB | Compress or split file |
| `PROCESSING_TIMEOUT` | 408 | Took > 15 minutes | Simplify model |
| `INTERNAL_ERROR` | 500 | Server error | Report to support |

### Error Handling Implementation

```dart
class BlenderApiErrorHandler {
  static Future<T> handleApiCall<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on BlenderApiException catch (e) {
      switch (e.errorCode) {
        case 'UNAUTHORIZED':
          // Prompt user to re-authenticate
          throw AuthenticationException(e.message);
        
        case 'FORBIDDEN':
          // User doesn't own this session
          throw PermissionException(e.message);
        
        case 'NOT_FOUND':
          // Session expired or doesn't exist
          throw NotFoundException(e.message);
        
        case 'TOO_MANY_REQUESTS':
          // Rate limited - wait and retry
          await Future.delayed(Duration(seconds: 60));
          return await call(); // Retry
        
        case 'SESSION_LIMIT_EXCEEDED':
          // Too many active sessions
          throw SessionLimitException(e.message);
        
        case 'FILE_TOO_LARGE':
          throw FileTooLargeException(e.message);
        
        case 'PROCESSING_TIMEOUT':
          throw ProcessingTimeoutException(e.message);
        
        default:
          throw UnknownApiException(e.message);
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } on TimeoutException {
      throw NetworkException('Request timeout');
    } catch (e) {
      throw UnknownApiException('Unexpected error: $e');
    }
  }
}

// Usage
final session = await BlenderApiErrorHandler.handleApiCall(
  () => apiService.createSession(),
);
```

---

## Testing

### Unit Tests

```dart
// test/services/blender_api_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

void main() {
  group('BlenderApiService', () {
    late BlenderApiService apiService;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      apiService = BlenderApiService(httpClient: mockClient);
    });

    test('createSession returns SessionResponse on success', () async {
      // Arrange
      when(mockClient.post(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                '{"session_id": "sess_test", "expires_at": "2025-12-30T12:00:00Z"}',
                201,
              ));

      // Act
      final response = await apiService.createSession();

      // Assert
      expect(response.sessionId, 'sess_test');
      expect(response.expiresAt.year, 2025);
    });

    test('uploadFile handles large files correctly', () async {
      // Test upload with mock file
    });

    test('pollUntilComplete times out after timeout period', () async {
      // Test timeout behavior
    });
  });
}
```

### Integration Tests

```dart
// integration_test/api_workflow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete API Workflow', () {
    late BlenderApiService apiService;

    setUpAll(() {
      apiService = BlenderApiService(
        baseUrl: 'https://blenderapi.stage.motorenflug.at',
      );
      // Set test API key
    });

    testWidgets('USDZ to GLB conversion workflow', (tester) async {
      // 1. Create session
      final session = await apiService.createSession();
      expect(session.sessionId, isNotEmpty);

      // 2. Upload file
      final testFile = File('test_assets/test.usdz');
      await apiService.uploadFile(
        sessionId: session.sessionId,
        file: testFile,
        assetType: 'model/vnd.usdz+zip',
      );

      // 3. Start conversion
      await apiService.convertUsdzToGlb(
        sessionId: session.sessionId,
        inputFilename: 'test.usdz',
      );

      // 4. Poll until complete
      final status = await apiService.pollUntilComplete(
        sessionId: session.sessionId,
        timeout: Duration(minutes: 5),
      );
      expect(status.sessionStatus, 'completed');

      // 5. Wait before download (CRITICAL)
      await Future.delayed(Duration(seconds: 3));

      // 6. Download result
      final outputFile = await apiService.downloadFile(
        sessionId: session.sessionId,
        filename: 'test.glb',
        savePath: '/tmp/test_output.glb',
      );
      expect(outputFile.existsSync(), true);

      // 7. Wait before delete (CRITICAL)
      await Future.delayed(Duration(seconds: 2));

      // 8. Cleanup
      await apiService.deleteSession(session.sessionId);
    });
  });
}
```

---

## Best Practices

### 1. Session Management

```dart
class SessionManager {
  final BlenderApiService _api;
  final Map<String, SessionResponse> _activeSessions = {};

  SessionManager(this._api);

  // Create and track session
  Future<String> createTrackedSession() async {
    final session = await _api.createSession();
    _activeSessions[session.sessionId] = session;
    return session.sessionId;
  }

  // Cleanup all sessions on app exit
  Future<void> cleanupAllSessions() async {
    for (final sessionId in _activeSessions.keys) {
      try {
        await _api.deleteSession(sessionId);
      } catch (e) {
        print('Failed to cleanup session $sessionId: $e');
      }
    }
    _activeSessions.clear();
  }

  // Check for expired sessions
  Future<void> cleanupExpiredSessions() async {
    final now = DateTime.now();
    final expired = _activeSessions.entries
        .where((e) => e.value.expiresAt.isBefore(now))
        .map((e) => e.key)
        .toList();

    for (final sessionId in expired) {
      _activeSessions.remove(sessionId);
      try {
        await _api.deleteSession(sessionId);
      } catch (e) {
        // Ignore - probably already expired server-side
      }
    }
  }
}
```

### 2. Progress Tracking

```dart
class ConversionProgress {
  final String sessionId;
  final int progress; // 0-100
  final String stage;
  final Duration elapsed;

  ConversionProgress({
    required this.sessionId,
    required this.progress,
    required this.stage,
    required this.elapsed,
  });
}

class ConversionProgressNotifier extends ChangeNotifier {
  ConversionProgress? _progress;
  ConversionProgress? get progress => _progress;

  Future<void> trackConversion(BlenderApiService api, String sessionId) async {
    final stopwatch = Stopwatch()..start();
    
    await api.pollUntilComplete(
      sessionId: sessionId,
      onProgress: (status) {
        _progress = ConversionProgress(
          sessionId: sessionId,
          progress: status.progress,
          stage: status.processingStage,
          elapsed: stopwatch.elapsed,
        );
        notifyListeners();
      },
    );
  }
}
```

### 3. Caching Downloaded Files

```dart
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

class FileCache {
  static Future<String> getCachePath(String sessionId, String filename) async {
    final cacheDir = await getApplicationCacheDirectory();
    final hash = md5.convert(utf8.encode('$sessionId/$filename')).toString();
    return '${cacheDir.path}/$hash.glb';
  }

  static Future<File?> getCachedFile(String sessionId, String filename) async {
    final path = await getCachePath(sessionId, filename);
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static Future<File> downloadOrCache(
    BlenderApiService api,
    String sessionId,
    String filename,
  ) async {
    // Check cache first
    final cached = await getCachedFile(sessionId, filename);
    if (cached != null) {
      print('Using cached file: ${cached.path}');
      return cached;
    }

    // Download and cache
    final path = await getCachePath(sessionId, filename);
    return await api.downloadFile(
      sessionId: sessionId,
      filename: filename,
      savePath: path,
    );
  }
}
```

### 4. Retry Logic

```dart
class RetryPolicy {
  static Future<T> retry<T>({
    required Future<T> Function() action,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempt = 0;
    
    while (true) {
      attempt++;
      
      try {
        return await action();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        
        if (shouldRetry != null && e is Exception && !shouldRetry(e)) {
          rethrow;
        }
        
        print('Attempt $attempt failed: $e. Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay * attempt); // Exponential backoff
      }
    }
  }
}

// Usage
final session = await RetryPolicy.retry(
  action: () => apiService.createSession(),
  maxAttempts: 3,
  shouldRetry: (e) => e is NetworkException,
);
```

---

## Complete Code Examples

### Example 1: Complete USDZ to GLB Conversion

```dart
import 'dart:io';
import 'package:flutter/material.dart';

class UsdzToGlbConverter extends StatefulWidget {
  @override
  _UsdzToGlbConverterState createState() => _UsdzToGlbConverterState();
}

class _UsdzToGlbConverterState extends State<UsdzToGlbConverter> {
  final BlenderApiService _api = BlenderApiService();
  
  String? _sessionId;
  double _progress = 0.0;
  String _status = 'Ready';
  File? _resultFile;

  Future<void> _convertFile(File usdzFile) async {
    setState(() {
      _status = 'Creating session...';
      _progress = 0.0;
    });

    try {
      // 1. Create session
      final session = await _api.createSession();
      _sessionId = session.sessionId;
      
      setState(() {
        _status = 'Uploading file...';
        _progress = 0.1;
      });

      // 2. Upload file
      await _api.uploadFile(
        sessionId: _sessionId!,
        file: usdzFile,
        assetType: 'model/vnd.usdz+zip',
      );

      setState(() {
        _status = 'Starting conversion...';
        _progress = 0.2;
      });

      // 3. Start conversion
      await _api.convertUsdzToGlb(
        sessionId: _sessionId!,
        inputFilename: usdzFile.path.split('/').last,
        params: ConversionParams(
          applyScale: false,
          mergeMeshes: false,
        ),
      );

      setState(() {
        _status = 'Converting...';
      });

      // 4. Poll until complete
      await _api.pollUntilComplete(
        sessionId: _sessionId!,
        onProgress: (status) {
          setState(() {
            _progress = 0.2 + (status.progress / 100 * 0.7);
            _status = 'Converting: ${status.progress}%';
          });
        },
      );

      setState(() {
        _status = 'Finalizing...';
        _progress = 0.9;
      });

      // 5. ⚠️ CRITICAL WAIT: Let file system stabilize
      await Future.delayed(Duration(seconds: 3));

      // 6. Download result
      final outputFilename = usdzFile.path.split('/').last.replaceAll('.usdz', '.glb');
      final cachePath = await FileCache.getCachePath(_sessionId!, outputFilename);
      
      _resultFile = await _api.downloadFile(
        sessionId: _sessionId!,
        filename: outputFilename,
        savePath: cachePath,
      );

      setState(() {
        _status = 'Cleaning up...';
        _progress = 0.95;
      });

      // 7. ⚠️ CRITICAL WAIT: Let download stream close
      await Future.delayed(Duration(seconds: 2));

      // 8. Cleanup
      await _api.deleteSession(_sessionId!);

      setState(() {
        _status = 'Complete!';
        _progress = 1.0;
      });

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversion complete! File: ${_resultFile!.path}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _progress = 0.0;
      });

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conversion failed: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Cleanup on error
      if (_sessionId != null) {
        try {
          await _api.deleteSession(_sessionId!);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('USDZ to GLB Converter')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_status'),
            SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 16),
            Text('Progress: ${(_progress * 100).toStringAsFixed(0)}%'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _progress == 0.0 || _progress == 1.0
                  ? () async {
                      // Pick file (use file_picker package)
                      // final file = await FilePicker...
                      // await _convertFile(file);
                    }
                  : null,
              child: Text('Select USDZ File'),
            ),
            if (_resultFile != null) ...[
              SizedBox(height: 16),
              Text('Result: ${_resultFile!.path}'),
              ElevatedButton(
                onPressed: () {
                  // Open file or share
                },
                child: Text('View Result'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Example 2: Debug Failed Conversion

```dart
class ConversionDebugger extends StatelessWidget {
  final String sessionId;
  final BlenderApiService api = BlenderApiService();

  ConversionDebugger({required this.sessionId});

  Future<void> _debugConversion(BuildContext context) async {
    try {
      // Get investigation data
      final investigation = await api.investigate(sessionId);

      // Show dialog with details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Session Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session ID: ${investigation.sessionInfo.sessionId}'),
                Text('Status: ${investigation.sessionInfo.status}'),
                Text('TTL Remaining: ${investigation.sessionInfo.ttlRemaining}s'),
                SizedBox(height: 16),
                Text('Workspace:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('  Input files: ${investigation.workspaceStructure.inputFiles.length}'),
                Text('  Output files: ${investigation.workspaceStructure.outputFiles.length}'),
                Text('  Total size: ${investigation.workspaceStructure.totalSizeBytes} bytes'),
                SizedBox(height: 16),
                if (investigation.errorDetails != null) ...[
                  Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('  Type: ${investigation.errorDetails!.errorType}'),
                  Text('  Message: ${investigation.errorDetails!.errorMessage}'),
                ],
                SizedBox(height: 16),
                Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...investigation.logSummaries.map((log) => 
                  Text('  ${log.filename}: ${log.errorCount} errors, ${log.warningCount} warnings')
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _debugConversion(context),
      child: Text('Debug Conversion'),
    );
  }
}
```

---

## Appendix

### A. Rate Limiting

**Limits:**
- 60 requests/minute per API key
- 50 concurrent sessions per API key

**Handling Rate Limits:**

```dart
if (response.statusCode == 429) {
  final retryAfter = response.headers['retry-after'];
  await Future.delayed(Duration(seconds: int.parse(retryAfter ?? '60')));
  // Retry request
}
```

### B. File Size Limits

- **Max upload**: 500MB
- **Recommended**: < 100MB for best performance
- **Chunked upload**: Not currently supported (use direct upload)

### C. Timeouts

- **Processing**: 15 minutes (900s)
- **Session TTL**: 1 hour (3600s)
- **Network request**: 30 seconds (configure in http client)

### D. Supported File Formats

**Input:**
- `.usdz` - Universal Scene Description (Apple)
- `.glb` - GL Transmission Format Binary (for NavMesh)

**Output:**
- `.glb` - GL Transmission Format Binary

---

## Support

### Questions?

- **Documentation**: Check `CONTENT_LENGTH_FIX_FINAL.md` for latest fixes
- **API Spec**: See `specs/007-session-investigate/` for detailed specs
- **Issues**: Report at GitLab Issues
- **Contact**: Support team for API key requests

### Changelog

**v1.1.0** (2025-12-30)
- ✅ Added Investigation API for debugging
- ✅ Fixed Content-Length race condition
- ✅ Added async file I/O with chunked encoding
- ✅ Updated documentation with critical wait periods

**v1.0.0** (2025-12-29)
- Initial release
- USDZ to GLB conversion
- NavMesh generation
- Session management

---

**End of Document**

For the latest updates, check the GitLab repository.
