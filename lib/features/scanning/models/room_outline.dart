import 'dart:math';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'room_outline.g.dart';

/// 2D floor plan outline extracted from 3D scan mesh
/// Represents a room's boundary as a closed polygon on the canvas
@JsonSerializable()
class RoomOutline {
  /// Unique identifier for this room outline (matches ScanData.id)
  final String scanId;

  /// Display name for the room (e.g., "Living Room", "Bedroom 1")
  final String roomName;

  /// 2D polygon vertices representing the room boundary (clockwise order)
  /// Coordinates are in canvas space (pixels)
  @JsonKey(fromJson: _pointsFromJson, toJson: _pointsToJson)
  final List<Offset> vertices;

  /// Current rotation angle in degrees (clockwise from north)
  final double rotationDegrees;

  /// Current position offset from original extraction (for manual adjustment)
  @JsonKey(fromJson: _offsetFromJson, toJson: _offsetToJson)
  final Offset positionOffset;

  /// Scale factor for the room outline (1.0 = original size)
  @JsonKey(defaultValue: 1.0)
  final double scaleFactor;

  /// Whether this room is currently selected on the canvas
  @JsonKey(defaultValue: false)
  final bool isSelected;

  /// Estimated door locations on room borders (index in vertices list)
  /// Empty list if no doors detected
  final List<int> estimatedDoorIndices;

  /// Color for rendering this room outline (defaults to blue)
  @JsonKey(fromJson: _colorFromJson, toJson: _colorToJson)
  final Color outlineColor;

  const RoomOutline({
    required this.scanId,
    required this.roomName,
    required this.vertices,
    this.rotationDegrees = 0.0,
    this.positionOffset = Offset.zero,
    this.scaleFactor = 1.0,
    this.isSelected = false,
    this.estimatedDoorIndices = const [],
    this.outlineColor = Colors.blue,
  });

  /// Create from JSON
  factory RoomOutline.fromJson(Map<String, dynamic> json) =>
      _$RoomOutlineFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RoomOutlineToJson(this);

  /// Create a copy with updated fields
  RoomOutline copyWith({
    String? scanId,
    String? roomName,
    List<Offset>? vertices,
    double? rotationDegrees,
    Offset? positionOffset,
    double? scaleFactor,
    bool? isSelected,
    List<int>? estimatedDoorIndices,
    Color? outlineColor,
  }) {
    return RoomOutline(
      scanId: scanId ?? this.scanId,
      roomName: roomName ?? this.roomName,
      vertices: vertices ?? this.vertices,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      positionOffset: positionOffset ?? this.positionOffset,
      scaleFactor: scaleFactor ?? this.scaleFactor,
      isSelected: isSelected ?? this.isSelected,
      estimatedDoorIndices: estimatedDoorIndices ?? this.estimatedDoorIndices,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }

  /// Check if a point (in canvas coordinates) is inside this room outline
  bool containsPoint(Offset point) {
    // Apply inverse transformation to point (undo position offset and rotation)
    final transformedPoint = _inverseTransformPoint(point);

    // Ray casting algorithm for point-in-polygon test
    int intersections = 0;
    for (int i = 0; i < vertices.length; i++) {
      final v1 = vertices[i];
      final v2 = vertices[(i + 1) % vertices.length];

      if (_rayIntersectsSegment(transformedPoint, v1, v2)) {
        intersections++;
      }
    }

    // Odd number of intersections means point is inside
    return intersections % 2 == 1;
  }

  /// Get bounding box of this room outline (axis-aligned)
  Rect getBoundingBox() {
    if (vertices.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final vertex in vertices) {
      final transformed = _transformPoint(vertex);
      minX = transformed.dx < minX ? transformed.dx : minX;
      minY = transformed.dy < minY ? transformed.dy : minY;
      maxX = transformed.dx > maxX ? transformed.dx : maxX;
      maxY = transformed.dy > maxY ? transformed.dy : maxY;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Transform a point from local to canvas coordinates
  Offset _transformPoint(Offset point) {
    // Apply scale first
    final scaled = Offset(point.dx * scaleFactor, point.dy * scaleFactor);

    // Apply rotation
    final radians = rotationDegrees * (pi / 180.0);
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);
    final rotated = Offset(
      scaled.dx * cosTheta - scaled.dy * sinTheta,
      scaled.dx * sinTheta + scaled.dy * cosTheta,
    );

    // Apply position offset
    return rotated + positionOffset;
  }

  /// Transform a point from canvas to local coordinates (inverse)
  Offset _inverseTransformPoint(Offset point) {
    // Remove position offset
    final translated = point - positionOffset;

    // Apply inverse rotation
    final radians = -rotationDegrees * (pi / 180.0);
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);
    final rotated = Offset(
      translated.dx * cosTheta - translated.dy * sinTheta,
      translated.dx * sinTheta + translated.dy * cosTheta,
    );

    // Apply inverse scale
    return Offset(rotated.dx / scaleFactor, rotated.dy / scaleFactor);
  }

  /// Ray casting helper: check if horizontal ray from point intersects line segment
  bool _rayIntersectsSegment(Offset point, Offset v1, Offset v2) {
    if (v1.dy > v2.dy) {
      final temp = v1;
      v1 = v2;
      v2 = temp;
    }

    if (point.dy < v1.dy || point.dy >= v2.dy) return false;
    if (point.dx >= (v1.dx > v2.dx ? v1.dx : v2.dx)) return false;

    if (point.dx < (v1.dx < v2.dx ? v1.dx : v2.dx)) return true;

    final slope = (v2.dx - v1.dx) / (v2.dy - v1.dy);
    final intersectionX = v1.dx + (point.dy - v1.dy) * slope;
    return point.dx < intersectionX;
  }

  // JSON serialization helpers for complex types
  static List<Offset> _pointsFromJson(List<dynamic> json) {
    return json
        .map(
          (p) =>
              Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()),
        )
        .toList();
  }

  static List<Map<String, double>> _pointsToJson(List<Offset> points) {
    return points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList();
  }

  static Color _colorFromJson(int value) => Color(value);
  static int _colorToJson(Color color) => color.toARGB32();

  static Offset _offsetFromJson(Map<String, dynamic> json) {
    return Offset(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }

  static Map<String, double> _offsetToJson(Offset offset) {
    return {'dx': offset.dx, 'dy': offset.dy};
  }
}
