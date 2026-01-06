import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/projects/screens/project_detail_screen.dart';

/// Test suite for ProjectDetailScreen "Combine Scans" button
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T026
void main() {
  group('ProjectDetailScreen - Combine Button', () {
    testWidgets('should be disabled when project has less than 2 scans',
        (WidgetTester tester) async {
      // Given: Project with only 1 scan
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 0.0,
          positionY: 0.0,
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Combine button should be disabled
      final combineButton = find.widgetWithText(ElevatedButton, 'Combine Scans to GLB');
      expect(combineButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(combineButton);
      expect(button.onPressed, isNull); // Disabled
    });

    testWidgets('should be disabled when scans lack position data',
        (WidgetTester tester) async {
      // Given: 2 scans without position data
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          // No position data
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          // No position data
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Combine button should be disabled
      final combineButton = find.widgetWithText(ElevatedButton, 'Combine Scans to GLB');
      expect(combineButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(combineButton);
      expect(button.onPressed, isNull); // Disabled
    });

    testWidgets('should be enabled when 2+ scans have position data',
        (WidgetTester tester) async {
      // Given: 2 scans with position data
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 0.0,
          positionY: 0.0,
          rotationDegrees: 0.0,
          scaleFactor: 1.0,
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 150.0,
          positionY: 0.0,
          rotationDegrees: 90.0,
          scaleFactor: 1.0,
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Combine button should be enabled
      final combineButton = find.widgetWithText(ElevatedButton, 'Combine Scans to GLB');
      expect(combineButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(combineButton);
      expect(button.onPressed, isNotNull); // Enabled
    });

    testWidgets('should show scan count in button text',
        (WidgetTester tester) async {
      // Given: 3 scans with position data
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 0.0,
          positionY: 0.0,
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 150.0,
          positionY: 0.0,
        ),
        ScanData(
          id: 'scan-3',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan3.usdz',
          fileSizeBytes: 6291456,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 300.0,
          positionY: 0.0,
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Button should show scan count
      expect(find.text('Combine 3 Scans to GLB'), findsOneWidget);
    });

    testWidgets('should trigger combine workflow when tapped',
        (WidgetTester tester) async {
      // Given: Valid scans for combining
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 0.0,
          positionY: 0.0,
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 150.0,
          positionY: 0.0,
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // And: Tapping combine button
      await tester.tap(find.text('Combine 2 Scans to GLB'));
      await tester.pumpAndSettle();

      // Then: Should show progress dialog
      expect(find.text('Combining Room Scans'), findsOneWidget);
    });

    testWidgets('should replace combine button with Generate NavMesh when GLB ready',
        (WidgetTester tester) async {
      // Given: Project with completed combined scan (glbReady status)
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
        ),
      ];

      // When: Displaying screen with existing combined scan
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
            hasGlbReady: true, // GLB is ready for navmesh
          ),
        ),
      );

      // Then: Should show Generate NavMesh button instead
      expect(find.text('Generate NavMesh'), findsOneWidget);
      expect(find.text('Combine Scans to GLB'), findsNothing);
    });

    testWidgets('should show tooltip when button is disabled',
        (WidgetTester tester) async {
      // Given: Project with insufficient scans
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Should show tooltip explaining why disabled
      final tooltipFinder = find.byTooltip('Need at least 2 scans with positions to combine');
      expect(tooltipFinder, findsOneWidget);
    });

    testWidgets('should have view_in_ar icon', (WidgetTester tester) async {
      // Given: Valid scans
      final scans = [
        ScanData(
          id: 'scan-1',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan1.usdz',
          fileSizeBytes: 5242880,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 0.0,
          positionY: 0.0,
        ),
        ScanData(
          id: 'scan-2',
          format: ScanFormat.usdz,
          localPath: '/path/to/scan2.usdz',
          fileSizeBytes: 4194304,
          capturedAt: DateTime.now(),
          status: ScanStatus.completed,
          projectId: 'project-1',
          positionX: 150.0,
          positionY: 0.0,
        ),
      ];

      // When: Displaying screen
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(
            projectId: 'project-1',
            scans: scans,
          ),
        ),
      );

      // Then: Button should have view_in_ar icon
      expect(find.byIcon(Icons.view_in_ar), findsOneWidget);
    });
  });
}
