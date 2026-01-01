import 'package:json_annotation/json_annotation.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';

part 'stitched_model.g.dart';

/// Represents a successfully stitched 3D model stored locally
///
/// Created from a completed RoomStitchJob after downloading the result file
@JsonSerializable()
class StitchedModel {
  /// Unique identifier (same as job ID)
  final String id;

  /// Local file path where stitched model is stored
  /// Example: "/Documents/scans/stitched-living-master-2025-01-01.glb"
  final String localPath;

  /// List of original scan IDs that were stitched together
  final List<String> originalScanIds;

  /// Optional room names mapped by scan ID
  /// Example: {'scan-001': 'Living Room', 'scan-002': 'Kitchen'}
  final Map<String, String>? roomNames;

  /// File size in bytes
  /// Typical range: 20 MB - 100 MB
  final int fileSizeBytes;

  /// Timestamp when stitched model was created (completed)
  final DateTime createdAt;

  /// Model format ('glb' or 'usdz')
  @JsonKey(defaultValue: 'glb')
  final String format;

  /// Optional metadata about the 3D model
  /// Example: {'polygonCount': 450000, 'textureCount': 12}
  final Map<String, dynamic>? metadata;

  StitchedModel({
    required this.id,
    required this.localPath,
    required this.originalScanIds,
    this.roomNames,
    required this.fileSizeBytes,
    required this.createdAt,
    this.format = 'glb',
    this.metadata,
  });

  /// Returns a user-friendly display name for the stitched model
  ///
  /// Logic:
  /// - 1 room with name: "Living Room"
  /// - 2 rooms with names: "Living Room + Master Bedroom"
  /// - 3+ rooms with names: "Living Room + Master Bedroom + 1 more"
  /// - No room names: "3 rooms stitched"
  String get displayName {
    if (roomNames == null || roomNames!.isEmpty) {
      return '${originalScanIds.length} rooms stitched';
    }

    final names = roomNames!.values.toList();

    if (names.length == 1) {
      return names[0];
    } else if (names.length == 2) {
      return '${names[0]} + ${names[1]}';
    } else {
      // 3+ rooms: show first 2 + count
      final remaining = names.length - 2;
      return '${names[0]} + ${names[1]} + $remaining more';
    }
  }

  /// Returns path to thumbnail image (placeholder for future enhancement)
  ///
  /// Future: Generate thumbnail from first frame of 3D model
  String? get thumbnailPath => null;

  /// Creates a StitchedModel from a completed RoomStitchJob
  ///
  /// Parameters:
  /// - [job]: Completed stitching job with resultUrl
  /// - [localPath]: Path where GLB/USDZ file was saved
  /// - [fileSizeBytes]: Size of downloaded file
  /// - [originalScanIds]: List of scan IDs that were stitched
  /// - [roomNames]: Optional room names for display
  factory StitchedModel.fromJob(
    RoomStitchJob job,
    String localPath,
    int fileSizeBytes,
    List<String> originalScanIds,
    Map<String, String>? roomNames,
  ) {
    return StitchedModel(
      id: job.jobId,
      localPath: localPath,
      originalScanIds: originalScanIds,
      roomNames: roomNames,
      fileSizeBytes: fileSizeBytes,
      createdAt: job.completedAt ?? DateTime.now(),
      format: localPath.endsWith('.usdz') ? 'usdz' : 'glb',
    );
  }

  // JSON serialization
  factory StitchedModel.fromJson(Map<String, dynamic> json) =>
      _$StitchedModelFromJson(json);

  Map<String, dynamic> toJson() => _$StitchedModelToJson(this);
}
