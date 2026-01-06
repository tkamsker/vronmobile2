import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'door_symbol.g.dart';

/// Type of door symbol
enum DoorType {
  /// Automatically detected door (estimated from geometry)
  estimated,

  /// Manually placed door by user
  manual,
}

/// Door symbol placed on room border
/// Represents a potential connection point between rooms
@JsonSerializable()
class DoorSymbol {
  /// Unique identifier for this door
  final String id;

  /// ID of the room this door belongs to
  final String roomScanId;

  /// Position of the door on canvas (center point)
  @JsonKey(
    fromJson: _offsetFromJson,
    toJson: _offsetToJson,
  )
  final Offset position;

  /// Width of the door opening in canvas pixels
  final double width;

  /// Rotation angle in degrees (perpendicular to wall)
  final double rotationDegrees;

  /// Type of door (estimated vs manual)
  final DoorType type;

  /// Optional connection to another door (for room stitching)
  /// If non-null, this door is connected to another room's door
  final String? connectedToDoorId;

  /// Visual color for rendering (red for manual, yellow for estimated)
  @JsonKey(
    fromJson: _colorFromJson,
    toJson: _colorToJson,
  )
  final Color color;

  const DoorSymbol({
    required this.id,
    required this.roomScanId,
    required this.position,
    this.width = 30.0, // Default door width in pixels
    this.rotationDegrees = 0.0,
    this.type = DoorType.manual,
    this.connectedToDoorId,
    Color? color,
  }) : color = color ?? (type == DoorType.manual ? Colors.red : Colors.yellow);

  /// Create from JSON
  factory DoorSymbol.fromJson(Map<String, dynamic> json) =>
      _$DoorSymbolFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$DoorSymbolToJson(this);

  /// Create a copy with updated fields
  DoorSymbol copyWith({
    String? id,
    String? roomScanId,
    Offset? position,
    double? width,
    double? rotationDegrees,
    DoorType? type,
    String? connectedToDoorId,
    Color? color,
  }) {
    return DoorSymbol(
      id: id ?? this.id,
      roomScanId: roomScanId ?? this.roomScanId,
      position: position ?? this.position,
      width: width ?? this.width,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      type: type ?? this.type,
      connectedToDoorId: connectedToDoorId ?? this.connectedToDoorId,
      color: color ?? this.color,
    );
  }

  /// Check if this door is close enough to another door for connection suggestion
  bool isNearby(DoorSymbol other, double threshold) {
    final distance = (position - other.position).distance;
    return distance <= threshold;
  }

  /// Check if a point is within the door's hitbox (for tap detection)
  bool containsPoint(Offset point, {double hitboxPadding = 10.0}) {
    final rect = Rect.fromCenter(
      center: position,
      width: width + hitboxPadding * 2,
      height: width + hitboxPadding * 2,
    );
    return rect.contains(point);
  }

  /// Get the bounding box for this door symbol
  Rect getBoundingBox() {
    return Rect.fromCenter(
      center: position,
      width: width,
      height: width,
    );
  }

  // JSON serialization helpers
  static Offset _offsetFromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  static Map<String, double> _offsetToJson(Offset offset) {
    return {'dx': offset.dx, 'dy': offset.dy};
  }

  static Color _colorFromJson(int value) => Color(value);
  static int _colorToJson(Color color) => color.toARGB32();
}
