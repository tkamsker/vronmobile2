import 'package:flutter/foundation.dart';

/// Structured logger for Feature 018: Combined Scan to NavMesh Workflow
/// T087: Structured logging with consistent format
class CombinedScanLogger {
  static const String _prefix = '🔄 [CombinedScan]';

  /// Log operation start
  static void logStart(String operation, Map<String, dynamic>? context) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | Context: $context' : '';
      print('$_prefix START: $operation$contextStr');
    }
  }

  /// Log operation success
  static void logSuccess(String operation, Map<String, dynamic>? result) {
    if (kDebugMode) {
      final resultStr = result != null ? ' | Result: $result' : '';
      print('✅ $_prefix SUCCESS: $operation$resultStr');
    }
  }

  /// Log operation failure
  static void logError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | Context: $context' : '';
      print('❌ $_prefix ERROR: $operation$contextStr');
      print('   Error: $error');
      if (stackTrace != null) {
        print('   Stack: ${stackTrace.toString().split('\n').take(5).join('\n   ')}');
      }
    }
  }

  /// Log progress update
  static void logProgress(
    String operation,
    double progress, {
    Map<String, dynamic>? context,
  }) {
    if (kDebugMode) {
      final percentage = (progress * 100).toStringAsFixed(1);
      final contextStr = context != null ? ' | $context' : '';
      print('$_prefix PROGRESS: $operation - $percentage%$contextStr');
    }
  }

  /// Log status change
  static void logStatusChange(String from, String to, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | $context' : '';
      print('$_prefix STATUS: $from → $to$contextStr');
    }
  }

  /// Log warning
  static void logWarning(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | Context: $context' : '';
      print('⚠️ $_prefix WARNING: $message$contextStr');
    }
  }

  /// Log info
  static void logInfo(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final contextStr = context != null ? ' | $context' : '';
      print('ℹ️ $_prefix INFO: $message$contextStr');
    }
  }
}
