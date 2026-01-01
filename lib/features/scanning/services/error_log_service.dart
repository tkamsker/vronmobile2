import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:vronmobile2/features/scanning/models/error_context.dart';

/// Service for logging errors to local JSON file storage
///
/// - Appends errors to Documents/error_logs.json
/// - Maintains 7-day TTL (time-to-live) for log entries
/// - Provides filtering and retrieval of recent errors
/// - Thread-safe with lock for concurrent writes
class ErrorLogService {
  static const String _logFileName = 'error_logs.json';
  static const int _ttlDays = 7;

  final String? _testDirectory; // For testing only
  Future<void> _lastWrite = Future.value(); // Chain of write operations

  ErrorLogService({String? testDirectory}) : _testDirectory = testDirectory;

  /// Get path to error log file
  Future<String> _getLogFilePath() async {
    if (_testDirectory != null) {
      return '$_testDirectory/$_logFileName';
    }

    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }

  /// Log error to JSON file (append mode) with thread-safe serialization
  Future<void> logError(ErrorContext errorContext) async {
    // Chain this write after the previous one completes
    _lastWrite = _lastWrite.then((_) => _performWrite(errorContext));
    return _lastWrite;
  }

  /// Internal method that performs the actual write operation
  Future<void> _performWrite(ErrorContext errorContext) async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      // Read existing logs
      List<Map<String, dynamic>> logs = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          try {
            final decoded = json.decode(content);
            if (decoded is List) {
              logs = List<Map<String, dynamic>>.from(
                decoded.map((e) => e as Map<String, dynamic>),
              );
            }
          } catch (e) {
            // If JSON is malformed, start fresh
            logs = [];
          }
        }
      }

      // Append new error
      logs.add(errorContext.toJson());

      // Write back to file
      await file.writeAsString(
        json.encode(logs),
        mode: FileMode.write,
        flush: true,
      );
    } catch (e) {
      // Silently fail - logging errors shouldn't crash the app
      print('Error writing to error log: $e');
    }
  }

  /// Get recent errors with optional filtering
  Future<List<ErrorContext>> getRecentErrors({
    String? sessionId,
    String? errorCode,
    int? limit,
  }) async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final decoded = json.decode(content);
      if (decoded is! List) {
        return [];
      }

      // Parse all errors
      final errors = decoded
          .map((e) => ErrorContext.fromJson(e as Map<String, dynamic>))
          .toList();

      // Apply filters
      var filtered = errors.where((error) {
        if (sessionId != null && error.sessionId != sessionId) {
          return false;
        }
        if (errorCode != null && error.errorCode != errorCode) {
          return false;
        }
        return true;
      }).toList();

      // Sort by timestamp descending (most recent first)
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Apply limit
      if (limit != null && limit > 0) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e) {
      print('Error reading error log: $e');
      return [];
    }
  }

  /// Clean up errors older than 7 days (TTL)
  ///
  /// [referenceTime] - Optional reference time for cutoff calculation (defaults to DateTime.now())
  /// Useful for testing with fixed timestamps
  Future<void> cleanup({DateTime? referenceTime}) async {
    try {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      if (!await file.exists()) {
        return;
      }

      final content = await file.readAsString();
      if (content.isEmpty) {
        return;
      }

      final decoded = json.decode(content);
      if (decoded is! List) {
        return;
      }

      // Parse all errors
      final errors = decoded
          .map((e) => ErrorContext.fromJson(e as Map<String, dynamic>))
          .toList();

      // Calculate cutoff date (7 days ago from reference time)
      final cutoffDate = (referenceTime ?? DateTime.now()).subtract(
        Duration(days: _ttlDays),
      );

      // Filter out old errors (keep errors >= cutoffDate, i.e., from last 7 days including boundary)
      final recentErrors = errors
          .where((error) => !error.timestamp.isBefore(cutoffDate))
          .toList();

      // Write filtered list back to file
      await file.writeAsString(
        json.encode(recentErrors.map((e) => e.toJson()).toList()),
        mode: FileMode.write,
        flush: true,
      );
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
