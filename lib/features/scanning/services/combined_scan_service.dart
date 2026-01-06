import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vronmobile2/core/utils/logger.dart'; // T087: Structured logging
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/services/usdz_combiner_service.dart';
import 'package:vronmobile2/features/scanning/services/blenderapi_service.dart';

/// Orchestration service for combined scan workflow
/// Feature 018: Combined Scan to NavMesh Workflow
/// Coordinates USDZ combination, upload, GLB conversion, and navmesh generation
class CombinedScanService {
  final USDZCombinerService combiner;
  final BlenderAPIService blenderAPI;

  CombinedScanService({
    USDZCombinerService? combiner,
    BlenderAPIService? blenderAPI,
  })  : combiner = combiner ?? USDZCombinerService(),
        blenderAPI = blenderAPI ?? BlenderAPIService();

  /// Create combined scan from multiple positioned room scans
  ///
  /// Workflow:
  /// 1. Validate scans (minimum 2, with positions)
  /// 2. Combine USDZ files on-device using iOS native
  /// 3. Return CombinedScan with initial state
  ///
  /// [projectId] - Associated project
  /// [scans] - List of positioned scans (minimum 2)
  /// [documentsDirectory] - App documents directory
  /// [onStatusChange] - Optional callback for status updates
  ///
  /// Returns CombinedScan in 'combining' or later state
  ///
  /// Throws [ArgumentError] if validation fails
  /// Throws [Exception] if combination fails
  Future<CombinedScan> createCombinedScan({
    required String projectId,
    required List<ScanData> scans,
    required String documentsDirectory,
    void Function(CombinedScanStatus status)? onStatusChange,
  }) async {
    // Validation
    if (scans.length < 2) {
      throw ArgumentError('Need at least 2 scans to combine');
    }

    // Validate scans have position data (at least positionX/Y set)
    final validScans = scans.where((scan) {
      return scan.positionX != null || scan.positionY != null;
    }).toList();

    if (validScans.length < 2) {
      throw ArgumentError(
        'At least 2 scans must have position data from canvas arrangement',
      );
    }

    // T091: File size validation (warn if total >50MB)
    final totalSizeBytes = scans.fold<int>(
      0,
      (sum, scan) => sum + scan.fileSizeBytes,
    );
    final totalSizeMB = totalSizeBytes / (1024 * 1024);

    if (totalSizeMB > 50) {
      print('⚠️ Large file size warning: Total ${totalSizeMB.toStringAsFixed(1)}MB');
      print('   Combination may take longer and use more memory');
    }

    if (totalSizeMB > 250) {
      throw ArgumentError(
        'Total file size (${totalSizeMB.toStringAsFixed(1)}MB) exceeds 250MB limit. '
        'Please reduce the number of scans or capture at lower quality.',
      );
    }

    // Generate unique ID
    final combinedScanId = Uuid().v4();
    final createdAt = DateTime.now();

    // Generate output path
    final outputPath = USDZCombinerService.generateOutputPath(
      projectId: projectId,
      documentsDirectory: documentsDirectory,
    );

    // Create combined scan record
    var combinedScan = CombinedScan(
      id: combinedScanId,
      projectId: projectId,
      scanIds: scans.map((s) => s.id).toList(),
      localCombinedPath: outputPath,
      status: CombinedScanStatus.combining,
      createdAt: createdAt,
    );

    // Notify status change
    onStatusChange?.call(CombinedScanStatus.combining);

    // T087: Log operation start
    CombinedScanLogger.logStart('createCombinedScan', {
      'projectId': projectId,
      'scanCount': scans.length,
      'totalSizeMB': totalSizeMB.toStringAsFixed(1),
    });

    try {
      // Step 1: Combine USDZ files on-device
      CombinedScanLogger.logInfo('Combining ${scans.length} scans into single USDZ');
      final combinedPath = await combiner.combineScans(
        scans: scans,
        outputPath: outputPath,
      );

      CombinedScanLogger.logSuccess('USDZ combination', {
        'outputPath': combinedPath,
      });

      // Update status
      combinedScan = combinedScan.copyWith(
        localCombinedPath: combinedPath,
      );

      return combinedScan;
    } catch (e, stackTrace) {
      // Mark as failed
      combinedScan = combinedScan.copyWith(
        status: CombinedScanStatus.failed,
        errorMessage: 'Failed to combine USDZ files: $e',
      );

      CombinedScanLogger.logError('createCombinedScan', e,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'scanCount': scans.length});

      throw Exception('Failed to create combined scan: $e');
    }
  }

  /// Generate navmesh from combined GLB using BlenderAPI
  ///
  /// Workflow:
  /// 1. Create BlenderAPI session
  /// 2. Upload combined GLB file
  /// 3. Start navmesh generation with Unity-standard parameters
  /// 4. Poll status until completed
  /// 5. Download navmesh file
  /// 6. Delete session (cleanup)
  ///
  /// [combinedScan] - Combined scan with glbReady status
  /// [documentsDirectory] - App documents directory
  /// [onStatusChange] - Optional callback for status updates
  ///
  /// Returns updated CombinedScan with completed status
  ///
  /// Throws [Exception] if GLB not ready or navmesh generation fails
  Future<CombinedScan> generateNavmesh({
    required CombinedScan combinedScan,
    required String documentsDirectory,
    void Function(CombinedScanStatus status)? onStatusChange,
  }) async {
    // Validation
    if (!combinedScan.canGenerateNavmesh()) {
      throw Exception(
        'Cannot generate navmesh: Combined scan is not in glbReady state',
      );
    }

    if (combinedScan.combinedGlbLocalPath == null) {
      throw Exception('Combined GLB local path is not set');
    }

    String? sessionId;
    var updatedScan = combinedScan;

    try {
      // Step 1: Create BlenderAPI session
      print('🔄 Creating BlenderAPI session...');
      onStatusChange?.call(CombinedScanStatus.uploadingToBlender);
      updatedScan = updatedScan.copyWith(
        status: CombinedScanStatus.uploadingToBlender,
      );

      sessionId = await blenderAPI.createSession();
      print('✅ Session created: $sessionId');

      updatedScan = updatedScan.copyWith(
        navmeshSessionId: sessionId,
      );

      // Step 2: Upload GLB to BlenderAPI
      print('📤 Uploading GLB to BlenderAPI...');
      final glbFile = File(combinedScan.combinedGlbLocalPath!);

      await blenderAPI.uploadGLB(
        sessionId: sessionId,
        glbFile: glbFile,
        onProgress: (progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );
      print('✅ GLB uploaded successfully');

      // Step 3: Start navmesh generation
      print('🗺️ Starting navmesh generation...');
      onStatusChange?.call(CombinedScanStatus.generatingNavmesh);
      updatedScan = updatedScan.copyWith(
        status: CombinedScanStatus.generatingNavmesh,
      );

      final inputFilename = glbFile.path.split('/').last;
      final outputFilename = 'navmesh_$inputFilename';

      await blenderAPI.startNavMeshGeneration(
        sessionId: sessionId,
        inputFilename: inputFilename,
        outputFilename: outputFilename,
        navmeshParams: BlenderAPIService.unityStandardNavMeshParams,
      );
      print('✅ NavMesh generation started');

      // Step 4: Poll status until completed
      print('⏳ Polling for completion...');
      final status = await blenderAPI.pollStatus(
        sessionId: sessionId,
      );
      print('✅ NavMesh generation completed with status: $status');

      // Step 5: Download navmesh
      print('📥 Downloading navmesh...');
      onStatusChange?.call(CombinedScanStatus.downloadingNavmesh);
      updatedScan = updatedScan.copyWith(
        status: CombinedScanStatus.downloadingNavmesh,
      );

      final navmeshPath =
          '$documentsDirectory/scans/navmesh/${combinedScan.id}_navmesh.glb';

      await blenderAPI.downloadNavMesh(
        sessionId: sessionId,
        filename: outputFilename,
        outputPath: navmeshPath,
      );
      print('✅ NavMesh downloaded to: $navmeshPath');

      // Step 6: Mark as completed
      onStatusChange?.call(CombinedScanStatus.completed);
      updatedScan = updatedScan.copyWith(
        status: CombinedScanStatus.completed,
        localNavmeshPath: navmeshPath,
        navmeshUrl: outputFilename, // Store filename as URL reference
        completedAt: DateTime.now(),
      );

      print('✅ NavMesh workflow complete!');

      return updatedScan;
    } catch (e) {
      // Mark as failed
      updatedScan = updatedScan.copyWith(
        status: CombinedScanStatus.failed,
        errorMessage: 'NavMesh generation failed: $e',
      );

      throw Exception('Failed to generate navmesh: $e');
    } finally {
      // Step 6: Always cleanup session
      if (sessionId != null) {
        print('🧹 Cleaning up BlenderAPI session...');
        await blenderAPI.deleteSession(sessionId: sessionId);
        print('✅ Session deleted');
      }
    }
  }
}
