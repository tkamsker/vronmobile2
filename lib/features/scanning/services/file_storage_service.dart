import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/scan_data.dart';

/// Service for managing local USDZ and GLB file storage
class FileStorageService {
  /// Get the scans directory path
  Future<Directory> getScansDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${directory.path}/scans');

    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    return scansDir;
  }

  /// Get the GLB cache directory path
  Future<Directory> getGLBCacheDirectory() async {
    final directory = await getApplicationCacheDirectory();
    final glbDir = Directory('${directory.path}/glb');

    if (!await glbDir.exists()) {
      await glbDir.create(recursive: true);
    }

    return glbDir;
  }

  /// Check available storage space
  Future<int> getAvailableStorageBytes() async {
    // This is a simplified version
    // In production, use platform channels to get actual free space
    // For now, return a mock value
    return 1000000000; // 1 GB
  }

  /// Check if sufficient storage is available
  Future<bool> hasSufficientStorage({required int requiredBytes}) async {
    final available = await getAvailableStorageBytes();
    // Require at least 500 MB free after saving file
    return available > (requiredBytes + 500000000);
  }

  /// Delete a scan file
  Future<void> deleteScanFile(ScanData scanData) async {
    await scanData.deleteLocally();
  }

  /// Delete all scans in a directory
  Future<void> clearScansDirectory() async {
    final scansDir = await getScansDirectory();
    final files = scansDir.listSync();

    for (final file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }

  /// Delete all GLB files in cache
  Future<void> clearGLBCache() async {
    final glbDir = await getGLBCacheDirectory();
    final files = glbDir.listSync();

    for (final file in files) {
      if (file is File) {
        await file.delete();
      }
    }
  }

  /// Get total size of all scans
  Future<int> getTotalScansSize() async {
    final scansDir = await getScansDirectory();
    final files = scansDir.listSync();

    int totalSize = 0;
    for (final file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  /// Validate file size limits (250 MB max)
  bool isFileSizeValid(int fileSizeBytes) {
    return fileSizeBytes <= 262144000; // 250 MB
  }
}
