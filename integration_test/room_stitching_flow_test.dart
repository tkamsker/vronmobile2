import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vronmobile2/main.dart' as app;
import 'package:vronmobile2/features/scanning/screens/scan_list_screen.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitching_screen.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitch_progress_screen.dart';
import 'package:vronmobile2/features/scanning/screens/stitched_model_preview_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Integration test for the complete room stitching flow
///
/// Test Flow:
/// 1. Start app and navigate to scan list
/// 2. Ensure at least 2 scans exist (create mock scans if needed)
/// 3. Tap "Stitch Rooms" button
/// 4. Select 2+ scans in RoomStitchingScreen
/// 5. Tap "Start Stitching"
/// 6. Verify progress screen appears with polling
/// 7. Wait for completion (simulated backend)
/// 8. Verify preview screen shows stitched model
/// 9. Test action buttons (AR, Export, Save)
///
/// Prerequisites:
/// - App must be running with test backend enabled
/// - Test backend should return mock stitching job responses
/// - At least 2 mock scans should be available
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Room Stitching Complete Flow', () {
    testWidgets('successfully stitches 2 rooms from scan list to preview', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Navigate to scan list screen
      // (Assuming user is already logged in or in guest mode)
      expect(find.byType(ScanListScreen), findsOneWidget);

      // Verify at least 2 scans are available
      final scanCards = find.byKey(const Key('scan_card'));
      expect(scanCards, findsAtLeastNWidgets(2), reason: 'Need at least 2 scans for stitching');

      // Step 2: Tap "Stitch Rooms" button to open stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Verify RoomStitchingScreen opened
      expect(find.byType(RoomStitchingScreen), findsOneWidget);
      expect(find.text('Stitch Rooms'), findsOneWidget);

      // Step 3: Select 2 scans
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsAtLeastNWidgets(2));

      // Tap first scan card to select
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      // Verify checkbox is checked
      expect(tester.widget<Checkbox>(checkboxes.at(0)).value, true);

      // Tap second scan card to select
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Verify second checkbox is checked
      expect(tester.widget<Checkbox>(checkboxes.at(1)).value, true);

      // Verify selection count updated
      expect(find.text('2 scans selected'), findsOneWidget);

      // Verify "Start Stitching" button is now enabled
      final startButton = find.widgetWithText(ElevatedButton, 'Start Stitching');
      expect(tester.widget<ElevatedButton>(startButton).onPressed, isNotNull);

      // Step 4: Tap "Start Stitching"
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify RoomStitchProgressScreen appeared
      expect(find.byType(RoomStitchProgressScreen), findsOneWidget);
      expect(find.text('Stitching Rooms'), findsOneWidget);

      // Step 5: Verify initial progress state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Waiting to start...'), findsOneWidget);

      // Wait for status to change to "Uploading"
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Uploading scans...'), findsOneWidget);

      // Wait for status to change to "Processing"
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Processing...'), findsOneWidget);

      // Wait for status to change to "Aligning"
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Aligning rooms...'), findsOneWidget);

      // Verify progress percentage is displayed
      expect(find.textContaining('%'), findsOneWidget);

      // Wait for status to change to "Merging"
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Merging geometry...'), findsOneWidget);

      // Step 6: Wait for completion
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Stitching complete!'), findsOneWidget);

      // Wait for download to complete and navigation to preview
      await tester.pumpAndSettle();

      // Step 7: Verify StitchedModelPreviewScreen appeared
      expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);
      expect(find.text('Stitched Model'), findsOneWidget);

      // Verify ModelViewer is present
      expect(find.byType(ModelViewer), findsOneWidget);

      // Verify room names are displayed
      // (Will be specific to the mock scans created)
      expect(find.textContaining('+'), findsOneWidget, reason: 'Should show room names joined with +');

      // Verify file size is displayed
      expect(find.textContaining('MB'), findsOneWidget);

      // Verify action buttons are present
      expect(find.widgetWithText(ElevatedButton, 'View in AR'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Export GLB'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save to Project'), findsOneWidget);

      // Step 8: Test action buttons

      // Test "Export GLB" - should open share sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Export GLB'));
      await tester.pumpAndSettle();
      // Share sheet opening is platform-specific, verify no errors

      // Wait for share sheet to close (simulated)
      await tester.pump(const Duration(seconds: 1));

      // Test "Save to Project" - should show project selection
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
      await tester.pumpAndSettle();

      // Verify project selection dialog appeared
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Select Project'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Step 9: Navigate back to verify state persistence
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Should return to scan list
      expect(find.byType(ScanListScreen), findsOneWidget);
    });

    testWidgets('handles stitching failure gracefully', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Select 2 scans
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Simulate backend returning failure after processing
      // (Test backend should be configured to fail on specific scan combinations)
      await tester.pump(const Duration(seconds: 5));

      // Verify error dialog appeared
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Stitching Failed'), findsOneWidget);
      expect(find.textContaining('overlap'), findsOneWidget, reason: 'Should show error message');

      // Verify "Retry" and "Cancel" buttons
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap "Cancel" to exit
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return to scan list
      expect(find.byType(ScanListScreen), findsOneWidget);
    });

    testWidgets('allows user to cancel stitching in progress', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to stitching screen and start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Wait for stitching to start processing
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Processing...'), findsOneWidget);

      // Tap "Cancel" button
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Verify cancellation confirmation dialog
      expect(find.text('Cancel Stitching?'), findsOneWidget);

      // Confirm cancellation
      await tester.tap(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();

      // Should return to scan list
      expect(find.byType(ScanListScreen), findsOneWidget);
    });

    testWidgets('validates minimum 2 scans requirement', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Select only 1 scan
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      // Verify "Start Stitching" button is disabled
      final startButton = find.widgetWithText(ElevatedButton, 'Start Stitching');
      expect(tester.widget<ElevatedButton>(startButton).onPressed, isNull);

      // Verify validation message
      expect(find.text('Select at least 2 scans to stitch'), findsOneWidget);
    });

    testWidgets('handles guest mode restriction for stitching', (tester) async {
      // Launch app in guest mode
      app.main(); // With guest mode flag
      await tester.pumpAndSettle();

      // Navigate to stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Select 2 scans
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Try to start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Verify authentication prompt appeared
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Account Required'), findsOneWidget);
      expect(find.textContaining('create an account'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should stay on stitching screen
      expect(find.byType(RoomStitchingScreen), findsOneWidget);
    });

    testWidgets('successfully stitches 3+ rooms', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Select 3 scans
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.tap(checkboxes.at(2));
      await tester.pumpAndSettle();

      // Verify selection count
      expect(find.text('3 scans selected'), findsOneWidget);

      // Start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Wait for completion (longer processing for 3 rooms)
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // Verify preview screen
      expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);

      // Verify 3 rooms are mentioned in display name
      // Format: "Room1 + Room2 + 1 more" or "3 rooms stitched"
      final displayName = find.textContaining('3');
      expect(displayName, findsOneWidget);
    });

    testWidgets('displays estimated time remaining during stitching', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate and start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Wait for processing to start
      await tester.pump(const Duration(seconds: 3));

      // Verify estimated time is displayed
      expect(find.textContaining('About'), findsOneWidget);
      expect(find.textContaining('remaining'), findsOneWidget);
    });

    testWidgets('preserves room names through entire flow', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to stitching screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      // Note the room names displayed in selection screen
      final firstRoomName = 'Living Room'; // Assuming mock data
      final secondRoomName = 'Master Bedroom';

      expect(find.text(firstRoomName), findsOneWidget);
      expect(find.text(secondRoomName), findsOneWidget);

      // Select these rooms
      await tester.tap(find.ancestor(
        of: find.text(firstRoomName),
        matching: find.byType(Checkbox),
      ));
      await tester.tap(find.ancestor(
        of: find.text(secondRoomName),
        matching: find.byType(Checkbox),
      ));
      await tester.pumpAndSettle();

      // Start stitching
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // On progress screen, verify room names are displayed
      expect(find.text('$firstRoomName + $secondRoomName'), findsOneWidget);

      // Wait for completion
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // On preview screen, verify room names are still displayed
      expect(find.text('$firstRoomName + $secondRoomName'), findsOneWidget);
    });

    testWidgets('handles network error during stitching start', (tester) async {
      // Launch app with network disabled
      // (Test configuration should simulate network error)
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Try to start stitching (should fail due to network)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Verify error dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Failed to Start Stitching'), findsOneWidget);
      expect(find.textContaining('Network'), findsOneWidget);

      // Dismiss error
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Should stay on stitching screen to allow retry
      expect(find.byType(RoomStitchingScreen), findsOneWidget);
    });

    testWidgets('retries stitching after failure', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Start stitching that will fail
      await tester.tap(find.widgetWithText(ElevatedButton, 'Stitch Rooms'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
      await tester.pumpAndSettle();

      // Wait for failure
      await tester.pump(const Duration(seconds: 5));

      // Error dialog appears
      expect(find.text('Stitching Failed'), findsOneWidget);

      // Tap "Retry"
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Progress screen should restart polling
      expect(find.byType(RoomStitchProgressScreen), findsOneWidget);
      expect(find.text('Waiting to start...'), findsOneWidget);

      // This time it succeeds
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.byType(StitchedModelPreviewScreen), findsOneWidget);
    });
  });
}
