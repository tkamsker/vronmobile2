import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/stitched_model.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';

void main() {
  group('StitchedModel', () {
    group('displayName getter', () {
      test('shows room names when 2 rooms provided', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
          },
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, 'Living Room + Master Bedroom');
      });

      test('shows first 2 room names + count for 3+ rooms', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
            'scan-003': 'Kitchen',
          },
          fileSizeBytes: 60000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, contains('Living Room'));
        expect(model.displayName, contains('Master Bedroom'));
        expect(model.displayName, contains('1 more'));
      });

      test('shows first 2 room names + count for 5 rooms', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003', 'scan-004', 'scan-005'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
            'scan-003': 'Kitchen',
            'scan-004': 'Bathroom',
            'scan-005': 'Dining Room',
          },
          fileSizeBytes: 100000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, contains('Living Room'));
        expect(model.displayName, contains('Master Bedroom'));
        expect(model.displayName, contains('3 more'));
      });

      test('shows scan count when no room names provided', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003'],
          fileSizeBytes: 50000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, '3 rooms stitched');
      });

      test('shows scan count when roomNames map is empty', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          roomNames: {},
          fileSizeBytes: 40000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, '2 rooms stitched');
      });
    });

    group('fromJob factory', () {
      test('creates StitchedModel from completed RoomStitchJob', () {
        final completedJob = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime(2025, 1, 1, 12, 0, 0),
          completedAt: DateTime(2025, 1, 1, 12, 2, 15),
        );

        final model = StitchedModel.fromJob(
          completedJob,
          '/Documents/scans/stitched-living-master-2025-01-01.glb',
          45000000,
          ['scan-001', 'scan-002'],
          {'scan-001': 'Living Room', 'scan-002': 'Master Bedroom'},
        );

        expect(model.id, 'job-001');
        expect(model.localPath, '/Documents/scans/stitched-living-master-2025-01-01.glb');
        expect(model.fileSizeBytes, 45000000);
        expect(model.originalScanIds, ['scan-001', 'scan-002']);
        expect(model.roomNames, {'scan-001': 'Living Room', 'scan-002': 'Master Bedroom'});
        expect(model.createdAt, DateTime(2025, 1, 1, 12, 2, 15)); // Uses completedAt
        expect(model.format, 'glb');
      });

      test('uses current time when job completedAt is null', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime.now(),
          // completedAt is null
        );

        final beforeCreation = DateTime.now();
        final model = StitchedModel.fromJob(
          job,
          '/Documents/scans/stitched-001.glb',
          45000000,
          ['scan-001', 'scan-002'],
          null,
        );
        final afterCreation = DateTime.now();

        expect(model.createdAt.isAfter(beforeCreation) || model.createdAt.isAtSameMomentAs(beforeCreation), true);
        expect(model.createdAt.isBefore(afterCreation) || model.createdAt.isAtSameMomentAs(afterCreation), true);
      });

      test('handles null roomNames', () {
        final job = RoomStitchJob(
          jobId: 'job-001',
          status: RoomStitchJobStatus.completed,
          progress: 100,
          resultUrl: 'https://example.com/stitched.glb',
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        final model = StitchedModel.fromJob(
          job,
          '/Documents/scans/stitched-001.glb',
          45000000,
          ['scan-001', 'scan-002', 'scan-003'],
          null, // No room names
        );

        expect(model.roomNames, isNull);
        expect(model.displayName, '3 rooms stitched');
      });
    });

    group('JSON serialization', () {
      test('toJson() serializes all fields correctly', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-living-master-2025-01-01.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          roomNames: {'scan-001': 'Living Room', 'scan-002': 'Master Bedroom'},
          fileSizeBytes: 45000000,
          createdAt: DateTime(2025, 1, 1, 12, 2, 15),
          format: 'glb',
          metadata: {'polygonCount': 450000, 'textureCount': 12},
        );

        final json = model.toJson();

        expect(json['id'], 'job-001');
        expect(json['localPath'], '/Documents/scans/stitched-living-master-2025-01-01.glb');
        expect(json['originalScanIds'], ['scan-001', 'scan-002']);
        expect(json['roomNames'], {'scan-001': 'Living Room', 'scan-002': 'Master Bedroom'});
        expect(json['fileSizeBytes'], 45000000);
        expect(json['createdAt'], isNotNull);
        expect(json['format'], 'glb');
        expect(json['metadata'], {'polygonCount': 450000, 'textureCount': 12});
      });

      test('toJson() handles null optional fields', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          fileSizeBytes: 40000000,
          createdAt: DateTime.now(),
        );

        final json = model.toJson();

        expect(json['id'], 'job-001');
        expect(json['roomNames'], isNull);
        expect(json['metadata'], isNull);
        expect(json['format'], 'glb'); // Default value
      });

      test('fromJson() deserializes correctly', () {
        final json = {
          'id': 'job-001',
          'localPath': '/Documents/scans/stitched-001.glb',
          'originalScanIds': ['scan-001', 'scan-002', 'scan-003'],
          'roomNames': {
            'scan-001': 'Living Room',
            'scan-002': 'Kitchen',
            'scan-003': 'Dining Room',
          },
          'fileSizeBytes': 60000000,
          'createdAt': '2025-01-01T12:00:00.000Z',
          'format': 'glb',
          'metadata': {'polygonCount': 600000},
        };

        final model = StitchedModel.fromJson(json);

        expect(model.id, 'job-001');
        expect(model.localPath, '/Documents/scans/stitched-001.glb');
        expect(model.originalScanIds, ['scan-001', 'scan-002', 'scan-003']);
        expect(model.roomNames, {'scan-001': 'Living Room', 'scan-002': 'Kitchen', 'scan-003': 'Dining Room'});
        expect(model.fileSizeBytes, 60000000);
        expect(model.format, 'glb');
        expect(model.metadata, {'polygonCount': 600000});
      });
    });

    group('File size formatting', () {
      test('typical stitched model is 20-100 MB', () {
        final smallModel = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          fileSizeBytes: 20000000, // 20 MB
          createdAt: DateTime.now(),
        );

        final largeModel = StitchedModel(
          id: 'job-002',
          localPath: '/Documents/scans/stitched-002.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003', 'scan-004', 'scan-005'],
          fileSizeBytes: 100000000, // 100 MB
          createdAt: DateTime.now(),
        );

        expect(smallModel.fileSizeBytes, 20000000);
        expect(largeModel.fileSizeBytes, 100000000);
      });
    });

    group('thumbnailPath getter', () {
      test('returns null (placeholder for future enhancement)', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
        );

        expect(model.thumbnailPath, isNull);
      });
    });

    group('Edge cases', () {
      test('handles very long room names in displayName', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          roomNames: {
            'scan-001': 'Master Bedroom with Walk-in Closet and Ensuite Bathroom',
            'scan-002': 'Living Room with Dining Area and Kitchen',
          },
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
        );

        // Should still show both names joined with +
        expect(model.displayName, contains('Master Bedroom with Walk-in Closet and Ensuite Bathroom'));
        expect(model.displayName, contains('Living Room with Dining Area and Kitchen'));
        expect(model.displayName, contains(' + '));
      });

      test('handles single room stitching (edge case)', () {
        // Although minimum is 2 scans, test handles 1 scan gracefully
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: ['scan-001'],
          roomNames: {'scan-001': 'Living Room'},
          fileSizeBytes: 20000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, 'Living Room');
      });

      test('handles empty originalScanIds list gracefully', () {
        final model = StitchedModel(
          id: 'job-001',
          localPath: '/Documents/scans/stitched-001.glb',
          originalScanIds: [],
          fileSizeBytes: 20000000,
          createdAt: DateTime.now(),
        );

        expect(model.displayName, '0 rooms stitched');
      });
    });
  });
}
