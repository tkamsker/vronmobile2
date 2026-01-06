// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'door_symbol.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoorSymbol _$DoorSymbolFromJson(Map<String, dynamic> json) => DoorSymbol(
  id: json['id'] as String,
  roomScanId: json['roomScanId'] as String,
  position: DoorSymbol._offsetFromJson(
    json['position'] as Map<String, dynamic>,
  ),
  width: (json['width'] as num?)?.toDouble() ?? 30.0,
  rotationDegrees: (json['rotationDegrees'] as num?)?.toDouble() ?? 0.0,
  type: $enumDecodeNullable(_$DoorTypeEnumMap, json['type']) ?? DoorType.manual,
  connectedToDoorId: json['connectedToDoorId'] as String?,
  color: DoorSymbol._colorFromJson((json['color'] as num).toInt()),
);

Map<String, dynamic> _$DoorSymbolToJson(DoorSymbol instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomScanId': instance.roomScanId,
      'position': DoorSymbol._offsetToJson(instance.position),
      'width': instance.width,
      'rotationDegrees': instance.rotationDegrees,
      'type': _$DoorTypeEnumMap[instance.type]!,
      'connectedToDoorId': instance.connectedToDoorId,
      'color': DoorSymbol._colorToJson(instance.color),
    };

const _$DoorTypeEnumMap = {
  DoorType.estimated: 'estimated',
  DoorType.manual: 'manual',
};
