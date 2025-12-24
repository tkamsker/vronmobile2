import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages guest mode session state
///
/// This service handles:
/// - Guest mode activation/deactivation
/// - Session state persistence via shared_preferences
/// - Scan count tracking during guest session
class GuestSessionManager {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _scanCountKey = 'guest_scan_count';

  final SharedPreferences _prefs;

  bool _isGuestMode = false;
  DateTime? _enteredAt;
  int _scanCount = 0;

  GuestSessionManager({required SharedPreferences prefs}) : _prefs = prefs;

  /// Whether the current session is in guest mode
  bool get isGuestMode => _isGuestMode;

  /// When guest mode was activated (null if not in guest mode)
  DateTime? get enteredAt => _enteredAt;

  /// Number of scans in current guest session
  int get scanCount => _scanCount;

  /// Initialize guest session state from persistent storage
  Future<void> initialize() async {
    _isGuestMode = _prefs.getBool(_guestModeKey) ?? false;
    _scanCount = _prefs.getInt(_scanCountKey) ?? 0;

    if (_isGuestMode) {
      _enteredAt = DateTime.now(); // Approximate - not persisted
      if (kDebugMode) {
        print('✅ [GUEST] Guest mode active, $_scanCount scans');
      }
    }
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    if (kDebugMode) print('🔐 [GUEST] Enabling guest mode');

    _isGuestMode = true;
    _enteredAt = DateTime.now();
    _scanCount = 0;

    await _prefs.setBool(_guestModeKey, true);
    await _prefs.setInt(_scanCountKey, 0);

    if (kDebugMode) print('✅ [GUEST] Guest mode enabled');
  }

  /// Disable guest mode (e.g., user creates account)
  Future<void> disableGuestMode() async {
    if (kDebugMode) print('🔐 [GUEST] Disabling guest mode');

    _isGuestMode = false;
    _enteredAt = null;
    _scanCount = 0;

    await _prefs.setBool(_guestModeKey, false);
    await _prefs.setInt(_scanCountKey, 0);

    if (kDebugMode) print('✅ [GUEST] Guest mode disabled');
  }

  /// Increment scan count
  Future<void> incrementScanCount() async {
    if (!_isGuestMode) return;

    _scanCount++;
    await _prefs.setInt(_scanCountKey, _scanCount);

    if (kDebugMode) print('📊 [GUEST] Scan count: $_scanCount');
  }
}
