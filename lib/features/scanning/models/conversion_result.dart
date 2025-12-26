/// Represents the status of a USDZ→GLB conversion
enum ConversionStatus {
  pending,
  inProgress,
  completed,
  failed,
  notApplicable; // For direct GLB uploads

  /// Parse from backend GraphQL format (e.g., "IN_PROGRESS")
  static ConversionStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return ConversionStatus.pending;
      case 'IN_PROGRESS':
        return ConversionStatus.inProgress;
      case 'COMPLETED':
        return ConversionStatus.completed;
      case 'FAILED':
        return ConversionStatus.failed;
      case 'NOT_APPLICABLE':
        return ConversionStatus.notApplicable;
      default:
        throw ArgumentError('Unknown conversion status: $value');
    }
  }

  /// Convert to GraphQL format
  String toGraphQL() {
    switch (this) {
      case ConversionStatus.pending:
        return 'PENDING';
      case ConversionStatus.inProgress:
        return 'IN_PROGRESS';
      case ConversionStatus.completed:
        return 'COMPLETED';
      case ConversionStatus.failed:
        return 'FAILED';
      case ConversionStatus.notApplicable:
        return 'NOT_APPLICABLE';
    }
  }
}

/// Represents a conversion error from the backend
class ConversionError {
  final String code;
  final String message;

  const ConversionError({
    required this.code,
    required this.message,
  });

  factory ConversionError.fromJson(Map<String, dynamic> json) {
    return ConversionError(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
    };
  }
}

/// Result from uploading a scan to the backend
class ConversionResult {
  final String? scanId;
  final String? usdzUrl;
  final String? glbUrl;
  final ConversionStatus conversionStatus;
  final ConversionError? error;
  final bool success;
  final String? message;

  const ConversionResult({
    this.scanId,
    this.usdzUrl,
    this.glbUrl,
    required this.conversionStatus,
    this.error,
    required this.success,
    this.message,
  });

  /// Parse from GraphQL uploadProjectScan response
  factory ConversionResult.fromJson(Map<String, dynamic> json) {
    final scan = json['scan'] as Map<String, dynamic>?;
    final success = json['success'] as bool;
    final message = json['message'] as String?;

    if (scan == null) {
      return ConversionResult(
        success: success,
        message: message,
        conversionStatus: ConversionStatus.failed,
      );
    }

    final conversionStatus = ConversionStatus.fromString(
      scan['conversionStatus'] as String,
    );

    final errorJson = scan['error'] as Map<String, dynamic>?;
    final error = errorJson != null
        ? ConversionError.fromJson(errorJson)
        : null;

    return ConversionResult(
      scanId: scan['id'] as String?,
      usdzUrl: scan['usdzUrl'] as String?,
      glbUrl: scan['glbUrl'] as String?,
      conversionStatus: conversionStatus,
      error: error,
      success: success,
      message: message,
    );
  }

  /// Check if conversion is complete (either succeeded or failed)
  bool get isComplete {
    return conversionStatus == ConversionStatus.completed ||
        conversionStatus == ConversionStatus.failed ||
        conversionStatus == ConversionStatus.notApplicable;
  }

  /// Check if conversion succeeded
  bool get isSuccess {
    return success && conversionStatus == ConversionStatus.completed;
  }
}
