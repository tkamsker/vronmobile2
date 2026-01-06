/// Deep Link Handler for OAuth Callbacks (T008)
/// Handles parsing and validation of OAuth redirect deep link callbacks
///
/// Example deep link URLs:
/// - Success: vronapp://oauth-callback?code=AUTHORIZATION_CODE
/// - Error: vronapp://oauth-callback?error=ERROR_CODE
library;

/// Result of parsing an OAuth callback deep link
class OAuthCallbackResult {
  final bool isSuccess;
  final String? code;
  final String? error;

  OAuthCallbackResult._({
    required this.isSuccess,
    this.code,
    this.error,
  });

  factory OAuthCallbackResult.success(String code) {
    return OAuthCallbackResult._(isSuccess: true, code: code);
  }

  factory OAuthCallbackResult.error(String error) {
    return OAuthCallbackResult._(isSuccess: false, error: error);
  }

  factory OAuthCallbackResult.invalid(String reason) {
    return OAuthCallbackResult._(isSuccess: false, error: 'invalid_callback: $reason');
  }
}

/// Utility class for parsing and validating OAuth deep link callbacks
class DeepLinkHandler {
  /// Expected deep link scheme for OAuth callbacks
  static const String expectedScheme = 'vronapp';

  /// Expected deep link host for OAuth callbacks
  static const String expectedHost = 'oauth-callback';

  /// Parses an OAuth callback deep link URL
  ///
  /// Returns [OAuthCallbackResult] with either:
  /// - Success: Contains authorization code
  /// - Error: Contains error code from backend
  /// - Invalid: Malformed URL or missing parameters
  ///
  /// Example usage:
  /// ```dart
  /// final result = DeepLinkHandler.parseOAuthCallback('vronapp://oauth-callback?code=abc123');
  /// if (result.isSuccess) {
  ///   print('Code: ${result.code}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  static OAuthCallbackResult parseOAuthCallback(String url) {
    try {
      final uri = Uri.parse(url);

      // Validate scheme
      if (uri.scheme != expectedScheme) {
        return OAuthCallbackResult.invalid(
          'Invalid URL scheme: ${uri.scheme}, expected: $expectedScheme',
        );
      }

      // Validate host
      if (uri.host != expectedHost) {
        return OAuthCallbackResult.invalid(
          'Invalid URL host: ${uri.host}, expected: $expectedHost',
        );
      }

      // Check for error parameter first (higher priority)
      if (uri.queryParameters.containsKey('error')) {
        final errorCode = uri.queryParameters['error'];
        if (errorCode == null || errorCode.isEmpty) {
          return OAuthCallbackResult.invalid('Empty error parameter');
        }
        return OAuthCallbackResult.error(errorCode);
      }

      // Check for code parameter (success case)
      if (uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code'];
        if (code == null || code.isEmpty) {
          return OAuthCallbackResult.invalid('Empty code parameter');
        }
        return OAuthCallbackResult.success(code);
      }

      // No error and no code - invalid callback
      return OAuthCallbackResult.invalid(
        'Missing required parameters: code or error',
      );
    } catch (e) {
      return OAuthCallbackResult.invalid('Failed to parse URL: $e');
    }
  }

  /// Extracts authorization code from a deep link URL
  ///
  /// Returns the authorization code if present, otherwise null
  ///
  /// Example usage:
  /// ```dart
  /// final code = DeepLinkHandler.extractAuthorizationCode('vronapp://oauth-callback?code=abc123');
  /// // Returns: 'abc123'
  /// ```
  static String? extractAuthorizationCode(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['code'];
    } catch (e) {
      return null;
    }
  }

  /// Extracts error code from a deep link URL
  ///
  /// Returns the error code if present, otherwise null
  ///
  /// Example usage:
  /// ```dart
  /// final error = DeepLinkHandler.extractErrorCode('vronapp://oauth-callback?error=access_denied');
  /// // Returns: 'access_denied'
  /// ```
  static String? extractErrorCode(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['error'];
    } catch (e) {
      return null;
    }
  }

  /// Validates that a URL is a valid OAuth callback deep link
  ///
  /// Returns true if the URL matches the expected scheme and host
  ///
  /// Example usage:
  /// ```dart
  /// if (DeepLinkHandler.isValidOAuthCallback('vronapp://oauth-callback?code=abc')) {
  ///   // Process callback
  /// }
  /// ```
  static bool isValidOAuthCallback(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == expectedScheme && uri.host == expectedHost;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a deep link callback contains an error
  ///
  /// Returns true if the URL contains an 'error' query parameter
  static bool hasError(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters.containsKey('error');
    } catch (e) {
      return false;
    }
  }

  /// Checks if a deep link callback contains an authorization code
  ///
  /// Returns true if the URL contains a 'code' query parameter
  static bool hasCode(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters.containsKey('code');
    } catch (e) {
      return false;
    }
  }
}
