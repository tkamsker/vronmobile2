import 'package:flutter/services.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

/// Flutter service for combining USDZ files via iOS native bridge
/// Feature 018: Combined Scan to NavMesh Workflow
/// Communicates with iOS USDZCombiner via MethodChannel
class USDZCombinerService {
  /// MethodChannel for iOS communication
  static const platform = MethodChannel('com.vron.usdz_combiner');

  /// Combine multiple USDZ scans into a single USDZ file
  ///
  /// [scans] - List of ScanData with position information
  /// [outputPath] - Desired output path for combined USDZ file
  ///
  /// Returns path to combined USDZ file
  ///
  /// Throws [PlatformException] if iOS native combination fails
  /// Throws [ArgumentError] if validation fails
  Future<String> combineScans({
    required List<ScanData> scans,
    required String outputPath,
  }) async {
    // Validation
    if (scans.length < 2) {
      throw ArgumentError('Need at least 2 scans to combine');
    }

    // Validate all scans have local paths
    for (final scan in scans) {
      if (scan.localPath.isEmpty) {
        throw ArgumentError('All scans must have valid local paths');
      }
    }

    // Extract paths
    final paths = scans.map((scan) => scan.localPath).toList();

    // Extract transforms (with defaults for missing data)
    final transforms = scans.map((scan) {
      return {
        'positionX': scan.positionX ?? 0.0,
        'positionY': scan.positionY ?? 0.0,
        'rotation': scan.rotationDegrees ?? 0.0,
        'scale': scan.scaleFactor ?? 1.0,
      };
    }).toList();

    try {
      // Call iOS native method
      final result = await platform.invokeMethod<String>(
        'combineScans',
        {
          'paths': paths,
          'transforms': transforms,
          'outputPath': outputPath,
        },
      );

      if (result == null) {
        throw Exception('iOS native method returned null');
      }

      return result;
    } on PlatformException catch (e) {
      // Re-throw with context
      throw PlatformException(
        code: e.code,
        message: 'Failed to combine USDZ files: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Generate output path for combined scan
  ///
  /// Format: {documentsDirectory}/scans/combined/combined_scan_{projectId}_{timestamp}.usdz
  ///
  /// [projectId] - Project identifier
  /// [documentsDirectory] - App documents directory path
  ///
  /// Returns absolute path for output file
  static String generateOutputPath({
    required String projectId,
    required String documentsDirectory,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'combined_scan_${projectId}_$timestamp.usdz';
    return '$documentsDirectory/scans/combined/$filename';
  }
}
