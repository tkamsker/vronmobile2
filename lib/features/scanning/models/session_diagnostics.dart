import 'package:json_annotation/json_annotation.dart';

part 'session_diagnostics.g.dart';

/// Individual file information within session workspace
@JsonSerializable(explicitToJson: true)
class FileInfo {
  /// File name (e.g., scan.usdz, scan.glb)
  final String name;

  /// File size in bytes
  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  /// Last modification timestamp (ISO 8601)
  @JsonKey(name: 'modified_at')
  final DateTime? modifiedAt;

  FileInfo({required this.name, required this.sizeBytes, this.modifiedAt});

  /// Human-readable file size (e.g., "1.5 KB", "2.0 MB")
  String get sizeHumanReadable {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}

/// Directory information with file listing
@JsonSerializable(explicitToJson: true)
class DirectoryInfo {
  /// Whether directory exists in session workspace
  final bool exists;

  /// Number of files in directory
  @JsonKey(name: 'file_count')
  final int fileCount;

  /// List of files in directory
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

/// Workspace file structure information
@JsonSerializable(explicitToJson: true)
class WorkspaceFilesInfo {
  /// Standard directories (input, output, logs)
  final Map<String, DirectoryInfo> directories;

  /// Files in workspace root
  @JsonKey(name: 'root_files')
  final List<FileInfo> rootFiles;

  WorkspaceFilesInfo({required this.directories, required this.rootFiles});

  factory WorkspaceFilesInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceFilesInfoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceFilesInfoToJson(this);
}

/// Log file summary information
@JsonSerializable(explicitToJson: true)
class LogSummary {
  /// Total number of log lines
  @JsonKey(name: 'total_lines')
  final int totalLines;

  /// Number of ERROR level logs
  @JsonKey(name: 'error_count')
  final int errorCount;

  /// Number of WARNING level logs
  @JsonKey(name: 'warning_count')
  final int warningCount;

  /// Log file size in bytes
  @JsonKey(name: 'file_size_bytes')
  final int fileSizeBytes;

  /// Last N lines from log file
  @JsonKey(name: 'last_lines')
  final List<String> lastLines;

  /// First log timestamp (ISO 8601)
  @JsonKey(name: 'first_timestamp')
  final DateTime? firstTimestamp;

  /// Last log timestamp (ISO 8601)
  @JsonKey(name: 'last_timestamp')
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

/// Error details for failed sessions
@JsonSerializable(explicitToJson: true)
class ErrorDetails {
  /// User-friendly error message
  @JsonKey(name: 'error_message')
  final String errorMessage;

  /// BlenderAPI error code (e.g., malformed_usdz)
  @JsonKey(name: 'error_code')
  final String? errorCode;

  /// Processing stage where error occurred
  @JsonKey(name: 'processing_stage')
  final String? processingStage;

  /// When error occurred (ISO 8601)
  @JsonKey(name: 'failed_at')
  final DateTime? failedAt;

  /// Blender process exit code
  @JsonKey(name: 'blender_exit_code')
  final int? blenderExitCode;

  /// Last error lines from logs
  @JsonKey(name: 'last_error_logs')
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

/// Complete session diagnostics from BlenderAPI investigation endpoint
///
/// This entity represents the full response from GET /sessions/{id}/investigate
/// Used for debugging session issues, displaying detailed error information,
/// and understanding session lifecycle state.
@JsonSerializable(explicitToJson: true)
class SessionDiagnostics {
  /// BlenderAPI session ID (format: sess_*)
  @JsonKey(name: 'session_id')
  final String sessionId;

  /// Current session status (active, processing, completed, failed, expired)
  @JsonKey(name: 'session_status')
  final String sessionStatus;

  /// Session creation timestamp (ISO 8601)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Session expiration timestamp (ISO 8601, TTL: 1 hour)
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  /// Last access timestamp (ISO 8601)
  @JsonKey(name: 'last_accessed')
  final DateTime? lastAccessed;

  /// Whether session workspace directory exists
  @JsonKey(name: 'workspace_exists')
  final bool workspaceExists;

  /// File structure information (null if workspace doesn't exist)
  final WorkspaceFilesInfo? files;

  /// Current status data (processing_stage, progress)
  @JsonKey(name: 'status_data')
  final Map<String, dynamic>? statusData;

  /// Output file metadata (filename, size_bytes)
  final Map<String, dynamic>? metadata;

  /// Job parameters (job_type)
  final Map<String, dynamic>? parameters;

  /// Log file summary (null if logs don't exist)
  @JsonKey(name: 'logs_summary')
  final LogSummary? logsSummary;

  /// Error details (only present for failed sessions)
  @JsonKey(name: 'error_details')
  final ErrorDetails? errorDetails;

  /// When this investigation was performed (ISO 8601)
  @JsonKey(name: 'investigation_timestamp')
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

  /// Whether session has expired (current time > expiresAt)
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// User-friendly status message
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

  factory SessionDiagnostics.fromJson(Map<String, dynamic> json) =>
      _$SessionDiagnosticsFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDiagnosticsToJson(this);
}
