import 'package:json_annotation/json_annotation.dart';

part 'room_stitch_job.g.dart';

/// Status of a room stitching job in the backend pipeline
enum RoomStitchJobStatus {
  /// Job created, waiting to start
  pending,

  /// Uploading scan files to backend
  uploading,

  /// Processing scan data (validation, preparation)
  processing,

  /// Aligning rooms using feature detection
  aligning,

  /// Merging aligned geometry into single model
  merging,

  /// Stitching completed successfully
  completed,

  /// Stitching failed (see errorMessage for details)
  failed,
}

/// Represents a room stitching job tracked by the backend
///
/// Jobs progress through states: pending → uploading → processing → aligning → merging → completed/failed
/// Polling interval: 2 seconds (configurable)
/// Maximum duration: ~5 minutes (backend timeout)
@JsonSerializable()
class RoomStitchJob {
  /// Unique job identifier from backend
  final String jobId;

  /// Current status of the stitching job
  final RoomStitchJobStatus status;

  /// Progress percentage (0-100)
  /// - 0: pending
  /// - 10: uploading
  /// - 30: processing
  /// - 60: aligning
  /// - 85: merging
  /// - 100: completed
  final int progress;

  /// Error message if status is failed
  final String? errorMessage;

  /// URL to download stitched GLB/USDZ file (available when completed)
  final String? resultUrl;

  /// Timestamp when job was created
  final DateTime createdAt;

  /// Timestamp when job reached terminal state (completed or failed)
  final DateTime? completedAt;

  /// Estimated total duration in seconds (provided by backend)
  /// Typical range: 60-300 seconds depending on scan count and complexity
  final int? estimatedDurationSeconds;

  RoomStitchJob({
    required this.jobId,
    required this.status,
    required this.progress,
    this.errorMessage,
    this.resultUrl,
    required this.createdAt,
    this.completedAt,
    this.estimatedDurationSeconds,
  });

  /// Returns true if job has reached a terminal state (completed or failed)
  ///
  /// Terminal states will not receive further updates from polling
  bool get isTerminal =>
      status == RoomStitchJobStatus.completed ||
      status == RoomStitchJobStatus.failed;

  /// Returns true if job completed successfully with a result URL
  bool get isSuccessful =>
      status == RoomStitchJobStatus.completed && resultUrl != null;

  /// Returns elapsed time in seconds
  ///
  /// If job is still running: time since createdAt
  /// If job is terminal: time between createdAt and completedAt
  int get elapsedSeconds {
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(createdAt).inSeconds;
  }

  /// Returns user-friendly status message for current state
  String get statusMessage {
    switch (status) {
      case RoomStitchJobStatus.pending:
        return 'Waiting to start...';
      case RoomStitchJobStatus.uploading:
        return 'Uploading scans...';
      case RoomStitchJobStatus.processing:
        return 'Processing...';
      case RoomStitchJobStatus.aligning:
        return 'Aligning rooms...';
      case RoomStitchJobStatus.merging:
        return 'Merging geometry...';
      case RoomStitchJobStatus.completed:
        return 'Stitching complete!';
      case RoomStitchJobStatus.failed:
        return errorMessage ?? 'Stitching failed';
    }
  }

  /// Creates a copy with updated fields
  ///
  /// Used during polling to update job state
  RoomStitchJob copyWith({
    String? jobId,
    RoomStitchJobStatus? status,
    int? progress,
    String? errorMessage,
    String? resultUrl,
    DateTime? createdAt,
    DateTime? completedAt,
    int? estimatedDurationSeconds,
  }) {
    return RoomStitchJob(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      resultUrl: resultUrl ?? this.resultUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
    );
  }

  // JSON serialization
  factory RoomStitchJob.fromJson(Map<String, dynamic> json) =>
      _$RoomStitchJobFromJson(json);

  Map<String, dynamic> toJson() => _$RoomStitchJobToJson(this);
}
