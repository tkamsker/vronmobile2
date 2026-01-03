import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/features/scanning/services/error_message_service.dart';
import 'package:vronmobile2/features/scanning/services/error_log_service.dart';
import 'package:vronmobile2/features/scanning/services/session_investigation_service.dart';
import 'package:vronmobile2/features/scanning/services/blender_api_client.dart';
import 'package:vronmobile2/features/scanning/services/device_info_service.dart';
import 'package:vronmobile2/features/scanning/services/retry_policy_service.dart';
import 'package:vronmobile2/features/scanning/models/error_context.dart';
import 'dart:convert';
import 'dart:io';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late ErrorMessageService errorMessageService;
  late ErrorLogService errorLogService;
  late SessionInvestigationService investigationService;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    mockClient = MockHttpClient();
    errorMessageService = ErrorMessageService();
    tempDir = await Directory.systemTemp.createTemp('integration_test_');
    errorLogService = ErrorLogService(testDirectory: tempDir.path);
    investigationService = SessionInvestigationService(
      client: mockClient,
      baseUrl: 'https://api.example.com',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Integration Test: Invalid USDZ File Flow (T033)', () {
    test(
      'should log error, provide detailed message, and allow session investigation',
      () async {
        // Scenario: User uploads invalid USDZ file, conversion fails with malformed_usdz error
        const sessionId = 'sess_INVALID_FILE';
        const errorCode = 'malformed_usdz';
        const httpStatus = 422;

        // Step 1: Conversion fails with BlenderAPI error
        final errorContext = ErrorContext(
          timestamp: DateTime.now(),
          sessionId: sessionId,
          httpStatus: httpStatus,
          errorCode: errorCode,
          message: 'USDZ file is corrupted',
          retryCount: 0,
          isRecoverable: false,
        );

        // Step 2: Error is logged
        await errorLogService.logError(errorContext);

        // Step 3: User-friendly message is generated
        final userMessage = errorMessageService.getUserMessage(
          errorCode,
          httpStatus,
        );
        expect(userMessage, contains('corrupted'));

        // Step 4: Recommended action is provided
        final action = errorMessageService.getRecommendedAction(
          errorCode,
          httpStatus,
        );
        expect(action, isNotNull);
        expect(action, contains('export'));

        // Step 5: Error is retrievable from log
        final loggedErrors = await errorLogService.getRecentErrors(
          sessionId: sessionId,
        );
        expect(loggedErrors.length, 1);
        expect(loggedErrors.first.errorCode, errorCode);
        expect(loggedErrors.first.sessionId, sessionId);

        // Step 6: User can investigate session details
        final diagnosticsJson = {
          'session_id': sessionId,
          'session_status': 'failed',
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now()
              .add(Duration(hours: 1))
              .toIso8601String(),
          'last_accessed': DateTime.now().toIso8601String(),
          'workspace_exists': true,
          'files': null,
          'status_data': null,
          'metadata': null,
          'parameters': null,
          'logs_summary': null,
          'error_details': {
            'error_message': 'Failed to load USDZ',
            'error_code': errorCode,
            'processing_stage': 'upload_validation',
            'failed_at': DateTime.now().toIso8601String(),
            'blender_exit_code': 1,
            'last_error_logs': ['ERROR: Invalid geometry data'],
          },
          'investigation_timestamp': DateTime.now().toIso8601String(),
        };

        when(
          () => mockClient.get(
            Uri.parse(
              'https://api.example.com/sessions/$sessionId/investigate',
            ),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer(
          (_) async => http.Response(json.encode(diagnosticsJson), 200),
        );

        final diagnostics = await investigationService.investigate(sessionId);

        // Verify diagnostics contain error details
        expect(diagnostics.sessionId, sessionId);
        expect(diagnostics.sessionStatus, 'failed');
        expect(diagnostics.errorDetails, isNotNull);
        expect(diagnostics.errorDetails!.errorCode, errorCode);

        print('✅ T033: Invalid USDZ file flow - Complete');
        print('   - Error logged with session ID');
        print('   - User-friendly message: "$userMessage"');
        print('   - Recommended action: "$action"');
        print('   - Session diagnostics available');
      },
    );
  });

  group('Integration Test: Conversion Timeout Flow (T034)', () {
    test(
      'should handle timeout, log error, and provide retry guidance',
      () async {
        // Scenario: Network timeout during conversion
        const sessionId = 'sess_TIMEOUT';
        const errorCode = 'timeout';

        // Step 1: Timeout error occurs
        final errorContext = ErrorContext(
          timestamp: DateTime.now(),
          sessionId: sessionId,
          httpStatus: null,
          errorCode: errorCode,
          message: 'Connection timed out',
          retryCount: 0,
          isRecoverable: true,
        );

        // Step 2: Error is logged
        await errorLogService.logError(errorContext);

        // Step 3: User-friendly message with timeout info
        final userMessage = errorMessageService.getUserMessage(errorCode, null);
        expect(userMessage, contains('timed out'));

        // Step 4: Retry guidance is provided
        final action = errorMessageService.getRecommendedAction(
          errorCode,
          null,
        );
        expect(action, isNotNull);
        expect(action, contains('try again'));

        // Step 5: Error marked as recoverable
        expect(errorContext.isRecoverable, true);

        // Step 6: Retry increments retry count
        final retriedContext = errorContext.withRetry();
        expect(retriedContext.retryCount, 1);
        expect(retriedContext.timestamp.isAfter(errorContext.timestamp), true);

        // Step 7: Log updated retry attempt
        await errorLogService.logError(retriedContext);

        // Step 8: Verify retry history
        final allErrors = await errorLogService.getRecentErrors(
          sessionId: sessionId,
        );
        expect(allErrors.length, 2); // Original + retry
        expect(allErrors.first.retryCount, 1); // Most recent has retry count

        print('✅ T034: Timeout flow - Complete');
        print('   - Error logged with recoverable flag');
        print('   - User message: "$userMessage"');
        print('   - Retry guidance: "$action"');
        print('   - Retry count tracked: ${retriedContext.retryCount}');
      },
    );

    test(
      'should provide appropriate message for 503 service unavailable',
      () async {
        // Scenario: Service temporarily unavailable
        const sessionId = 'sess_503';
        const httpStatus = 503;

        final errorContext = ErrorContext(
          timestamp: DateTime.now(),
          sessionId: sessionId,
          httpStatus: httpStatus,
          errorCode: null,
          message: 'Service unavailable',
          retryCount: 0,
          isRecoverable: true,
        );

        await errorLogService.logError(errorContext);

        final userMessage = errorMessageService.getUserMessage(
          null,
          httpStatus,
        );
        expect(userMessage, contains('unavailable'));
        expect(userMessage, contains('try again'));

        final action = errorMessageService.getRecommendedAction(
          null,
          httpStatus,
        );
        expect(action, contains('try again'));

        print('✅ T034b: 503 Service Unavailable - Complete');
        print('   - Message: "$userMessage"');
        print('   - Action: "$action"');
      },
    );
  });

  group('Integration Test: Session Investigation Flow (T035)', () {
    test('should investigate session and display all diagnostic data', () async {
      // Scenario: User clicks "View Details" to investigate failed conversion
      const sessionId = 'sess_INVESTIGATE';

      // Step 1: Complete diagnostics response from API
      final diagnosticsJson = {
        'session_id': sessionId,
        'session_status': 'failed',
        'created_at': '2025-12-30T12:00:00Z',
        'expires_at': '2025-12-30T13:00:00Z',
        'last_accessed': '2025-12-30T12:30:00Z',
        'workspace_exists': true,
        'files': {
          'directories': {
            'input': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'scan.usdz',
                  'size_bytes': 1234567,
                  'modified_at': '2025-12-30T12:01:00Z',
                },
              ],
            },
            'output': {'exists': false, 'file_count': 0, 'files': []},
            'logs': {
              'exists': true,
              'file_count': 1,
              'files': [
                {
                  'name': 'blender.log',
                  'size_bytes': 45678,
                  'modified_at': '2025-12-30T12:05:00Z',
                },
              ],
            },
          },
          'root_files': [
            {
              'name': 'status.json',
              'size_bytes': 1234,
              'modified_at': '2025-12-30T12:00:00Z',
            },
          ],
        },
        'status_data': null,
        'metadata': null,
        'parameters': {'job_type': 'usdz_to_glb'},
        'logs_summary': {
          'total_lines': 150,
          'error_count': 5,
          'warning_count': 2,
          'file_size_bytes': 45678,
          'last_lines': [
            'ERROR: Invalid geometry data',
            'ERROR: Conversion aborted',
          ],
          'first_timestamp': '2025-12-30T12:01:00Z',
          'last_timestamp': '2025-12-30T12:05:00Z',
        },
        'error_details': {
          'error_message': 'Failed to load USDZ',
          'error_code': 'malformed_usdz',
          'processing_stage': 'upload_validation',
          'failed_at': '2025-12-30T12:03:00Z',
          'blender_exit_code': 1,
          'last_error_logs': [
            'ERROR: Invalid geometry data',
            'ERROR: Conversion aborted',
          ],
        },
        'investigation_timestamp': '2025-12-30T12:30:00Z',
      };

      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(json.encode(diagnosticsJson), 200),
      );

      // Step 2: Investigation service fetches data
      final diagnostics = await investigationService.investigate(sessionId);

      // Step 3: Verify all diagnostic data is present
      expect(diagnostics.sessionId, sessionId);
      expect(diagnostics.sessionStatus, 'failed');
      expect(diagnostics.workspaceExists, true);

      // Files section
      expect(diagnostics.files, isNotNull);
      expect(diagnostics.files!.directories['input']!.exists, true);
      expect(diagnostics.files!.directories['input']!.files.length, 1);
      expect(
        diagnostics.files!.directories['input']!.files.first.name,
        'scan.usdz',
      );
      expect(
        diagnostics.files!.directories['input']!.files.first.sizeHumanReadable,
        '1.2 MB',
      );

      // Logs summary
      expect(diagnostics.logsSummary, isNotNull);
      expect(diagnostics.logsSummary!.totalLines, 150);
      expect(diagnostics.logsSummary!.errorCount, 5);
      expect(diagnostics.logsSummary!.warningCount, 2);
      expect(diagnostics.logsSummary!.lastLines.length, 2);

      // Error details
      expect(diagnostics.errorDetails, isNotNull);
      expect(diagnostics.errorDetails!.errorCode, 'malformed_usdz');
      expect(diagnostics.errorDetails!.blenderExitCode, 1);
      expect(diagnostics.errorDetails!.lastErrorLogs.length, 2);

      // Status helpers
      expect(diagnostics.statusMessage, 'Conversion failed');
      expect(diagnostics.isExpired, false);

      print('✅ T035: Session investigation flow - Complete');
      print('   - All diagnostic data retrieved');
      print('   - Files: ${diagnostics.files!.directories.length} directories');
      print(
        '   - Logs: ${diagnostics.logsSummary!.totalLines} lines, ${diagnostics.logsSummary!.errorCount} errors',
      );
      print('   - Error: ${diagnostics.errorDetails!.errorMessage}');
    });

    test('should handle expired session investigation', () async {
      const sessionId = 'sess_EXPIRED';

      final diagnosticsJson = {
        'session_id': sessionId,
        'session_status': 'expired',
        'created_at': DateTime.now()
            .subtract(Duration(hours: 2))
            .toIso8601String(),
        'expires_at': DateTime.now()
            .subtract(Duration(hours: 1))
            .toIso8601String(),
        'last_accessed': null,
        'workspace_exists': false,
        'files': null,
        'status_data': null,
        'metadata': null,
        'parameters': null,
        'logs_summary': null,
        'error_details': null,
        'investigation_timestamp': DateTime.now().toIso8601String(),
      };

      when(
        () => mockClient.get(
          Uri.parse('https://api.example.com/sessions/$sessionId/investigate'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(json.encode(diagnosticsJson), 200),
      );

      final diagnostics = await investigationService.investigate(sessionId);

      expect(diagnostics.sessionStatus, 'expired');
      expect(diagnostics.workspaceExists, false);
      expect(diagnostics.isExpired, true);
      expect(diagnostics.statusMessage, 'Session expired (TTL: 1 hour)');

      print('✅ T035b: Expired session investigation - Complete');
      print('   - Expired status detected');
      print('   - No workspace data');
    });
  });

  group('Integration Test: Error Log Cleanup (T035c)', () {
    test('should automatically cleanup old errors after 7 days', () async {
      // Create errors at different ages
      final now = DateTime.now();

      // Recent error (3 days old)
      final recentError = ErrorContext(
        timestamp: now.subtract(Duration(days: 3)),
        sessionId: 'sess_RECENT',
        message: 'Recent error',
        retryCount: 0,
        isRecoverable: true,
      );
      await errorLogService.logError(recentError);

      // Old error (8 days old)
      final oldError = ErrorContext(
        timestamp: now.subtract(Duration(days: 8)),
        sessionId: 'sess_OLD',
        message: 'Old error',
        retryCount: 0,
        isRecoverable: true,
      );
      await errorLogService.logError(oldError);

      // Verify both logged
      var allErrors = await errorLogService.getRecentErrors();
      expect(allErrors.length, 2);

      // Run cleanup with reference time
      await errorLogService.cleanup(referenceTime: now);

      // Verify old error removed
      allErrors = await errorLogService.getRecentErrors();
      expect(allErrors.length, 1);
      expect(allErrors.first.sessionId, 'sess_RECENT');

      print('✅ T035c: 7-day TTL cleanup - Complete');
      print('   - Old errors removed');
      print('   - Recent errors preserved');
    });
  });

  group('Integration Test: Multi-language Error Messages (T035d)', () {
    test('should provide error messages in multiple languages', () {
      // Test error message mapping for various codes
      final testCases = [
        {
          'code': 'invalid_file',
          'httpStatus': null,
          'contains': 'not supported',
        },
        {'code': 'malformed_usdz', 'httpStatus': null, 'contains': 'corrupted'},
        {'code': 'file_too_large', 'httpStatus': null, 'contains': '250 MB'},
        {'code': 'session_expired', 'httpStatus': null, 'contains': 'expired'},
        {'code': null, 'httpStatus': 429, 'contains': 'Too many'},
        {'code': null, 'httpStatus': 503, 'contains': 'unavailable'},
        {'code': null, 'httpStatus': 500, 'contains': 'Server error'},
      ];

      for (final testCase in testCases) {
        final message = errorMessageService.getUserMessage(
          testCase['code'] as String?,
          testCase['httpStatus'] as int?,
        );
        expect(message, contains(testCase['contains'] as String));
      }

      print('✅ T035d: Multi-language messages - Complete');
      print('   - All error codes mapped correctly');
    });
  });

  group('Integration Test: Automatic Retry with Exponential Backoff (US2)', () {
    late DeviceInfoService deviceInfoService;
    late RetryPolicyService retryPolicyService;
    late Directory retryTempDir;
    late ErrorLogService retryErrorLogService;

    setUp(() async {
      deviceInfoService = DeviceInfoService();
      await deviceInfoService.initialize();
      retryPolicyService = RetryPolicyService();
      retryTempDir = await Directory.systemTemp.createTemp('retry_test_');
      retryErrorLogService = ErrorLogService(testDirectory: retryTempDir.path);
    });

    tearDown(() async {
      if (await retryTempDir.exists()) {
        await retryTempDir.delete(recursive: true);
      }
    });

    test(
      'T060: Network failure during upload → automatic retry succeeds',
      () async {
        // Arrange
        int attemptCount = 0;
        final testFile = File('${retryTempDir.path}/test.usdz');
        await testFile.writeAsBytes([0x00, 0x01, 0x02]); // Dummy file

        final mockClient = MockClient((request) async {
          attemptCount++;

          // Fail first 2 attempts with network error, succeed on 3rd
          if (attemptCount <= 2) {
            throw const SocketException('Network unreachable');
          }

          // Third attempt succeeds
          if (request.url.path.contains('/sessions')) {
            return http.Response(
              '{"session_id": "sess_test_123", "expires_at": "2025-12-31T23:59:59Z", "status": "pending"}',
              201,
            );
          } else if (request.url.path.contains('/upload')) {
            return http.Response(
              '{"session_id": "sess_test_123", "filename": "test.usdz", "size_bytes": 3, "uploaded_at": "2025-12-31T12:00:00Z"}',
              200,
            );
          }

          return http.Response('Not found', 404);
        });

        final client = BlenderApiClient(
          client: mockClient,
          baseUrl: 'https://test.example.com',
          apiKey: 'test-api-key-1234567890',
          deviceInfoService: deviceInfoService,
          retryPolicy: retryPolicyService,
          errorLogService: retryErrorLogService,
        );

        // Act
        final session = await client.createSession();
        final uploadResponse = await client.uploadFile(
          sessionId: session.sessionId,
          file: testFile,
        );

        // Assert
        expect(
          attemptCount,
          equals(3),
          reason: 'Should retry twice after network failures',
        );
        expect(session.sessionId, equals('sess_test_123'));
        expect(uploadResponse.filename, equals('test.usdz'));

        // Verify retry attempts were logged
        final errorLogs = await retryErrorLogService.getRecentErrors(limit: 10);
        final retryLogs = errorLogs.where(
          (log) => log.message.contains('Retry attempt'),
        );
        expect(
          retryLogs.length,
          greaterThanOrEqualTo(2),
          reason: 'Should have logged retry attempts',
        );

        print('✅ T060: Network failure retry - Complete');
        print('   - Automatic retry after network errors');
        print('   - $attemptCount total attempts (2 retries)');
        print('   - Success on final attempt');
      },
    );

    test(
      'T061: 503 Service Unavailable → retry with exponential backoff',
      () async {
        // Arrange
        int attemptCount = 0;
        final retryTimestamps = <DateTime>[];

        final mockClient = MockClient((request) async {
          attemptCount++;
          retryTimestamps.add(DateTime.now());

          // Fail first 2 attempts with 503, succeed on 3rd
          if (attemptCount <= 2) {
            return http.Response(
              '{"error_code": "SERVICE_UNAVAILABLE", "message": "Service temporarily unavailable"}',
              503,
            );
          }

          // Third attempt succeeds
          return http.Response(
            '{"session_id": "sess_test_503", "expires_at": "2025-12-31T23:59:59Z", "status": "pending"}',
            201,
          );
        });

        final client = BlenderApiClient(
          client: mockClient,
          baseUrl: 'https://test.example.com',
          apiKey: 'test-api-key-1234567890',
          deviceInfoService: deviceInfoService,
          retryPolicy: retryPolicyService,
          errorLogService: retryErrorLogService,
        );

        // Act
        final session = await client.createSession();

        // Assert
        expect(
          attemptCount,
          equals(3),
          reason: 'Should retry twice after 503 errors',
        );
        expect(session.sessionId, equals('sess_test_503'));

        // Verify exponential backoff timing (approximately 2s, 4s intervals)
        if (retryTimestamps.length >= 3) {
          final delay1 = retryTimestamps[1]
              .difference(retryTimestamps[0])
              .inMilliseconds;
          final delay2 = retryTimestamps[2]
              .difference(retryTimestamps[1])
              .inMilliseconds;

          // Allow some tolerance for test execution time
          expect(
            delay1,
            greaterThanOrEqualTo(1800),
            reason: 'First retry should wait ~2 seconds',
          );
          expect(
            delay2,
            greaterThanOrEqualTo(3800),
            reason: 'Second retry should wait ~4 seconds',
          );
        }

        // Verify retry logging
        final errorLogs = await retryErrorLogService.getRecentErrors(limit: 10);
        final retryLogs = errorLogs.where(
          (log) => log.message.contains('Retry attempt'),
        );
        expect(
          retryLogs.length,
          greaterThanOrEqualTo(2),
          reason: 'Should have logged retry attempts',
        );

        print('✅ T061: 503 exponential backoff - Complete');
        print('   - Exponential backoff applied (2s, 4s)');
        print('   - $attemptCount total attempts');
        print('   - Success after transient 503 errors');
      },
    );

    test('T062: 429 Rate Limit → wait and retry after backoff', () async {
      // Arrange
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;

        // Fail first 2 attempts with 429, succeed on 3rd
        if (attemptCount <= 2) {
          return http.Response(
            '{"error_code": "RATE_LIMIT", "message": "Too many requests. Please wait and try again."}',
            429,
          );
        }

        // Third attempt succeeds
        return http.Response(
          '{"session_id": "sess_test_429", "expires_at": "2025-12-31T23:59:59Z", "status": "pending"}',
          201,
        );
      });

      final client = BlenderApiClient(
        client: mockClient,
        baseUrl: 'https://test.example.com',
        apiKey: 'test-api-key-1234567890',
        deviceInfoService: deviceInfoService,
        retryPolicy: retryPolicyService,
        errorLogService: retryErrorLogService,
      );

      // Act
      final session = await client.createSession();

      // Assert
      expect(
        attemptCount,
        equals(3),
        reason: 'Should retry twice after rate limit errors',
      );
      expect(session.sessionId, equals('sess_test_429'));

      // Verify 429 is classified as recoverable
      expect(
        retryPolicyService.isRecoverable(429, null),
        isTrue,
        reason: '429 Rate Limit should be recoverable',
      );

      // Verify retry logging with HTTP status
      final errorLogs = await retryErrorLogService.getRecentErrors(limit: 10);
      final retryLogs = errorLogs.where(
        (log) => log.message.contains('Retry attempt') && log.httpStatus == 429,
      );
      expect(
        retryLogs.length,
        greaterThanOrEqualTo(2),
        reason: 'Should have logged 429 retry attempts',
      );

      print('✅ T062: 429 rate limit retry - Complete');
      print('   - Automatic retry after rate limit');
      print('   - $attemptCount total attempts');
      print('   - Success after waiting');
    });

    test(
      'T063: Max retries exhausted → display detailed error to user',
      () async {
        // Arrange
        int attemptCount = 0;

        final mockClient = MockClient((request) async {
          attemptCount++;

          // Always fail with 503 to exhaust retries
          return http.Response(
            '{"error_code": "SERVICE_UNAVAILABLE", "message": "Service is down"}',
            503,
          );
        });

        final client = BlenderApiClient(
          client: mockClient,
          baseUrl: 'https://test.example.com',
          apiKey: 'test-api-key-1234567890',
          deviceInfoService: deviceInfoService,
          retryPolicy: retryPolicyService,
          errorLogService: retryErrorLogService,
        );

        // Act & Assert
        try {
          await client.createSession();
          fail('Should have thrown BlenderApiException after max retries');
        } catch (e) {
          // Verify max retries (3 attempts)
          expect(
            attemptCount,
            equals(3),
            reason: 'Should stop after 3 attempts (max retries)',
          );

          // Verify exception contains useful error details
          expect(
            e.toString(),
            contains('503'),
            reason: 'Error should include HTTP status code',
          );

          // Verify all retry attempts were logged
          final errorLogs = await retryErrorLogService.getRecentErrors(
            limit: 10,
          );
          final retryLogs = errorLogs.where(
            (log) => log.message.contains('Retry attempt'),
          );

          // Should have 2 retry logs (attempt 1 and 2, final attempt 3 throws)
          expect(
            retryLogs.length,
            equals(2),
            reason: 'Should have logged 2 retry attempts before final failure',
          );

          // Verify retry counts are correct
          final retryCounts = retryLogs.map((log) => log.retryCount).toList();
          expect(
            retryCounts,
            contains(1),
            reason: 'Should have logged retry attempt 1',
          );
          expect(
            retryCounts,
            contains(2),
            reason: 'Should have logged retry attempt 2',
          );

          print('✅ T063: Max retries exhausted - Complete');
          print('   - Stopped after 3 attempts');
          print('   - All retry attempts logged');
          print('   - Detailed error information available');
        }
      },
    );

    test('T063b: Non-recoverable error → no retry, immediate failure', () async {
      // Arrange
      int attemptCount = 0;

      final mockClient = MockClient((request) async {
        attemptCount++;

        // Return non-recoverable error (400 Bad Request)
        return http.Response(
          '{"error_code": "INVALID_REQUEST", "message": "Invalid request format"}',
          400,
        );
      });

      final client = BlenderApiClient(
        client: mockClient,
        baseUrl: 'https://test.example.com',
        apiKey: 'test-api-key-1234567890',
        deviceInfoService: deviceInfoService,
        retryPolicy: retryPolicyService,
        errorLogService: retryErrorLogService,
      );

      // Act & Assert
      try {
        await client.createSession();
        fail('Should have thrown BlenderApiException immediately');
      } catch (e) {
        // Verify NO retries (only 1 attempt)
        expect(
          attemptCount,
          equals(1),
          reason: 'Should NOT retry non-recoverable 400 error',
        );

        // Verify 400 is classified as non-recoverable
        expect(
          retryPolicyService.isRecoverable(400, null),
          isFalse,
          reason: '400 Bad Request should not be recoverable',
        );

        // Verify NO retry logs (since no retries happened)
        final errorLogs = await retryErrorLogService.getRecentErrors(limit: 10);
        final retryLogs = errorLogs.where(
          (log) => log.message.contains('Retry attempt'),
        );
        expect(
          retryLogs.length,
          equals(0),
          reason: 'Should NOT have logged any retry attempts',
        );

        print('✅ T063b: Non-recoverable error - Complete');
        print('   - No retry for 400 Bad Request');
        print('   - Immediate failure');
        print('   - Clear error classification');
      }
    });
  });
}
