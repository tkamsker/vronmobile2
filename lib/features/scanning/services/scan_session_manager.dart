import '../models/scan_data.dart';

/// Manages scan data in memory for the current session
/// Data is not persisted - it's cleared when the app restarts
/// Used for logged-in users to temporarily store scans before upload
class ScanSessionManager {
  static final ScanSessionManager _instance = ScanSessionManager._internal();
  factory ScanSessionManager() => _instance;
  ScanSessionManager._internal();

  final List<ScanData> _scans = [];

  /// Get all scans for current session
  List<ScanData> get scans => List.unmodifiable(_scans);

  /// Check if any scans exist in session
  bool get hasScans => _scans.isNotEmpty;

  /// Add a new scan to the session
  void addScan(ScanData scan) {
    _scans.add(scan);
    print('📊 [SESSION] Added scan ${scan.id}, total: ${_scans.length}');
  }

  /// Remove a scan from the session
  /// Returns true if scan was found and removed, false otherwise
  bool removeScan(String scanId) {
    final initialLength = _scans.length;
    _scans.removeWhere((scan) => scan.id == scanId);
    final removed = _scans.length < initialLength;

    if (removed) {
      print('📊 [SESSION] Removed scan $scanId, remaining: ${_scans.length}');
    } else {
      print('⚠️ [SESSION] Scan $scanId not found in session');
    }

    return removed;
  }

  /// Get a specific scan by ID
  ScanData? getScan(String scanId) {
    try {
      return _scans.firstWhere((scan) => scan.id == scanId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all scans from session
  void clearAll() {
    _scans.clear();
    print('📊 [SESSION] Cleared all scans');
  }

  /// Get total size of all scans in bytes
  int get totalSizeBytes {
    return _scans.fold(0, (sum, scan) => sum + scan.fileSizeBytes);
  }

  /// Get total size in MB
  double get totalSizeMB {
    return totalSizeBytes / (1024 * 1024);
  }

  /// Update an existing scan in the session
  void updateScan(ScanData updatedScan) {
    final index = _scans.indexWhere((scan) => scan.id == updatedScan.id);
    if (index != -1) {
      _scans[index] = updatedScan;
      print('📊 [SESSION] Updated scan ${updatedScan.id}');
    } else {
      print('⚠️ [SESSION] Scan ${updatedScan.id} not found for update');
    }
  }
}
