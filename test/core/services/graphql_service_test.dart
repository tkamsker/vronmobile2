import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/main.dart' as main_app;

void main() {
  late SharedPreferences prefs;
  late GuestSessionManager guestManager;
  late GraphQLService graphqlService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    guestManager = GuestSessionManager(prefs: prefs);
    await guestManager.initialize();

    // Initialize global guestSessionManager for GraphQLService
    main_app.guestSessionManager = guestManager;

    graphqlService = GraphQLService();
  });

  group('GraphQLService Guest Mode Blocking', () {
    // T014: Test that backend calls are blocked in guest mode
    test('blocks query when in guest mode (debug)', () async {
      // Enable guest mode
      await guestManager.enableGuestMode();

      // In debug mode, should throw StateError
      expect(
        () async => await graphqlService.query('{ test }'),
        throwsA(isA<StateError>()),
      );
    });

    test('blocks mutation when in guest mode (debug)', () async {
      // Enable guest mode
      await guestManager.enableGuestMode();

      // In debug mode, should throw StateError
      expect(
        () async => await graphqlService.mutate('mutation { test }'),
        throwsA(isA<StateError>()),
      );
    });

    test('allows queries when not in guest mode', () async {
      // Guest mode not enabled (default state)
      expect(guestManager.isGuestMode, false);

      // Should NOT throw - but will fail with network error since we don't have backend
      // This test mainly verifies the guest mode check doesn't interfere with normal operation
      // In a real scenario, we'd mock the HTTP client
      // For now, we just check it doesn't throw StateError
      try {
        await graphqlService.query('{ test }');
      } catch (e) {
        // Network error is expected, StateError is not
        expect(e, isNot(isA<StateError>()));
      }
    });
  });
}
