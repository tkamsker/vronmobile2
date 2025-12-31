import 'package:vronmobile2/core/i18n/i18n_service.dart';

/// Service for converting error codes and HTTP status codes into user-friendly messages
///
/// Maps BlenderAPI error codes and HTTP status codes to localized, actionable
/// error messages. Integrates with I18nService for multi-language support.
class ErrorMessageService {
  final I18nService _i18n;

  ErrorMessageService({I18nService? i18nService})
      : _i18n = i18nService ?? I18nService();

  /// Error code to i18n key mapping
  static const Map<String, String> _errorCodeMap = {
    // BlenderAPI error codes
    'invalid_file': 'errors.blender_api.invalid_file',
    'malformed_usdz': 'errors.blender_api.malformed_usdz',
    'file_too_large': 'errors.blender_api.file_too_large',
    'invalid_session': 'errors.blender_api.invalid_session',
    'session_expired': 'errors.blender_api.session_expired',

    // Network error codes
    'timeout': 'errors.network.timeout',
    'connection_failed': 'errors.network.connection_failed',
    'offline': 'errors.network.offline',
  };

  /// HTTP status code to i18n key mapping
  static const Map<int, String> _httpStatusMap = {
    400: 'errors.http.400',
    404: 'errors.http.404',
    429: 'errors.http.429',
    500: 'errors.http.500',
    503: 'errors.http.503',
  };

  /// Get user-friendly error message
  ///
  /// Priority: error code > HTTP status > generic fallback
  /// Returns localized message from i18n service
  String getUserMessage(String? errorCode, int? httpStatus) {
    // Priority 1: Check error code mapping
    if (errorCode != null && _errorCodeMap.containsKey(errorCode)) {
      final key = _errorCodeMap[errorCode]!;
      final translated = _i18n.translate(key);
      // Fallback to key if translation fails
      if (translated == key) {
        return _getFallbackMessage(errorCode, httpStatus);
      }
      return translated;
    }

    // Priority 2: Check HTTP status mapping
    if (httpStatus != null && _httpStatusMap.containsKey(httpStatus)) {
      final key = _httpStatusMap[httpStatus]!;
      final translated = _i18n.translate(key);
      // Fallback to key if translation fails
      if (translated == key) {
        return _getFallbackMessage(errorCode, httpStatus);
      }
      return translated;
    }

    // Priority 3: Generic fallback
    final translated = _i18n.translate('errors.fallback.generic');
    if (translated == 'errors.fallback.generic') {
      return 'Something went wrong. Please try again.';
    }
    return translated;
  }

  /// Fallback messages when i18n not available (for testing)
  String _getFallbackMessage(String? errorCode, int? httpStatus) {
    if (errorCode != null) {
      switch (errorCode) {
        case 'invalid_file':
          return 'File format not supported. Please use USDZ or GLB files.';
        case 'malformed_usdz':
          return 'File appears corrupted. Try exporting it again.';
        case 'file_too_large':
          return 'File exceeds 250 MB limit. Please reduce file size.';
        case 'invalid_session':
          return 'Session not found. Please start a new conversion.';
        case 'session_expired':
          return 'Session expired after 1 hour. Please upload again.';
        case 'timeout':
          return 'Connection timed out. Please try again.';
        case 'connection_failed':
          return 'Unable to connect. Check your internet connection.';
        case 'offline':
          return 'You\'re offline. Changes will sync when you reconnect.';
      }
    }

    if (httpStatus != null) {
      switch (httpStatus) {
        case 429:
          return 'Too many requests. Please wait a moment and try again.';
        case 503:
          return 'Service temporarily unavailable. Please try again shortly.';
        case 500:
          return 'Server error occurred. Our team has been notified.';
        case 404:
          return 'Resource not found. It may have been removed.';
        case 400:
          return 'Invalid request. Please check your input.';
      }
    }

    return 'Something went wrong. Please try again.';
  }

  /// Get recommended action for user to resolve error
  ///
  /// Returns actionable guidance or null if no specific action available
  String? getRecommendedAction(String? errorCode, int? httpStatus) {
    // Priority 1: Error code specific actions
    if (errorCode != null) {
      switch (errorCode) {
        case 'invalid_file':
          return 'Please use USDZ or GLB files only.';
        case 'malformed_usdz':
          return 'Try exporting the file again from your 3D software.';
        case 'file_too_large':
          return 'Reduce file size to under 250 MB.';
        case 'session_expired':
        case 'invalid_session':
          return 'Please upload your file again.';
        case 'timeout':
        case 'connection_failed':
          return 'Check your internet connection and try again.';
        case 'offline':
          return 'Changes will sync when you reconnect.';
      }
    }

    // Priority 2: HTTP status specific actions
    if (httpStatus != null) {
      switch (httpStatus) {
        case 429: // Rate limit
          return 'Please wait a moment before trying again.';
        case 503: // Service unavailable
          return 'Please try again in a few minutes.';
        case 400: // Bad request
          return 'Please check your input and try again.';
        // 404, 500 typically don't have user actions
        default:
          return null;
      }
    }

    return null;
  }
}
