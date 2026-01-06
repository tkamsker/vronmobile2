import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Guest storage helper for managing local guest scan files
/// Stores GLB files in the app's documents directory under "guest_scans" folder
class GuestStorageHelper {
  static const String _guestScansFolder = 'guest_scans';

  /// Gets the guest storage path, creating the directory if it doesn't exist
  /// Returns: Path to the guest_scans directory
  /// Throws: FileSystemException if directory cannot be created
  Future<String> getGuestStoragePath() async {
    if (kDebugMode) print('📁 [GUEST STORAGE] Getting guest storage path');

    try {
      // Get app documents directory
      final appDocDir = await getApplicationDocumentsDirectory();

      // Create guest_scans subdirectory
      final guestScansDir = Directory(
        path.join(appDocDir.path, _guestScansFolder),
      );

      // Create directory if it doesn't exist
      if (!await guestScansDir.exists()) {
        if (kDebugMode) {
          print('📁 [GUEST STORAGE] Creating guest_scans directory');
        }
        await guestScansDir.create(recursive: true);
      }

      final storagePath = guestScansDir.path;
      if (kDebugMode) print('✅ [GUEST STORAGE] Storage path: $storagePath');

      return storagePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST STORAGE] Failed to get storage path: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Saves a guest scan to local storage
  ///
  /// Parameters:
  ///   - scanData: The GLB file data as bytes
  ///   - fileName: Optional custom file name (default: timestamp-based name)
  ///
  /// Returns: Path to the saved file
  /// Throws: FileSystemException if file cannot be written
  Future<String> saveGuestScan(List<int> scanData, {String? fileName}) async {
    if (kDebugMode) print('💾 [GUEST STORAGE] Saving guest scan');

    try {
      final storagePath = await getGuestStoragePath();

      // Generate file name if not provided
      final scanFileName =
          fileName ?? 'guest_scan_${DateTime.now().millisecondsSinceEpoch}.glb';

      // Create full file path
      final filePath = path.join(storagePath, scanFileName);

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(scanData);

      if (kDebugMode) {
        print(
          '✅ [GUEST STORAGE] Scan saved: $filePath (${scanData.length} bytes)',
        );
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST STORAGE] Failed to save scan: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Lists all guest scan files
  ///
  /// Returns: List of file paths for all GLB files in guest storage
  /// Returns empty list if directory doesn't exist or has no files
  Future<List<String>> listGuestScans() async {
    if (kDebugMode) print('📋 [GUEST STORAGE] Listing guest scans');

    try {
      final storagePath = await getGuestStoragePath();
      final directory = Directory(storagePath);

      if (!await directory.exists()) {
        if (kDebugMode) print('⚠️ [GUEST STORAGE] Directory does not exist');
        return [];
      }

      // List all GLB files
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.glb'))
          .map((entity) => entity.path)
          .toList();

      if (kDebugMode) {
        print('✅ [GUEST STORAGE] Found ${files.length} guest scans');
      }

      return files;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST STORAGE] Failed to list scans: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Deletes a specific guest scan file
  ///
  /// Parameters:
  ///   - filePath: Path to the file to delete
  ///
  /// Returns: true if file was deleted, false if file didn't exist
  /// Throws: FileSystemException if file cannot be deleted
  Future<bool> deleteGuestScan(String filePath) async {
    if (kDebugMode) print('🗑️ [GUEST STORAGE] Deleting guest scan: $filePath');

    try {
      final file = File(filePath);

      if (!await file.exists()) {
        if (kDebugMode) print('⚠️ [GUEST STORAGE] File does not exist');
        return false;
      }

      await file.delete();

      if (kDebugMode) print('✅ [GUEST STORAGE] Scan deleted successfully');

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST STORAGE] Failed to delete scan: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Deletes all guest scans (cleanup utility)
  ///
  /// Returns: Number of files deleted
  Future<int> deleteAllGuestScans() async {
    if (kDebugMode) print('🗑️ [GUEST STORAGE] Deleting all guest scans');

    try {
      final files = await listGuestScans();
      int deletedCount = 0;

      for (final filePath in files) {
        final deleted = await deleteGuestScan(filePath);
        if (deleted) deletedCount++;
      }

      if (kDebugMode) {
        print('✅ [GUEST STORAGE] Deleted $deletedCount guest scans');
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST STORAGE] Failed to delete all scans: ${e.toString()}');
      }
      rethrow;
    }
  }
}
