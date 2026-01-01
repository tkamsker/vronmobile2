import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('ScanningScreen Guest Mode', () {
    // T025: Test that "Save to Project" button is HIDDEN in guest mode
    testWidgets('hides Save to Project button when in guest mode', (
      WidgetTester tester,
    ) async {
      // Arrange - enable guest mode
      await guestManager.enableGuestMode();

      // Act
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Assert - "Save to Project" button should NOT be visible
      expect(find.text('Save to Project'), findsNothing);
      expect(
        find.widgetWithText(ElevatedButton, 'Save to Project'),
        findsNothing,
      );
    });

    testWidgets('shows Save to Project button when NOT in guest mode', (
      WidgetTester tester,
    ) async {
      // Arrange - guest mode NOT enabled (default state)
      expect(guestManager.isGuestMode, false);

      // Act
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Assert - "Save to Project" button SHOULD be visible
      expect(find.text('Save to Project'), findsOneWidget);
    });

    testWidgets('shows Export GLB button in both modes', (
      WidgetTester tester,
    ) async {
      // Test in guest mode
      await guestManager.enableGuestMode();
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );
      expect(find.text('Export GLB'), findsOneWidget);

      // Test in authenticated mode
      await guestManager.disableGuestMode();
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );
      expect(find.text('Export GLB'), findsOneWidget);
    });

    testWidgets('displays guest mode banner when in guest mode', (
      WidgetTester tester,
    ) async {
      // Arrange
      await guestManager.enableGuestMode();

      // Act
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Assert - guest banner should be visible
      expect(
        find.text('Guest Mode - Scans saved locally only'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT display guest banner when authenticated', (
      WidgetTester tester,
    ) async {
      // Arrange - guest mode NOT enabled
      expect(guestManager.isGuestMode, false);

      // Act
      await tester.pumpWidget(
        MaterialApp(home: ScanningScreen(guestSessionManager: guestManager)),
      );

      // Assert - guest banner should NOT be visible
      expect(find.text('Guest Mode - Scans saved locally only'), findsNothing);
    });
  });
}
