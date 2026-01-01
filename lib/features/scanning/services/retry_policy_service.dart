import 'dart:async';
import 'dart:math' as math;

/// Service for handling automatic retry logic with exponential backoff
///
/// Classifies errors as recoverable (automatic retry) or non-recoverable (user action required)
/// and implements intelligent retry logic for transient failures.
///
/// **Retry Policy**:
/// - Max retries: 3 attempts
/// - Backoff strategy: Exponential (2s, 4s, 8s)
/// - Time window: 1 minute maximum
/// - Error classification: HTTP status + error code lookup
///
/// **Recoverable Errors**:
/// - Network timeouts (no HTTP status)
/// - 429 Rate Limit
/// - 500-504 Server errors
///
/// **Non-Recoverable Errors**:
/// - 400-422 Client errors (bad request, auth, validation)
/// - Business logic errors (invalid_file, malformed_usdz, etc.)
class RetryPolicyService {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxWindow = Duration(minutes: 1);

  /// Classifies error as recoverable (auto-retry) or non-recoverable
  ///
  /// **Classification Priority**:
  /// 1. Error code (if present and in non-recoverable set) → non-recoverable
  /// 2. HTTP status (if present) → check recoverable/non-recoverable sets
  /// 3. No HTTP status (network error) → recoverable
  ///
  /// Examples:
  /// ```dart
  /// isRecoverable(503, null) → true (service unavailable)
  /// isRecoverable(404, null) → false (not found)
  /// isRecoverable(503, 'invalid_file') → false (error code takes precedence)
  /// isRecoverable(null, null) → true (network error)
  /// ```
  bool isRecoverable(int? httpStatus, String? errorCode) {
    // Check error code first (more specific than HTTP status)
    if (errorCode != null && _nonRecoverableErrorCodes.contains(errorCode)) {
      return false;
    }

    // Check HTTP status
    if (httpStatus != null) {
      if (_recoverableHttpStatuses.contains(httpStatus)) {
        return true;
      }
      if (_nonRecoverableHttpStatuses.contains(httpStatus)) {
        return false;
      }
    }

    // Network errors (no HTTP status) are recoverable
    return httpStatus == null;
  }

  /// Executes operation with exponential backoff retry
  ///
  /// **Retry Behavior**:
  /// - Attempt 1: Immediate
  /// - Attempt 2: After 2 seconds
  /// - Attempt 3: After 4 seconds (6s total)
  /// - Attempt 4: After 8 seconds (14s total) - only if within 1 minute window
  ///
  /// **Stopping Conditions**:
  /// - Operation succeeds
  /// - Error is non-recoverable (isRecoverableError returns false)
  /// - Max retries reached (3 attempts)
  /// - Time window exceeded (1 minute)
  ///
  /// Example:
  /// ```dart
  /// final result = await retryPolicy.executeWithRetry(
  ///   operation: () => http.get(url),
  ///   isRecoverableError: (error) {
  ///     if (error is HttpException) {
  ///       return retryPolicy.isRecoverable(error.statusCode, null);
  ///     }
  ///     return true; // Network errors are recoverable
  ///   },
  ///   onRetry: (attempt, error) {
  ///     print('Retry attempt $attempt: $error');
  ///   },
  /// );
  /// ```
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required bool Function(dynamic error) isRecoverableError,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    final startTime = DateTime.now();

    while (true) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        // Check if error is recoverable
        if (!isRecoverableError(error)) {
          rethrow;
        }

        // Check retry limits
        if (attempt >= maxRetries) {
          rethrow;
        }

        // Check time window
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed >= maxWindow) {
          rethrow;
        }

        // Calculate backoff delay: 2^attempt * baseDelay (2s, 4s, 8s)
        final delay = baseDelay * math.pow(2, attempt - 1).toInt();

        // Notify retry callback
        onRetry?.call(attempt, error);

        // Wait before retry
        await Future.delayed(delay);
      }
    }
  }

  // Recoverable HTTP statuses (transient server/network errors)
  static const Set<int> _recoverableHttpStatuses = {
    429, // Rate Limit (wait and retry)
    500, // Internal Server Error (temporary)
    502, // Bad Gateway (temporary)
    503, // Service Unavailable (temporary)
    504, // Gateway Timeout (temporary)
  };

  // Non-recoverable HTTP statuses (client errors)
  static const Set<int> _nonRecoverableHttpStatuses = {
    400, // Bad Request (invalid input)
    401, // Unauthorized (auth problem)
    403, // Forbidden (permission problem)
    404, // Not Found (session expired)
    413, // Payload Too Large (file too big)
    422, // Unprocessable Entity (validation error)
  };

  // Non-recoverable error codes (business logic errors)
  static const Set<String> _nonRecoverableErrorCodes = {
    'invalid_file',
    'malformed_usdz',
    'file_too_large',
    'session_expired',
    'unauthorized',
  };
}
