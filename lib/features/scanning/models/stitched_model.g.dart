// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stitched_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StitchedModel _$StitchedModelFromJson(Map<String, dynamic> json) =>
    StitchedModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      originalScanIds: (json['originalScanIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      roomNames: (json['roomNames'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      format: json['format'] as String? ?? 'glb',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StitchedModelToJson(StitchedModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'localPath': instance.localPath,
      'originalScanIds': instance.originalScanIds,
      'roomNames': instance.roomNames,
      'fileSizeBytes': instance.fileSizeBytes,
      'createdAt': instance.createdAt.toIso8601String(),
      'format': instance.format,
      'metadata': instance.metadata,
    };
