import 'package:json_annotation/json_annotation.dart';
import 'error_context.dart';

part 'pending_operation.g.dart';

/// Represents a failed operation queued for retry in offline mode
///
/// This entity is stored in shared_preferences as JSON and used by:
/// - OfflineQueueService for persistence across app restarts
/// - RetryPolicyService for automatic retry execution
/// - SessionInvestigationScreen for displaying pending operations
@JsonSerializable(explicitToJson: true)
class PendingOperation {
  /// Unique operation ID (format: op_*)
  final String id;

  /// Type of operation (upload, status_poll, investigate)
  @JsonKey(name: 'operationType')
  final String operationType;

  /// BlenderAPI session ID (format: sess_*), null for pre-session operations
  final String? sessionId;

  /// Complete error context from original failure
  final ErrorContext errorContext;

  /// When operation was added to queue (ISO 8601)
  final DateTime queuedAt;

  /// Number of retry attempts for this operation (0-3)
  final int retryCount;

  PendingOperation({
    required this.id,
    required this.operationType,
    this.sessionId,
    required this.errorContext,
    required this.queuedAt,
    required this.retryCount,
  });

  /// Whether operation is stale (queued over 1 hour ago)
  bool get isStale => DateTime.now().difference(queuedAt).inHours >= 1;

  /// Creates new PendingOperation with incremented retry count and updated error context
  PendingOperation withRetry() => PendingOperation(
    id: id,
    operationType: operationType,
    sessionId: sessionId,
    errorContext: errorContext.withRetry(),
    queuedAt: queuedAt, // Preserve original queue time
    retryCount: retryCount + 1,
  );

  factory PendingOperation.fromJson(Map<String, dynamic> json) =>
      _$PendingOperationFromJson(json);

  Map<String, dynamic> toJson() => _$PendingOperationToJson(this);
}
