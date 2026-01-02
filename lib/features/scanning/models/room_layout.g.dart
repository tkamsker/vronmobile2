// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_layout.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomLayout _$RoomLayoutFromJson(Map<String, dynamic> json) => RoomLayout(
  rooms: (json['rooms'] as List<dynamic>)
      .map((e) => RoomOutline.fromJson(e as Map<String, dynamic>))
      .toList(),
  doors: (json['doors'] as List<dynamic>)
      .map((e) => DoorSymbol.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RoomLayoutToJson(RoomLayout instance) =>
    <String, dynamic>{
      'rooms': instance.rooms,
      'doors': instance.doors,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
