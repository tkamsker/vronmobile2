import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';

/// Service for exporting combined scan files
/// Feature 018: Combined Scan to NavMesh Workflow
/// Handles sharing GLB, NavMesh, and ZIP exports
class ExportService {
  /// Export combined GLB file using native share dialog
  ///
  /// [combinedScan] - Combined scan with GLB file path
  ///
  /// Returns ShareResult indicating user action
  ///
  /// Throws [Exception] if file doesn't exist or share fails
  Future<ShareResult> exportGlb({
    required CombinedScan combinedScan,
  }) async {
    if (combinedScan.combinedGlbLocalPath == null) {
      throw Exception('Combined GLB path is not set');
    }

    final file = File(combinedScan.combinedGlbLocalPath!);
    if (!await file.exists()) {
      throw Exception('Combined GLB file not found: ${file.path}');
    }

    // Get file name for display
    final fileName = file.path.split('/').last;

    // Share file using native dialog
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'model/gltf-binary')],
      subject: 'Combined Room Scan - GLB',
      text: 'Combined 3D scan in GLB format\nFile: $fileName',
    );

    return result;
  }

  /// Export navmesh file using native share dialog
  ///
  /// [combinedScan] - Combined scan with navmesh file path
  ///
  /// Returns ShareResult indicating user action
  ///
  /// Throws [Exception] if file doesn't exist or share fails
  Future<ShareResult> exportNavmesh({
    required CombinedScan combinedScan,
  }) async {
    if (combinedScan.localNavmeshPath == null) {
      throw Exception('NavMesh path is not set');
    }

    final file = File(combinedScan.localNavmeshPath!);
    if (!await file.exists()) {
      throw Exception('NavMesh file not found: ${file.path}');
    }

    // Get file name for display
    final fileName = file.path.split('/').last;

    // Share file using native dialog
    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'model/gltf-binary')],
      subject: 'Navigation Mesh - GLB',
      text: 'Navigation mesh for Unity/game engines\nFile: $fileName',
    );

    return result;
  }

  /// Export both GLB and NavMesh as a ZIP archive
  ///
  /// [combinedScan] - Combined scan with both file paths
  ///
  /// Returns ShareResult indicating user action
  ///
  /// Throws [Exception] if files don't exist or ZIP creation fails
  Future<ShareResult> exportBothAsZip({
    required CombinedScan combinedScan,
  }) async {
    if (combinedScan.combinedGlbLocalPath == null) {
      throw Exception('Combined GLB path is not set');
    }
    if (combinedScan.localNavmeshPath == null) {
      throw Exception('NavMesh path is not set');
    }

    final glbFile = File(combinedScan.combinedGlbLocalPath!);
    final navmeshFile = File(combinedScan.localNavmeshPath!);

    if (!await glbFile.exists()) {
      throw Exception('Combined GLB file not found: ${glbFile.path}');
    }
    if (!await navmeshFile.exists()) {
      throw Exception('NavMesh file not found: ${navmeshFile.path}');
    }

    // Create temporary directory for ZIP
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipPath = '${tempDir.path}/combined_scan_$timestamp.zip';

    try {
      // Create ZIP archive
      final archive = Archive();

      // Add GLB file
      final glbBytes = await glbFile.readAsBytes();
      final glbFileName = glbFile.path.split('/').last;
      archive.addFile(ArchiveFile(glbFileName, glbBytes.length, glbBytes));

      // Add NavMesh file
      final navmeshBytes = await navmeshFile.readAsBytes();
      final navmeshFileName = navmeshFile.path.split('/').last;
      archive.addFile(
        ArchiveFile(navmeshFileName, navmeshBytes.length, navmeshBytes),
      );

      // Encode and write ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Failed to create ZIP archive');
      }

      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);

      // Share ZIP file using native dialog
      final result = await Share.shareXFiles(
        [XFile(zipPath, mimeType: 'application/zip')],
        subject: 'Combined Room Scan - Complete Package',
        text: 'Combined 3D scan (GLB) and navigation mesh\nContains: $glbFileName, $navmeshFileName',
      );

      // Cleanup temporary ZIP file after sharing
      try {
        await zipFile.delete();
      } catch (e) {
        // Ignore cleanup errors
        print('Warning: Failed to delete temporary ZIP: $e');
      }

      return result;
    } catch (e) {
      // Cleanup on error
      try {
        await File(zipPath).delete();
      } catch (_) {
        // Ignore cleanup errors
      }
      rethrow;
    }
  }

  /// Get file size in human-readable format
  ///
  /// [filePath] - Path to file
  ///
  /// Returns formatted size string (e.g., "15.3 MB")
  ///
  /// Throws [Exception] if file doesn't exist
  Future<String> getFileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final bytes = await file.length();
    return _formatBytes(bytes);
  }

  /// Format bytes to human-readable size
  String _formatBytes(int bytes) {
    const int mb = 1024 * 1024;
    const int kb = 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
}
