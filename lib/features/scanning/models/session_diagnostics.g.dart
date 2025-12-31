// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_diagnostics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) => FileInfo(
  name: json['name'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  modifiedAt: json['modified_at'] == null
      ? null
      : DateTime.parse(json['modified_at'] as String),
);

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
  'name': instance.name,
  'size_bytes': instance.sizeBytes,
  'modified_at': instance.modifiedAt?.toIso8601String(),
};

DirectoryInfo _$DirectoryInfoFromJson(Map<String, dynamic> json) =>
    DirectoryInfo(
      exists: json['exists'] as bool,
      fileCount: (json['file_count'] as num).toInt(),
      files: (json['files'] as List<dynamic>)
          .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DirectoryInfoToJson(DirectoryInfo instance) =>
    <String, dynamic>{
      'exists': instance.exists,
      'file_count': instance.fileCount,
      'files': instance.files.map((e) => e.toJson()).toList(),
    };

WorkspaceFilesInfo _$WorkspaceFilesInfoFromJson(Map<String, dynamic> json) =>
    WorkspaceFilesInfo(
      directories: (json['directories'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, DirectoryInfo.fromJson(e as Map<String, dynamic>)),
      ),
      rootFiles: (json['root_files'] as List<dynamic>)
          .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkspaceFilesInfoToJson(
  WorkspaceFilesInfo instance,
) => <String, dynamic>{
  'directories': instance.directories.map((k, e) => MapEntry(k, e.toJson())),
  'root_files': instance.rootFiles.map((e) => e.toJson()).toList(),
};

LogSummary _$LogSummaryFromJson(Map<String, dynamic> json) => LogSummary(
  totalLines: (json['total_lines'] as num).toInt(),
  errorCount: (json['error_count'] as num).toInt(),
  warningCount: (json['warning_count'] as num).toInt(),
  fileSizeBytes: (json['file_size_bytes'] as num).toInt(),
  lastLines: (json['last_lines'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  firstTimestamp: json['first_timestamp'] == null
      ? null
      : DateTime.parse(json['first_timestamp'] as String),
  lastTimestamp: json['last_timestamp'] == null
      ? null
      : DateTime.parse(json['last_timestamp'] as String),
);

Map<String, dynamic> _$LogSummaryToJson(LogSummary instance) =>
    <String, dynamic>{
      'total_lines': instance.totalLines,
      'error_count': instance.errorCount,
      'warning_count': instance.warningCount,
      'file_size_bytes': instance.fileSizeBytes,
      'last_lines': instance.lastLines,
      'first_timestamp': instance.firstTimestamp?.toIso8601String(),
      'last_timestamp': instance.lastTimestamp?.toIso8601String(),
    };

ErrorDetails _$ErrorDetailsFromJson(Map<String, dynamic> json) => ErrorDetails(
  errorMessage: json['error_message'] as String,
  errorCode: json['error_code'] as String?,
  processingStage: json['processing_stage'] as String?,
  failedAt: json['failed_at'] == null
      ? null
      : DateTime.parse(json['failed_at'] as String),
  blenderExitCode: (json['blender_exit_code'] as num?)?.toInt(),
  lastErrorLogs: (json['last_error_logs'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ErrorDetailsToJson(ErrorDetails instance) =>
    <String, dynamic>{
      'error_message': instance.errorMessage,
      'error_code': instance.errorCode,
      'processing_stage': instance.processingStage,
      'failed_at': instance.failedAt?.toIso8601String(),
      'blender_exit_code': instance.blenderExitCode,
      'last_error_logs': instance.lastErrorLogs,
    };

SessionDiagnostics _$SessionDiagnosticsFromJson(Map<String, dynamic> json) =>
    SessionDiagnostics(
      sessionId: json['session_id'] as String,
      sessionStatus: json['session_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      lastAccessed: json['last_accessed'] == null
          ? null
          : DateTime.parse(json['last_accessed'] as String),
      workspaceExists: json['workspace_exists'] as bool,
      files: json['files'] == null
          ? null
          : WorkspaceFilesInfo.fromJson(json['files'] as Map<String, dynamic>),
      statusData: json['status_data'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      logsSummary: json['logs_summary'] == null
          ? null
          : LogSummary.fromJson(json['logs_summary'] as Map<String, dynamic>),
      errorDetails: json['error_details'] == null
          ? null
          : ErrorDetails.fromJson(
              json['error_details'] as Map<String, dynamic>,
            ),
      investigationTimestamp: DateTime.parse(
        json['investigation_timestamp'] as String,
      ),
    );

Map<String, dynamic> _$SessionDiagnosticsToJson(
  SessionDiagnostics instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'session_status': instance.sessionStatus,
  'created_at': instance.createdAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'last_accessed': instance.lastAccessed?.toIso8601String(),
  'workspace_exists': instance.workspaceExists,
  'files': instance.files?.toJson(),
  'status_data': instance.statusData,
  'metadata': instance.metadata,
  'parameters': instance.parameters,
  'logs_summary': instance.logsSummary?.toJson(),
  'error_details': instance.errorDetails?.toJson(),
  'investigation_timestamp': instance.investigationTimestamp.toIso8601String(),
};
