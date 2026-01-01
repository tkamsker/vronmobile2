import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/error_context.dart';

void main() {
  group('ErrorContext', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ABC123',
        httpStatus: 500,
        errorCode: 'server_error',
        message: 'Internal server error occurred',
        technicalMessage: 'Database connection failed',
        retryCount: 1,
        userId: 'user-123',
        stackTrace: 'at line 42',
        isRecoverable: true,
      );

      // Act
      final json = errorContext.toJson();

      // Assert
      expect(json['timestamp'], '2025-12-30T12:00:00.000Z');
      expect(json['sessionId'], 'sess_ABC123');
      expect(json['httpStatus'], 500);
      expect(json['errorCode'], 'server_error');
      expect(json['message'], 'Internal server error occurred');
      expect(json['technicalMessage'], 'Database connection failed');
      expect(json['retryCount'], 1);
      expect(json['userId'], 'user-123');
      expect(json['stackTrace'], 'at line 42');
      expect(json['isRecoverable'], true);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'timestamp': '2025-12-30T12:00:00.000Z',
        'sessionId': 'sess_ABC123',
        'httpStatus': 404,
        'errorCode': 'not_found',
        'message': 'Session not found',
        'technicalMessage': null,
        'retryCount': 0,
        'userId': 'user-456',
        'stackTrace': null,
        'isRecoverable': false,
      };

      // Act
      final errorContext = ErrorContext.fromJson(json);

      // Assert
      expect(
        errorContext.timestamp,
        DateTime.parse('2025-12-30T12:00:00.000Z'),
      );
      expect(errorContext.sessionId, 'sess_ABC123');
      expect(errorContext.httpStatus, 404);
      expect(errorContext.errorCode, 'not_found');
      expect(errorContext.message, 'Session not found');
      expect(errorContext.technicalMessage, null);
      expect(errorContext.retryCount, 0);
      expect(errorContext.userId, 'user-456');
      expect(errorContext.stackTrace, null);
      expect(errorContext.isRecoverable, false);
    });

    test('should handle null optional fields', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        message: 'Network error',
        retryCount: 0,
        isRecoverable: true,
      );

      // Act
      final json = errorContext.toJson();
      final deserialized = ErrorContext.fromJson(json);

      // Assert
      expect(deserialized.sessionId, null);
      expect(deserialized.httpStatus, null);
      expect(deserialized.errorCode, null);
      expect(deserialized.technicalMessage, null);
      expect(deserialized.userId, null);
      expect(deserialized.stackTrace, null);
      expect(deserialized.message, 'Network error');
      expect(deserialized.retryCount, 0);
      expect(deserialized.isRecoverable, true);
    });

    test('withRetry should increment retry count and update timestamp', () {
      // Arrange
      final original = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ABC123',
        httpStatus: 503,
        errorCode: 'service_unavailable',
        message: 'Service temporarily unavailable',
        retryCount: 1,
        isRecoverable: true,
      );

      // Act
      final retried = original.withRetry();

      // Assert
      expect(retried.retryCount, 2);
      expect(retried.timestamp.isAfter(original.timestamp), true);
      expect(retried.sessionId, original.sessionId);
      expect(retried.httpStatus, original.httpStatus);
      expect(retried.errorCode, original.errorCode);
      expect(retried.message, original.message);
      expect(retried.isRecoverable, original.isRecoverable);
    });

    test('should preserve all fields through serialization round-trip', () {
      // Arrange
      final original = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_XYZ789',
        httpStatus: 429,
        errorCode: 'rate_limit',
        message: 'Too many requests',
        technicalMessage: 'Rate limit: 100 requests/minute',
        retryCount: 2,
        userId: 'user-789',
        stackTrace: 'stack trace here',
        isRecoverable: true,
      );

      // Act
      final json = original.toJson();
      final deserialized = ErrorContext.fromJson(json);

      // Assert
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized.sessionId, original.sessionId);
      expect(deserialized.httpStatus, original.httpStatus);
      expect(deserialized.errorCode, original.errorCode);
      expect(deserialized.message, original.message);
      expect(deserialized.technicalMessage, original.technicalMessage);
      expect(deserialized.retryCount, original.retryCount);
      expect(deserialized.userId, original.userId);
      expect(deserialized.stackTrace, original.stackTrace);
      expect(deserialized.isRecoverable, original.isRecoverable);
    });
  });
}
