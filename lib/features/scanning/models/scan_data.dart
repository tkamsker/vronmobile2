import 'dart:io';

enum ScanFormat {
  usdz, // Apple RoomPlan native output
  glb,  // glTF binary format
}

enum ScanStatus {
  capturing,    // Scan in progress
  completed,    // Scan finished, stored locally
  uploading,    // Upload to backend in progress
  uploaded,     // Successfully uploaded to backend
  failed,       // Scan or upload failed
}

class ScanData {
  final String id;              // Unique identifier (UUID)
  final ScanFormat format;      // USDZ or GLB
  final String localPath;       // Local filesystem path
  final int fileSizeBytes;      // File size in bytes
  final DateTime capturedAt;    // Timestamp of scan completion
  final ScanStatus status;      // Current status
  final String? projectId;      // Associated project (null for guest scans)
  final String? remoteUrl;      // Backend URL after upload (null if not uploaded)
  final Map<String, dynamic>? metadata; // Additional metadata (room dimensions, object count, etc.)

  ScanData({
    required this.id,
    required this.format,
    required this.localPath,
    required this.fileSizeBytes,
    required this.capturedAt,
    required this.status,
    this.projectId,
    this.remoteUrl,
    this.metadata,
  });

  // JSON serialization for local storage (shared_preferences)
  factory ScanData.fromJson(Map<String, dynamic> json) {
    return ScanData(
      id: json['id'] as String,
      format: ScanFormat.values.byName(json['format'] as String),
      localPath: json['localPath'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      status: ScanStatus.values.byName(json['status'] as String),
      projectId: json['projectId'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format.name,
      'localPath': localPath,
      'fileSizeBytes': fileSizeBytes,
      'capturedAt': capturedAt.toIso8601String(),
      'status': status.name,
      'projectId': projectId,
      'remoteUrl': remoteUrl,
      'metadata': metadata,
    };
  }

  // Helper: Check if file exists on device
  Future<bool> existsLocally() async {
    final file = File(localPath);
    return await file.exists();
  }

  // Helper: Delete local file
  Future<void> deleteLocally() async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Helper: Get file as bytes for upload
  Future<List<int>> readBytes() async {
    final file = File(localPath);
    return await file.readAsBytes();
  }
}
