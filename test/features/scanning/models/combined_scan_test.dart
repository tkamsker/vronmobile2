import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';

/// Test suite for CombinedScan model
/// Feature 018: Combined Scan to NavMesh Workflow
/// Test: T023
void main() {
  group('CombinedScan Model', () {
    group('Constructor and Validation', () {
      test('should create CombinedScan with valid data', () {
        // Given: Valid data
        final createdAt = DateTime(2026, 1, 4, 10, 0);

        // When: Creating CombinedScan
        final scan = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          status: CombinedScanStatus.combining,
          createdAt: createdAt,
        );

        // Then: Should have correct values
        expect(scan.id, 'scan-1');
        expect(scan.projectId, 'project-1');
        expect(scan.scanIds, ['scan-a', 'scan-b']);
        expect(scan.localCombinedPath, '/path/to/combined.usdz');
        expect(scan.status, CombinedScanStatus.combining);
        expect(scan.createdAt, createdAt);
        expect(scan.completedAt, isNull);
        expect(scan.errorMessage, isNull);
      });

      test('should throw error when scanIds has less than 2 items', () {
        // Given: Invalid data (only 1 scan)
        // When/Then: Should throw ArgumentError
        expect(
          () => CombinedScan(
            id: 'scan-1',
            projectId: 'project-1',
            scanIds: ['scan-a'], // Only 1 scan - invalid
            localCombinedPath: '/path/to/combined.usdz',
            createdAt: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error when completedAt is before createdAt', () {
        // Given: Invalid timestamps
        final createdAt = DateTime(2026, 1, 4, 10, 0);
        final completedAt = DateTime(2026, 1, 4, 9, 0); // Before createdAt

        // When/Then: Should throw ArgumentError
        expect(
          () => CombinedScan(
            id: 'scan-1',
            projectId: 'project-1',
            scanIds: ['scan-a', 'scan-b'],
            localCombinedPath: '/path/to/combined.usdz',
            createdAt: createdAt,
            completedAt: completedAt, // Invalid
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error when status is failed without errorMessage', () {
        // Given: Failed status without error message
        // When/Then: Should throw ArgumentError
        expect(
          () => CombinedScan(
            id: 'scan-1',
            projectId: 'project-1',
            scanIds: ['scan-a', 'scan-b'],
            localCombinedPath: '/path/to/combined.usdz',
            status: CombinedScanStatus.failed,
            createdAt: DateTime.now(),
            // Missing errorMessage - invalid
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        // Given: CombinedScan instance
        final createdAt = DateTime(2026, 1, 4, 10, 0);
        final scan = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b', 'scan-c'],
          localCombinedPath: '/path/to/combined.usdz',
          combinedGlbUrl: 'https://api.example.com/combined.glb',
          combinedGlbLocalPath: '/path/to/combined.glb',
          navmeshSessionId: 'session-123',
          navmeshUrl: 'https://api.example.com/navmesh.glb',
          localNavmeshPath: '/path/to/navmesh.glb',
          status: CombinedScanStatus.completed,
          createdAt: createdAt,
          completedAt: createdAt.add(Duration(minutes: 5)),
        );

        // When: Serializing to JSON
        final json = scan.toJson();

        // Then: Should have correct JSON structure
        expect(json['id'], 'scan-1');
        expect(json['projectId'], 'project-1');
        expect(json['scanIds'], ['scan-a', 'scan-b', 'scan-c']);
        expect(json['localCombinedPath'], '/path/to/combined.usdz');
        expect(json['combinedGlbUrl'], 'https://api.example.com/combined.glb');
        expect(json['combinedGlbLocalPath'], '/path/to/combined.glb');
        expect(json['navmeshSessionId'], 'session-123');
        expect(json['navmeshUrl'], 'https://api.example.com/navmesh.glb');
        expect(json['localNavmeshPath'], '/path/to/navmesh.glb');
        expect(json['status'], 'completed');
        expect(json['createdAt'], createdAt.toIso8601String());
        expect(json['completedAt'], isA<String>());
      });

      test('should deserialize from JSON correctly', () {
        // Given: JSON data
        final json = {
          'id': 'scan-2',
          'projectId': 'project-2',
          'scanIds': ['scan-d', 'scan-e'],
          'localCombinedPath': '/path/to/combined2.usdz',
          'combinedGlbUrl': 'https://api.example.com/combined2.glb',
          'combinedGlbLocalPath': null,
          'navmeshSessionId': null,
          'navmeshUrl': null,
          'localNavmeshPath': null,
          'status': 'glbReady',
          'createdAt': '2026-01-04T10:00:00.000Z',
          'completedAt': null,
          'errorMessage': null,
        };

        // When: Deserializing from JSON
        final scan = CombinedScan.fromJson(json);

        // Then: Should have correct values
        expect(scan.id, 'scan-2');
        expect(scan.projectId, 'project-2');
        expect(scan.scanIds, ['scan-d', 'scan-e']);
        expect(scan.localCombinedPath, '/path/to/combined2.usdz');
        expect(scan.combinedGlbUrl, 'https://api.example.com/combined2.glb');
        expect(scan.status, CombinedScanStatus.glbReady);
        expect(scan.completedAt, isNull);
      });

      test('should roundtrip serialize/deserialize', () {
        // Given: Original CombinedScan
        final original = CombinedScan(
          id: 'scan-3',
          projectId: 'project-3',
          scanIds: ['scan-f', 'scan-g', 'scan-h'],
          localCombinedPath: '/path/to/combined3.usdz',
          status: CombinedScanStatus.uploadingToBlender,
          createdAt: DateTime(2026, 1, 4, 12, 0),
        );

        // When: Serialize then deserialize
        final json = original.toJson();
        final deserialized = CombinedScan.fromJson(json);

        // Then: Should be equivalent
        expect(deserialized.id, original.id);
        expect(deserialized.projectId, original.projectId);
        expect(deserialized.scanIds, original.scanIds);
        expect(deserialized.localCombinedPath, original.localCombinedPath);
        expect(deserialized.status, original.status);
        expect(deserialized.createdAt, original.createdAt);
      });
    });

    group('copyWith', () {
      test('should copy with updated status', () {
        // Given: Original scan
        final original = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          status: CombinedScanStatus.combining,
          createdAt: DateTime(2026, 1, 4, 10, 0),
        );

        // When: Copying with updated status
        final updated = original.copyWith(
          status: CombinedScanStatus.uploadingUsdz,
        );

        // Then: Should have new status, same other fields
        expect(updated.status, CombinedScanStatus.uploadingUsdz);
        expect(updated.id, original.id);
        expect(updated.projectId, original.projectId);
        expect(updated.scanIds, original.scanIds);
      });

      test('should copy with multiple updated fields', () {
        // Given: Original scan
        final original = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime(2026, 1, 4, 10, 0),
        );

        // When: Copying with multiple updates
        final completedAt = DateTime(2026, 1, 4, 10, 5);
        final updated = original.copyWith(
          status: CombinedScanStatus.completed,
          navmeshUrl: 'https://api.example.com/navmesh.glb',
          localNavmeshPath: '/path/to/navmesh.glb',
          completedAt: completedAt,
        );

        // Then: Should have all updates
        expect(updated.status, CombinedScanStatus.completed);
        expect(updated.navmeshUrl, 'https://api.example.com/navmesh.glb');
        expect(updated.localNavmeshPath, '/path/to/navmesh.glb');
        expect(updated.completedAt, completedAt);
      });
    });

    group('Helper Methods', () {
      test('isInProgress should return true for in-progress statuses', () {
        final statuses = [
          CombinedScanStatus.combining,
          CombinedScanStatus.uploadingUsdz,
          CombinedScanStatus.processingGlb,
          CombinedScanStatus.glbReady,
          CombinedScanStatus.uploadingToBlender,
          CombinedScanStatus.generatingNavmesh,
          CombinedScanStatus.downloadingNavmesh,
        ];

        for (final status in statuses) {
          final scan = CombinedScan(
            id: 'scan-1',
            projectId: 'project-1',
            scanIds: ['scan-a', 'scan-b'],
            localCombinedPath: '/path/to/combined.usdz',
            status: status,
            createdAt: DateTime.now(),
          );

          expect(scan.isInProgress(), isTrue, reason: 'Status $status should be in progress');
        }
      });

      test('isInProgress should return false for terminal statuses', () {
        final terminalStatuses = [
          CombinedScanStatus.completed,
          CombinedScanStatus.failed,
        ];

        for (final status in terminalStatuses) {
          final scan = CombinedScan(
            id: 'scan-1',
            projectId: 'project-1',
            scanIds: ['scan-a', 'scan-b'],
            localCombinedPath: '/path/to/combined.usdz',
            status: status,
            createdAt: DateTime.now(),
            errorMessage: status == CombinedScanStatus.failed ? 'Error' : null,
          );

          expect(scan.isInProgress(), isFalse, reason: 'Status $status should not be in progress');
        }
      });

      test('canGenerateNavmesh should return true only for glbReady status', () {
        // Given: Scan with glbReady status
        final readyScan = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime.now(),
        );

        // Then: Should be able to generate navmesh
        expect(readyScan.canGenerateNavmesh(), isTrue);

        // Given: Scan with other status
        final otherScan = readyScan.copyWith(
          status: CombinedScanStatus.uploadingUsdz,
        );

        // Then: Should not be able to generate navmesh
        expect(otherScan.canGenerateNavmesh(), isFalse);
      });

      test('hasGlb should return true when combinedGlbUrl is set', () {
        // Given: Scan without GLB
        final noGlb = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          createdAt: DateTime.now(),
        );

        // Then: Should not have GLB
        expect(noGlb.hasGlb(), isFalse);

        // Given: Scan with GLB
        final withGlb = noGlb.copyWith(
          combinedGlbUrl: 'https://api.example.com/combined.glb',
        );

        // Then: Should have GLB
        expect(withGlb.hasGlb(), isTrue);
      });

      test('hasNavmesh should return true when both navmeshUrl and localNavmeshPath are set', () {
        // Given: Scan without navmesh
        final noNavmesh = CombinedScan(
          id: 'scan-1',
          projectId: 'project-1',
          scanIds: ['scan-a', 'scan-b'],
          localCombinedPath: '/path/to/combined.usdz',
          createdAt: DateTime.now(),
        );

        // Then: Should not have navmesh
        expect(noNavmesh.hasNavmesh(), isFalse);

        // Given: Scan with only URL
        final onlyUrl = noNavmesh.copyWith(
          navmeshUrl: 'https://api.example.com/navmesh.glb',
        );

        // Then: Should not have navmesh (missing local path)
        expect(onlyUrl.hasNavmesh(), isFalse);

        // Given: Scan with both URL and local path
        final withNavmesh = onlyUrl.copyWith(
          localNavmeshPath: '/path/to/navmesh.glb',
        );

        // Then: Should have navmesh
        expect(withNavmesh.hasNavmesh(), isTrue);
      });
    });
  });
}
