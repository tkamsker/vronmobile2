import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';
import 'package:vronmobile2/features/scanning/widgets/combine_progress_dialog.dart';

/// Test suite for CombineProgressDialog widget
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T024
void main() {
  group('CombineProgressDialog', () {
    testWidgets('should display combining status', (WidgetTester tester) async {
      // Given: CombinedScan in combining state
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.combining,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show combining status
      expect(find.text('Combining Room Scans'), findsOneWidget);
      expect(find.text('Combining scans...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display uploadingUsdz status with progress',
        (WidgetTester tester) async {
      // Given: CombinedScan in uploading state
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.uploadingUsdz,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog with 50% progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              uploadProgress: 0.5,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show uploading status and progress
      expect(find.text('Uploading to server...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('should display processingGlb status',
        (WidgetTester tester) async {
      // Given: CombinedScan in processing state
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.processingGlb,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show processing status
      expect(find.text('Creating Combined GLB'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display uploadingToBlender status',
        (WidgetTester tester) async {
      // Given: CombinedScan uploading to BlenderAPI
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.uploadingToBlender,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show BlenderAPI upload status
      expect(find.text('Uploading GLB to BlenderAPI...'), findsOneWidget);
    });

    testWidgets('should display generatingNavmesh status',
        (WidgetTester tester) async {
      // Given: CombinedScan generating navmesh
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.generatingNavmesh,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show navmesh generation status
      expect(find.text('Generating NavMesh...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display downloadingNavmesh status',
        (WidgetTester tester) async {
      // Given: CombinedScan downloading navmesh
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.downloadingNavmesh,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show download status
      expect(find.text('Downloading NavMesh...'), findsOneWidget);
    });

    testWidgets('should display failed status with error message',
        (WidgetTester tester) async {
      // Given: Failed CombinedScan
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.failed,
        createdAt: DateTime.now(),
        errorMessage: 'Failed to load USDZ at /path/to/scan1.usdz',
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show error status and message
      expect(find.text('Failed'), findsOneWidget);
      expect(
          find.text('Failed to load USDZ at /path/to/scan1.usdz'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should call onCancel when Cancel button tapped',
        (WidgetTester tester) async {
      // Given: Dialog in progress
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        status: CombinedScanStatus.uploadingUsdz,
        createdAt: DateTime.now(),
      );

      var cancelCalled = false;

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {
                cancelCalled = true;
              },
            ),
          ),
        ),
      );

      // And: Tapping cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Then: Should call onCancel callback
      expect(cancelCalled, isTrue);
    });

    testWidgets('should show checkmarks for completed steps',
        (WidgetTester tester) async {
      // Given: Scan at generatingNavmesh stage (previous steps completed)
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        combinedGlbUrl: 'https://api.example.com/combined.glb',
        status: CombinedScanStatus.generatingNavmesh,
        createdAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {},
            ),
          ),
        ),
      );

      // Then: Should show checkmarks for completed steps
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      // And: Current step should have progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should be dismissible when completed',
        (WidgetTester tester) async {
      // Given: Completed scan
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b'],
        localCombinedPath: '/path/to/combined.usdz',
        combinedGlbUrl: 'https://api.example.com/combined.glb',
        navmeshUrl: 'https://api.example.com/navmesh.glb',
        localNavmeshPath: '/path/to/navmesh.glb',
        status: CombinedScanStatus.completed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now().add(Duration(minutes: 3)),
      );

      var closeCalled = false;

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CombineProgressDialog(
              combinedScan: scan,
              onCancel: () {
                closeCalled = true;
              },
            ),
          ),
        ),
      );

      // Then: Should show Close button instead of Cancel
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);

      // And: Tapping close should work
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(closeCalled, isTrue);
    });
  });
}
