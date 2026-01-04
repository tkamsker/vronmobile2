import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/services/combined_scan_service.dart';
import 'package:vronmobile2/features/scanning/services/usdz_combiner_service.dart';
import 'package:vronmobile2/features/scanning/services/blenderapi_service.dart';

// Generate mocks: flutter pub run build_runner build
@GenerateMocks([USDZCombinerService, BlenderAPIService])
import 'combined_scan_service_test.mocks.dart';

/// Test suite for CombinedScanService (orchestration layer)
/// Feature 018: Combined Scan to NavMesh Workflow
/// Tests: T021, T022
void main() {
  group('CombinedScanService', () {
    late CombinedScanService service;
    late MockUSDZCombinerService mockCombiner;
    late MockBlenderAPIService mockBlenderAPI;

    setUp(() {
      mockCombiner = MockUSDZCombinerService();
      mockBlenderAPI = MockBlenderAPIService();
      service = CombinedScanService(
        combiner: mockCombiner,
        blenderAPI: mockBlenderAPI,
      );
    });

    group('T021: createCombinedScan orchestration', () {
      test('should orchestrate full combine workflow successfully', () async {
        // Given: Multiple scans with positions
        final scans = [
          ScanData(
            id: 'scan-1',
            format: ScanFormat.usdz,
            localPath: '/path/to/scan1.usdz',
            fileSizeBytes: 5242880,
            capturedAt: DateTime(2026, 1, 4, 10, 0),
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
            capturedAt: DateTime(2026, 1, 4, 10, 5),
            status: ScanStatus.completed,
            projectId: 'project-1',
            positionX: 150.0,
            positionY: 0.0,
            rotationDegrees: 90.0,
            scaleFactor: 1.0,
          ),
        ];

        const projectId = 'project-1';
        const documentsDir = '/Users/test/Documents';

        // And: Mock successful USDZ combination
        when(mockCombiner.combineScans(
          scans: anyNamed('scans'),
          outputPath: anyNamed('outputPath'),
        )).thenAnswer((_) async => '/path/to/combined_scan.usdz');

        // When: Creating combined scan
        final combinedScan = await service.createCombinedScan(
          projectId: projectId,
          scans: scans,
          documentsDirectory: documentsDir,
        );

        // Then: Should return CombinedScan with correct initial state
        expect(combinedScan.id, isNotEmpty);
        expect(combinedScan.projectId, projectId);
        expect(combinedScan.scanIds, ['scan-1', 'scan-2']);
        expect(combinedScan.localCombinedPath, '/path/to/combined_scan.usdz');
        expect(combinedScan.status, CombinedScanStatus.combining);
        expect(combinedScan.createdAt, isA<DateTime>());

        // And: Should have called combiner service
        verify(mockCombiner.combineScans(
          scans: scans,
          outputPath: anyNamed('outputPath'),
        )).called(1);
      });

      test('should update status throughout workflow', () async {
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

        // And: Track status changes
        final statusChanges = <CombinedScanStatus>[];

        // And: Mock successful combination
        when(mockCombiner.combineScans(
          scans: anyNamed('scans'),
          outputPath: anyNamed('outputPath'),
        )).thenAnswer((_) async => '/path/to/combined_scan.usdz');

        // When: Creating combined scan with status callback
        await service.createCombinedScan(
          projectId: 'project-1',
          scans: scans,
          documentsDirectory: '/tmp',
          onStatusChange: (status) {
            statusChanges.add(status);
          },
        );

        // Then: Should report status changes
        expect(statusChanges, isNotEmpty);
        expect(statusChanges.first, CombinedScanStatus.combining);
      });

      test('should handle combination failure', () async {
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

        // And: Mock combination failure
        when(mockCombiner.combineScans(
          scans: anyNamed('scans'),
          outputPath: anyNamed('outputPath'),
        )).thenThrow(Exception('Failed to load USDZ'));

        // When/Then: Should throw exception
        expect(
          () => service.createCombinedScan(
            projectId: 'project-1',
            scans: scans,
            documentsDirectory: '/tmp',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate minimum scan count', () async {
        // Given: Only 1 scan
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

        // When/Then: Should throw ArgumentError
        expect(
          () => service.createCombinedScan(
            projectId: 'project-1',
            scans: scans,
            documentsDirectory: '/tmp',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('T022: generateNavmesh complete workflow', () {
      test('should orchestrate full BlenderAPI navmesh workflow', () async {
        // Given: CombinedScan ready for navmesh generation
        final combinedScan = CombinedScan(
          id: 'combined-1',
          projectId: 'project-1',
          scanIds: ['scan-1', 'scan-2'],
          localCombinedPath: '/path/to/combined_scan.usdz',
          combinedGlbUrl: 'https://api.example.com/combined.glb',
          combinedGlbLocalPath: '/path/to/combined.glb',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime(2026, 1, 4, 10, 0),
        );

        // And: Mock BlenderAPI success responses (6-step workflow)
        // Step 1: Create session
        when(mockBlenderAPI.createSession())
            .thenAnswer((_) async => 'session-abc-123');

        // Step 2: Upload GLB
        when(mockBlenderAPI.uploadGLB(
          sessionId: anyNamed('sessionId'),
          glbFile: anyNamed('glbFile'),
          onProgress: anyNamed('onProgress'),
        )).thenAnswer((_) async => {});

        // Step 3: Start navmesh generation
        when(mockBlenderAPI.startNavMeshGeneration(
          sessionId: anyNamed('sessionId'),
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: anyNamed('navmeshParams'),
        )).thenAnswer((_) async => {});

        // Step 4: Poll status
        when(mockBlenderAPI.pollStatus(
          sessionId: anyNamed('sessionId'),
          pollingInterval: anyNamed('pollingInterval'),
          maxAttempts: anyNamed('maxAttempts'),
        )).thenAnswer((_) async => 'COMPLETED');

        // Step 5: Download navmesh
        when(mockBlenderAPI.downloadNavMesh(
          sessionId: anyNamed('sessionId'),
          filename: anyNamed('filename'),
          outputPath: anyNamed('outputPath'),
        )).thenAnswer((_) async => {});

        // Step 6: Delete session
        when(mockBlenderAPI.deleteSession(
          sessionId: anyNamed('sessionId'),
        )).thenAnswer((_) async => {});

        // When: Generating navmesh
        final updatedScan = await service.generateNavmesh(
          combinedScan: combinedScan,
          documentsDirectory: '/tmp',
        );

        // Then: Should have completed all 6 steps
        verify(mockBlenderAPI.createSession()).called(1);
        verify(mockBlenderAPI.uploadGLB(
          sessionId: 'session-abc-123',
          glbFile: anyNamed('glbFile'),
          onProgress: anyNamed('onProgress'),
        )).called(1);
        verify(mockBlenderAPI.startNavMeshGeneration(
          sessionId: 'session-abc-123',
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: anyNamed('navmeshParams'),
        )).called(1);
        verify(mockBlenderAPI.pollStatus(
          sessionId: 'session-abc-123',
          pollingInterval: anyNamed('pollingInterval'),
          maxAttempts: anyNamed('maxAttempts'),
        )).called(1);
        verify(mockBlenderAPI.downloadNavMesh(
          sessionId: 'session-abc-123',
          filename: anyNamed('filename'),
          outputPath: anyNamed('outputPath'),
        )).called(1);
        verify(mockBlenderAPI.deleteSession(
          sessionId: 'session-abc-123',
        )).called(1);

        // And: Should update CombinedScan with navmesh data
        expect(updatedScan.status, CombinedScanStatus.completed);
        expect(updatedScan.navmeshSessionId, 'session-abc-123');
        expect(updatedScan.localNavmeshPath, isNotEmpty);
        expect(updatedScan.completedAt, isNotNull);
      });

      test('should track status through all navmesh generation phases', () async {
        // Given: CombinedScan ready for navmesh
        final combinedScan = CombinedScan(
          id: 'combined-1',
          projectId: 'project-1',
          scanIds: ['scan-1', 'scan-2'],
          localCombinedPath: '/path/to/combined_scan.usdz',
          combinedGlbUrl: 'https://api.example.com/combined.glb',
          combinedGlbLocalPath: '/path/to/combined.glb',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime(2026, 1, 4, 10, 0),
        );

        // And: Track status changes
        final statusChanges = <CombinedScanStatus>[];

        // And: Mock successful workflow
        when(mockBlenderAPI.createSession()).thenAnswer((_) async => 'session-123');
        when(mockBlenderAPI.uploadGLB(
          sessionId: anyNamed('sessionId'),
          glbFile: anyNamed('glbFile'),
          onProgress: anyNamed('onProgress'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.startNavMeshGeneration(
          sessionId: anyNamed('sessionId'),
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: anyNamed('navmeshParams'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.pollStatus(
          sessionId: anyNamed('sessionId'),
          pollingInterval: anyNamed('pollingInterval'),
          maxAttempts: anyNamed('maxAttempts'),
        )).thenAnswer((_) async => 'COMPLETED');
        when(mockBlenderAPI.downloadNavMesh(
          sessionId: anyNamed('sessionId'),
          filename: anyNamed('filename'),
          outputPath: anyNamed('outputPath'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.deleteSession(sessionId: anyNamed('sessionId')))
            .thenAnswer((_) async => {});

        // When: Generating with status callback
        await service.generateNavmesh(
          combinedScan: combinedScan,
          documentsDirectory: '/tmp',
          onStatusChange: (status) {
            statusChanges.add(status);
          },
        );

        // Then: Should report status progression
        expect(statusChanges, contains(CombinedScanStatus.uploadingToBlender));
        expect(statusChanges, contains(CombinedScanStatus.generatingNavmesh));
        expect(statusChanges, contains(CombinedScanStatus.downloadingNavmesh));
        expect(statusChanges, contains(CombinedScanStatus.completed));
      });

      test('should use Unity-standard navmesh parameters', () async {
        // Given: CombinedScan ready for navmesh
        final combinedScan = CombinedScan(
          id: 'combined-1',
          projectId: 'project-1',
          scanIds: ['scan-1', 'scan-2'],
          localCombinedPath: '/path/to/combined_scan.usdz',
          combinedGlbUrl: 'https://api.example.com/combined.glb',
          combinedGlbLocalPath: '/path/to/combined.glb',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime.now(),
        );

        // And: Mock successful workflow
        when(mockBlenderAPI.createSession()).thenAnswer((_) async => 'session-123');
        when(mockBlenderAPI.uploadGLB(
          sessionId: anyNamed('sessionId'),
          glbFile: anyNamed('glbFile'),
          onProgress: anyNamed('onProgress'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.startNavMeshGeneration(
          sessionId: anyNamed('sessionId'),
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: anyNamed('navmeshParams'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.pollStatus(
          sessionId: anyNamed('sessionId'),
          pollingInterval: anyNamed('pollingInterval'),
          maxAttempts: anyNamed('maxAttempts'),
        )).thenAnswer((_) async => 'COMPLETED');
        when(mockBlenderAPI.downloadNavMesh(
          sessionId: anyNamed('sessionId'),
          filename: anyNamed('filename'),
          outputPath: anyNamed('outputPath'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.deleteSession(sessionId: anyNamed('sessionId')))
            .thenAnswer((_) async => {});

        // When: Generating navmesh
        await service.generateNavmesh(
          combinedScan: combinedScan,
          documentsDirectory: '/tmp',
        );

        // Then: Should pass Unity-standard parameters
        final captured = verify(mockBlenderAPI.startNavMeshGeneration(
          sessionId: anyNamed('sessionId'),
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: captureAnyNamed('navmeshParams'),
        )).captured;

        final params = captured[0] as Map<String, dynamic>;
        expect(params['cell_size'], 0.3);
        expect(params['cell_height'], 0.2);
        expect(params['agent_height'], 2.0);
        expect(params['agent_radius'], 0.6);
        expect(params['agent_max_climb'], 0.9);
        expect(params['agent_max_slope'], 45.0);
      });

      test('should cleanup session even if download fails', () async {
        // Given: CombinedScan ready for navmesh
        final combinedScan = CombinedScan(
          id: 'combined-1',
          projectId: 'project-1',
          scanIds: ['scan-1', 'scan-2'],
          localCombinedPath: '/path/to/combined_scan.usdz',
          combinedGlbUrl: 'https://api.example.com/combined.glb',
          combinedGlbLocalPath: '/path/to/combined.glb',
          status: CombinedScanStatus.glbReady,
          createdAt: DateTime.now(),
        );

        // And: Mock workflow with download failure
        when(mockBlenderAPI.createSession()).thenAnswer((_) async => 'session-123');
        when(mockBlenderAPI.uploadGLB(
          sessionId: anyNamed('sessionId'),
          glbFile: anyNamed('glbFile'),
          onProgress: anyNamed('onProgress'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.startNavMeshGeneration(
          sessionId: anyNamed('sessionId'),
          inputFilename: anyNamed('inputFilename'),
          outputFilename: anyNamed('outputFilename'),
          navmeshParams: anyNamed('navmeshParams'),
        )).thenAnswer((_) async => {});
        when(mockBlenderAPI.pollStatus(
          sessionId: anyNamed('sessionId'),
          pollingInterval: anyNamed('pollingInterval'),
          maxAttempts: anyNamed('maxAttempts'),
        )).thenAnswer((_) async => 'COMPLETED');
        when(mockBlenderAPI.downloadNavMesh(
          sessionId: anyNamed('sessionId'),
          filename: anyNamed('filename'),
          outputPath: anyNamed('outputPath'),
        )).thenThrow(Exception('Network error'));
        when(mockBlenderAPI.deleteSession(sessionId: anyNamed('sessionId')))
            .thenAnswer((_) async => {});

        // When: Attempting to generate navmesh
        try {
          await service.generateNavmesh(
            combinedScan: combinedScan,
            documentsDirectory: '/tmp',
          );
          fail('Should have thrown exception');
        } catch (e) {
          // Expected
        }

        // Then: Should still cleanup session
        verify(mockBlenderAPI.deleteSession(sessionId: 'session-123')).called(1);
      });
    });
  });
}
