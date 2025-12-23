import 'package:flutter/services.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// OAuth error categories for better error handling
enum OAuthErrorCode {
  /// User cancelled the sign-in flow
  cancelled,

  /// Network connectivity issues
  networkError,

  /// Google Sign-In service temporarily unavailable
  serviceUnavailable,

  /// Failed to obtain valid credentials from Google
  invalidCredentials,

  /// Backend authentication service error
  backendError,

  /// Unknown or unexpected error
  unknown,
}

/// Maps platform-specific errors to user-friendly messages
class OAuthErrorMapper {
  /// Map PlatformException to OAuthErrorCode
  static OAuthErrorCode fromPlatformException(PlatformException exception) {
    final code = exception.code.toLowerCase();

    // Google Sign-In error codes
    // Reference: https://developers.google.com/android/reference/com/google/android/gms/common/api/CommonStatusCodes
    if (code.contains('sign_in_cancelled') ||
        code.contains('cancelled') ||
        code.contains('error_user_canceled')) {
      return OAuthErrorCode.cancelled;
    }

    if (code.contains('network_error') ||
        code.contains('error_network') ||
        code.contains('no_internet')) {
      return OAuthErrorCode.networkError;
    }

    if (code.contains('service_disabled') ||
        code.contains('service_invalid') ||
        code.contains('error_service')) {
      return OAuthErrorCode.serviceUnavailable;
    }

    if (code.contains('sign_in_failed') ||
        code.contains('error_sign_in_failed') ||
        code.contains('invalid_account')) {
      return OAuthErrorCode.invalidCredentials;
    }

    return OAuthErrorCode.unknown;
  }

  /// Map Exception to OAuthErrorCode
  static OAuthErrorCode fromException(Exception exception) {
    final message = exception.toString().toLowerCase();

    if (message.contains('cancel')) {
      return OAuthErrorCode.cancelled;
    }

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket')) {
      return OAuthErrorCode.networkError;
    }

    if (message.contains('service') || message.contains('unavailable')) {
      return OAuthErrorCode.serviceUnavailable;
    }

    return OAuthErrorCode.unknown;
  }

  /// Get user-friendly error message from error code
  static String getUserMessage(OAuthErrorCode code) {
    switch (code) {
      case OAuthErrorCode.cancelled:
        return AppStrings.oauthCancelled;
      case OAuthErrorCode.networkError:
        return AppStrings.oauthNetworkError;
      case OAuthErrorCode.serviceUnavailable:
        return AppStrings.oauthServiceUnavailable;
      case OAuthErrorCode.invalidCredentials:
        return AppStrings.oauthInvalidCredentials;
      case OAuthErrorCode.backendError:
        return AppStrings.oauthBackendError;
      case OAuthErrorCode.unknown:
        return AppStrings.oauthAuthenticationFailed;
    }
  }

  /// Map PlatformException directly to user message
  static String mapPlatformError(PlatformException exception) {
    final errorCode = fromPlatformException(exception);
    return getUserMessage(errorCode);
  }

  /// Map generic Exception directly to user message
  static String mapGenericError(Exception exception) {
    final errorCode = fromException(exception);
    return getUserMessage(errorCode);
  }
}
