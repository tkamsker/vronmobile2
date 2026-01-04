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
  final String localPath;       // Local filesystem path (USDZ file)
  final String? glbLocalPath;   // Local GLB file path (null if not converted yet)
  final int fileSizeBytes;      // File size in bytes
  final DateTime capturedAt;    // Timestamp of scan completion
  final ScanStatus status;      // Current status
  final String? projectId;      // Associated project (null for guest scans)
  final String? remoteUrl;      // Backend URL after upload (null if not uploaded)
  final Map<String, dynamic>? metadata; // Additional metadata (room dimensions, object count, etc.)

  // Positioning data from room arrangement canvas (for combining scans)
  final double? positionX;      // X position on canvas (null if not arranged)
  final double? positionY;      // Y position on canvas (null if not arranged)
  final double? rotationDegrees; // Rotation in degrees (null if not arranged)
  final double? scaleFactor;    // Scale factor (null if not arranged, default 1.0)

  ScanData({
    required this.id,
    required this.format,
    required this.localPath,
    this.glbLocalPath,
    required this.fileSizeBytes,
    required this.capturedAt,
    required this.status,
    this.projectId,
    this.remoteUrl,
    this.metadata,
    this.positionX,
    this.positionY,
    this.rotationDegrees,
    this.scaleFactor,
  });

  // JSON serialization for local storage (shared_preferences)
  factory ScanData.fromJson(Map<String, dynamic> json) {
    return ScanData(
      id: json['id'] as String,
      format: ScanFormat.values.byName(json['format'] as String),
      localPath: json['localPath'] as String,
      glbLocalPath: json['glbLocalPath'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      status: ScanStatus.values.byName(json['status'] as String),
      projectId: json['projectId'] as String?,
      remoteUrl: json['remoteUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      positionX: json['positionX'] as double?,
      positionY: json['positionY'] as double?,
      rotationDegrees: json['rotationDegrees'] as double?,
      scaleFactor: json['scaleFactor'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format.name,
      'localPath': localPath,
      'glbLocalPath': glbLocalPath,
      'fileSizeBytes': fileSizeBytes,
      'capturedAt': capturedAt.toIso8601String(),
      'status': status.name,
      'projectId': projectId,
      'remoteUrl': remoteUrl,
      'metadata': metadata,
      'positionX': positionX,
      'positionY': positionY,
      'rotationDegrees': rotationDegrees,
      'scaleFactor': scaleFactor,
    };
  }

  // Copy with method to update glbLocalPath after conversion
  ScanData copyWith({
    String? id,
    ScanFormat? format,
    String? localPath,
    String? glbLocalPath,
    int? fileSizeBytes,
    DateTime? capturedAt,
    ScanStatus? status,
    String? projectId,
    String? remoteUrl,
    Map<String, dynamic>? metadata,
    double? positionX,
    double? positionY,
    double? rotationDegrees,
    double? scaleFactor,
  }) {
    return ScanData(
      id: id ?? this.id,
      format: format ?? this.format,
      localPath: localPath ?? this.localPath,
      glbLocalPath: glbLocalPath ?? this.glbLocalPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      metadata: metadata ?? this.metadata,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
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
