import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitch_progress_screen.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';
import 'package:vronmobile2/features/scanning/services/room_stitching_service.dart';

// Mock classes
class MockRoomStitchingService extends Mock implements RoomStitchingService {}

class MockFile extends Mock implements File {}

void main() {
  group('RoomStitchProgressScreen', () {
    late MockRoomStitchingService mockStitchingService;

    setUp(() {
      mockStitchingService = MockRoomStitchingService();
    });

    Widget createTestWidget({
      required String jobId,
      required List<String> scanIds,
      Map<String, String>? roomNames,
    }) {
      return MaterialApp(
        home: RoomStitchProgressScreen(
          jobId: jobId,
          scanIds: scanIds,
          roomNames: roomNames,
          stitchingService: mockStitchingService,
        ),
      );
    }

    group('Initial UI State', () {
      testWidgets('displays screen title "Stitching Rooms"', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        expect(find.text('Stitching Rooms'), findsOneWidget);
      });

      testWidgets('displays initial progress indicator (indeterminate)', (
        tester,
      ) async {
        // Mock polling that never completes (for initial state test)
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );
        await tester.pump(); // Initial frame

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Cleanup: wait for polling to complete
        await tester.pumpAndSettle();
      });

      testWidgets('displays initial status message "Waiting to start..."', (
        tester,
      ) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );
        await tester.pump();

        expect(find.text('Waiting to start...'), findsOneWidget);

        // Cleanup
        await tester.pumpAndSettle();
      });

      testWidgets('displays room names being stitched', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.pending,
            progress: 0,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(
            jobId: 'job-001',
            scanIds: ['scan-001', 'scan-002'],
            roomNames: {
              'scan-001': 'Living Room',
              'scan-002': 'Master Bedroom',
            },
          ),
        );
        await tester.pump();

        expect(find.text('Living Room + Master Bedroom'), findsOneWidget);

        // Cleanup
        await tester.pumpAndSettle();
      });
    });

    group('Progress Updates', () {
      testWidgets('updates progress indicator when status changes', (
        tester,
      ) async {
        final statusUpdates = <RoomStitchJob>[
          RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.uploading,
            progress: 10,
            createdAt: DateTime.now(),
          ),
          RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.processing,
            progress: 30,
            createdAt: DateTime.now(),
          ),
          RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.aligning,
            progress: 60,
            createdAt: DateTime.now(),
          ),
        ];

        int callCount = 0;
        void Function(RoomStitchJob)? onStatusChangeCallback;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((invocation) async {
          onStatusChangeCallback =
              invocation.namedArguments[#onStatusChange]
                  as void Function(RoomStitchJob)?;

          // Simulate status updates
          for (final update in statusUpdates) {
            await Future.delayed(const Duration(milliseconds: 100));
            onStatusChangeCallback?.call(update);
          }

          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        // Initial state
        await tester.pump();

        // Wait for status updates
        await tester.pump(const Duration(milliseconds: 100));

        // Should show first update (uploading, 10%)
        expect(find.text('Uploading scans...'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));

        // Should show second update (processing, 30%)
        expect(find.text('Processing...'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 100));

        // Should show third update (aligning, 60%)
        expect(find.text('Aligning rooms...'), findsOneWidget);
      });

      testWidgets('displays progress percentage', (tester) async {
        void Function(RoomStitchJob)? onStatusChangeCallback;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((invocation) async {
          onStatusChangeCallback =
              invocation.namedArguments[#onStatusChange]
                  as void Function(RoomStitchJob)?;

          await Future.delayed(const Duration(milliseconds: 100));
          onStatusChangeCallback?.call(
            RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.aligning,
              progress: 65,
              createdAt: DateTime.now(),
            ),
          );

          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('65%'), findsOneWidget);
      });

      testWidgets('shows all status messages during progression', (
        tester,
      ) async {
        final statuses = [
          (RoomStitchJobStatus.pending, 'Waiting to start...'),
          (RoomStitchJobStatus.uploading, 'Uploading scans...'),
          (RoomStitchJobStatus.processing, 'Processing...'),
          (RoomStitchJobStatus.aligning, 'Aligning rooms...'),
          (RoomStitchJobStatus.merging, 'Merging geometry...'),
        ];

        for (final (status, expectedMessage) in statuses) {
          void Function(RoomStitchJob)? onStatusChangeCallback;

          when(
            () => mockStitchingService.pollStitchStatus(
              jobId: any(named: 'jobId'),
              onStatusChange: any(named: 'onStatusChange'),
            ),
          ).thenAnswer((invocation) async {
            onStatusChangeCallback =
                invocation.namedArguments[#onStatusChange]
                    as void Function(RoomStitchJob)?;

            await Future.delayed(const Duration(milliseconds: 50));
            onStatusChangeCallback?.call(
              RoomStitchJob(
                jobId: 'job-001',
                status: status,
                progress: 50,
                createdAt: DateTime.now(),
              ),
            );

            return RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.completed,
              progress: 100,
              createdAt: DateTime.now(),
            );
          });

          await tester.pumpWidget(
            createTestWidget(
              jobId: 'job-001',
              scanIds: ['scan-001', 'scan-002'],
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.text(expectedMessage), findsOneWidget);

          // Reset for next iteration
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('displays estimated time remaining', (tester) async {
        void Function(RoomStitchJob)? onStatusChangeCallback;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((invocation) async {
          onStatusChangeCallback =
              invocation.namedArguments[#onStatusChange]
                  as void Function(RoomStitchJob)?;

          await Future.delayed(const Duration(milliseconds: 100));
          onStatusChangeCallback?.call(
            RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.processing,
              progress: 30,
              estimatedDurationSeconds: 120, // 2 minutes estimated
              createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
            ),
          );

          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show estimated time (approximately 90 seconds remaining)
        expect(find.textContaining('About'), findsOneWidget);
        expect(find.textContaining('remaining'), findsOneWidget);
      });
    });

    group('Success Handling', () {
      testWidgets('navigates to preview screen when stitching completes', (
        tester,
      ) async {
        final mockFile = MockFile();
        when(
          () => mockFile.path,
        ).thenReturn('/Documents/scans/stitched-001.glb');
        when(() => mockFile.lengthSync()).thenReturn(45000000); // 45 MB

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        when(
          () => mockStitchingService.downloadStitchedModel(
            resultUrl: any(named: 'resultUrl'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async => mockFile);

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Should navigate to preview screen (progress screen no longer visible)
        expect(find.byType(RoomStitchProgressScreen), findsNothing);
      });

      testWidgets('downloads stitched model before navigating to preview', (
        tester,
      ) async {
        final mockFile = MockFile();
        when(
          () => mockFile.path,
        ).thenReturn('/Documents/scans/stitched-001.glb');
        when(() => mockFile.lengthSync()).thenReturn(45000000);

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        when(
          () => mockStitchingService.downloadStitchedModel(
            resultUrl: any(named: 'resultUrl'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async => mockFile);

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Verify download was called
        verify(
          () => mockStitchingService.downloadStitchedModel(
            resultUrl: 'https://example.com/stitched.glb',
            filename: any(named: 'filename'),
          ),
        ).called(1);
      });

      testWidgets('shows success message "Stitching complete!"', (
        tester,
      ) async {
        final mockFile = MockFile();
        when(
          () => mockFile.path,
        ).thenReturn('/Documents/scans/stitched-001.glb');
        when(() => mockFile.lengthSync()).thenReturn(45000000);

        void Function(RoomStitchJob)? onStatusChangeCallback;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((invocation) async {
          onStatusChangeCallback =
              invocation.namedArguments[#onStatusChange]
                  as void Function(RoomStitchJob)?;

          await Future.delayed(const Duration(milliseconds: 100));
          final completedJob = RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );
          onStatusChangeCallback?.call(completedJob);

          return completedJob;
        });

        when(
          () => mockStitchingService.downloadStitchedModel(
            resultUrl: any(named: 'resultUrl'),
            filename: any(named: 'filename'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 2));
          return mockFile;
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Stitching complete!'), findsOneWidget);
      });
    });

    group('Failure Handling', () {
      testWidgets('shows error dialog when stitching fails', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.failed,
            progress: 50,
            errorMessage: 'Insufficient overlap between scans',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Stitching Failed'), findsOneWidget);
        expect(find.text('Insufficient overlap between scans'), findsOneWidget);
      });

      testWidgets('displays user-friendly error messages', (tester) async {
        final errorMessages = [
          'Insufficient overlap between scans',
          'Alignment failure - unable to detect common features',
          'Backend timeout - processing exceeded 5-minute limit',
        ];

        for (final errorMessage in errorMessages) {
          when(
            () => mockStitchingService.pollStitchStatus(
              jobId: any(named: 'jobId'),
              onStatusChange: any(named: 'onStatusChange'),
            ),
          ).thenAnswer(
            (_) async => RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.failed,
              progress: 50,
              errorMessage: errorMessage,
              createdAt: DateTime.now(),
              completedAt: DateTime.now(),
            ),
          );

          await tester.pumpWidget(
            createTestWidget(
              jobId: 'job-001',
              scanIds: ['scan-001', 'scan-002'],
            ),
          );

          await tester.pumpAndSettle();

          expect(find.text(errorMessage), findsOneWidget);

          // Dismiss dialog for next iteration
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          // Reset widget tree
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('provides "Retry" button in error dialog', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.failed,
            progress: 50,
            errorMessage: 'Backend timeout',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('"Retry" button restarts polling', (tester) async {
        int pollCallCount = 0;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          pollCallCount++;

          if (pollCallCount == 1) {
            // First attempt fails
            return RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.failed,
              progress: 50,
              errorMessage: 'Temporary error',
              createdAt: DateTime.now(),
              completedAt: DateTime.now(),
            );
          } else {
            // Retry succeeds
            return RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.completed,
              progress: 100,
              resultUrl: 'https://example.com/stitched.glb',
              createdAt: DateTime.now(),
              completedAt: DateTime.now(),
            );
          }
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // First attempt failed, dialog shown
        expect(find.byType(AlertDialog), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should call pollStitchStatus again
        expect(pollCallCount, 2);
      });

      testWidgets('"Cancel" button exits screen', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.failed,
            progress: 50,
            errorMessage: 'Error',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Screen should be popped
        expect(find.byType(RoomStitchProgressScreen), findsNothing);
      });

      testWidgets('handles polling timeout gracefully', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenThrow(TimeoutException('Polling exceeded maximum attempts'));

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Should show error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.textContaining('timeout'),
          findsOneWidget,
          reason: 'Should mention timeout',
        );
      });

      testWidgets('handles download failure gracefully', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer(
          (_) async => RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            resultUrl: 'https://example.com/stitched.glb',
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          ),
        );

        when(
          () => mockStitchingService.downloadStitchedModel(
            resultUrl: any(named: 'resultUrl'),
            filename: any(named: 'filename'),
          ),
        ).thenThrow(Exception('Network error during download'));

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pumpAndSettle();

        // Should show download error dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.textContaining('download'),
          findsOneWidget,
          reason: 'Should mention download error',
        );
      });
    });

    group('Cancel Button', () {
      testWidgets('displays "Cancel" button during progress', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.processing,
            progress: 50,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();

        expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);

        // Cleanup
        await tester.pumpAndSettle();
      });

      testWidgets('shows confirmation dialog when cancel is tapped', (
        tester,
      ) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.processing,
            progress: 50,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();

        // Tap cancel
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Cancel Stitching?'), findsOneWidget);
        expect(find.textContaining('Are you sure'), findsOneWidget);
      });

      testWidgets('exits screen when cancellation confirmed', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.processing,
            progress: 50,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();

        // Tap cancel
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        // Confirm cancellation
        await tester.tap(find.text('Yes, Cancel'));
        await tester.pumpAndSettle();

        // Screen should be popped
        expect(find.byType(RoomStitchProgressScreen), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('announces status changes to screen readers', (tester) async {
        void Function(RoomStitchJob)? onStatusChangeCallback;

        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((invocation) async {
          onStatusChangeCallback =
              invocation.namedArguments[#onStatusChange]
                  as void Function(RoomStitchJob)?;

          await Future.delayed(const Duration(milliseconds: 100));
          onStatusChangeCallback?.call(
            RoomStitchJob(
              jobId: 'job-001',
              status: RoomStitchJobStatus.aligning,
              progress: 60,
              createdAt: DateTime.now(),
            ),
          );

          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.completed,
            progress: 100,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();

        // Status messages should be in live region for screen reader announcements
        // (Implementation will need to use Semantics with liveRegion: true)

        // Cleanup
        await tester.pumpAndSettle();
      });

      testWidgets('progress indicator has accessible label', (tester) async {
        when(
          () => mockStitchingService.pollStitchStatus(
            jobId: any(named: 'jobId'),
            onStatusChange: any(named: 'onStatusChange'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 200));
          return RoomStitchJob(
            jobId: 'job-001',
            status: RoomStitchJobStatus.processing,
            progress: 50,
            createdAt: DateTime.now(),
          );
        });

        await tester.pumpWidget(
          createTestWidget(jobId: 'job-001', scanIds: ['scan-001', 'scan-002']),
        );

        await tester.pump();

        expect(
          find.bySemanticsLabel('Stitching progress indicator'),
          findsOneWidget,
        );

        // Cleanup
        await tester.pumpAndSettle();
      });
    });
  });
}
