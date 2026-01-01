import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';

void main() {
  late SharedPreferences prefs;
  late GuestSessionManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    manager = GuestSessionManager(prefs: prefs);
  });

  group('GuestSessionManager', () {
    // T010: Test initialize() default state
    test('initializes with guest mode disabled by default', () async {
      await manager.initialize();

      expect(manager.isGuestMode, false);
      expect(manager.scanCount, 0);
      expect(manager.enteredAt, null);
    });

    // T011: Test enableGuestMode() state change
    test('enables guest mode and persists state', () async {
      await manager.enableGuestMode();

      expect(manager.isGuestMode, true);
      expect(manager.enteredAt, isNotNull);
      expect(manager.scanCount, 0);
      expect(prefs.getBool('is_guest_mode'), true);
      expect(prefs.getInt('guest_scan_count'), 0);
    });

    // T012: Test disableGuestMode() state change
    test('disables guest mode and clears state', () async {
      // First enable guest mode
      await manager.enableGuestMode();
      expect(manager.isGuestMode, true);

      // Then disable it
      await manager.disableGuestMode();

      expect(manager.isGuestMode, false);
      expect(manager.enteredAt, null);
      expect(manager.scanCount, 0);
      expect(prefs.getBool('is_guest_mode'), false);
    });

    // T013: Test persistence across restarts
    test('restores guest mode state on initialize', () async {
      // Set up persistent state
      await prefs.setBool('is_guest_mode', true);
      await prefs.setInt('guest_scan_count', 5);

      // Create new manager instance (simulates app restart)
      final newManager = GuestSessionManager(prefs: prefs);
      await newManager.initialize();

      expect(newManager.isGuestMode, true);
      expect(newManager.scanCount, 5);
      expect(
        newManager.enteredAt,
        isNotNull,
      ); // Timestamp not persisted, but should be set
    });

    test('increments scan count when in guest mode', () async {
      await manager.enableGuestMode();
      await manager.incrementScanCount();

      expect(manager.scanCount, 1);
      expect(prefs.getInt('guest_scan_count'), 1);

      await manager.incrementScanCount();
      expect(manager.scanCount, 2);
    });

    test('does not increment scan count when not in guest mode', () async {
      // Guest mode not enabled
      await manager.incrementScanCount();

      expect(manager.scanCount, 0);
    });
  });
}
