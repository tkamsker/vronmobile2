import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitching_screen.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_request.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';
import 'package:vronmobile2/features/scanning/services/room_stitching_service.dart';

// Mock classes
class MockRoomStitchingService extends Mock implements RoomStitchingService {}

// Fake classes for mocktail
class FakeRoomStitchRequest extends Fake implements RoomStitchRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRoomStitchRequest());
  });

  group('RoomStitchingScreen', () {
    late MockRoomStitchingService mockStitchingService;
    late List<ScanData> mockScans;

    setUp(() {
      mockStitchingService = MockRoomStitchingService();

      // Create mock scans for testing
      mockScans = [
        ScanData(
          id: 'scan-001',
          format: ScanFormat.glb,
          localPath: '/Documents/scans/scan-001.glb',
          fileSizeBytes: 15000000,
          capturedAt: DateTime(2025, 1, 1, 10, 0, 0),
          status: ScanStatus.completed,
          metadata: {'roomName': 'Living Room'},
        ),
        ScanData(
          id: 'scan-002',
          format: ScanFormat.glb,
          localPath: '/Documents/scans/scan-002.glb',
          fileSizeBytes: 12000000,
          capturedAt: DateTime(2025, 1, 1, 10, 15, 0),
          status: ScanStatus.completed,
          metadata: {'roomName': 'Master Bedroom'},
        ),
        ScanData(
          id: 'scan-003',
          format: ScanFormat.glb,
          localPath: '/Documents/scans/scan-003.glb',
          fileSizeBytes: 18000000,
          capturedAt: DateTime(2025, 1, 1, 10, 30, 0),
          status: ScanStatus.completed,
          metadata: {'roomName': 'Kitchen'},
        ),
        ScanData(
          id: 'scan-004',
          format: ScanFormat.glb,
          localPath: '/Documents/scans/scan-004.glb',
          // No room name - should display as "Scan 4"
          fileSizeBytes: 10000000,
          capturedAt: DateTime(2025, 1, 1, 10, 45, 0),
          status: ScanStatus.completed,
          metadata: {},
        ),
      ];
    });

    Widget createTestWidget({required List<ScanData> scans}) {
      return MaterialApp(
        home: RoomStitchingScreen(
          scans: scans,
          stitchingService: mockStitchingService,
          projectId: 'proj-001',
        ),
      );
    }

    group('Initial UI State', () {
      testWidgets('displays screen title "Stitch Rooms"', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        expect(find.text('Stitch Rooms'), findsOneWidget);
      });

      testWidgets('displays all scans in a list', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        expect(find.text('Living Room'), findsOneWidget);
        expect(find.text('Master Bedroom'), findsOneWidget);
        expect(find.text('Kitchen'), findsOneWidget);
        expect(find.text('Scan 4'), findsOneWidget); // No room name
      });

      testWidgets('displays checkboxes for each scan (initially unchecked)', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        final checkboxes = find.byType(Checkbox);
        expect(checkboxes, findsNWidgets(4)); // 4 scans = 4 checkboxes

        // All checkboxes should be unchecked initially
        for (int i = 0; i < 4; i++) {
          final checkbox = tester.widget<Checkbox>(checkboxes.at(i));
          expect(checkbox.value, false);
        }
      });

      testWidgets('displays "Start Stitching" button (initially disabled)', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        expect(button, findsOneWidget);

        // Button should be disabled when no scans selected
        final elevatedButton = tester.widget<ElevatedButton>(button);
        expect(elevatedButton.onPressed, isNull);
      });

      testWidgets('displays help text "Select at least 2 scans to stitch"', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        expect(find.text('Select at least 2 scans to stitch'), findsOneWidget);
      });
    });

    group('Scan Selection', () {
      testWidgets('tapping scan card toggles checkbox', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Initially unchecked
        final firstCheckbox = find.byType(Checkbox).first;
        expect(tester.widget<Checkbox>(firstCheckbox).value, false);

        // Tap scan card
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();

        // Now checked
        expect(tester.widget<Checkbox>(firstCheckbox).value, true);

        // Tap again to uncheck
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();

        // Back to unchecked
        expect(tester.widget<Checkbox>(firstCheckbox).value, false);
      });

      testWidgets('tapping checkbox directly toggles selection', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        final firstCheckbox = find.byType(Checkbox).first;

        // Initially unchecked
        expect(tester.widget<Checkbox>(firstCheckbox).value, false);

        // Tap checkbox
        await tester.tap(firstCheckbox);
        await tester.pumpAndSettle();

        // Now checked
        expect(tester.widget<Checkbox>(firstCheckbox).value, true);
      });

      testWidgets('selection count updates when scans are selected', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        expect(find.text('2 scans selected'), findsOneWidget);

        // Select 1 more
        await tester.tap(find.text('Kitchen'));
        await tester.pumpAndSettle();

        expect(find.text('3 scans selected'), findsOneWidget);
      });

      testWidgets('can select all scans', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select all 4 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.tap(find.text('Kitchen'));
        await tester.tap(find.text('Scan 4'));
        await tester.pumpAndSettle();

        expect(find.text('4 scans selected'), findsOneWidget);

        // All checkboxes should be checked
        final checkboxes = find.byType(Checkbox);
        for (int i = 0; i < 4; i++) {
          expect(tester.widget<Checkbox>(checkboxes.at(i)).value, true);
        }
      });
    });

    group('Button Validation', () {
      testWidgets('"Start Stitching" button disabled when 0 scans selected', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        final elevatedButton = tester.widget<ElevatedButton>(button);

        expect(elevatedButton.onPressed, isNull);
      });

      testWidgets('"Start Stitching" button disabled when only 1 scan selected', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select 1 scan
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();

        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        final elevatedButton = tester.widget<ElevatedButton>(button);

        expect(elevatedButton.onPressed, isNull);
      });

      testWidgets('"Start Stitching" button enabled when 2 scans selected', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        final elevatedButton = tester.widget<ElevatedButton>(button);

        expect(elevatedButton.onPressed, isNotNull);
      });

      testWidgets('"Start Stitching" button enabled when 3+ scans selected', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select 3 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.tap(find.text('Kitchen'));
        await tester.pumpAndSettle();

        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        final elevatedButton = tester.widget<ElevatedButton>(button);

        expect(elevatedButton.onPressed, isNotNull);
      });

      testWidgets('button becomes disabled again when selection drops below 2', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Button enabled
        var button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);

        // Deselect 1 scan (now only 1 selected)
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Button disabled again
        expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      });
    });

    group('Stitching Initiation', () {
      testWidgets('tapping "Start Stitching" calls RoomStitchingService.startStitching()', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Mock the startStitching response
        when(() => mockStitchingService.startStitching(any())).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.pending,
            progress: 0,
            createdAt: DateTime.now(),
          ),
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        // Verify startStitching was called
        verify(() => mockStitchingService.startStitching(any())).called(1);
      });

      testWidgets('passes correct scanIds to RoomStitchRequest', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        RoomStitchRequest? capturedRequest;

        when(() => mockStitchingService.startStitching(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as RoomStitchRequest;
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.pending,
            progress: 0,
            createdAt: DateTime.now(),
          );
        });

        // Select Living Room and Kitchen
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Kitchen'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.projectId, 'proj-001');
        expect(capturedRequest!.scanIds, containsAll(['scan-001', 'scan-003']));
        expect(capturedRequest!.scanIds.length, 2);
      });

      testWidgets('passes room names to RoomStitchRequest', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        RoomStitchRequest? capturedRequest;

        when(() => mockStitchingService.startStitching(any())).thenAnswer((invocation) async {
          capturedRequest = invocation.positionalArguments[0] as RoomStitchRequest;
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.pending,
            progress: 0,
            createdAt: DateTime.now(),
          );
        });

        // Select Living Room and Master Bedroom
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        expect(capturedRequest!.roomNames, isNotNull);
        expect(capturedRequest!.roomNames!['scan-001'], 'Living Room');
        expect(capturedRequest!.roomNames!['scan-002'], 'Master Bedroom');
      });

      testWidgets('navigates to RoomStitchProgressScreen on success', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        when(() => mockStitchingService.startStitching(any())).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.pending,
            progress: 0,
            createdAt: DateTime.now(),
          ),
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        // Should navigate to progress screen
        // (Screen implementation will need to handle this navigation)
        expect(find.byType(RoomStitchingScreen), findsNothing); // Screen popped/replaced
      });

      testWidgets('shows loading indicator while starting stitch', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Delay the response to simulate network latency
        when(() => mockStitchingService.startStitching(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 500));
            return RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.pending,
              progress: 0,
              createdAt: DateTime.now(),
            );
          },
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pump(); // Trigger frame but don't settle

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Clean up: wait for async operation to complete
        await tester.pumpAndSettle();
      });

      testWidgets('shows error dialog when stitching fails to start', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        when(() => mockStitchingService.startStitching(any())).thenThrow(
          Exception('Network error: Unable to connect to server'),
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Failed to Start Stitching'), findsOneWidget);
        expect(find.textContaining('Network error'), findsOneWidget);
      });

      testWidgets('can dismiss error dialog and try again', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        when(() => mockStitchingService.startStitching(any())).thenThrow(
          Exception('Temporary error'),
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching" (fails)
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        // Dismiss error dialog
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed, screen still visible
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(RoomStitchingScreen), findsOneWidget);
      });
    });

    group('Guest User Handling', () {
      testWidgets('shows authentication prompt for guest users', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RoomStitchingScreen(
              scans: mockScans,
              stitchingService: mockStitchingService,
              projectId: 'proj-001',
              isGuestMode: true, // Guest user
            ),
          ),
        );

        // Select 2 scans
        await tester.tap(find.text('Living Room'));
        await tester.tap(find.text('Master Bedroom'));
        await tester.pumpAndSettle();

        // Tap "Start Stitching"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Start Stitching'));
        await tester.pumpAndSettle();

        // Should show auth prompt instead of starting stitch
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Account Required'), findsOneWidget);
        expect(find.textContaining('create an account'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles empty scan list gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: []));

        expect(find.text('Stitch Rooms'), findsOneWidget);
        expect(find.text('No scans available'), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('handles single scan (insufficient for stitching)', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: [mockScans[0]]));

        expect(find.text('Living Room'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);

        // Select the only scan
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();

        // Button should still be disabled (need 2+ scans)
        final button = find.widgetWithText(ElevatedButton, 'Start Stitching');
        expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

        // Should show warning
        expect(find.textContaining('Need at least 2 scans'), findsOneWidget);
      });

      testWidgets('displays file size for each scan', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // File sizes should be formatted and displayed
        // 15000000 bytes = 14.3 MB, 12000000 = 11.4 MB, 18000000 = 17.2 MB, 10000000 = 9.5 MB
        expect(find.textContaining('14.3'), findsOneWidget);
        expect(find.textContaining('11.4'), findsOneWidget);
        expect(find.textContaining('17.2'), findsOneWidget);
        expect(find.textContaining('9.5'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('screen has proper semantics labels', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Screen title should be accessible
        expect(
          find.bySemanticsLabel('Stitch Rooms'),
          findsOneWidget,
        );

        // Checkboxes should have labels
        expect(
          find.bySemanticsLabel('Select Living Room for stitching'),
          findsOneWidget,
        );

        // Button should have label
        expect(
          find.bySemanticsLabel('Start stitching selected scans'),
          findsOneWidget,
        );
      });

      testWidgets('announces selection changes to screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(scans: mockScans));

        // Select a scan
        await tester.tap(find.text('Living Room'));
        await tester.pumpAndSettle();

        // Should announce "Living Room selected"
        // (Implementation will need to use Semantics.liveRegion or announceMessage)
      });
    });
  });
}
