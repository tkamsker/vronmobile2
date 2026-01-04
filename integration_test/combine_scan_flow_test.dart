import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vronmobile2/main.dart' as app;

/// E2E Integration Test for Combined Scan to NavMesh Workflow
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T027
///
/// Tests complete user journey:
/// 1. User has 3 scans arranged on canvas
/// 2. Tap "Combine Scans to GLB"
/// 3. Monitor progress through all statuses
/// 4. Tap "Generate NavMesh"
/// 5. Monitor navmesh generation
/// 6. Export both files
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Combine Scan to NavMesh Complete Workflow', () {
    testWidgets('should complete full workflow from combine to export',
        (WidgetTester tester) async {
      // Given: App is running with logged-in user
      app.main();
      await tester.pumpAndSettle();

      // Navigate to project with 3 positioned scans
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Project')); // Assumes test project exists
      await tester.pumpAndSettle();

      // Verify we're on project detail screen with scans
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('3 Scans'), findsOneWidget);

      // Step 1: Start combination workflow
      // When: Tapping Combine button
      await tester.tap(find.text('Combine 3 Scans to GLB'));
      await tester.pumpAndSettle();

      // Then: Progress dialog should appear
      expect(find.text('Combining Room Scans'), findsOneWidget);
      expect(find.text('Combining scans...'), findsOneWidget);

      // Step 2: Monitor combining status
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should show uploading status
      expect(find.text('Uploading to server...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Step 3: Wait for GLB conversion
      // Poll until processingGlb or glbReady appears
      for (var i = 0; i < 30; i++) {
        await tester.pump(Duration(seconds: 2));

        if (find.text('Creating Combined GLB').evaluate().isNotEmpty ||
            find.text('Combined GLB Ready').evaluate().isNotEmpty) {
          break;
        }
      }

      // Dialog should auto-dismiss when glbReady
      await tester.pumpAndSettle();

      // Step 4: Verify "Generate NavMesh" button appears
      expect(find.text('Generate NavMesh'), findsOneWidget);

      // Step 5: Start navmesh generation
      // When: Tapping Generate NavMesh
      await tester.tap(find.text('Generate NavMesh'));
      await tester.pumpAndSettle();

      // Then: Progress dialog should show BlenderAPI workflow
      expect(find.text('Uploading GLB to BlenderAPI...'), findsOneWidget);

      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Generating NavMesh...'), findsOneWidget);

      // Step 6: Wait for navmesh completion
      // Poll until downloadingNavmesh or completed appears
      for (var i = 0; i < 60; i++) {
        await tester.pump(Duration(seconds: 2));

        if (find.text('Downloading NavMesh...').evaluate().isNotEmpty ||
            find.text('NavMesh Ready').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.pumpAndSettle();

      // Step 7: Export dialog should appear
      expect(find.text('Combined Scan Ready'), findsOneWidget);
      expect(find.text('Combined GLB'), findsOneWidget);
      expect(find.text('Navigation Mesh'), findsOneWidget);

      // Verify file sizes are displayed
      expect(find.textContaining('MB'), findsNWidgets(2));

      // Step 8: Test export functionality
      // Export Combined GLB
      await tester.tap(find.text('Export Combined GLB'));
      await tester.pumpAndSettle();

      // iOS share sheet should appear (can't fully test native UI)
      // Just verify no errors occurred
      await tester.pump(Duration(seconds: 1));

      // Dismiss share sheet (if possible in test)
      await tester.tapAt(Offset(10, 10)); // Tap outside
      await tester.pumpAndSettle();

      // Export NavMesh
      await tester.tap(find.text('Export NavMesh'));
      await tester.pumpAndSettle();

      await tester.pump(Duration(seconds: 1));
      await tester.tapAt(Offset(10, 10));
      await tester.pumpAndSettle();

      // Export Both as ZIP
      await tester.tap(find.text('Export Both as ZIP'));
      await tester.pumpAndSettle();

      await tester.pump(Duration(seconds: 1));
      await tester.tapAt(Offset(10, 10));
      await tester.pumpAndSettle();

      // Step 9: Close export dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Then: Should be back on project detail screen
      expect(find.text('Test Project'), findsOneWidget);

      // And: Combined scan should be visible in project
      expect(find.text('Combined Scan'), findsOneWidget);
    });

    testWidgets('should handle cancellation during upload',
        (WidgetTester tester) async {
      // Given: App with project
      app.main();
      await tester.pumpAndSettle();

      // Navigate to project
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      // When: Starting combination
      await tester.tap(find.text('Combine 3 Scans to GLB'));
      await tester.pumpAndSettle();

      // Wait for uploading status
      await tester.pump(Duration(seconds: 2));
      await tester.pumpAndSettle();

      // And: Canceling during upload
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Then: Should return to project detail screen
      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('Combining Room Scans'), findsNothing);

      // And: Should be able to retry
      expect(find.text('Combine 3 Scans to GLB'), findsOneWidget);
    });

    testWidgets('should show error message when combination fails',
        (WidgetTester tester) async {
      // Given: App with project that has invalid scan
      app.main();
      await tester.pumpAndSettle();

      // Navigate to project with broken scan
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Project With Invalid Scan'));
      await tester.pumpAndSettle();

      // When: Attempting to combine
      await tester.tap(find.text('Combine 2 Scans to GLB'));
      await tester.pumpAndSettle();

      // Wait for error to occur
      await tester.pump(Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Then: Should show error message
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Error message should be descriptive
      expect(find.textContaining('Failed to'), findsOneWidget);

      // Should have Close button
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should persist state across app restart',
        (WidgetTester tester) async {
      // Given: Complete a combination workflow
      app.main();
      await tester.pumpAndSettle();

      // Navigate and start combination
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Combine 3 Scans to GLB'));
      await tester.pumpAndSettle();

      // Wait for completion (simplified for test)
      for (var i = 0; i < 30; i++) {
        await tester.pump(Duration(seconds: 2));
        if (find.text('Generate NavMesh').evaluate().isNotEmpty) {
          break;
        }
      }

      await tester.pumpAndSettle();

      // When: Restart app (simulate)
      await tester.pumpWidget(Container()); // Clear widget tree
      app.main();
      await tester.pumpAndSettle();

      // Navigate back to project
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      // Then: Should still show Generate NavMesh button (state persisted)
      expect(find.text('Generate NavMesh'), findsOneWidget);
    });
  });
}
