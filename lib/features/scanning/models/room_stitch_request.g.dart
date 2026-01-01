// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_stitch_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomStitchRequest _$RoomStitchRequestFromJson(Map<String, dynamic> json) =>
    RoomStitchRequest(
      projectId: json['projectId'] as String,
      scanIds: (json['scanIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      alignmentMode:
          $enumDecodeNullable(_$AlignmentModeEnumMap, json['alignmentMode']) ??
          AlignmentMode.auto,
      outputFormat:
          $enumDecodeNullable(_$OutputFormatEnumMap, json['outputFormat']) ??
          OutputFormat.glb,
      roomNames: (json['roomNames'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$RoomStitchRequestToJson(RoomStitchRequest instance) =>
    <String, dynamic>{
      'projectId': instance.projectId,
      'scanIds': instance.scanIds,
      'alignmentMode': _$AlignmentModeEnumMap[instance.alignmentMode]!,
      'outputFormat': _$OutputFormatEnumMap[instance.outputFormat]!,
      'roomNames': instance.roomNames,
    };

const _$AlignmentModeEnumMap = {
  AlignmentMode.auto: 'auto',
  AlignmentMode.manual: 'manual',
};

const _$OutputFormatEnumMap = {
  OutputFormat.glb: 'glb',
  OutputFormat.usdz: 'usdz',
};
