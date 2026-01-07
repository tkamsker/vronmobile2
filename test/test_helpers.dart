import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/main.dart' as app;

/// Initialize test environment with required global dependencies
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences with mock data for testing
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // Initialize global guestSessionManager for tests
  final guestManager = GuestSessionManager(prefs: prefs);
  await guestManager.initialize();
  app.guestSessionManager = guestManager;
}

/// Reset test environment between tests
Future<void> tearDownTestEnvironment() async {
  // Reset SharedPreferences
  SharedPreferences.setMockInitialValues({});
}
