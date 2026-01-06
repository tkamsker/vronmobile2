// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_outline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomOutline _$RoomOutlineFromJson(Map<String, dynamic> json) => RoomOutline(
  scanId: json['scanId'] as String,
  roomName: json['roomName'] as String,
  vertices: RoomOutline._pointsFromJson(json['vertices'] as List),
  rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
  positionOffset: json['positionOffset'] == null
      ? Offset.zero
      : RoomOutline._offsetFromJson(
          json['positionOffset'] as Map<String, dynamic>,
        ),
  scaleFactor: (json['scaleFactor'] as num?)?.toDouble() ?? 1.0,
  isSelected: json['isSelected'] as bool? ?? false,
  estimatedDoorIndices:
      (json['estimatedDoorIndices'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  outlineColor: json['outlineColor'] == null
      ? Colors.blue
      : RoomOutline._colorFromJson((json['outlineColor'] as num).toInt()),
);

Map<String, dynamic> _$RoomOutlineToJson(RoomOutline instance) =>
    <String, dynamic>{
      'scanId': instance.scanId,
      'roomName': instance.roomName,
      'vertices': RoomOutline._pointsToJson(instance.vertices),
      'rotationDegrees': instance.rotationDegrees,
      'positionOffset': RoomOutline._offsetToJson(instance.positionOffset),
      'scaleFactor': instance.scaleFactor,
      'isSelected': instance.isSelected,
      'estimatedDoorIndices': instance.estimatedDoorIndices,
      'outlineColor': RoomOutline._colorToJson(instance.outlineColor),
    };
