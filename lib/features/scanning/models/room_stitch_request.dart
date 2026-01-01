import 'package:json_annotation/json_annotation.dart';

part 'room_stitch_request.g.dart';

/// Alignment mode for stitching multiple room scans
enum AlignmentMode {
  /// Automatic alignment using feature detection
  auto,

  /// Manual alignment with user-defined anchor points
  manual,
}

/// Output format for stitched 3D model
enum OutputFormat {
  /// GL Transmission Format (binary) - widely supported
  glb,

  /// Universal Scene Description (Apple AR) - iOS optimized
  usdz,
}

/// Request to stitch multiple room scans into a single 3D model
///
/// Minimum requirement: 2 scans
/// Maximum: 10 scans (backend limitation)
@JsonSerializable()
class RoomStitchRequest {
  /// Project ID that owns the scans
  final String projectId;

  /// List of scan IDs to stitch together (minimum 2, maximum 10)
  final List<String> scanIds;

  /// Alignment mode (default: auto)
  @JsonKey(defaultValue: AlignmentMode.auto)
  final AlignmentMode alignmentMode;

  /// Output format (default: GLB)
  @JsonKey(defaultValue: OutputFormat.glb)
  final OutputFormat outputFormat;

  /// Optional room names mapped by scan ID
  /// Example: {'scan-001': 'Living Room', 'scan-002': 'Kitchen'}
  final Map<String, String>? roomNames;

  RoomStitchRequest({
    required this.projectId,
    required this.scanIds,
    this.alignmentMode = AlignmentMode.auto,
    this.outputFormat = OutputFormat.glb,
    this.roomNames,
  });

  /// Validates the request meets minimum requirements
  ///
  /// Returns true if:
  /// - projectId is not empty
  /// - scanIds contains at least 2 scans
  bool isValid() {
    return projectId.isNotEmpty && scanIds.length >= 2;
  }

  /// Generates a filename for the stitched model
  ///
  /// Format with room names: "living-room-master-bedroom-2025-01-01.glb"
  /// Format without names: "3-rooms-stitched-2025-01-01.glb"
  String generateFilename() {
    final date = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final extension = outputFormat == OutputFormat.glb ? 'glb' : 'usdz';

    String baseName;

    if (roomNames != null && roomNames!.isNotEmpty) {
      // Use room names (sanitized)
      final sanitizedNames = roomNames!.values
          .map((name) => _sanitizeForFilename(name))
          .join('-');
      baseName = 'stitched-$sanitizedNames';
    } else {
      // Use scan count
      baseName = 'stitched-${scanIds.length}-rooms';
    }

    return '$baseName-$date.$extension';
  }

  /// Sanitizes a room name for use in a filename
  ///
  /// - Converts to lowercase
  /// - Replaces spaces with hyphens
  /// - Removes special characters (keep only alphanumeric and hyphens)
  String _sanitizeForFilename(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  }

  /// Converts request to GraphQL mutation variables
  ///
  /// Returns a map in the format expected by the StitchRooms mutation:
  /// ```
  /// {
  ///   "input": {
  ///     "projectId": "proj-001",
  ///     "scanIds": ["scan-001", "scan-002"],
  ///     "alignmentMode": "AUTO",
  ///     "outputFormat": "GLB",
  ///     "roomNames": [
  ///       {"scanId": "scan-001", "name": "Living Room"},
  ///       {"scanId": "scan-002", "name": "Kitchen"}
  ///     ]
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toGraphQLVariables() {
    return {
      'input': {
        'projectId': projectId,
        'scanIds': scanIds,
        'alignmentMode': alignmentMode.name.toUpperCase(),
        'outputFormat': outputFormat.name.toUpperCase(),
        if (roomNames != null && roomNames!.isNotEmpty)
          'roomNames': roomNames!.entries
              .map((e) => {
                    'scanId': e.key,
                    'name': e.value,
                  })
              .toList(),
      },
    };
  }

  // JSON serialization
  factory RoomStitchRequest.fromJson(Map<String, dynamic> json) =>
      _$RoomStitchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RoomStitchRequestToJson(this);
}
