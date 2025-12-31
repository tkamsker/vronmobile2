import 'package:json_annotation/json_annotation.dart';

part 'error_context.g.dart';

/// Captures complete error state for logging, retry decisions, and user display.
///
/// This entity is JSON-serializable and used for:
/// - Local error logging to Documents/error_logs.json
/// - Retry decision making via RetryPolicyService
/// - User-facing error displays
@JsonSerializable()
class ErrorContext {
  /// When error occurred (ISO 8601 format)
  final DateTime timestamp;

  /// BlenderAPI session ID (if applicable), format: sess_*
  final String? sessionId;

  /// HTTP status code (100-599) or null for network errors
  final int? httpStatus;

  /// BlenderAPI error code (e.g., invalid_file, malformed_usdz)
  final String? errorCode;

  /// User-friendly error message (non-empty, max 500 chars)
  final String message;

  /// Original technical error message for debugging (max 1000 chars)
  final String? technicalMessage;

  /// Number of retry attempts so far (0-3)
  final int retryCount;

  /// User identifier (non-sensitive, UUID or null)
  final String? userId;

  /// Sanitized stack trace for debugging (max 2000 chars, sensitive paths removed)
  final String? stackTrace;

  /// Whether error is eligible for automatic retry (computed by RetryPolicy)
  final bool isRecoverable;

  ErrorContext({
    required this.timestamp,
    this.sessionId,
    this.httpStatus,
    this.errorCode,
    required this.message,
    this.technicalMessage,
    required this.retryCount,
    this.userId,
    this.stackTrace,
    required this.isRecoverable,
  });

  /// Creates new ErrorContext with incremented retry count and updated timestamp
  ErrorContext withRetry() => ErrorContext(
        timestamp: DateTime.now(),
        sessionId: sessionId,
        httpStatus: httpStatus,
        errorCode: errorCode,
        message: message,
        technicalMessage: technicalMessage,
        retryCount: retryCount + 1,
        userId: userId,
        stackTrace: stackTrace,
        isRecoverable: isRecoverable,
      );

  factory ErrorContext.fromJson(Map<String, dynamic> json) =>
      _$ErrorContextFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorContextToJson(this);
}
