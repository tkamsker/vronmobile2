import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/utils/email_validator.dart';

void main() {
  group('EmailValidator', () {
    test('returns error message for empty email', () {
      final result = EmailValidator.validate('');
      expect(result, 'Email is required');
    });

    test('returns error message for null email', () {
      final result = EmailValidator.validate(null);
      expect(result, 'Email is required');
    });

    test('returns error message for invalid email format - no @', () {
      final result = EmailValidator.validate('notanemail');
      expect(result, 'Invalid email format');
    });

    test('returns error message for invalid email format - no domain', () {
      final result = EmailValidator.validate('user@');
      expect(result, 'Invalid email format');
    });

    test('returns error message for invalid email format - no TLD', () {
      final result = EmailValidator.validate('user@domain');
      expect(result, 'Invalid email format');
    });

    test('returns error message for invalid email format - spaces', () {
      final result = EmailValidator.validate('user @example.com');
      expect(result, 'Invalid email format');
    });

    test('returns null for valid email - standard format', () {
      final result = EmailValidator.validate('user@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email - with subdomain', () {
      final result = EmailValidator.validate('user@mail.example.com');
      expect(result, isNull);
    });

    test('returns null for valid email - with plus', () {
      final result = EmailValidator.validate('user+tag@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email - with dots', () {
      final result = EmailValidator.validate('first.last@example.com');
      expect(result, isNull);
    });

    test('returns null for valid email - with numbers', () {
      final result = EmailValidator.validate('user123@example456.com');
      expect(result, isNull);
    });
  });
}
