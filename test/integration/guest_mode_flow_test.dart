import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';
import 'package:vronmobile2/features/auth/screens/main_screen.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/features/lidar/screens/scanning_screen.dart';

void main() {
  late SharedPreferences prefs;
  late GuestSessionManager guestManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    guestManager = GuestSessionManager(prefs: prefs);
    await guestManager.initialize();
  });

  group('Guest Mode Integration Tests', () {
    // T027: Test guest mode banner visibility in complete flow
    testWidgets(
      'guest mode banner is visible in scanning screen when guest mode enabled',
      (WidgetTester tester) async {
        // Arrange - enable guest mode first
        await guestManager.enableGuestMode();

        // Act - navigate directly to scanning screen
        await tester.pumpWidget(
          MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
        );
        await tester.pumpAndSettle();

        // Assert - guest banner should be visible on scanning screen
        expect(
          find.text('Guest Mode - Scans saved locally only'),
          findsOneWidget,
        );
      },
    );

    // T028: Test "Sign Up" button in banner triggers dialog
    testWidgets('Sign Up button in banner triggers account creation dialog', (
      WidgetTester tester,
    ) async {
      // Arrange - enable guest mode and navigate to scanning screen
      await guestManager.enableGuestMode();
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Act - tap Sign Up button in banner
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Assert - dialog should appear
      expect(find.text('Create an Account?'), findsOneWidget);
      expect(
        find.text(
          'Create an account to save your scans to the cloud and access them from any device.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('scanning screen shows correct UI in guest mode', (
      WidgetTester tester,
    ) async {
      // Arrange - enable guest mode
      await guestManager.enableGuestMode();

      // Act - navigate to scanning screen
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );
      await tester.pumpAndSettle();

      // Assert - guest mode banner visible
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );

      // Assert - Save to Project button hidden
      expect(find.text('Save to Project'), findsNothing);

      // Assert - Export GLB button visible (local export still works)
      expect(find.text('Export GLB'), findsOneWidget);
    });

    testWidgets('dialog Continue as Guest keeps user in guest mode', (
      WidgetTester tester,
    ) async {
      // Arrange
      await guestManager.enableGuestMode();
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Open dialog
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();
      expect(find.text('Create an Account?'), findsOneWidget);

      // Act - tap "Continue as Guest"
      await tester.tap(find.widgetWithText(TextButton, 'Continue as Guest'));
      await tester.pumpAndSettle();

      // Assert - dialog closed, still in guest mode
      expect(find.text('Create an Account?'), findsNothing);
      expect(guestManager.isGuestMode, true);
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );
    });

    testWidgets('dialog Sign Up navigates to signup and disables guest mode', (
      WidgetTester tester,
    ) async {
      bool navigatedToSignup = false;

      // Arrange
      await guestManager.enableGuestMode();
      await tester.pumpWidget(
        MaterialApp(
          home: ScanningScreen(guestSessionManager: guestManager),
          routes: {
            '/signup': (context) {
              navigatedToSignup = true;
              return Scaffold(
                appBar: AppBar(title: const Text('Sign Up')),
                body: const Center(child: Text('Sign Up Screen')),
              );
            },
          },
        ),
      );

      // Open dialog
      await tester.tap(find.widgetWithText(TextButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Act - tap "Sign Up" in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Assert - navigated to signup screen
      expect(navigatedToSignup, true);

      // Assert - guest mode disabled
      expect(guestManager.isGuestMode, false);
    });

    testWidgets('guest mode persistence across screen navigation', (
      WidgetTester tester,
    ) async {
      // Arrange - enable guest mode
      await guestManager.enableGuestMode();

      // Navigate to scanning screen
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Assert - guest mode active
      expect(guestManager.isGuestMode, true);
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );

      // Simulate app restart (new manager instance)
      final newManager = GuestSessionManager(prefs: prefs);
      await newManager.initialize();

      // Assert - guest mode persisted
      expect(newManager.isGuestMode, true);
    });
  });
}
