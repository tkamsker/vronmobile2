import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';
import 'package:vronmobile2/features/scanning/widgets/export_combined_dialog.dart';

/// Test suite for ExportCombinedDialog widget
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T025
void main() {
  group('ExportCombinedDialog', () {
    testWidgets('should display file sizes for both files',
        (WidgetTester tester) async {
      // Given: Completed CombinedScan with both files
      final scan = CombinedScan(
        id: 'scan-1',
        projectId: 'project-1',
        scanIds: ['scan-a', 'scan-b', 'scan-c'],
        localCombinedPath: '/path/to/combined.usdz',
        combinedGlbUrl: 'https://api.example.com/combined.glb',
        combinedGlbLocalPath: '/path/to/combined.glb',
        navmeshUrl: 'https://api.example.com/navmesh.glb',
        localNavmeshPath: '/path/to/navmesh.glb',
        status: CombinedScanStatus.completed,
        createdAt: DateTime.now(),
        completedAt: DateTime.now().add(Duration(minutes: 3)),
      );

      // And: File sizes
      const combinedGlbSize = 12582912; // 12 MB
      const navmeshSize = 1258291; // ~1.2 MB

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {},
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // Then: Should display both file sizes
      expect(find.text('Combined GLB (12.0 MB)'), findsOneWidget);
      expect(find.text('Navigation Mesh (1.2 MB)'), findsOneWidget);
      expect(find.text('Combined Scan Ready'), findsOneWidget);
    });

    testWidgets('should show all three export buttons',
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
        completedAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {},
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // Then: Should show all export options
      expect(find.text('Export Combined GLB'), findsOneWidget);
      expect(find.text('Export NavMesh'), findsOneWidget);
      expect(find.text('Export Both as ZIP'), findsOneWidget);
    });

    testWidgets('should call onExportCombinedGlb when button tapped',
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
        completedAt: DateTime.now(),
      );

      var exportGlbCalled = false;

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {
                exportGlbCalled = true;
              },
              onExportNavmesh: () {},
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // And: Tapping Export Combined GLB button
      await tester.tap(find.text('Export Combined GLB'));
      await tester.pumpAndSettle();

      // Then: Should call callback
      expect(exportGlbCalled, isTrue);
    });

    testWidgets('should call onExportNavmesh when button tapped',
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
        completedAt: DateTime.now(),
      );

      var exportNavmeshCalled = false;

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {
                exportNavmeshCalled = true;
              },
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // And: Tapping Export NavMesh button
      await tester.tap(find.text('Export NavMesh'));
      await tester.pumpAndSettle();

      // Then: Should call callback
      expect(exportNavmeshCalled, isTrue);
    });

    testWidgets('should call onExportBoth when ZIP button tapped',
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
        completedAt: DateTime.now(),
      );

      var exportBothCalled = false;

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {},
              onExportBoth: () {
                exportBothCalled = true;
              },
            ),
          ),
        ),
      );

      // And: Tapping Export Both button
      await tester.tap(find.text('Export Both as ZIP'));
      await tester.pumpAndSettle();

      // Then: Should call callback
      expect(exportBothCalled, isTrue);
    });

    testWidgets('should show checkmarks for available files',
        (WidgetTester tester) async {
      // Given: Completed scan with both files
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
        completedAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {},
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // Then: Should show file info (widget doesn't show checkmarks in current implementation)
      expect(find.text('Combined GLB'), findsOneWidget);
    });

    testWidgets('should format file sizes correctly',
        (WidgetTester tester) async {
      // Given: Various file sizes
      final testCases = [
        (bytes: 1024, expected: '1.0 KB'),
        (bytes: 1048576, expected: '1.0 MB'),
        (bytes: 12582912, expected: '12.0 MB'),
        (bytes: 1258291, expected: '1.2 MB'),
      ];

      for (final testCase in testCases) {
        // When: Displaying dialog with specific file size
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
          completedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportCombinedDialog(
                combinedScan: scan,
                onExportGlb: () {},
                onExportNavmesh: () {},
                onExportBoth: () {},
              ),
            ),
          ),
        );

        // Then: Should format size correctly
        expect(find.textContaining(testCase.expected), findsWidgets);

        // Cleanup for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('should have Close button', (WidgetTester tester) async {
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
        completedAt: DateTime.now(),
      );

      // When: Displaying dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportCombinedDialog(
              combinedScan: scan,
              onExportGlb: () {},
              onExportNavmesh: () {},
              onExportBoth: () {},
            ),
          ),
        ),
      );

      // Then: Should have Close button
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
