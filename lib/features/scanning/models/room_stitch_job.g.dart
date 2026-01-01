// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_stitch_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomStitchJob _$RoomStitchJobFromJson(Map<String, dynamic> json) =>
    RoomStitchJob(
      jobId: json['jobId'] as String,
      status: $enumDecode(_$RoomStitchJobStatusEnumMap, json['status']),
      progress: (json['progress'] as num).toInt(),
      errorMessage: json['errorMessage'] as String?,
      resultUrl: json['resultUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      estimatedDurationSeconds: (json['estimatedDurationSeconds'] as num?)
          ?.toInt(),
    );

Map<String, dynamic> _$RoomStitchJobToJson(RoomStitchJob instance) =>
    <String, dynamic>{
      'jobId': instance.jobId,
      'status': _$RoomStitchJobStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'errorMessage': instance.errorMessage,
      'resultUrl': instance.resultUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'estimatedDurationSeconds': instance.estimatedDurationSeconds,
    };

const _$RoomStitchJobStatusEnumMap = {
  RoomStitchJobStatus.pending: 'pending',
  RoomStitchJobStatus.uploading: 'uploading',
  RoomStitchJobStatus.processing: 'processing',
  RoomStitchJobStatus.aligning: 'aligning',
  RoomStitchJobStatus.merging: 'merging',
  RoomStitchJobStatus.completed: 'completed',
  RoomStitchJobStatus.failed: 'failed',
};
