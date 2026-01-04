import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/room_layout.dart';
import 'package:vronmobile2/features/scanning/models/room_outline.dart';
import 'package:vronmobile2/features/scanning/models/door_symbol.dart';
import 'package:vronmobile2/features/scanning/models/canvas_configuration.dart';
import 'package:vronmobile2/features/scanning/models/canvas_interaction_mode.dart';
import 'package:vronmobile2/features/scanning/widgets/room_layout_canvas.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/services/room_outline_extraction_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

/// Canvas screen for arranging room scans before stitching
/// Supports selection, rotation, dragging, and door placement
class RoomLayoutCanvasScreen extends StatefulWidget {
  final List<ScanData> scans;
  final String projectId;

  const RoomLayoutCanvasScreen({
    super.key,
    required this.scans,
    required this.projectId,
  });

  @override
  State<RoomLayoutCanvasScreen> createState() => _RoomLayoutCanvasScreenState();
}

class _RoomLayoutCanvasScreenState extends State<RoomLayoutCanvasScreen> {
  late RoomLayout _layout;
  late CanvasConfiguration _config;
  CanvasInteractionMode _mode = CanvasInteractionMode.selecting;

  // For drag gesture tracking
  Offset? _lastPanPosition;
  final Uuid _uuid = const Uuid();
  final RoomOutlineExtractionService _extractionService = RoomOutlineExtractionService();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLayout();
  }

  /// Initialize layout by extracting 3D→2D outlines from scan files
  Future<void> _initializeLayout() async {
    setState(() {
      _isLoading = true;
    });

    // Get canvas configuration from .env
    _config = CanvasConfiguration.defaultConfig();

    try {
      // Extract real outlines from 3D models
      print('🔄 Extracting outlines from ${widget.scans.length} scans...');
      final outlines = await _extractionService.extractOutlines(widget.scans);

      // Position rooms in a grid layout on the canvas
      final positionedRooms = <RoomOutline>[];
      for (int i = 0; i < outlines.length; i++) {
        final outline = outlines[i];
        final room = outline.copyWith(
          positionOffset: Offset(150.0 + i * 150.0, 200.0),
          outlineColor: _getColorForIndex(i),
        );
        positionedRooms.add(room);
      }

      setState(() {
        _layout = RoomLayout.empty().copyWith(rooms: positionedRooms);
        _isLoading = false;
      });

      print('✅ Canvas initialized with ${positionedRooms.length} room outlines');
    } catch (e) {
      print('❌ Error initializing layout: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get a distinct color for each room
  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  /// Handle tap on canvas
  void _handleTapDown(TapDownDetails details) {
    final tapPosition = details.localPosition;

    // Handle different interaction modes
    switch (_mode) {
      case CanvasInteractionMode.selecting:
        _handleSelectTap(tapPosition);
        break;
      case CanvasInteractionMode.moving:
      case CanvasInteractionMode.rotating:
      case CanvasInteractionMode.placingDoor:
      case CanvasInteractionMode.idle:
        // These modes don't use tap
        break;
    }
  }

  /// Handle selection tap
  void _handleSelectTap(Offset tapPosition) {
    // Check if tap is on any room
    for (final room in _layout.rooms) {
      if (room.containsPoint(tapPosition)) {
        setState(() {
          if (room.isSelected) {
            // Deselect if already selected
            _layout = _layout.deselectAllRooms();
            _mode = CanvasInteractionMode.selecting;
          } else {
            // Select this room
            _layout = _layout.selectRoom(room.scanId);
          }
        });
        return;
      }
    }

    // Tap outside any room - deselect all
    setState(() {
      _layout = _layout.deselectAllRooms();
      _mode = CanvasInteractionMode.selecting;
    });
  }

  /// Handle door placement on room borders
  void _handleDoorPlacement(Offset tapPosition) {
    final selectedRoom = _layout.getSelectedRoom();
    if (selectedRoom == null) return;

    // Find closest edge to tap position
    final doorPosition = _findClosestEdgePoint(selectedRoom, tapPosition);
    if (doorPosition == null) return;

    // Calculate door rotation (perpendicular to edge)
    final doorRotation = _calculateDoorRotation(selectedRoom, doorPosition);

    // Create door symbol
    final door = DoorSymbol(
      id: _uuid.v4(),
      roomScanId: selectedRoom.scanId,
      position: doorPosition,
      rotationDegrees: doorRotation,
      type: DoorType.manual,
    );

    setState(() {
      _layout = _layout.addDoor(door);
    });
  }

  /// Find closest point on room border to tap position
  Offset? _findClosestEdgePoint(RoomOutline room, Offset tapPosition) {
    if (room.vertices.isEmpty) return null;

    double minDistance = double.infinity;
    Offset? closestPoint;

    // Check each edge
    for (int i = 0; i < room.vertices.length; i++) {
      final v1 = _transformVertex(room, room.vertices[i]);
      final v2 = _transformVertex(room, room.vertices[(i + 1) % room.vertices.length]);

      // Find closest point on this edge
      final edgePoint = _closestPointOnSegment(tapPosition, v1, v2);
      final distance = (edgePoint - tapPosition).distance;

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = edgePoint;
      }
    }

    // Only accept if tap is close enough (within 30 pixels)
    if (minDistance < 30.0) {
      return closestPoint;
    }

    return null;
  }

  /// Find closest point on line segment to a given point
  Offset _closestPointOnSegment(Offset point, Offset segmentStart, Offset segmentEnd) {
    final segmentVector = segmentEnd - segmentStart;
    final pointVector = point - segmentStart;

    final segmentLengthSquared = segmentVector.dx * segmentVector.dx +
                                  segmentVector.dy * segmentVector.dy;

    if (segmentLengthSquared == 0) return segmentStart;

    final t = ((pointVector.dx * segmentVector.dx + pointVector.dy * segmentVector.dy) /
               segmentLengthSquared).clamp(0.0, 1.0);

    return segmentStart + segmentVector * t;
  }

  /// Calculate door rotation perpendicular to edge
  double _calculateDoorRotation(RoomOutline room, Offset doorPosition) {
    // Find which edge this door is on
    double minDistance = double.infinity;
    double rotation = 0.0;

    for (int i = 0; i < room.vertices.length; i++) {
      final v1 = _transformVertex(room, room.vertices[i]);
      final v2 = _transformVertex(room, room.vertices[(i + 1) % room.vertices.length]);

      final edgePoint = _closestPointOnSegment(doorPosition, v1, v2);
      final distance = (edgePoint - doorPosition).distance;

      if (distance < minDistance) {
        minDistance = distance;
        // Calculate edge angle and add 90 degrees for perpendicular
        final edgeAngle = atan2(v2.dy - v1.dy, v2.dx - v1.dx) * 180 / pi;
        rotation = (edgeAngle + 90) % 360;
      }
    }

    return rotation;
  }

  /// Transform vertex from local to canvas coordinates
  Offset _transformVertex(RoomOutline room, Offset vertex) {
    final radians = room.rotationDegrees * (pi / 180.0);
    final cosTheta = cos(radians);
    final sinTheta = sin(radians);
    final rotated = Offset(
      vertex.dx * cosTheta - vertex.dy * sinTheta,
      vertex.dx * sinTheta + vertex.dy * cosTheta,
    );
    return rotated + room.positionOffset;
  }

  /// Handle pan start (for moving rooms)
  void _handlePanStart(DragStartDetails details) {
    if (_mode != CanvasInteractionMode.moving) return;

    final selectedRoom = _layout.getSelectedRoom();
    if (selectedRoom == null) return;

    _lastPanPosition = details.localPosition;
  }

  /// Handle pan update (for moving rooms)
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_mode != CanvasInteractionMode.moving) return;
    if (_lastPanPosition == null) return;

    final selectedRoom = _layout.getSelectedRoom();
    if (selectedRoom == null) return;

    final delta = details.localPosition - _lastPanPosition!;
    final newPosition = selectedRoom.positionOffset + delta;

    setState(() {
      _layout = _layout.updateRoom(
        selectedRoom.scanId,
        selectedRoom.copyWith(positionOffset: newPosition),
      );
    });

    _lastPanPosition = details.localPosition;
  }

  /// Handle pan end
  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
  }

  /// Rotate selected room
  void _rotateSelectedRoom() {
    final selectedRoom = _layout.getSelectedRoom();
    if (selectedRoom == null) return;

    final newRotation =
        (selectedRoom.rotationDegrees + _config.rotationIncrement) % 360;

    setState(() {
      _layout = _layout.updateRoom(
        selectedRoom.scanId,
        selectedRoom.copyWith(rotationDegrees: newRotation),
      );
    });
  }

  /// Scale all rooms bigger (convenience feature for positioning)
  void _scaleSelectedRoomBigger() {
    setState(() {
      final updatedRooms = _layout.rooms.map((room) {
        final newScale = (room.scaleFactor + 0.1).clamp(0.1, 5.0);
        return room.copyWith(scaleFactor: newScale);
      }).toList();
      _layout = _layout.copyWith(rooms: updatedRooms);
    });
  }

  /// Scale all rooms smaller (convenience feature for positioning)
  void _scaleSelectedRoomSmaller() {
    setState(() {
      final updatedRooms = _layout.rooms.map((room) {
        final newScale = (room.scaleFactor - 0.1).clamp(0.1, 5.0);
        return room.copyWith(scaleFactor: newScale);
      }).toList();
      _layout = _layout.copyWith(rooms: updatedRooms);
    });
  }

  /// Reset all room sizes to original (scale = 1.0)
  void _resetAllRoomSizes() {
    setState(() {
      final updatedRooms = _layout.rooms.map((room) {
        return room.copyWith(scaleFactor: 1.0);
      }).toList();
      _layout = _layout.copyWith(rooms: updatedRooms);
    });
  }

  /// Proceed to stitching
  void _proceedToStitching() {
    Navigator.of(context).pop(_layout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrange Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _proceedToStitching,
            tooltip: 'Done - Proceed to Stitching',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Extracting room outlines...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing ${widget.scans.length} scan(s)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : Column(
        children: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Mode: ${_mode.displayName}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Selected: ${_layout.getSelectedRoom()?.roomName ?? 'None'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: CustomPaint(
                painter: RoomLayoutCanvasPainter(
                  layout: _layout,
                  config: _config,
                ),
                child: Container(
                  color: Colors.transparent, // Make entire area tappable
                ),
              ),
            ),
          ),

          // Control buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.touch_app,
                  label: 'Select',
                  isActive: _mode == CanvasInteractionMode.selecting,
                  onPressed: () {
                    setState(() {
                      _mode = CanvasInteractionMode.selecting;
                    });
                  },
                ),
                _buildControlButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  isActive: _mode == CanvasInteractionMode.rotating,
                  onPressed: _layout.getSelectedRoom() != null
                      ? _rotateSelectedRoom
                      : null,
                ),
                _buildControlButton(
                  icon: Icons.remove_circle_outline,
                  label: 'Smaller',
                  isActive: false,
                  onPressed: _scaleSelectedRoomSmaller,
                ),
                _buildControlButton(
                  icon: Icons.add_circle_outline,
                  label: 'Bigger',
                  isActive: false,
                  onPressed: _scaleSelectedRoomBigger,
                ),
                _buildControlButton(
                  icon: Icons.restart_alt,
                  label: 'Reset Size',
                  isActive: false,
                  onPressed: _resetAllRoomSizes,
                ),
                _buildControlButton(
                  icon: Icons.open_with,
                  label: 'Move',
                  isActive: _mode == CanvasInteractionMode.moving,
                  onPressed: () {
                    if (_layout.getSelectedRoom() != null) {
                      setState(() {
                        _mode = CanvasInteractionMode.moving;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: isActive ? Colors.orange : Colors.grey[700],
          iconSize: 28,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.orange : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
