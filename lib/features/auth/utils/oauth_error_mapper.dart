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

  /// Invalid or expired authorization code (redirect-based flow)
  invalidCode,

  /// Authorization code expired (redirect-based flow)
  codeExpired,

  /// Failed to launch OAuth redirect URL (redirect-based flow)
  urlLaunchFailed,

  /// Invalid OAuth callback URL (redirect-based flow)
  invalidCallback,

  /// Code exchange mutation failed (redirect-based flow)
  codeExchangeFailed,

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
      case OAuthErrorCode.invalidCode:
        return AppStrings.oauthInvalidCode;
      case OAuthErrorCode.codeExpired:
        return AppStrings.oauthCodeExpired;
      case OAuthErrorCode.urlLaunchFailed:
        return AppStrings.oauthUrlLaunchFailed;
      case OAuthErrorCode.invalidCallback:
        return AppStrings.oauthInvalidCallback;
      case OAuthErrorCode.codeExchangeFailed:
        return AppStrings.oauthCodeExchangeFailed;
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

  /// Map OAuth redirect error code to OAuthErrorCode (T009)
  /// Handles error codes from backend OAuth redirect callback
  ///
  /// Backend error codes:
  /// - access_denied: User cancelled OAuth consent
  /// - server_error: Backend error during OAuth
  /// - temporarily_unavailable: Google OAuth service unavailable
  static OAuthErrorCode fromRedirectError(String errorCode) {
    final code = errorCode.toLowerCase();

    if (code == 'access_denied' || code.contains('denied')) {
      return OAuthErrorCode.cancelled;
    }

    if (code == 'temporarily_unavailable' || code.contains('unavailable')) {
      return OAuthErrorCode.serviceUnavailable;
    }

    if (code == 'server_error' || code.contains('server')) {
      return OAuthErrorCode.backendError;
    }

    return OAuthErrorCode.unknown;
  }

  /// Map OAuth redirect error to user-friendly message (T009)
  static String mapRedirectError(String errorCode) {
    final oauthErrorCode = fromRedirectError(errorCode);
    return getUserMessage(oauthErrorCode);
  }

  /// Map GraphQL mutation error to OAuthErrorCode (T009)
  /// Handles errors from exchangeMobileAuthCode mutation
  ///
  /// GraphQL error codes:
  /// - INVALID_CODE: Malformed, expired, or already used code
  /// - CODE_EXPIRED: Code expired (older than 5-10 minutes)
  /// - CODE_ALREADY_USED: Code has already been exchanged
  /// - NETWORK_ERROR: Backend internal error
  /// - RATE_LIMIT_EXCEEDED: Too many attempts
  static OAuthErrorCode fromMutationError(String errorCode) {
    final code = errorCode.toUpperCase();

    if (code == 'INVALID_CODE' || code == 'CODE_ALREADY_USED') {
      return OAuthErrorCode.invalidCode;
    }

    if (code == 'CODE_EXPIRED') {
      return OAuthErrorCode.codeExpired;
    }

    if (code == 'NETWORK_ERROR' || code.contains('NETWORK')) {
      return OAuthErrorCode.networkError;
    }

    if (code.contains('RATE_LIMIT')) {
      return OAuthErrorCode.backendError;
    }

    return OAuthErrorCode.codeExchangeFailed;
  }

  /// Map GraphQL mutation error to user-friendly message (T009)
  static String mapMutationError(String errorCode) {
    final oauthErrorCode = fromMutationError(errorCode);
    return getUserMessage(oauthErrorCode);
  }
}
