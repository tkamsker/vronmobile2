import 'dart:io';

/// Status of a combined scan through the combine → upload → GLB → navmesh workflow
/// Feature 018: Combined Scan to NavMesh Workflow
enum CombinedScanStatus {
  combining,            // Creating local USDZ on-device
  uploadingUsdz,        // Uploading combined USDZ to GraphQL backend
  processingGlb,        // Backend creating GLB from USDZ
  glbReady,             // GLB created and downloaded, ready for navmesh
  uploadingToBlender,   // Uploading GLB to BlenderAPI session
  generatingNavmesh,    // BlenderAPI creating navmesh from GLB
  downloadingNavmesh,   // Downloading navmesh from BlenderAPI
  completed,            // Both GLB and navmesh ready locally
  failed,               // Operation failed (see errorMessage)
}

/// Tracks state of a combined scan through combine → upload → GLB → navmesh workflow
/// Feature 018: Combined Scan to NavMesh Workflow
/// Spec: specs/018-combined-scan-navmesh/data-model.md
class CombinedScan {
  /// Unique identifier (also backend scan ID)
  final String id;

  /// Associated project ID
  final String projectId;

  /// Source scan IDs (in combination order)
  final List<String> scanIds;

  /// Local combined USDZ file path
  final String localCombinedPath;

  /// Backend GLB URL (after conversion)
  final String? combinedGlbUrl;

  /// Local GLB file path (downloaded from backend)
  final String? combinedGlbLocalPath;

  /// BlenderAPI session ID for navmesh generation
  final String? navmeshSessionId;

  /// Downloaded navmesh GLB URL (from BlenderAPI session)
  final String? navmeshUrl;

  /// Local navmesh file path (after download)
  final String? localNavmeshPath;

  /// Current status
  final CombinedScanStatus status;

  /// Creation timestamp
  final DateTime createdAt;

  /// Completion timestamp
  final DateTime? completedAt;

  /// Error message if failed
  final String? errorMessage;

  CombinedScan({
    required this.id,
    required this.projectId,
    required this.scanIds,
    required this.localCombinedPath,
    this.combinedGlbUrl,
    this.combinedGlbLocalPath,
    this.navmeshSessionId,
    this.navmeshUrl,
    this.localNavmeshPath,
    this.status = CombinedScanStatus.combining,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  }) {
    // Validation
    if (scanIds.length < 2) {
      throw ArgumentError('CombinedScan must reference at least 2 source scans');
    }
    if (completedAt != null && completedAt!.isBefore(createdAt)) {
      throw ArgumentError('completedAt must be after createdAt');
    }
    if (status == CombinedScanStatus.failed && errorMessage == null) {
      throw ArgumentError('errorMessage required when status is failed');
    }
  }

  /// JSON serialization for local storage (SharedPreferences)
  factory CombinedScan.fromJson(Map<String, dynamic> json) {
    return CombinedScan(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      scanIds: (json['scanIds'] as List<dynamic>).cast<String>(),
      localCombinedPath: json['localCombinedPath'] as String,
      combinedGlbUrl: json['combinedGlbUrl'] as String?,
      combinedGlbLocalPath: json['combinedGlbLocalPath'] as String?,
      navmeshSessionId: json['navmeshSessionId'] as String?,
      navmeshUrl: json['navmeshUrl'] as String?,
      localNavmeshPath: json['localNavmeshPath'] as String?,
      status: CombinedScanStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'scanIds': scanIds,
      'localCombinedPath': localCombinedPath,
      'combinedGlbUrl': combinedGlbUrl,
      'combinedGlbLocalPath': combinedGlbLocalPath,
      'navmeshSessionId': navmeshSessionId,
      'navmeshUrl': navmeshUrl,
      'localNavmeshPath': localNavmeshPath,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// Copy with method for state updates
  CombinedScan copyWith({
    String? id,
    String? projectId,
    List<String>? scanIds,
    String? localCombinedPath,
    String? combinedGlbUrl,
    String? combinedGlbLocalPath,
    String? navmeshSessionId,
    String? navmeshUrl,
    String? localNavmeshPath,
    CombinedScanStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return CombinedScan(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      scanIds: scanIds ?? this.scanIds,
      localCombinedPath: localCombinedPath ?? this.localCombinedPath,
      combinedGlbUrl: combinedGlbUrl ?? this.combinedGlbUrl,
      combinedGlbLocalPath: combinedGlbLocalPath ?? this.combinedGlbLocalPath,
      navmeshSessionId: navmeshSessionId ?? this.navmeshSessionId,
      navmeshUrl: navmeshUrl ?? this.navmeshUrl,
      localNavmeshPath: localNavmeshPath ?? this.localNavmeshPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Helper methods

  /// Check if operation is in progress
  bool isInProgress() =>
      status != CombinedScanStatus.completed &&
      status != CombinedScanStatus.failed;

  /// Check if ready to generate navmesh
  bool canGenerateNavmesh() => status == CombinedScanStatus.glbReady;

  /// Check if GLB file is available
  bool hasGlb() => combinedGlbUrl != null;

  /// Check if navmesh is available
  bool hasNavmesh() => navmeshUrl != null && localNavmeshPath != null;

  /// Get local combined file size in bytes
  Future<int?> getLocalCombinedFileSize() async {
    try {
      final file = File(localCombinedPath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get local navmesh file size in bytes
  Future<int?> getLocalNavmeshFileSize() async {
    if (localNavmeshPath == null) return null;
    try {
      final file = File(localNavmeshPath!);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete all local files (combined USDZ and navmesh)
  Future<void> deleteLocalFiles() async {
    // Delete combined USDZ
    try {
      final combinedFile = File(localCombinedPath);
      if (await combinedFile.exists()) {
        await combinedFile.delete();
      }
    } catch (e) {
      // Ignore errors, continue cleanup
    }

    // Delete combined GLB if exists locally
    if (combinedGlbLocalPath != null) {
      try {
        final glbFile = File(combinedGlbLocalPath!);
        if (await glbFile.exists()) {
          await glbFile.delete();
        }
      } catch (e) {
        // Ignore errors, continue cleanup
      }
    }

    // Delete navmesh if exists locally
    if (localNavmeshPath != null) {
      try {
        final navmeshFile = File(localNavmeshPath!);
        if (await navmeshFile.exists()) {
          await navmeshFile.delete();
        }
      } catch (e) {
        // Ignore errors
      }
    }
  }
}
