# Data Model: Enhanced Backend Error Handling

**Feature**: 015-backend-error-handling
**Date**: 2025-12-30
**Purpose**: Define entities, relationships, validation rules, and state transitions for error handling subsystem

## Overview

This document defines the data structures used throughout the error handling feature, including error context, session diagnostics, retry policy configuration, and offline queue operations. All entities are designed for JSON serialization to support local logging and API communication.

---

## Entity Diagram

```
┌─────────────────┐
│  ErrorContext   │──┐
└─────────────────┘  │
                     │
                     │  logged by
                     │
                     ▼
              ┌──────────────────┐
              │ ErrorLogService  │
              └──────────────────┘
                     │
                     │  persists to
                     │
                     ▼
              ┌──────────────────┐
              │  error_logs.json │  (File)
              └──────────────────┘

┌─────────────────────┐
│ SessionDiagnostics  │◄─── fetched from ───┐
└─────────────────────┘                      │
         │                                   │
         │  contains                         │
         ▼                                   │
┌─────────────────────┐            ┌─────────────────────────┐
│  WorkspaceFilesInfo │            │ SessionInvestigationSvc │
├─────────────────────┤            └─────────────────────────┘
│  LogSummary         │                      │
├─────────────────────┤                      │
│  ErrorDetails       │                      │  calls
└─────────────────────┘                      │
                                             ▼
                                  ┌─────────────────────────┐
                                  │  BlenderAPI             │
                                  │  GET /sessions/{id}/    │
                                  │      investigate        │
                                  └─────────────────────────┘

┌──────────────────┐
│  RetryPolicy     │──► classifies ──► ErrorContext
└──────────────────┘

┌──────────────────────┐
│  PendingOperation    │──┐
└──────────────────────┘  │  queued in
                          │
                          ▼
                   ┌─────────────────────┐
                   │ ConnectivityService │
                   └─────────────────────┘
                          │
                          │  persists to
                          │
                          ▼
                   ┌─────────────────────┐
                   │  shared_preferences │
                   │  (error_queue)      │
                   └─────────────────────┘
```

---

## Core Entities

### 1. ErrorContext

**Purpose**: Captures complete error state for logging, retry decisions, and user display.

**Location**: `lib/features/scanning/models/error_context.dart`

**Fields**:

| Field | Type | Required | Description | Validation |
|-------|------|----------|-------------|------------|
| `timestamp` | `DateTime` | Yes | When error occurred (ISO 8601) | Must be valid DateTime |
| `sessionId` | `String?` | No | BlenderAPI session ID (if applicable) | Format: `sess_*` or null |
| `httpStatus` | `int?` | No | HTTP status code | 100-599 or null |
| `errorCode` | `String?` | No | BlenderAPI error code | Non-empty string or null |
| `message` | `String` | Yes | User-friendly error message | Non-empty, max 500 chars |
| `technicalMessage` | `String?` | No | Original technical error message | Max 1000 chars |
| `retryCount` | `int` | Yes | Number of retry attempts so far | >= 0, <= 3 |
| `userId` | `String?` | No | User identifier (non-sensitive) | UUID or null |
| `stackTrace` | `String?` | No | Sanitized stack trace for debugging | Max 2000 chars, sensitive paths removed |
| `isRecoverable` | `bool` | Yes | Whether error is eligible for retry | Computed by RetryPolicy |

**JSON Serialization**:

```dart
@JsonSerializable()
class ErrorContext {
  final DateTime timestamp;
  final String? sessionId;
  final int? httpStatus;
  final String? errorCode;
  final String message;
  final String? technicalMessage;
  final int retryCount;
  final String? userId;
  final String? stackTrace;
  final bool isRecoverable;

  ErrorContext({
    required this.timestamp,
    this.sessionId,
    this.httpStatus,
    this.errorCode,
    required this.message,
    this.technicalMessage,
    required this.retryCount,
    this.userId,
    this.stackTrace,
    required this.isRecoverable,
  });

  factory ErrorContext.fromJson(Map<String, dynamic> json) =>
      _$ErrorContextFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorContextToJson(this);

  /// Creates new ErrorContext with incremented retry count
  ErrorContext withRetry() => ErrorContext(
    timestamp: DateTime.now(),
    sessionId: sessionId,
    httpStatus: httpStatus,
    errorCode: errorCode,
    message: message,
    technicalMessage: technicalMessage,
    retryCount: retryCount + 1,
    userId: userId,
    stackTrace: stackTrace,
    isRecoverable: isRecoverable,
  );
}
```

