import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';

void main() {
  group('RoomStitchJob', () {
    group('isTerminal getter', () {
      test('returns true when status is completed', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, true);
      });

      test('returns true when status is failed', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.failed,
          progress: 50,
          createdAt: DateTime.now(),
          errorMessage: 'Stitching failed',
        );

        expect(job.isTerminal, true);
      });

      test('returns false when status is pending', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.pending,
          progress: 0,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, false);
      });

      test('returns false when status is uploading', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.uploading,
          progress: 10,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, false);
      });

      test('returns false when status is processing', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 30,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, false);
      });

      test('returns false when status is aligning', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.aligning,
          progress: 60,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, false);
      });

      test('returns false when status is merging', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.merging,
          progress: 85,
          createdAt: DateTime.now(),
        );

        expect(job.isTerminal, false);
      });
    });

    group('isSuccessful getter', () {
      test('returns true when status is completed and resultUrl is present', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime.now(),
        );

        expect(job.isSuccessful, true);
      });

      test('returns false when status is completed but resultUrl is null', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          createdAt: DateTime.now(),
        );

        expect(job.isSuccessful, false);
      });

      test('returns false when status is failed', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.failed,
          progress: 50,
          errorMessage: 'Alignment failed',
          createdAt: DateTime.now(),
        );

        expect(job.isSuccessful, false);
      });

      test('returns false when status is still in progress', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.aligning,
          progress: 65,
          createdAt: DateTime.now(),
        );

        expect(job.isSuccessful, false);
      });
    });

    group('elapsedSeconds getter', () {
      test('returns elapsed time when job is still running', () {
        final startTime = DateTime.now().subtract(const Duration(seconds: 30));
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 40,
          createdAt: startTime,
        );

        final elapsed = job.elapsedSeconds;

        expect(elapsed, greaterThanOrEqualTo(29)); // Allow 1 second tolerance
        expect(elapsed, lessThanOrEqualTo(31));
      });

      test('returns total duration when job is completed', () {
        final startTime = DateTime.now().subtract(const Duration(seconds: 120));
        final endTime = startTime.add(const Duration(seconds: 115));

        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          createdAt: startTime,
          completedAt: endTime,
          resultUrl: 'https://example.com/stitched.glb',
        );

        expect(job.elapsedSeconds, 115);
      });

      test('returns total duration when job failed', () {
        final startTime = DateTime.now().subtract(const Duration(seconds: 60));
        final endTime = startTime.add(const Duration(seconds: 45));

        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.failed,
          progress: 50,
          errorMessage: 'Backend timeout',
          createdAt: startTime,
          completedAt: endTime,
        );

        expect(job.elapsedSeconds, 45);
      });
    });

    group('statusMessage getter', () {
      test('returns "Waiting to start..." when status is pending', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.pending,
          progress: 0,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Waiting to start...');
      });

      test('returns "Uploading scans..." when status is uploading', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.uploading,
          progress: 10,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Uploading scans...');
      });

      test('returns "Processing..." when status is processing', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 30,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Processing...');
      });

      test('returns "Aligning rooms..." when status is aligning', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.aligning,
          progress: 60,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Aligning rooms...');
      });

      test('returns "Merging geometry..." when status is merging', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.merging,
          progress: 85,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Merging geometry...');
      });

      test('returns "Stitching complete!" when status is completed', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Stitching complete!');
      });

      test('returns error message when status is failed and errorMessage provided', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.failed,
          progress: 50,
          errorMessage: 'Insufficient overlap between scans',
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Insufficient overlap between scans');
      });

      test('returns "Stitching failed" when status is failed but no errorMessage', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.failed,
          progress: 50,
          createdAt: DateTime.now(),
        );

        expect(job.statusMessage, 'Stitching failed');
      });
    });

    group('copyWith()', () {
      test('creates copy with updated status', () {
        final original = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.pending,
          progress: 0,
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(status: RoomStitchJobStatus.uploading);

        expect(updated.jobId, original.jobId);
        expect(updated.status, RoomStitchJobStatus.uploading);
        expect(updated.progress, original.progress);
      });

      test('creates copy with updated progress', () {
        final original = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 30,
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(progress: 65);

        expect(updated.jobId, original.jobId);
        expect(updated.status, original.status);
        expect(updated.progress, 65);
      });

      test('creates copy with updated resultUrl when completed', () {
        final original = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 90,
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          completedAt: DateTime.now(),
        );

        expect(updated.status, RoomStitchJobStatus.completed);
        expect(updated.progress, 100);
        expect(updated.resultUrl, 'https://example.com/stitched.glb');
        expect(updated.completedAt, isNotNull);
      });

      test('creates copy with errorMessage when failed', () {
        final original = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.aligning,
          progress: 60,
          createdAt: DateTime.now(),
        );

        final updated = original.copyWith(
          status: RoomStitchJobStatus.failed,
          errorMessage: 'Alignment failure',
          completedAt: DateTime.now(),
        );

        expect(updated.status, RoomStitchJobStatus.failed);
        expect(updated.errorMessage, 'Alignment failure');
        expect(updated.completedAt, isNotNull);
      });

      test('preserves original values when not specified in copyWith', () {
        final original = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 40,
          createdAt: DateTime.now(),
          estimatedDurationSeconds: 120,
        );

        final updated = original.copyWith(progress: 50);

        expect(updated.jobId, original.jobId);
        expect(updated.status, original.status);
        expect(updated.createdAt, original.createdAt);
        expect(updated.estimatedDurationSeconds, 120);
      });
    });

    group('JSON serialization', () {
      test('toJson() serializes all fields correctly', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime(2025, 1, 1, 12, 0, 0),
          completedAt: DateTime(2025, 1, 1, 12, 2, 15),
          estimatedDurationSeconds: 120,
        );

        final json = job.toJson();

        expect(json['jobId'], 'job-001');
        expect(json['status'], isNotNull);
        expect(json['progress'], 100);
        expect(json['resultUrl'], 'https://example.com/stitched.glb');
        expect(json['createdAt'], isNotNull);
        expect(json['completedAt'], isNotNull);
        expect(json['estimatedDurationSeconds'], 120);
      });

      test('toJson() handles null optional fields', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.processing,
          progress: 45,
          createdAt: DateTime.now(),
        );

        final json = job.toJson();

        expect(json['jobId'], 'job-001');
        expect(json['status'], isNotNull);
        expect(json['progress'], 45);
        expect(json['errorMessage'], isNull);
        expect(json['resultUrl'], isNull);
        expect(json['completedAt'], isNull);
      });

      test('fromJson() deserializes correctly', () {
        final json = {
          'jobId': 'job-001',
          'status': 'aligning',
          'progress': 65,
          'createdAt': '2025-01-01T12:00:00.000Z',
          'estimatedDurationSeconds': 120,
        };

        final job = RoomStitchJob.fromJson(json);

        expect(job.jobId, 'job-001');
        expect(job.status, RoomStitchJobStatus.aligning);
        expect(job.progress, 65);
        expect(job.estimatedDurationSeconds, 120);
      });
    });

    group('State transitions', () {
      test('simulates full successful flow: pending → uploading → processing → aligning → merging → completed', () {
        final createdAt = DateTime.now();

        // Step 1: Job created (pending)
        final job1 = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.pending,
          progress: 0,
          createdAt: createdAt,
          estimatedDurationSeconds: 120,
        );

        expect(job1.isTerminal, false);
        expect(job1.statusMessage, 'Waiting to start...');

        // Step 2: Upload started
        final job2 = job1.copyWith(
          status: RoomStitchJobStatus.uploading,
          progress: 10,
        );

        expect(job2.isTerminal, false);
        expect(job2.statusMessage, 'Uploading scans...');

        // Step 3: Processing started
        final job3 = job2.copyWith(
          status: RoomStitchJobStatus.processing,
          progress: 30,
        );

        expect(job3.isTerminal, false);
        expect(job3.statusMessage, 'Processing...');

        // Step 4: Aligning rooms
        final job4 = job3.copyWith(
          status: RoomStitchJobStatus.aligning,
          progress: 60,
        );

        expect(job4.isTerminal, false);
        expect(job4.statusMessage, 'Aligning rooms...');

        // Step 5: Merging geometry
        final job5 = job4.copyWith(
          status: RoomStitchJobStatus.merging,
          progress: 85,
        );

        expect(job5.isTerminal, false);
        expect(job5.statusMessage, 'Merging geometry...');

        // Step 6: Completed
        final job6 = job5.copyWith(
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          completedAt: DateTime.now(),
        );

        expect(job6.isTerminal, true);
        expect(job6.isSuccessful, true);
        expect(job6.statusMessage, 'Stitching complete!');
      });

      test('simulates failure flow: pending → uploading → processing → failed', () {
        final createdAt = DateTime.now();

        // Step 1: Job created
        final job1 = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.pending,
          progress: 0,
          createdAt: createdAt,
        );

        // Step 2: Upload started
        final job2 = job1.copyWith(
          status: RoomStitchJobStatus.uploading,
          progress: 10,
        );

        // Step 3: Processing started
        final job3 = job2.copyWith(
          status: RoomStitchJobStatus.processing,
          progress: 30,
        );

        // Step 4: Failed
        final job4 = job3.copyWith(
          status: RoomStitchJobStatus.failed,
          errorMessage: 'Backend timeout - processing exceeded 5-minute limit',
          completedAt: DateTime.now(),
        );

        expect(job4.isTerminal, true);
        expect(job4.isSuccessful, false);
        expect(job4.statusMessage, 'Backend timeout - processing exceeded 5-minute limit');
      });
    });
  });
}
