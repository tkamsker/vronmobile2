import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/models/pending_operation.dart';
import 'package:vronmobile2/features/scanning/models/error_context.dart';

void main() {
  group('PendingOperation', () {
    test('should serialize to JSON correctly', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ABC123',
        httpStatus: 503,
        errorCode: 'service_unavailable',
        message: 'Service temporarily unavailable',
        retryCount: 0,
        isRecoverable: true,
      );

      final pendingOp = PendingOperation(
        id: 'op_123456',
        operationType: 'upload',
        sessionId: 'sess_ABC123',
        errorContext: errorContext,
        queuedAt: DateTime.parse('2025-12-30T12:00:00Z'),
        retryCount: 0,
      );

      // Act
      final json = pendingOp.toJson();

      // Assert
      expect(json['id'], 'op_123456');
      expect(json['operationType'], 'upload');
      expect(json['sessionId'], 'sess_ABC123');
      expect(json['errorContext'], isA<Map>());
      expect(json['queuedAt'], '2025-12-30T12:00:00.000Z');
      expect(json['retryCount'], 0);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'id': 'op_789012',
        'operationType': 'status_poll',
        'sessionId': 'sess_XYZ789',
        'errorContext': {
          'timestamp': '2025-12-30T12:00:00.000Z',
          'sessionId': 'sess_XYZ789',
          'httpStatus': null,
          'errorCode': 'network_error',
          'message': 'Network connection lost',
          'technicalMessage': null,
          'retryCount': 0,
          'userId': null,
          'stackTrace': null,
          'isRecoverable': true,
        },
        'queuedAt': '2025-12-30T12:00:00.000Z',
        'retryCount': 1,
      };

      // Act
      final pendingOp = PendingOperation.fromJson(json);

      // Assert
      expect(pendingOp.id, 'op_789012');
      expect(pendingOp.operationType, 'status_poll');
      expect(pendingOp.sessionId, 'sess_XYZ789');
      expect(pendingOp.errorContext.errorCode, 'network_error');
      expect(pendingOp.retryCount, 1);
    });

    test('should handle null sessionId', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        message: 'Network error',
        retryCount: 0,
        isRecoverable: true,
      );

      final pendingOp = PendingOperation(
        id: 'op_NO_SESSION',
        operationType: 'investigate',
        sessionId: null,
        errorContext: errorContext,
        queuedAt: DateTime.parse('2025-12-30T12:00:00Z'),
        retryCount: 0,
      );

      // Act
      final json = pendingOp.toJson();
      final deserialized = PendingOperation.fromJson(json);

      // Assert
      expect(deserialized.sessionId, null);
      expect(deserialized.operationType, 'investigate');
    });

    test('isStale should return true when queued over 1 hour ago', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        message: 'Old error',
        retryCount: 0,
        isRecoverable: true,
      );

      final pendingOp = PendingOperation(
        id: 'op_OLD',
        operationType: 'upload',
        sessionId: 'sess_OLD',
        errorContext: errorContext,
        queuedAt: DateTime.now().subtract(Duration(hours: 2)),
        retryCount: 0,
      );

      // Act & Assert
      expect(pendingOp.isStale, true);
    });

    test('isStale should return false when queued less than 1 hour ago', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        message: 'Recent error',
        retryCount: 0,
        isRecoverable: true,
      );

      final pendingOp = PendingOperation(
        id: 'op_RECENT',
        operationType: 'upload',
        sessionId: 'sess_RECENT',
        errorContext: errorContext,
        queuedAt: DateTime.now().subtract(Duration(minutes: 30)),
        retryCount: 0,
      );

      // Act & Assert
      expect(pendingOp.isStale, false);
    });

    test('withRetry should increment retry count and update error context', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ABC123',
        httpStatus: 503,
        errorCode: 'service_unavailable',
        message: 'Service temporarily unavailable',
        retryCount: 0,
        isRecoverable: true,
      );

      final original = PendingOperation(
        id: 'op_RETRY',
        operationType: 'upload',
        sessionId: 'sess_ABC123',
        errorContext: errorContext,
        queuedAt: DateTime.parse('2025-12-30T12:00:00Z'),
        retryCount: 1,
      );

      // Act
      final retried = original.withRetry();

      // Assert
      expect(retried.retryCount, 2);
      expect(
        retried.errorContext.retryCount,
        1,
      ); // ErrorContext retry count incremented
      expect(
        retried.errorContext.timestamp.isAfter(original.errorContext.timestamp),
        true,
      );
      expect(retried.id, original.id); // ID preserved
      expect(retried.operationType, original.operationType);
      expect(retried.sessionId, original.sessionId);
      expect(retried.queuedAt, original.queuedAt); // Queue time preserved
    });

    test('should preserve all fields through serialization round-trip', () {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ROUNDTRIP',
        httpStatus: 429,
        errorCode: 'rate_limit',
        message: 'Too many requests',
        technicalMessage: 'Rate limit exceeded',
        retryCount: 0,
        userId: 'user-123',
        stackTrace: 'stack trace',
        isRecoverable: true,
      );

      final original = PendingOperation(
        id: 'op_ROUNDTRIP',
        operationType: 'status_poll',
        sessionId: 'sess_ROUNDTRIP',
        errorContext: errorContext,
        queuedAt: DateTime.parse('2025-12-30T12:00:00Z'),
        retryCount: 2,
      );

      // Act
      final json = original.toJson();
      final deserialized = PendingOperation.fromJson(json);

      // Assert
      expect(deserialized.id, original.id);
      expect(deserialized.operationType, original.operationType);
      expect(deserialized.sessionId, original.sessionId);
      expect(deserialized.queuedAt, original.queuedAt);
      expect(deserialized.retryCount, original.retryCount);
      expect(
        deserialized.errorContext.sessionId,
        original.errorContext.sessionId,
      );
      expect(
        deserialized.errorContext.httpStatus,
        original.errorContext.httpStatus,
      );
      expect(
        deserialized.errorContext.errorCode,
        original.errorContext.errorCode,
      );
    });
  });
}