**Validation Rules**:
- `message` must not be empty
- `retryCount` must be 0-3 (max retries)
- `httpStatus` if present must be valid HTTP status code (100-599)
- `sessionId` if present must match pattern `sess_[A-Za-z0-9_-]+`
- `stackTrace` must be sanitized (no absolute file paths, no secrets)

**State Transitions**: None (immutable entity, new instance created for retry)

---

### 2. SessionDiagnostics

**Purpose**: Represents complete diagnostic information returned by `/sessions/{session_id}/investigate` API endpoint.

**Location**: `lib/features/scanning/models/session_diagnostics.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `sessionId` | `String` | Yes | Session identifier |
| `sessionStatus` | `String` | Yes | Session status (active, processing, completed, failed, expired) |
| `createdAt` | `DateTime` | Yes | Session creation timestamp |
| `expiresAt` | `DateTime` | Yes | Session expiration timestamp (TTL: 1 hour) |
| `lastAccessed` | `DateTime?` | No | Last access timestamp |
| `workspaceExists` | `bool` | Yes | Whether workspace directory exists on server |
| `files` | `WorkspaceFilesInfo?` | No | File structure information |
| `statusData` | `Map<String, dynamic>?` | No | Contents of status.json |
| `metadata` | `Map<String, dynamic>?` | No | Contents of meta.json |
| `parameters` | `Map<String, dynamic>?` | No | Contents of params.json |
| `logsSummary` | `LogSummary?` | No | Summary of blender.log |
| `errorDetails` | `ErrorDetails?` | No | Detailed error information if processing failed |
| `investigationTimestamp` | `DateTime` | Yes | When investigation was performed |

**JSON Serialization**:

```dart
@JsonSerializable()
class SessionDiagnostics {
  final String sessionId;
  final String sessionStatus;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastAccessed;
  final bool workspaceExists;
  final WorkspaceFilesInfo? files;
  final Map<String, dynamic>? statusData;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? parameters;
  final LogSummary? logsSummary;
  final ErrorDetails? errorDetails;
  final DateTime investigationTimestamp;

  SessionDiagnostics({
    required this.sessionId,
    required this.sessionStatus,
    required this.createdAt,
    required this.expiresAt,
    this.lastAccessed,
    required this.workspaceExists,
    this.files,
    this.statusData,
    this.metadata,
    this.parameters,
    this.logsSummary,
    this.errorDetails,
    required this.investigationTimestamp,
  });

  factory SessionDiagnostics.fromJson(Map<String, dynamic> json) =>
      _$SessionDiagnosticsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDiagnosticsToJson(this);

  /// Check if session has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Get human-readable status message
  String get statusMessage {
    switch (sessionStatus) {
      case 'active':
        return 'Session active, ready for upload';
      case 'processing':
        return 'Conversion in progress';
      case 'completed':
        return 'Conversion completed successfully';
      case 'failed':
        return 'Conversion failed';
      case 'expired':
        return 'Session expired (TTL: 1 hour)';
      default:
        return 'Unknown status: $sessionStatus';
    }
  }
}
```

---

### 3. WorkspaceFilesInfo

**Purpose**: Represents file structure of session workspace on BlenderAPI server.

**Location**: `lib/features/scanning/models/session_diagnostics.dart` (nested model)

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `directories` | `Map<String, DirectoryInfo>` | Map of directory name → directory info (input/, output/, logs/) |
| `rootFiles` | `List<FileInfo>` | Files in root of workspace (status.json, params.json, meta.json) |

```dart
@JsonSerializable()
class WorkspaceFilesInfo {
  final Map<String, DirectoryInfo> directories;
  final List<FileInfo> rootFiles;

  WorkspaceFilesInfo({
    required this.directories,
    required this.rootFiles,
  });

  factory WorkspaceFilesInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceFilesInfoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceFilesInfoToJson(this);
}

