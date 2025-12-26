import 'dart:io';
import 'dart:async';
import 'package:flutter_roomplan/flutter_roomplan.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lidar_capability.dart';
import '../models/scan_data.dart';

class ScanningService {
  final FlutterRoomplan _roomplan = FlutterRoomplan();
  ScanData? _currentScan;
  bool _isScanning = false;

  /// Check device LiDAR capability
  Future<LidarCapability> checkCapability() async {
    return await LidarCapability.detect();
  }

  /// Start a new LiDAR scan
  ///
  /// Returns completed [ScanData] when scan finishes
  /// Calls [onProgress] callback with progress values 0.0-1.0
  /// Throws [UnsupportedError] if LiDAR not supported
  /// Throws [Exception] if permissions denied or scan fails
  Future<ScanData> startScan({
    Function(double progress)? onProgress,
  }) async {
    // Check capability
    final capability = await checkCapability();
    if (!capability.isScanningSupportpported) {
      throw UnsupportedError(
        capability.unsupportedReason ?? 'LiDAR scanning not supported',
      );
    }

    if (_isScanning) {
      throw StateError('A scan is already in progress');
    }

    _isScanning = true;

    try {
      // Generate unique ID
      final scanId = _generateUUID();

      // Create scan data with capturing status
      _currentScan = ScanData(
        id: scanId,
        format: ScanFormat.usdz,
        localPath: '', // Will be set after scan completes
        fileSizeBytes: 0, // Will be set after scan completes
        capturedAt: DateTime.now(),
        status: ScanStatus.capturing,
      );

      // Use Completer to wait for the callback
      final completer = Completer<String?>();

      // Register callback BEFORE starting scan (required by flutter_roomplan)
      print('📱 [SERVICE] Registering onRoomCaptureFinished callback...');
      _roomplan.onRoomCaptureFinished(() async {
        print('✅ [SERVICE] onRoomCaptureFinished callback triggered!');
        try {
          final usdzPath = await _roomplan.getUsdzFilePath();
          print('📁 [SERVICE] USDZ path from callback: $usdzPath');
          completer.complete(usdzPath);
        } catch (e) {
          print('❌ [SERVICE] Error in callback: $e');
          completer.completeError(e);
        }
      });

      // Start RoomPlan scan
      // Note: startScan() launches the iOS scanning UI and blocks until user taps Done
      print('📱 [SERVICE] Launching RoomPlan startScan()...');
      await _roomplan.startScan();
      print('✅ [SERVICE] RoomPlan startScan() completed (user tapped Done)');

      // Wait for the callback to provide the file path
      print('⏳ [SERVICE] Waiting for USDZ file path from callback...');
      final usdzPath = await completer.future;
      print('📁 [SERVICE] Received USDZ path: $usdzPath');

      if (usdzPath == null || usdzPath.isEmpty) {
        print('❌ [SERVICE] No USDZ path returned - scan may have insufficient data');
        throw Exception('Scan failed: Insufficient data captured. Try scanning more of the room slowly and ensure good lighting.');
      }

      // Simulate progress updates (actual progress comes from iOS UI)
      if (onProgress != null) {
        print('📊 [SERVICE] Setting progress to 100%');
        onProgress(1.0); // Scan complete
      }

      // Save scan locally and get final path
      print('💾 [SERVICE] Saving scan locally...');
      final savedScan = await _saveScanLocally(
        scanId: scanId,
        usdzPath: usdzPath,
      );
      print('✅ [SERVICE] Scan saved successfully!');
      print('📦 [SERVICE] Final path: ${savedScan.localPath}');
      print('📦 [SERVICE] File size: ${savedScan.fileSizeBytes} bytes');

      _currentScan = savedScan;
      _isScanning = false;

      return savedScan;
    } catch (e) {
      _isScanning = false;
      _currentScan = null;

      if (e.toString().contains('permission')) {
        throw Exception('Camera permission is required for LiDAR scanning');
      }

      rethrow;
    }
  }

