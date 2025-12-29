/// BlenderAPI Models for USDZ to GLB Conversion
/// Reference: Requirements/FLUTTER_API_PRD.md
///
/// These models represent request/response structures for the BlenderAPI service
/// which handles USDZ to GLB conversion via Blender's native import/export.

import 'package:json_annotation/json_annotation.dart';

part 'blender_api_models.g.dart';

/// Session created response from POST /sessions
/// Contains session ID and expiration timestamp
@JsonSerializable()
class BlenderApiSession {
  @JsonKey(name: 'session_id')
  final String sessionId;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  BlenderApiSession({
    required this.sessionId,
    required this.expiresAt,
  });

  factory BlenderApiSession.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiSessionFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiSessionToJson(this);

  @override
  String toString() => 'BlenderApiSession(sessionId: $sessionId, expiresAt: $expiresAt)';
}

/// Upload response from POST /sessions/{id}/upload
/// Confirms file upload with metadata
@JsonSerializable()
class BlenderApiUploadResponse {
  @JsonKey(name: 'session_id')
  final String sessionId;

  final String filename;

  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  @JsonKey(name: 'uploaded_at')
  final DateTime uploadedAt;

  BlenderApiUploadResponse({
    required this.sessionId,
    required this.filename,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  factory BlenderApiUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiUploadResponseToJson(this);

  @override
  String toString() =>
      'BlenderApiUploadResponse(sessionId: $sessionId, filename: $filename, sizeBytes: $sizeBytes)';
}

/// Conversion request parameters for POST /sessions/{id}/convert
/// Configures USDZ to GLB conversion behavior
@JsonSerializable()
class BlenderApiConversionRequest {
  @JsonKey(name: 'job_type')
  final String jobType; // Always "usdz_to_glb"

  @JsonKey(name: 'input_filename')
  final String inputFilename;

  @JsonKey(name: 'output_filename')
  final String? outputFilename;

  @JsonKey(name: 'conversion_params')
  final ConversionParams? conversionParams;

  BlenderApiConversionRequest({
    required this.inputFilename,
    this.outputFilename,
    this.conversionParams,
    this.jobType = 'usdz_to_glb', // Default value, always "usdz_to_glb"
  });

  factory BlenderApiConversionRequest.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiConversionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiConversionRequestToJson(this);
}

/// Conversion parameters for USDZ to GLB conversion
@JsonSerializable()
class ConversionParams {
  @JsonKey(name: 'apply_scale')
  final bool? applyScale;

  @JsonKey(name: 'merge_meshes')
  final bool? mergeMeshes;

  @JsonKey(name: 'target_scale')
  final double? targetScale;

  ConversionParams({
    this.applyScale = false,
    this.mergeMeshes = false,
    this.targetScale = 1.0,
  });

  factory ConversionParams.fromJson(Map<String, dynamic> json) =>
      _$ConversionParamsFromJson(json);

  Map<String, dynamic> toJson() => _$ConversionParamsToJson(this);
}

/// Processing started response from POST /sessions/{id}/convert
@JsonSerializable()
class BlenderApiProcessingStarted {
  @JsonKey(name: 'session_id')
  final String sessionId;

  @JsonKey(name: 'job_type')
  final String jobType;

  @JsonKey(name: 'started_at')
  final DateTime startedAt;

  BlenderApiProcessingStarted({
    required this.sessionId,
    required this.jobType,
    required this.startedAt,
  });

  factory BlenderApiProcessingStarted.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiProcessingStartedFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiProcessingStartedToJson(this);
}

/// Status response from GET /sessions/{id}/status
/// Tracks conversion progress and completion
@JsonSerializable()
class BlenderApiStatus {
  @JsonKey(name: 'session_id')
  final String sessionId;

  @JsonKey(name: 'session_status')
  final String sessionStatus; // pending, uploading, validating, processing, completed, failed, expired

  @JsonKey(name: 'processing_stage')
  final String processingStage; // pending, processing, completed, failed

  final int progress; // 0-100

  @JsonKey(name: 'started_at')
  final DateTime? startedAt;

  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  @JsonKey(name: 'error_message')
  final String? errorMessage;

  final ConversionResult? result;

  BlenderApiStatus({
    required this.sessionId,
    required this.sessionStatus,
    required this.processingStage,
    required this.progress,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.result,
  });

  factory BlenderApiStatus.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiStatusFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiStatusToJson(this);

  bool get isCompleted => sessionStatus == 'completed';
  bool get isFailed => sessionStatus == 'failed';
  bool get isProcessing => sessionStatus == 'processing';

  @override
  String toString() =>
      'BlenderApiStatus(sessionStatus: $sessionStatus, progress: $progress%, stage: $processingStage)';
}

/// Conversion result metadata when processing completes
@JsonSerializable()
class ConversionResult {
  final String filename;

  @JsonKey(name: 'size_bytes')
  final int sizeBytes;

  final String format; // "glb"

  @JsonKey(name: 'polygon_count')
  final int? polygonCount;

  @JsonKey(name: 'mesh_count')
  final int? meshCount;

  @JsonKey(name: 'material_count')
  final int? materialCount;

  ConversionResult({
    required this.filename,
    required this.sizeBytes,
    required this.format,
    this.polygonCount,
    this.meshCount,
    this.materialCount,
  });

  factory ConversionResult.fromJson(Map<String, dynamic> json) =>
      _$ConversionResultFromJson(json);

  Map<String, dynamic> toJson() => _$ConversionResultToJson(this);

  @override
  String toString() =>
      'ConversionResult(filename: $filename, size: ${(sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB, polygons: $polygonCount)';
}

/// Error response from BlenderAPI
/// Returned for 4xx and 5xx HTTP status codes
@JsonSerializable()
class BlenderApiError {
  @JsonKey(name: 'error_code')
  final String? errorCode;

  final String message;

  final Map<String, dynamic>? details;

  BlenderApiError({
    this.errorCode,
    required this.message,
    this.details,
  });

  factory BlenderApiError.fromJson(Map<String, dynamic> json) =>
      _$BlenderApiErrorFromJson(json);

  Map<String, dynamic> toJson() => _$BlenderApiErrorToJson(this);

  @override
  String toString() => 'BlenderApiError($errorCode): $message';
}

/// Exception thrown by BlenderAPI client
class BlenderApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? details;

  BlenderApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  factory BlenderApiException.fromError(int statusCode, BlenderApiError error) {
    return BlenderApiException(
      statusCode: statusCode,
      message: error.message,
      errorCode: error.errorCode,
      details: error.details,
    );
  }

  /// User-friendly error message for display
  String get userMessage {
    switch (statusCode) {
      case 401:
        return 'Service authentication failed. Please contact support.';
      case 404:
        return 'Session not found or expired. Please try again.';
      case 409:
        return 'Processing already in progress for this session.';
      case 422:
        return 'File validation failed: ${message}';
      case 429:
        return 'Service busy. Maximum 3 scans can be processed simultaneously. Please try again in a moment.';
      case 500:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'BlenderApiException($statusCode): $message';
}