@JsonSerializable()
class DirectoryInfo {
  final bool exists;
  final int fileCount;
  final List<FileInfo> files;

  DirectoryInfo({
    required this.exists,
    required this.fileCount,
    required this.files,
  });

  factory DirectoryInfo.fromJson(Map<String, dynamic> json) =>
      _$DirectoryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryInfoToJson(this);
}

@JsonSerializable()
class FileInfo {
  final String name;
  final int sizeBytes;
  final DateTime? modifiedAt;

  FileInfo({
    required this.name,
    required this.sizeBytes,
    this.modifiedAt,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);

  /// Get human-readable file size
  String get sizeHumanReadable {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

---

### 4. LogSummary

**Purpose**: Summarizes blender.log file without loading entire file into memory.

**Location**: `lib/features/scanning/models/session_diagnostics.dart` (nested model)

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `totalLines` | `int` | Total number of log lines |
| `errorCount` | `int` | Count of lines containing "ERROR" or "CRITICAL" |
| `warningCount` | `int` | Count of lines containing "WARNING" |
| `fileSizeBytes` | `int` | Log file size in bytes |
| `lastLines` | `List<String>` | Last N lines of log (default: 20, max: 100) |
| `firstTimestamp` | `DateTime?` | First log timestamp (if parseable) |
| `lastTimestamp` | `DateTime?` | Last log timestamp (if parseable) |

```dart
@JsonSerializable()
class LogSummary {
  final int totalLines;
  final int errorCount;
  final int warningCount;
  final int fileSizeBytes;
  final List<String> lastLines;
  final DateTime? firstTimestamp;
  final DateTime? lastTimestamp;

  LogSummary({
    required this.totalLines,
    required this.errorCount,
    required this.warningCount,
    required this.fileSizeBytes,
    required this.lastLines,
    this.firstTimestamp,
    this.lastTimestamp,
  });

  factory LogSummary.fromJson(Map<String, dynamic> json) =>
      _$LogSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$LogSummaryToJson(this);
}
```

---

### 5. ErrorDetails

**Purpose**: Detailed error information when processing fails.

**Location**: `lib/features/scanning/models/session_diagnostics.dart` (nested model)

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `errorMessage` | `String` | Error message from status.json |
| `errorCode` | `String?` | BlenderAPI error code |
| `processingStage` | `String?` | Stage where failure occurred (upload, processing, export) |
| `failedAt` | `DateTime?` | Timestamp of failure |
| `blenderExitCode` | `int?` | Blender process exit code |
| `lastErrorLogs` | `List<String>` | Last error log entries |

```dart
@JsonSerializable()
class ErrorDetails {
  final String errorMessage;
  final String? errorCode;
  final String? processingStage;
  final DateTime? failedAt;
  final int? blenderExitCode;
  final List<String> lastErrorLogs;

  ErrorDetails({
    required this.errorMessage,
    this.errorCode,
    this.processingStage,
    this.failedAt,
    this.blenderExitCode,
    required this.lastErrorLogs,
  });

  factory ErrorDetails.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDetailsToJson(this);
}
```

---

### 6. PendingOperation

**Purpose**: Represents queued operation waiting for network connectivity.

**Location**: `lib/features/scanning/models/pending_operation.dart`

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `String` | Yes | Unique operation ID (UUID) |
| `operationType` | `String` | Yes | Type of operation (upload, status_poll, investigate) |
| `sessionId` | `String?` | No | Associated session ID (if applicable) |
| `errorContext` | `ErrorContext` | Yes | Error that triggered queueing |
| `queuedAt` | `DateTime` | Yes | When operation was queued |
| `retryCount` | `int` | Yes | Number of queue processing attempts |

**State Machine**:

```
┌─────────┐
│ Queued  │
└────┬────┘
     │
     │ connectivity restored
     │
     ▼
┌──────────┐      success     ┌───────────┐
│Processing├─────────────────►│ Completed │
└────┬─────┘                  └───────────┘
     │
     │ failure
     │
     ▼
┌──────────┐
│ Requeued │ (if retryCount < 3)
└──────────┘
     │
     │ max retries exceeded
     │
     ▼
┌─────────┐
│ Failed  │
└─────────┘
```

```dart
@JsonSerializable()
class PendingOperation {
  final String id;
  final String operationType;
  final String? sessionId;
  final ErrorContext errorContext;
  final DateTime queuedAt;
  final int retryCount;

  PendingOperation({
    required this.id,
    required this.operationType,
    this.sessionId,
    required this.errorContext,
    required this.queuedAt,
    required this.retryCount,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      _$PendingOperationFromJson(json);

  Map<String, dynamic> toJson() => _$PendingOperationToJson(this);

  /// Check if operation has been queued too long (> 1 hour)
  bool get isStale {
    return DateTime.now().difference(queuedAt).inHours > 1;
  }

  /// Create new instance with incremented retry count
  PendingOperation withRetry() => PendingOperation(
    id: id,
    operationType: operationType,
    sessionId: sessionId,
    errorContext: errorContext.withRetry(),
    queuedAt: queuedAt,
    retryCount: retryCount + 1,
  );
}
```

---

## Configuration Entities

### 7. RetryPolicyConfig

**Purpose**: Configuration for retry behavior (not persisted, code constants).

**Location**: `lib/features/scanning/services/retry_policy_service.dart`

**Structure**:

```dart
class RetryPolicyConfig {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxWindow = Duration(minutes: 1);

  // Recoverable HTTP statuses (transient errors)
  static const Set<int> recoverableHttpStatuses = {
    429, // Rate Limit
    500, // Internal Server Error
    502, // Bad Gateway
    503, // Service Unavailable
    504, // Gateway Timeout
  };

  // Non-recoverable HTTP statuses (client errors)
  static const Set<int> nonRecoverableHttpStatuses = {
    400, // Bad Request
    401, // Unauthorized
    403, // Forbidden
    404, // Not Found
    413, // Payload Too Large
    422, // Unprocessable Entity
  };

  // Non-recoverable error codes (business logic errors)
  static const Set<String> nonRecoverableErrorCodes = {
    'invalid_file',
    'malformed_usdz',
    'file_too_large',
    'session_expired',
    'unauthorized',
  };
}
```

---

## Entity Relationships

1. **ErrorContext** → **ErrorLogService**: Many-to-one (many errors logged by one service)
2. **ErrorContext** → **RetryPolicy**: One-to-one (each error is classified by policy)
3. **PendingOperation** → **ErrorContext**: One-to-one (each queued operation has associated error)
4. **PendingOperation** → **ConnectivityService**: Many-to-one (many operations queued in one service)
5. **SessionDiagnostics** → **WorkspaceFilesInfo**: One-to-zero-or-one (diagnostics may include files)
6. **SessionDiagnostics** → **LogSummary**: One-to-zero-or-one (diagnostics may include logs)
7. **SessionDiagnostics** → **ErrorDetails**: One-to-zero-or-one (diagnostics may include error details)

---

## Validation Summary

| Entity | Validation Rules |
|--------|------------------|
| ErrorContext | Non-empty message, valid HTTP status, 0-3 retry count, sanitized stack trace |
| SessionDiagnostics | Valid session ID format, timestamps in order (createdAt < expiresAt) |
| WorkspaceFilesInfo | File sizes >= 0, valid directory names (input/output/logs) |
| PendingOperation | Non-empty operation type, valid UUID id, non-stale (<1 hour) |

---

## Data Flow

1. **Error Occurs** → Create `ErrorContext` with `retryCount=0`
2. **Classify Error** → `RetryPolicy.isRecoverable()` sets `isRecoverable` flag
3. **Log Error** → `ErrorLogService.logError()` appends to `error_logs.json`
4. **If Recoverable & Online** → Retry with exponential backoff (2s, 4s, 8s)
5. **If Recoverable & Offline** → Create `PendingOperation`, queue in `ConnectivityService`
6. **Connectivity Restored** → Process queued operations from `shared_preferences`
7. **User Views Error** → Fetch `SessionDiagnostics` from `/sessions/{id}/investigate` API
8. **Display Details** → Show `WorkspaceFilesInfo`, `LogSummary`, `ErrorDetails` in UI

---

**End of Data Model Document**
