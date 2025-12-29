// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blender_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlenderApiSession _$BlenderApiSessionFromJson(Map<String, dynamic> json) =>
    BlenderApiSession(
      sessionId: json['session_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$BlenderApiSessionToJson(BlenderApiSession instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

BlenderApiUploadResponse _$BlenderApiUploadResponseFromJson(
  Map<String, dynamic> json,
) => BlenderApiUploadResponse(
  sessionId: json['session_id'] as String,
  filename: json['filename'] as String,
  sizeBytes: (json['size_bytes'] as num).toInt(),
  uploadedAt: DateTime.parse(json['uploaded_at'] as String),
);

Map<String, dynamic> _$BlenderApiUploadResponseToJson(
  BlenderApiUploadResponse instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'filename': instance.filename,
  'size_bytes': instance.sizeBytes,
  'uploaded_at': instance.uploadedAt.toIso8601String(),
};

BlenderApiConversionRequest _$BlenderApiConversionRequestFromJson(
  Map<String, dynamic> json,
) => BlenderApiConversionRequest(
  inputFilename: json['input_filename'] as String,
  outputFilename: json['output_filename'] as String?,
  conversionParams: json['conversion_params'] == null
      ? null
      : ConversionParams.fromJson(
          json['conversion_params'] as Map<String, dynamic>,
        ),
  jobType: json['job_type'] as String? ?? 'usdz_to_glb',
);

Map<String, dynamic> _$BlenderApiConversionRequestToJson(
  BlenderApiConversionRequest instance,
) => <String, dynamic>{
  'job_type': instance.jobType,
  'input_filename': instance.inputFilename,
  'output_filename': instance.outputFilename,
  'conversion_params': instance.conversionParams,
};

ConversionParams _$ConversionParamsFromJson(Map<String, dynamic> json) =>
    ConversionParams(
      applyScale: json['apply_scale'] as bool? ?? false,
      mergeMeshes: json['merge_meshes'] as bool? ?? false,
      targetScale: (json['target_scale'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$ConversionParamsToJson(ConversionParams instance) =>
    <String, dynamic>{
      'apply_scale': instance.applyScale,
      'merge_meshes': instance.mergeMeshes,
      'target_scale': instance.targetScale,
    };

BlenderApiProcessingStarted _$BlenderApiProcessingStartedFromJson(
  Map<String, dynamic> json,
) => BlenderApiProcessingStarted(
  sessionId: json['session_id'] as String,
  jobType: json['job_type'] as String,
  startedAt: DateTime.parse(json['started_at'] as String),
);

Map<String, dynamic> _$BlenderApiProcessingStartedToJson(
  BlenderApiProcessingStarted instance,
) => <String, dynamic>{
  'session_id': instance.sessionId,
  'job_type': instance.jobType,
  'started_at': instance.startedAt.toIso8601String(),
};

BlenderApiStatus _$BlenderApiStatusFromJson(Map<String, dynamic> json) =>
    BlenderApiStatus(
      sessionId: json['session_id'] as String,
      sessionStatus: json['session_status'] as String,
      processingStage: json['processing_stage'] as String,
      progress: (json['progress'] as num).toInt(),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      errorMessage: json['error_message'] as String?,
      result: json['result'] == null
          ? null
          : ConversionResult.fromJson(json['result'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BlenderApiStatusToJson(BlenderApiStatus instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'session_status': instance.sessionStatus,
      'processing_stage': instance.processingStage,
      'progress': instance.progress,
      'started_at': instance.startedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'error_message': instance.errorMessage,
      'result': instance.result,
    };

ConversionResult _$ConversionResultFromJson(Map<String, dynamic> json) =>
    ConversionResult(
      filename: json['filename'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
      format: json['format'] as String,
      polygonCount: (json['polygon_count'] as num?)?.toInt(),
      meshCount: (json['mesh_count'] as num?)?.toInt(),
      materialCount: (json['material_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConversionResultToJson(ConversionResult instance) =>
    <String, dynamic>{
      'filename': instance.filename,
      'size_bytes': instance.sizeBytes,
      'format': instance.format,
      'polygon_count': instance.polygonCount,
      'mesh_count': instance.meshCount,
      'material_count': instance.materialCount,
    };

BlenderApiError _$BlenderApiErrorFromJson(Map<String, dynamic> json) =>
    BlenderApiError(
      errorCode: json['error_code'] as String?,
      message: json['message'] as String,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$BlenderApiErrorToJson(BlenderApiError instance) =>
    <String, dynamic>{
      'error_code': instance.errorCode,
      'message': instance.message,
      'details': instance.details,
    };
