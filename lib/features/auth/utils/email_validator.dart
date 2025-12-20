/// Email validation utility using RFC 5322 simplified regex pattern
class EmailValidator {
  // RFC 5322 simplified email regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates an email address
  /// Returns error message if invalid, null if valid
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }

    return null;
  }
}
