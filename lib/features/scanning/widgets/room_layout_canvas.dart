import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/room_layout.dart';
import 'package:vronmobile2/features/scanning/models/room_outline.dart';
import 'package:vronmobile2/features/scanning/models/door_symbol.dart';
import 'package:vronmobile2/features/scanning/models/canvas_configuration.dart';

/// CustomPainter for rendering room layout canvas
/// Displays room outlines, door symbols, and connection suggestions
class RoomLayoutCanvasPainter extends CustomPainter {
  final RoomLayout layout;
  final CanvasConfiguration config;

  RoomLayoutCanvasPainter({
    required this.layout,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layer 1: Background grid (if enabled)
    if (config.gridSize > 0) {
      _drawGrid(canvas, size);
    }

    // Layer 2: Room outlines (unselected first, selected last)
    final unselectedRooms = layout.rooms.where((r) => !r.isSelected).toList();
    final selectedRooms = layout.rooms.where((r) => r.isSelected).toList();

    for (final room in unselectedRooms) {
      _drawRoomOutline(canvas, room, isSelected: false);
    }

    for (final room in selectedRooms) {
      _drawRoomOutline(canvas, room, isSelected: true);
    }

    // Layer 3: Door symbols
    for (final door in layout.doors) {
      _drawDoorSymbol(canvas, door);
    }

    // Layer 4: Connection suggestions (nearby doors)
    _drawConnectionSuggestions(canvas);

    // Layer 5: Room labels
    for (final room in layout.rooms) {
      _drawRoomLabel(canvas, room);
    }
  }

  /// Draw background grid
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridSize = config.gridSize.toDouble();

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  /// Draw a single room outline
  void _drawRoomOutline(Canvas canvas, RoomOutline room, {required bool isSelected}) {
    if (room.vertices.isEmpty) return;

    // Create path from vertices
    final path = Path();
    final firstVertex = _transformVertex(room, room.vertices[0]);
    path.moveTo(firstVertex.dx, firstVertex.dy);

    for (int i = 1; i < room.vertices.length; i++) {
      final vertex = _transformVertex(room, room.vertices[i]);
      path.lineTo(vertex.dx, vertex.dy);
    }
    path.close();

    // Fill color (semi-transparent)
    final fillPaint = Paint()
      ..color = room.outlineColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Outline stroke
    final strokePaint = Paint()
      ..color = isSelected ? Colors.orange : room.outlineColor
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);

    // Draw selection handle (center point) if selected
    if (isSelected) {
      final bounds = room.getBoundingBox();
      final center = bounds.center;
      final handlePaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6.0, handlePaint);
    }
  }

  /// Transform a vertex from local room coordinates to canvas coordinates
  Offset _transformVertex(RoomOutline room, Offset vertex) {
    // Apply scale first
    final scaled = Offset(vertex.dx * room.scaleFactor, vertex.dy * room.scaleFactor);

    // Apply rotation
    final radians = room.rotationDegrees * (pi / 180.0);
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);
    final rotated = Offset(
      scaled.dx * cosTheta - scaled.dy * sinTheta,
      scaled.dx * sinTheta + scaled.dy * cosTheta,
    );

    // Apply position offset
    return rotated + room.positionOffset;
  }

  /// Draw a door symbol
  void _drawDoorSymbol(Canvas canvas, DoorSymbol door) {
    final paint = Paint()
      ..color = door.color
      ..style = PaintingStyle.fill;

    // Draw door as a small rectangle
    final rect = Rect.fromCenter(
      center: door.position,
      width: door.width,
      height: 8.0,
    );

    // Rotate the canvas to match door rotation
    canvas.save();
    canvas.translate(door.position.dx, door.position.dy);
    canvas.rotate(door.rotationDegrees * (pi / 180.0));
    canvas.translate(-door.position.dx, -door.position.dy);

    canvas.drawRect(rect, paint);

    // Draw door outline
    final outlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, outlinePaint);

    canvas.restore();

    // Draw connection indicator if connected
    if (door.connectedToDoorId != null) {
      final connectedPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(door.position, 4.0, connectedPaint);
    }
  }

  /// Draw connection suggestions between nearby doors
  void _drawConnectionSuggestions(Canvas canvas) {
    final nearbyPairs = layout.findNearbyDoorPairs(
      config.doorConnectionThreshold.toDouble(),
    );

    final suggestionPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pair in nearbyPairs) {
      // Only draw if neither door is already connected
      if (pair.door1.connectedToDoorId == null &&
          pair.door2.connectedToDoorId == null) {
        canvas.drawLine(
          pair.door1.position,
          pair.door2.position,
          suggestionPaint,
        );
      }
    }
  }

  /// Draw room label (name)
  void _drawRoomLabel(Canvas canvas, RoomOutline room) {
    if (room.vertices.isEmpty) return;

    final bounds = room.getBoundingBox();
    final center = bounds.center;

    final textSpan = TextSpan(
      text: room.roomName,
      style: TextStyle(
        color: Colors.black,
        fontSize: 12.0,
        fontWeight: room.isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background for text
    final textBgRect = Rect.fromCenter(
      center: center,
      width: textPainter.width + 8.0,
      height: textPainter.height + 4.0,
    );

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(textBgRect, bgPaint);

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant RoomLayoutCanvasPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.config != config;
  }
}