  /// Stop the current scan
  /// Note: flutter_roomplan doesn't have an explicit stop method
  /// The scan is controlled through the iOS UI
  Future<void> stopScan() async {
    if (!_isScanning) {
      return;
    }

    // Mark as not scanning - actual stop happens through iOS UI
    _isScanning = false;
    _currentScan = null;
  }

  /// Save USDZ scan data to local filesystem and SharedPreferences
  Future<ScanData> _saveScanLocally({
    required String scanId,
    required String usdzPath,
  }) async {
    // Get app Documents directory
    final directory = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${directory.path}/scans');

    // Create scans directory if it doesn't exist
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    // Define final path
    final finalPath = '${scansDir.path}/scan_$scanId.usdz';

    // Copy USDZ file to final location
    final usdzFile = File(usdzPath);
    if (!await usdzFile.exists()) {
      throw Exception('USDZ file not found at $usdzPath');
    }

    await usdzFile.copy(finalPath);

    // Get file size
    final finalFile = File(finalPath);
    final fileSize = await finalFile.length();

    // Check storage limits (250 MB max)
    if (fileSize > 262144000) {
      await finalFile.delete();
      throw Exception('Scan file size exceeds 250 MB limit');
    }

    // Extract metadata from RoomPlan (if available)
    final metadata = await _extractMetadata(finalPath);

    // Create completed ScanData
    final scanData = ScanData(
      id: scanId,
      format: ScanFormat.usdz,
      localPath: finalPath,
      fileSizeBytes: fileSize,
      capturedAt: DateTime.now(),
      status: ScanStatus.completed,
      metadata: metadata,
    );

    // Save to SharedPreferences
    await _saveToPreferences(scanData);

    return scanData;
  }

  /// Save scan metadata to SharedPreferences
  Future<void> _saveToPreferences(ScanData scanData) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing scan list
    final scanListJson = prefs.getString('scan_data_list');
    List<Map<String, dynamic>> scanList = [];

    if (scanListJson != null) {
      final decoded = jsonDecode(scanListJson) as List;
      scanList = decoded.cast<Map<String, dynamic>>();
    }

    // Add new scan
    scanList.add(scanData.toJson());

    // Save updated list
    await prefs.setString('scan_data_list', jsonEncode(scanList));
  }

  /// Extract metadata from USDZ file (simplified version)
  Future<Map<String, dynamic>> _extractMetadata(String usdzPath) async {
    // In a production implementation, this would parse USDZ file
    // and extract RoomPlan metadata (walls, doors, windows, dimensions)
    // For now, return basic metadata
    return {
      'captureDevice': Platform.isIOS ? 'iOS Device' : 'Unknown',
      'osVersion': Platform.operatingSystemVersion,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Generate a simple UUID (simplified version)
  String _generateUUID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 1000000).toString();
    return 'scan-$timestamp-$random';
  }

  /// Handle scan interruption (phone call, app backgrounded, low battery)
  Future<InterruptionAction> handleInterruption(InterruptionReason reason) async {
    // In production, this would show a dialog to the user
    // For now, return a default action
    switch (reason) {
      case InterruptionReason.phoneCall:
      case InterruptionReason.backgrounded:
        return InterruptionAction.savePartial;
      case InterruptionReason.lowBattery:
        return InterruptionAction.savePartial;
      default:
        return InterruptionAction.continue_;
    }
  }

  /// Get all saved scans from SharedPreferences
  Future<List<ScanData>> getSavedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scanListJson = prefs.getString('scan_data_list');

    if (scanListJson == null) {
      return [];
    }

    final decoded = jsonDecode(scanListJson) as List;
    return decoded.map((json) => ScanData.fromJson(json)).toList();
  }
}

enum InterruptionReason {
  phoneCall,
  backgrounded,
  lowBattery,
}

enum InterruptionAction {
  savePartial,
  discard,
  continue_,
}
