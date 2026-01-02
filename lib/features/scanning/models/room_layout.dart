import 'package:json_annotation/json_annotation.dart';
import 'package:vronmobile2/features/scanning/models/room_outline.dart';
import 'package:vronmobile2/features/scanning/models/door_symbol.dart';

part 'room_layout.g.dart';

/// Container for complete canvas layout state
/// Includes all room outlines, door symbols, and their connections
@JsonSerializable()
class RoomLayout {
  /// All room outlines on the canvas
  final List<RoomOutline> rooms;

  /// All door symbols on the canvas
  final List<DoorSymbol> doors;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modification timestamp
  final DateTime updatedAt;

  const RoomLayout({
    required this.rooms,
    required this.doors,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty layout
  factory RoomLayout.empty() {
    final now = DateTime.now();
    return RoomLayout(
      rooms: [],
      doors: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from JSON
  factory RoomLayout.fromJson(Map<String, dynamic> json) =>
      _$RoomLayoutFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$RoomLayoutToJson(this);

  /// Create a copy with updated fields
  RoomLayout copyWith({
    List<RoomOutline>? rooms,
    List<DoorSymbol>? doors,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomLayout(
      rooms: rooms ?? this.rooms,
      doors: doors ?? this.doors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Add a room to the layout
  RoomLayout addRoom(RoomOutline room) {
    return copyWith(
      rooms: [...rooms, room],
      updatedAt: DateTime.now(),
    );
  }

  /// Update an existing room
  RoomLayout updateRoom(String scanId, RoomOutline updatedRoom) {
    final updatedRooms = rooms.map((r) {
      return r.scanId == scanId ? updatedRoom : r;
    }).toList();

    return copyWith(
      rooms: updatedRooms,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a room from the layout
  RoomLayout removeRoom(String scanId) {
    return copyWith(
      rooms: rooms.where((r) => r.scanId != scanId).toList(),
      doors: doors.where((d) => d.roomScanId != scanId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add a door symbol to the layout
  RoomLayout addDoor(DoorSymbol door) {
    return copyWith(
      doors: [...doors, door],
      updatedAt: DateTime.now(),
    );
  }

  /// Update an existing door
  RoomLayout updateDoor(String doorId, DoorSymbol updatedDoor) {
    final updatedDoors = doors.map((d) {
      return d.id == doorId ? updatedDoor : d;
    }).toList();

    return copyWith(
      doors: updatedDoors,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a door from the layout
  RoomLayout removeDoor(String doorId) {
    return copyWith(
      doors: doors.where((d) => d.id != doorId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get room by scan ID
  RoomOutline? getRoomById(String scanId) {
    try {
      return rooms.firstWhere((r) => r.scanId == scanId);
    } catch (_) {
      return null;
    }
  }

  /// Get door by ID
  DoorSymbol? getDoorById(String doorId) {
    try {
      return doors.firstWhere((d) => d.id == doorId);
    } catch (_) {
      return null;
    }
  }

  /// Get all doors for a specific room
  List<DoorSymbol> getDoorsForRoom(String scanId) {
    return doors.where((d) => d.roomScanId == scanId).toList();
  }

  /// Get currently selected room (if any)
  RoomOutline? getSelectedRoom() {
    try {
      return rooms.firstWhere((r) => r.isSelected);
    } catch (_) {
      return null;
    }
  }

  /// Deselect all rooms
  RoomLayout deselectAllRooms() {
    final updatedRooms = rooms.map((r) => r.copyWith(isSelected: false)).toList();
    return copyWith(
      rooms: updatedRooms,
      updatedAt: DateTime.now(),
    );
  }

  /// Select a room (and deselect others)
  RoomLayout selectRoom(String scanId) {
    final updatedRooms = rooms.map((r) {
      return r.copyWith(isSelected: r.scanId == scanId);
    }).toList();

    return copyWith(
      rooms: updatedRooms,
      updatedAt: DateTime.now(),
    );
  }

  /// Find nearby door pairs within connection threshold
  List<DoorPair> findNearbyDoorPairs(double threshold) {
    final pairs = <DoorPair>[];

    for (int i = 0; i < doors.length; i++) {
      for (int j = i + 1; j < doors.length; j++) {
        final door1 = doors[i];
        final door2 = doors[j];

        // Only suggest connections between different rooms
        if (door1.roomScanId != door2.roomScanId &&
            door1.isNearby(door2, threshold)) {
          pairs.add(DoorPair(door1: door1, door2: door2));
        }
      }
    }

    return pairs;
  }

  /// Check if layout has any rooms
  bool get isEmpty => rooms.isEmpty;

  /// Get total number of room connections
  int get connectionCount {
    final connectedDoorIds = doors
        .where((d) => d.connectedToDoorId != null)
        .map((d) => d.id)
        .toSet();
    return connectedDoorIds.length ~/ 2; // Each connection involves 2 doors
  }
}

/// Represents a pair of nearby doors that could be connected
class DoorPair {
  final DoorSymbol door1;
  final DoorSymbol door2;

  const DoorPair({
    required this.door1,
    required this.door2,
  });

  /// Calculate distance between the two doors
  double get distance => (door1.position - door2.position).distance;
}
