import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vronmobile2/features/scanning/services/blenderapi_service.dart';

// Generate mocks: flutter pub run build_runner build
@GenerateMocks([http.Client])
import 'blenderapi_service_test.mocks.dart';

/// Test suite for BlenderAPIService (REST API client)
/// Feature 018: Combined Scan to NavMesh Workflow
/// Tests: T016, T017, T018, T019, T020
void main() {
  group('BlenderAPIService', () {
    late BlenderAPIService service;
    late MockClient mockClient;

    const baseUrl = 'https://blenderapi.stage.motorenflug.at';
    const apiKey = 'test-api-key-1234567890';

    setUp(() {
      mockClient = MockClient();
      service = BlenderAPIService(
        baseUrl: baseUrl,
        apiKey: apiKey,
        client: mockClient,
      );
    });

    group('T016: createSession', () {
      test('should create session and return session ID', () async {
        // Given: Mock successful response
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              '{"session_id": "session-abc-123"}',
              201,
            ));

        // When: Creating session
        final sessionId = await service.createSession();

        // Then: Should return session ID
        expect(sessionId, 'session-abc-123');

        // And: Should include API key in headers
        verify(mockClient.post(
          Uri.parse('$baseUrl/sessions'),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
          },
        )).called(1);
      });

      test('should throw exception on session creation failure', () async {
        // Given: Mock error response
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              '{"error": "Service unavailable"}',
              503,
            ));

        // When/Then: Should throw exception
        expect(
          () => service.createSession(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('T017: uploadGLB with progress callbacks', () {
      test('should upload GLB file and report progress', () async {
        // Given: Mock file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test.glb')
          ..writeAsBytesSync(List.filled(1024 * 1024, 0)); // 1MB file

        // And: Progress tracking
        final progressValues = <double>[];

        // And: Mock successful upload response
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/upload'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              '{"filename": "test.glb", "size": 1048576}',
              200,
            ));

        // When: Uploading with progress callback
        await service.uploadGLB(
          sessionId: 'session-123',
          glbFile: testFile,
          onProgress: (progress) {
            progressValues.add(progress);
          },
        );

        // Then: Should call upload endpoint
        verify(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/upload'),
          headers: {
            'X-API-Key': apiKey,
            'Content-Type': 'application/octet-stream',
          },
          body: anyNamed('body'),
        )).called(1);

        // And: Should report progress (at least start and end)
        expect(progressValues, isNotEmpty);
        expect(progressValues.last, closeTo(1.0, 0.1)); // Should reach ~100%

        // Cleanup
        tempDir.deleteSync(recursive: true);
      });

      test('should throw exception when file does not exist', () async {
        // Given: Non-existent file
        final nonExistentFile = File('/path/that/does/not/exist.glb');

        // When/Then: Should throw exception
        expect(
          () => service.uploadGLB(
            sessionId: 'session-123',
            glbFile: nonExistentFile,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle upload failure with error response', () async {
        // Given: Valid file
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test.glb')
          ..writeAsBytesSync(List.filled(1024, 0));

        // And: Mock 413 Payload Too Large error
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/upload'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              '{"error": "File too large"}',
              413,
            ));

        // When/Then: Should throw exception
        expect(
          () => service.uploadGLB(
            sessionId: 'session-123',
            glbFile: testFile,
          ),
          throwsA(isA<Exception>()),
        );

        // Cleanup
        tempDir.deleteSync(recursive: true);
      });
    });

    group('T018: startNavMeshGeneration with parameters', () {
      test('should start navmesh generation with correct parameters', () async {
        // Given: Navmesh parameters
        final params = {
          'cell_size': 0.3,
          'cell_height': 0.2,
          'agent_height': 2.0,
          'agent_radius': 0.6,
          'agent_max_climb': 0.9,
          'agent_max_slope': 45.0,
        };

        // And: Mock successful response
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/navmesh'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              '{"job_id": "job-456", "status": "PROCESSING"}',
              200,
            ));

        // When: Starting navmesh generation
        await service.startNavMeshGeneration(
          sessionId: 'session-123',
          inputFilename: 'combined_scan.glb',
          outputFilename: 'navmesh_combined_scan.glb',
          navmeshParams: params,
        );

        // Then: Should call navmesh endpoint with parameters
        final captured = verify(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/navmesh'),
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        // Verify headers
        expect(captured[0], containsPair('Content-Type', 'application/json'));
        expect(captured[0], containsPair('X-API-Key', apiKey));

        // Verify body contains parameters
        final body = captured[1] as String;
        expect(body, contains('cell_size'));
        expect(body, contains('0.3'));
        expect(body, contains('agent_height'));
        expect(body, contains('2.0'));
      });

      test('should use Unity-standard defaults when no parameters provided', () async {
        // Given: Mock successful response
        when(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/navmesh'),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
              '{"job_id": "job-456", "status": "PROCESSING"}',
              200,
            ));

        // When: Starting navmesh without explicit parameters
        await service.startNavMeshGeneration(
          sessionId: 'session-123',
          inputFilename: 'combined_scan.glb',
          outputFilename: 'navmesh_combined_scan.glb',
          // No navmeshParams - should use defaults
        );

        // Then: Should use Unity-standard defaults
        final captured = verify(mockClient.post(
          Uri.parse('$baseUrl/sessions/session-123/navmesh'),
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        final body = captured[1] as String;
        expect(body, contains('0.3')); // cell_size default
        expect(body, contains('2.0')); // agent_height default
      });
    });

    group('T019: pollStatus until completed', () {
      test('should poll status and return when completed', () async {
        // Given: Mock responses (processing → completed)
        var callCount = 0;
        when(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/status'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async {
          callCount++;
          if (callCount < 3) {
            // First 2 calls: still processing
            return http.Response(
              '{"status": "PROCESSING", "progress": ${callCount * 30}}',
              200,
            );
          } else {
            // 3rd call: completed
            return http.Response(
              '{"status": "COMPLETED", "available_files": ["navmesh_combined_scan.glb"]}',
              200,
            );
          }
        });

        // When: Polling status
        final status = await service.pollStatus(
          sessionId: 'session-123',
          pollingInterval: Duration(milliseconds: 100),
        );

        // Then: Should eventually return COMPLETED
        expect(status, 'COMPLETED');

        // And: Should have polled multiple times
        expect(callCount, greaterThanOrEqualTo(3));
      });

      test('should throw exception when status is FAILED', () async {
        // Given: Mock failed response
        when(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/status'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              '{"status": "FAILED", "error": "INVALID_GEOMETRY"}',
              200,
            ));

        // When/Then: Should throw exception
        expect(
          () => service.pollStatus(
            sessionId: 'session-123',
            pollingInterval: Duration(milliseconds: 100),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should timeout after maximum polling attempts', () async {
        // Given: Mock response that never completes
        when(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/status'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              '{"status": "PROCESSING", "progress": 50}',
              200,
            ));

        // When/Then: Should throw timeout exception
        expect(
          () => service.pollStatus(
            sessionId: 'session-123',
            pollingInterval: Duration(milliseconds: 100),
            maxAttempts: 5, // Timeout after 5 attempts
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('T020: downloadNavMesh', () {
      test('should download navmesh file to specified path', () async {
        // Given: Mock navmesh data
        final navmeshData = List.filled(1024 * 512, 42); // 512KB mock data

        // And: Mock successful download
        when(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/download/navmesh_combined_scan.glb'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response.bytes(
              navmeshData,
              200,
            ));

        // And: Output path
        final tempDir = Directory.systemTemp.createTempSync();
        final outputPath = '${tempDir.path}/downloaded_navmesh.glb';

        // When: Downloading navmesh
        await service.downloadNavMesh(
          sessionId: 'session-123',
          filename: 'navmesh_combined_scan.glb',
          outputPath: outputPath,
        );

        // Then: Should download file
        verify(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/download/navmesh_combined_scan.glb'),
          headers: {
            'X-API-Key': apiKey,
          },
        )).called(1);

        // And: Should save to output path
        final downloadedFile = File(outputPath);
        expect(await downloadedFile.exists(), isTrue);
        expect(await downloadedFile.length(), equals(navmeshData.length));

        // Cleanup
        tempDir.deleteSync(recursive: true);
      });

      test('should throw exception on download failure', () async {
        // Given: Mock 404 response
        when(mockClient.get(
          Uri.parse('$baseUrl/sessions/session-123/download/nonexistent.glb'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
              '{"error": "File not found"}',
              404,
            ));

        // When/Then: Should throw exception
        expect(
          () => service.downloadNavMesh(
            sessionId: 'session-123',
            filename: 'nonexistent.glb',
            outputPath: '/tmp/output.glb',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteSession', () {
      test('should delete session successfully', () async {
        // Given: Mock successful delete
        when(mockClient.delete(
          Uri.parse('$baseUrl/sessions/session-123'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 204));

        // When: Deleting session
        await service.deleteSession(sessionId: 'session-123');

        // Then: Should call delete endpoint
        verify(mockClient.delete(
          Uri.parse('$baseUrl/sessions/session-123'),
          headers: {
            'X-API-Key': apiKey,
          },
        )).called(1);
      });

      test('should not throw on delete failure (cleanup best-effort)', () async {
        // Given: Mock 404 response (session already deleted)
        when(mockClient.delete(
          Uri.parse('$baseUrl/sessions/session-123'),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('', 404));

        // When/Then: Should not throw (cleanup is best-effort)
        await expectLater(
          service.deleteSession(sessionId: 'session-123'),
          completes,
        );
      });
    });
  });
}
