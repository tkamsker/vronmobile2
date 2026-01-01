import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/services/error_message_service.dart';

void main() {
  late ErrorMessageService service;

  setUp(() {
    service = ErrorMessageService();
  });

  group('ErrorMessageService - getUserMessage', () {
    test('should return message for known BlenderAPI error codes', () {
      // Test invalid_file error code
      final message1 = service.getUserMessage('invalid_file', null);
      expect(message1, contains('not supported'));
      expect(message1, contains('USDZ'));

      // Test malformed_usdz error code
      final message2 = service.getUserMessage('malformed_usdz', null);
      expect(message2, contains('corrupted'));

      // Test file_too_large error code
      final message3 = service.getUserMessage('file_too_large', null);
      expect(message3, contains('250 MB'));

      // Test invalid_session error code
      final message4 = service.getUserMessage('invalid_session', null);
      expect(message4, contains('not found'));

      // Test session_expired error code
      final message5 = service.getUserMessage('session_expired', null);
      expect(message5, contains('expired'));
    });

    test('should return message for HTTP status codes when no error code', () {
      // Test 429 (rate limit)
      final message1 = service.getUserMessage(null, 429);
      expect(message1, contains('Too many'));
      expect(message1, contains('wait'));

      // Test 503 (service unavailable)
      final message2 = service.getUserMessage(null, 503);
      expect(message2, contains('unavailable'));

      // Test 500 (server error)
      final message3 = service.getUserMessage(null, 500);
      expect(message3, contains('Server error'));

      // Test 404 (not found)
      final message4 = service.getUserMessage(null, 404);
      expect(message4, contains('not found'));

      // Test 400 (bad request)
      final message5 = service.getUserMessage(null, 400);
      expect(message5, contains('Invalid'));
    });

    test('should prioritize error code over HTTP status', () {
      // When both error code and HTTP status present, error code takes priority
      final message = service.getUserMessage('malformed_usdz', 500);
      expect(message, contains('corrupted'));
      expect(message, isNot(contains('Server error')));
    });

    test(
      'should return generic fallback for unknown error code and status',
      () {
        final message = service.getUserMessage('unknown_error', 999);
        expect(message, contains('Something went wrong'));
      },
    );

    test('should return generic fallback when both parameters are null', () {
      final message = service.getUserMessage(null, null);
      expect(message, contains('Something went wrong'));
    });

    test('should handle network error codes', () {
      // Test timeout
      final message1 = service.getUserMessage('timeout', null);
      expect(message1, contains('timed out'));

      // Test connection failure
      final message2 = service.getUserMessage('connection_failed', null);
      expect(message2, contains('connect'));
      expect(message2, contains('internet'));

      // Test offline
      final message3 = service.getUserMessage('offline', null);
      expect(message3, contains('offline'));
    });
  });

  group('ErrorMessageService - getRecommendedAction', () {
    test('should return specific actions for BlenderAPI error codes', () {
      // invalid_file: suggest using correct format
      final action1 = service.getRecommendedAction('invalid_file', null);
      expect(action1, isNotNull);
      expect(action1, contains('USDZ'));

      // malformed_usdz: suggest re-export
      final action2 = service.getRecommendedAction('malformed_usdz', null);
      expect(action2, isNotNull);
      expect(action2!.toLowerCase(), contains('export'));

      // file_too_large: suggest reducing size
      final action3 = service.getRecommendedAction('file_too_large', null);
      expect(action3, isNotNull);
      expect(action3!.toLowerCase(), contains('reduce'));

      // session_expired: suggest re-upload
      final action4 = service.getRecommendedAction('session_expired', null);
      expect(action4, isNotNull);
      expect(action4, contains('upload'));
    });

    test('should return retry action for transient HTTP errors', () {
      // 503 Service Unavailable
      final action1 = service.getRecommendedAction(null, 503);
      expect(action1, isNotNull);
      expect(action1, contains('try again'));

      // 429 Rate Limit
      final action2 = service.getRecommendedAction(null, 429);
      expect(action2, isNotNull);
      expect(action2, contains('wait'));
    });

    test('should return null for errors without specific action', () {
      // 500 errors typically don't have user actions
      final action = service.getRecommendedAction(null, 500);
      expect(action, isNull);
    });

    test('should return action for network errors', () {
      // timeout: suggest retry
      final action1 = service.getRecommendedAction('timeout', null);
      expect(action1, isNotNull);
      expect(action1, contains('try again'));

      // connection_failed: check internet
      final action2 = service.getRecommendedAction('connection_failed', null);
      expect(action2, isNotNull);
      expect(action2, contains('internet'));

      // offline: wait for connection
      final action3 = service.getRecommendedAction('offline', null);
      expect(action3, isNotNull);
      expect(action3, contains('reconnect'));
    });

    test('should prioritize error code over HTTP status for actions', () {
      final action = service.getRecommendedAction('file_too_large', 500);
      expect(action, isNotNull);
      expect(action!.toLowerCase(), contains('reduce'));
    });
  });
}
