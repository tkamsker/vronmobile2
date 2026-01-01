import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:vronmobile2/features/scanning/services/retry_policy_service.dart';

void main() {
  group('RetryPolicyService', () {
    late RetryPolicyService service;

    setUp(() {
      service = RetryPolicyService();
    });

    group('isRecoverable - Error Classification', () {
      test('T052: classifies recoverable HTTP statuses correctly', () {
        // Arrange & Act & Assert - Recoverable statuses
        expect(
          service.isRecoverable(429, null),
          isTrue,
          reason: '429 Rate Limit should be recoverable',
        );
        expect(
          service.isRecoverable(500, null),
          isTrue,
          reason: '500 Internal Server Error should be recoverable',
        );
        expect(
          service.isRecoverable(502, null),
          isTrue,
          reason: '502 Bad Gateway should be recoverable',
        );
        expect(
          service.isRecoverable(503, null),
          isTrue,
          reason: '503 Service Unavailable should be recoverable',
        );
        expect(
          service.isRecoverable(504, null),
          isTrue,
          reason: '504 Gateway Timeout should be recoverable',
        );
      });

      test('T052: classifies non-recoverable HTTP statuses correctly', () {
        // Arrange & Act & Assert - Non-recoverable statuses
        expect(
          service.isRecoverable(400, null),
          isFalse,
          reason: '400 Bad Request should not be recoverable',
        );
        expect(
          service.isRecoverable(401, null),
          isFalse,
          reason: '401 Unauthorized should not be recoverable',
        );
        expect(
          service.isRecoverable(403, null),
          isFalse,
          reason: '403 Forbidden should not be recoverable',
        );
        expect(
          service.isRecoverable(404, null),
          isFalse,
          reason: '404 Not Found should not be recoverable',
        );
        expect(
          service.isRecoverable(413, null),
          isFalse,
          reason: '413 Payload Too Large should not be recoverable',
        );
        expect(
          service.isRecoverable(422, null),
          isFalse,
          reason: '422 Unprocessable Entity should not be recoverable',
        );
      });

      test('T052: classifies non-recoverable error codes correctly', () {
        // Arrange & Act & Assert - Non-recoverable error codes
        expect(service.isRecoverable(null, 'invalid_file'), isFalse);
        expect(service.isRecoverable(null, 'malformed_usdz'), isFalse);
        expect(service.isRecoverable(null, 'file_too_large'), isFalse);
        expect(service.isRecoverable(null, 'session_expired'), isFalse);
        expect(service.isRecoverable(null, 'unauthorized'), isFalse);
      });

      test('T052: prioritizes error code over HTTP status', () {
        // Arrange & Act - Non-recoverable error code with recoverable HTTP status
        final result = service.isRecoverable(503, 'invalid_file');

        // Assert - Error code takes precedence
        expect(
          result,
          isFalse,
          reason:
              'invalid_file error code should override 503 recoverable status',
        );
      });

      test('T052: treats network errors (no HTTP status) as recoverable', () {
        // Arrange & Act & Assert
        expect(
          service.isRecoverable(null, null),
          isTrue,
          reason: 'Network errors with no status should be recoverable',
        );
      });
    });

    group('executeWithRetry - Exponential Backoff', () {
      test('T053: succeeds on first attempt without retry', () async {
        // Arrange
        int callCount = 0;
        Future<String> operation() async {
          callCount++;
          return 'success';
        }

        // Act
        final result = await service.executeWithRetry(
          operation: operation,
          isRecoverableError: (_) => true,
        );

        // Assert
        expect(result, equals('success'));
        expect(callCount, equals(1), reason: 'Should succeed on first attempt');
      });

      test('T053: retries with exponential backoff (2s, 4s, 8s)', () {
        fakeAsync((async) {
          // Arrange
          int callCount = 0;
          final callTimes = <Duration>[];
          final startTime = Duration.zero;

          Future<String> operation() async {
            callCount++;
            callTimes.add(async.elapsed);
            if (callCount < 3) {
              throw Exception('Transient error');
            }
            return 'success';
          }

          // Act
          service.executeWithRetry(
            operation: operation,
            isRecoverableError: (_) => true,
          );

          // Simulate time passing
          async.elapse(Duration(seconds: 0)); // First attempt (immediate)
          async.elapse(Duration(seconds: 2)); // First retry after 2s
          async.elapse(Duration(seconds: 4)); // Second retry after 4s

          // Assert
          expect(callCount, equals(3));
          expect(
            callTimes[0],
            equals(Duration.zero),
            reason: 'First attempt should be immediate',
          );
          expect(
            callTimes[1],
            equals(Duration(seconds: 2)),
            reason: 'First retry should be after 2 seconds',
          );
          expect(
            callTimes[2],
            equals(Duration(seconds: 6)),
            reason: 'Second retry should be after 6 seconds total (2+4)',
          );
        });
      });

      test('T053: onRetry callback is called for each retry attempt', () async {
        // Arrange
        int callCount = 0;
        final retryAttempts = <int>[];
        final retryErrors = <dynamic>[];

        Future<String> operation() async {
          callCount++;
          if (callCount < 3) {
            throw Exception('Transient error $callCount');
          }
          return 'success';
        }

        // Act
        await service.executeWithRetry(
          operation: operation,
          isRecoverableError: (_) => true,
          onRetry: (attempt, error) {
            retryAttempts.add(attempt);
            retryErrors.add(error);
          },
        );

        // Assert
        expect(
          retryAttempts,
          equals([1, 2]),
          reason: 'onRetry should be called for attempts 1 and 2',
        );
        expect(retryErrors.length, equals(2));
      });
    });

    group('executeWithRetry - Retry Limits', () {
      test('T054: stops after max retries (3 attempts)', () async {
        // Arrange
        int callCount = 0;
        Future<String> operation() async {
          callCount++;
          throw Exception('Persistent error');
        }

        // Act & Assert
        await expectLater(
          service.executeWithRetry(
            operation: operation,
            isRecoverableError: (_) => true,
          ),
          throwsException,
        );

        expect(
          callCount,
          equals(3),
          reason: 'Should stop after 3 attempts (max retries)',
        );
      });

      test('T054: stops immediately for non-recoverable errors', () async {
        // Arrange
        int callCount = 0;
        Future<String> operation() async {
          callCount++;
          throw Exception('Non-recoverable error');
        }

        // Act & Assert
        await expectLater(
          service.executeWithRetry(
            operation: operation,
            isRecoverableError: (_) => false,
          ),
          throwsException,
        );

        expect(
          callCount,
          equals(1),
          reason: 'Should not retry non-recoverable errors',
        );
      });

      test('T055: stops after time window limit (1 minute)', () {
        fakeAsync((async) {
          // Arrange
          int callCount = 0;
          bool exceptionThrown = false;

          Future<String> operation() async {
            callCount++;
            throw Exception('Persistent error');
          }

          // Act
          service
              .executeWithRetry(
                operation: operation,
                isRecoverableError: (_) => true,
              )
              .catchError((error) {
                exceptionThrown = true;
                return 'error'; // Return dummy value to satisfy type requirement
              });

          // Simulate time passing beyond 1 minute window
          async.elapse(Duration(seconds: 0)); // First attempt
          async.elapse(Duration(seconds: 2)); // First retry (2s)
          async.elapse(Duration(seconds: 4)); // Second retry (6s total)
          async.elapse(
            Duration(seconds: 55),
          ); // Try to trigger third retry (61s total)

          // Assert - Should stop before third retry due to time window
          expect(
            callCount,
            lessThanOrEqualTo(3),
            reason: 'Should stop within 1 minute time window',
          );
          expect(
            exceptionThrown,
            isTrue,
            reason: 'Should throw exception after time window expires',
          );
        });
      });
    });
  });
}
