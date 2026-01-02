/// Interaction modes for canvas manipulation
/// Determines how user input is interpreted on the canvas
enum CanvasInteractionMode {
  /// Default mode - no active interaction
  idle,

  /// User can tap rooms to select/deselect them
  selecting,

  /// User can drag to move the selected room
  moving,

  /// User can tap Rotate button to rotate selected room
  rotating,

  /// User can tap room borders to place manual door symbols
  placingDoor,
}

/// Extension for displaying mode names
extension CanvasInteractionModeExtension on CanvasInteractionMode {
  String get displayName {
    switch (this) {
      case CanvasInteractionMode.idle:
        return 'Idle';
      case CanvasInteractionMode.selecting:
        return 'Selecting';
      case CanvasInteractionMode.moving:
        return 'Moving';
      case CanvasInteractionMode.rotating:
        return 'Rotating';
      case CanvasInteractionMode.placingDoor:
        return 'Placing Door';
    }
  }

  bool get isInteractive {
    return this != CanvasInteractionMode.idle;
  }
}
