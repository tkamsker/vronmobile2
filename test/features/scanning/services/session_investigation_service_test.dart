import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/services/session_investigation_service.dart';
import 'dart:convert';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late SessionInvestigationService service;
  late MockHttpClient mockClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = SessionInvestigationService(
      client: mockClient,
      baseUrl: 'https://api.example.com',
    );
  });

  group('SessionInvestigationService - investigate success', () {
    test('should return SessionDiagnostics on successful API call', () async {
      // Arrange
      const sessionId = 'sess_ABC123';
      final responseJson = {
        'session_id': sessionId,
        'session_status': 'completed',
        'created_at': '2025-12-30T12:00:00Z',
        'expires_at': '2025-12-30T13:00:00Z',
        'last_accessed': '2025-12-30T12:30:00Z',
        'workspace_exists': true,
        'files': {
          'directories': {
            'output': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'scan.glb',
                  'size_bytes': 2345678,
                  'modified_at': '2025-12-30T12:05:00Z',
                },
              ],
            },
          },
          'root_files': [],
        },
        'status_data': null,
        'metadata': {'filename': 'scan.glb', 'size_bytes': 2345678},
        'parameters': {'job_type': 'usdz_to_glb'},
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': '2025-12-30T12:30:00Z',
      };

      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      // Act
      final result = await service.investigate(sessionId);

      // Assert
      expect(result.sessionId, sessionId);
      expect(result.sessionStatus, 'completed');
      expect(result.workspaceExists, true);
      expect(result.files, isNotNull);
      expect(result.files!.directories['output']!.exists, true);
    });

    test('should handle failed session with error details', () async {
      // Arrange
      const sessionId = 'sess_FAILED';
      final responseJson = {
        'session_id': sessionId,
        'session_status': 'failed',
        'created_at': '2025-12-30T11:00:00Z',
        'expires_at': '2025-12-30T12:00:00Z',
        'last_accessed': '2025-12-30T11:05:00Z',
        'workspace_exists': true,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': {
          'error_message': 'Failed to load USDZ',
          'error_code': 'malformed_usdz',
          'processing_stage': 'upload_validation',
          'failed_at': '2025-12-30T11:03:00Z',
          'blender_exit_code': 1,
          'last_error_logs': ['ERROR: Invalid geometry data'],
        },
        'investigation_timestamp': '2025-12-30T11:10:00Z',
      };

      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      // Act
      final result = await service.investigate(sessionId);

      // Assert
      expect(result.sessionStatus, 'failed');
      expect(result.errorDetails, isNotNull);
      expect(result.errorDetails!.errorCode, 'malformed_usdz');
      expect(result.errorDetails!.blenderExitCode, 1);
    });

    test('should include authorization header in request', () async {
      // Arrange
      const sessionId = 'sess_TEST';
      const token = 'test_token_123';
      final responseJson = {
        'session_id': sessionId,
        'session_status': 'active',
        'created_at': '2025-12-30T12:00:00Z',
        'expires_at': '2025-12-30T13:00:00Z',
        'last_accessed': null,
        'workspace_exists': false,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': '2025-12-30T12:00:00Z',
      };

      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      // Act
      await service.investigate(sessionId, authToken: token);

      // Assert
      verify(
        () => mockClient.get(
          any(),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      ).called(1);
    });
  });

  group('SessionInvestigationService - error handling', () {
    test('should throw exception for 404 Not Found', () async {
      // Arrange
      const sessionId = 'sess_NOTFOUND';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(json.encode({'error': 'Session not found'}), 404),
      );

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.statusCode == 404 &&
                e.message.contains('not found'),
          ),
        ),
      );
    });

    test('should throw exception for 401 Unauthorized', () async {
      // Arrange
      const sessionId = 'sess_UNAUTH';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(json.encode({'error': 'Unauthorized'}), 401),
      );

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.statusCode == 401 &&
                e.message.contains('Unauthorized'),
          ),
        ),
      );
    });

    test('should throw exception for 429 Rate Limit', () async {
      // Arrange
      const sessionId = 'sess_RATELIMIT';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(json.encode({'error': 'Rate limit exceeded'}), 429),
      );

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.statusCode == 429 &&
                e.message.contains('Rate limit'),
          ),
        ),
      );
    });

    test('should throw exception for 500 Server Error', () async {
      // Arrange
      const sessionId = 'sess_ERROR';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(json.encode({'error': 'Internal server error'}), 500),
      );

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.statusCode == 500 &&
                e.message.contains('Server error'),
          ),
        ),
      );
    });

    test('should throw exception for network timeout', () async {
      // Arrange
      const sessionId = 'sess_TIMEOUT';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) => Future.error(http.ClientException('Connection timeout')),
      );

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.message.contains('timeout'),
          ),
        ),
      );
    });

    test('should throw exception for invalid JSON response', () async {
      // Arrange
      const sessionId = 'sess_BADJSON';
      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Invalid JSON {', 200));

      // Act & Assert
      expect(
        () => service.investigate(sessionId),
        throwsA(
          predicate(
            (e) =>
                e is SessionInvestigationException &&
                e.message.contains('Invalid response'),
          ),
        ),
      );
    });
  });
}
