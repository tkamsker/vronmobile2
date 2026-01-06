import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/utils/oauth_error_mapper.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

void main() {
  group('OAuthErrorMapper', () {
    group('fromPlatformException', () {
      test('T013: maps sign_in_cancelled to cancelled error code', () {
        final exception = PlatformException(
          code: 'sign_in_cancelled',
          message: 'User cancelled sign-in',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.cancelled);
      });

      test('T013: maps SIGN_IN_CANCELLED (uppercase) to cancelled', () {
        final exception = PlatformException(
          code: 'SIGN_IN_CANCELLED',
          message: 'User cancelled',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.cancelled);
      });

      test('T013: maps error_user_canceled to cancelled', () {
        final exception = PlatformException(
          code: 'error_user_canceled',
          message: 'User canceled',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.cancelled);
      });

      test('T013: maps network_error to networkError code', () {
        final exception = PlatformException(
          code: 'network_error',
          message: 'Network connection failed',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps error_network to networkError code', () {
        final exception = PlatformException(
          code: 'error_network',
          message: 'Network issue',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps no_internet to networkError code', () {
        final exception = PlatformException(
          code: 'no_internet',
          message: 'No internet connection',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps service_disabled to serviceUnavailable code', () {
        final exception = PlatformException(
          code: 'service_disabled',
          message: 'Google Sign-In service disabled',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.serviceUnavailable);
      });

      test('T013: maps service_invalid to serviceUnavailable code', () {
        final exception = PlatformException(
          code: 'service_invalid',
          message: 'Service is invalid',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.serviceUnavailable);
      });

      test('T013: maps sign_in_failed to invalidCredentials code', () {
        final exception = PlatformException(
          code: 'sign_in_failed',
          message: 'Failed to sign in',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.invalidCredentials);
      });

      test('T013: maps error_sign_in_failed to invalidCredentials code', () {
        final exception = PlatformException(
          code: 'error_sign_in_failed',
          message: 'Sign-in error',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.invalidCredentials);
      });

      test('T013: maps invalid_account to invalidCredentials code', () {
        final exception = PlatformException(
          code: 'invalid_account',
          message: 'Account is invalid',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.invalidCredentials);
      });

      test('T013: maps unknown error code to unknown', () {
        final exception = PlatformException(
          code: 'some_random_error',
          message: 'Unknown error occurred',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.unknown);
      });
    });

    group('fromException', () {
      test('T013: maps cancel message to cancelled code', () {
        final exception = Exception('User cancelled the operation');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.cancelled);
      });

      test('T013: maps network message to networkError code', () {
        final exception = Exception('Network connection failed');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps connection message to networkError code', () {
        final exception = Exception('Connection timed out');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps timeout message to networkError code', () {
        final exception = Exception('Request timeout');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps socket message to networkError code', () {
        final exception = Exception('Socket exception occurred');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.networkError);
      });

      test('T013: maps service unavailable message to serviceUnavailable code', () {
        final exception = Exception('Service temporarily unavailable');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.serviceUnavailable);
      });

      test('T013: maps unknown message to unknown code', () {
        final exception = Exception('Some random error');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.unknown);
      });

      test('T013: handles case insensitivity in exception message', () {
        final exception = Exception('NETWORK CONNECTION FAILED');

        final result = OAuthErrorMapper.fromException(exception);

        expect(result, OAuthErrorCode.networkError);
      });
    });

    group('getUserMessage', () {
      test('T013: returns correct message for cancelled', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.cancelled);

        expect(message, AppStrings.oauthCancelled);
        expect(message, 'Sign-in was cancelled');
      });

      test('T013: returns correct message for networkError', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.networkError);

        expect(message, AppStrings.oauthNetworkError);
        expect(message, 'Network error. Please check your connection and try again');
      });

      test('T013: returns correct message for serviceUnavailable', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.serviceUnavailable);

        expect(message, AppStrings.oauthServiceUnavailable);
        expect(message, 'Google sign-in is temporarily unavailable. Please try again later');
      });

      test('T013: returns correct message for invalidCredentials', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.invalidCredentials);

        expect(message, AppStrings.oauthInvalidCredentials);
        expect(message, 'Failed to obtain Google credentials');
      });

      test('T013: returns correct message for backendError', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.backendError);

        expect(message, AppStrings.oauthBackendError);
        expect(message, 'Sign-in failed. Please try again later');
      });

      test('T013: returns correct message for invalidCode', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.invalidCode);

        expect(message, AppStrings.oauthInvalidCode);
        expect(message, 'Invalid authorization code. Please try again');
      });

      test('T013: returns correct message for codeExpired', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.codeExpired);

        expect(message, AppStrings.oauthCodeExpired);
        expect(message, 'Session expired. Please sign in again');
      });

      test('T013: returns correct message for urlLaunchFailed', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.urlLaunchFailed);

        expect(message, AppStrings.oauthUrlLaunchFailed);
        expect(message, 'Failed to open sign-in page. Please try again');
      });

      test('T013: returns correct message for invalidCallback', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.invalidCallback);

        expect(message, AppStrings.oauthInvalidCallback);
        expect(message, 'Invalid OAuth callback');
      });

      test('T013: returns correct message for codeExchangeFailed', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.codeExchangeFailed);

        expect(message, AppStrings.oauthCodeExchangeFailed);
        expect(message, 'Failed to complete authentication. Please try again');
      });

      test('T013: returns correct message for unknown', () {
        final message = OAuthErrorMapper.getUserMessage(OAuthErrorCode.unknown);

        expect(message, AppStrings.oauthAuthenticationFailed);
        expect(message, 'Authentication failed. Please try again');
      });
    });

    group('mapPlatformError', () {
      test('T013: maps PlatformException directly to user message', () {
        final exception = PlatformException(
          code: 'sign_in_cancelled',
          message: 'User cancelled',
        );

        final message = OAuthErrorMapper.mapPlatformError(exception);

        expect(message, AppStrings.oauthCancelled);
        expect(message, 'Sign-in was cancelled');
      });

      test('T013: maps network error directly to user message', () {
        final exception = PlatformException(
          code: 'network_error',
          message: 'No connection',
        );

        final message = OAuthErrorMapper.mapPlatformError(exception);

        expect(message, AppStrings.oauthNetworkError);
      });

      test('T013: maps unknown error directly to generic message', () {
        final exception = PlatformException(
          code: 'random_error',
          message: 'Something went wrong',
        );

        final message = OAuthErrorMapper.mapPlatformError(exception);

        expect(message, AppStrings.oauthAuthenticationFailed);
      });
    });

    group('mapGenericError', () {
      test('T013: maps generic Exception directly to user message', () {
        final exception = Exception('User cancelled the operation');

        final message = OAuthErrorMapper.mapGenericError(exception);

        expect(message, AppStrings.oauthCancelled);
        expect(message, 'Sign-in was cancelled');
      });

      test('T013: maps network exception directly to user message', () {
        final exception = Exception('Network connection failed');

        final message = OAuthErrorMapper.mapGenericError(exception);

        expect(message, AppStrings.oauthNetworkError);
      });

      test('T013: maps unknown exception directly to generic message', () {
        final exception = Exception('Random error');

        final message = OAuthErrorMapper.mapGenericError(exception);

        expect(message, AppStrings.oauthAuthenticationFailed);
      });
    });

    group('edge cases', () {
      test('T013: handles empty error code', () {
        final exception = PlatformException(code: '', message: 'Empty code');

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.unknown);
      });

      test('T013: handles mixed case error codes', () {
        final exception = PlatformException(
          code: 'Sign_In_Cancelled',
          message: 'Mixed case',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.cancelled);
      });

      test('T013: handles partial matches in error codes', () {
        final exception = PlatformException(
          code: 'prefix_network_error_suffix',
          message: 'Partial match',
        );

        final result = OAuthErrorMapper.fromPlatformException(exception);

        expect(result, OAuthErrorCode.networkError);
      });
    });
  });
}
