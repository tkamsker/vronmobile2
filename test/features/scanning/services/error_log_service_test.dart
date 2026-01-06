import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/services/error_log_service.dart';
import 'package:vronmobile2/features/scanning/models/error_context.dart';

void main() {
  late ErrorLogService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Create temporary directory for test files
    tempDir = await Directory.systemTemp.createTemp('error_log_test_');
    service = ErrorLogService(testDirectory: tempDir.path);
  });

  tearDown(() async {
    // Clean up test directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ErrorLogService - logError', () {
    test('should write error to JSON file', () async {
      // Arrange
      final errorContext = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_ABC123',
        httpStatus: 500,
        errorCode: 'server_error',
        message: 'Internal server error',
        retryCount: 0,
        isRecoverable: true,
      );

      // Act
      await service.logError(errorContext);

      // Assert - verify file exists
      final logFile = File('${tempDir.path}/error_logs.json');
      expect(await logFile.exists(), true);

      // Assert - verify content is valid JSON
      final content = await logFile.readAsString();
      expect(content, isNotEmpty);
      expect(content, contains('sess_ABC123'));
      expect(content, contains('server_error'));
    });

    test('should append multiple errors to same file', () async {
      // Arrange
      final error1 = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
        sessionId: 'sess_001',
        message: 'Error 1',
        retryCount: 0,
        isRecoverable: true,
      );
      final error2 = ErrorContext(
        timestamp: DateTime.parse('2025-12-30T12:01:00Z'),
        sessionId: 'sess_002',
        message: 'Error 2',
        retryCount: 0,
        isRecoverable: true,
      );

      // Act
      await service.logError(error1);
      await service.logError(error2);

      // Assert
      final errors = await service.getRecentErrors();
      expect(errors.length, 2);
      expect(errors[0].sessionId, 'sess_002'); // Most recent first
      expect(errors[1].sessionId, 'sess_001');
    });

    test('should handle concurrent writes safely', () async {
      // Arrange
      final errors = List.generate(
        10,
        (i) => ErrorContext(
          timestamp: DateTime.now(),
          sessionId: 'sess_$i',
          message: 'Error $i',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act - write concurrently
      await Future.wait(errors.map((error) => service.logError(error)));

      // Assert - all errors should be logged
      final logged = await service.getRecentErrors();
      expect(logged.length, 10);
    });
  });

  group('ErrorLogService - getRecentErrors', () {
    test('should return empty list when no errors logged', () async {
      final errors = await service.getRecentErrors();
      expect(errors, isEmpty);
    });

    test('should return errors sorted by timestamp descending', () async {
      // Arrange - log errors with different timestamps
      await service.logError(
        ErrorContext(
          timestamp: DateTime.parse('2025-12-30T10:00:00Z'),
          message: 'Old error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.parse('2025-12-30T12:00:00Z'),
          message: 'Recent error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.parse('2025-12-30T11:00:00Z'),
          message: 'Middle error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act
      final errors = await service.getRecentErrors();

      // Assert - most recent first
      expect(errors.length, 3);
      expect(errors[0].message, 'Recent error');
      expect(errors[1].message, 'Middle error');
      expect(errors[2].message, 'Old error');
    });

    test('should filter by sessionId when provided', () async {
      // Arrange
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          sessionId: 'sess_A',
          message: 'Error A1',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          sessionId: 'sess_B',
          message: 'Error B1',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          sessionId: 'sess_A',
          message: 'Error A2',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act
      final errors = await service.getRecentErrors(sessionId: 'sess_A');

      // Assert
      expect(errors.length, 2);
      expect(errors.every((e) => e.sessionId == 'sess_A'), true);
    });

    test('should filter by errorCode when provided', () async {
      // Arrange
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          errorCode: 'timeout',
          message: 'Timeout 1',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          errorCode: 'invalid_file',
          message: 'Invalid file',
          retryCount: 0,
          isRecoverable: true,
        ),
      );
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          errorCode: 'timeout',
          message: 'Timeout 2',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act
      final errors = await service.getRecentErrors(errorCode: 'timeout');

      // Assert
      expect(errors.length, 2);
      expect(errors.every((e) => e.errorCode == 'timeout'), true);
    });

    test('should limit results when limit parameter provided', () async {
      // Arrange - log 10 errors
      for (int i = 0; i < 10; i++) {
        await service.logError(
          ErrorContext(
            timestamp: DateTime.now().add(Duration(minutes: i)),
            message: 'Error $i',
            retryCount: 0,
            isRecoverable: true,
          ),
        );
      }

      // Act
      final errors = await service.getRecentErrors(limit: 5);

      // Assert
      expect(errors.length, 5);
    });
  });

  group('ErrorLogService - cleanup (7-day TTL)', () {
    test('should remove errors older than 7 days', () async {
      // Arrange - log errors with different ages
      final now = DateTime.now();

      // Recent error (keep)
      await service.logError(
        ErrorContext(
          timestamp: now.subtract(Duration(days: 3)),
          message: 'Recent error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Old error (remove)
      await service.logError(
        ErrorContext(
          timestamp: now.subtract(Duration(days: 8)),
          message: 'Old error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Exactly 7 days (keep)
      await service.logError(
        ErrorContext(
          timestamp: now.subtract(Duration(days: 7)),
          message: 'Boundary error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act - pass now as reference time to ensure consistent cutoff
      await service.cleanup(referenceTime: now);

      // Assert
      final errors = await service.getRecentErrors();
      expect(errors.length, 2);
      expect(errors.any((e) => e.message == 'Old error'), false);
      expect(errors.any((e) => e.message == 'Recent error'), true);
      expect(errors.any((e) => e.message == 'Boundary error'), true);
    });

    test('should not fail when log file does not exist', () async {
      // Act & Assert - should not throw
      expect(() => service.cleanup(), returnsNormally);
    });

    test('should preserve file structure after cleanup', () async {
      // Arrange
      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          message: 'Recent error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      // Act
      await service.cleanup();

      // Assert - should still be able to read/write
      final errors = await service.getRecentErrors();
      expect(errors.length, 1);

      await service.logError(
        ErrorContext(
          timestamp: DateTime.now(),
          message: 'New error',
          retryCount: 0,
          isRecoverable: true,
        ),
      );

      final updatedErrors = await service.getRecentErrors();
      expect(updatedErrors.length, 2);
    });
  });
}
