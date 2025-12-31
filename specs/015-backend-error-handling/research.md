# Research: Enhanced Backend Error Handling

**Feature**: 015-backend-error-handling
**Date**: 2025-12-30
**Purpose**: Resolve technical unknowns from Technical Context and establish implementation patterns

## Overview

This document captures research findings and technical decisions for implementing comprehensive error handling for BlenderAPI integration in the Flutter mobile app. Key areas researched: error message mapping service pattern, retry policy with exponential backoff, local JSON log storage, offline queue management, and session investigation UI patterns.

---

## 1. Error Message Mapping Service Pattern

### Decision
Implement **centralized service class** (`ErrorMessageService`) using static lookup map with i18n integration.

### Rationale
- **Maintainability**: Single source of truth for all error mappings, easy to update and test
- **Localization**: Integrates with existing i18n infrastructure (`lib/core/i18n/*.json`)
- **Testability**: Pure functions with no side effects, straightforward unit testing
- **Performance**: O(1) lookup time using Map<String, String> keyed by error code
- **Type Safety**: Dart's strong typing ensures compile-time safety for error codes

### Implementation Pattern

```dart
// lib/features/scanning/services/error_message_service.dart
class ErrorMessageService {
  final I18nService _i18n;

  ErrorMessageService(this._i18n);

  /// Maps technical error code + HTTP status to user-friendly message
  String getUserMessage(String errorCode, int? httpStatus) {
    // Lookup in predefined mapping table
    final key = _getErrorKey(errorCode, httpStatus);
    return _i18n.translate(key) ?? _getDefaultMessage(httpStatus);
  }

  /// Returns recommended action for error
  String getRecommendedAction(String errorCode, int? httpStatus) {
    final key = '${_getErrorKey(errorCode, httpStatus)}_action';
    return _i18n.translate(key) ?? _i18n.translate('error.default_action');
  }

  String _getErrorKey(String errorCode, int? httpStatus) {
    // Priority: specific error code > HTTP status category
    if (_errorCodeMap.containsKey(errorCode)) {
      return _errorCodeMap[errorCode]!;
    }
    return _httpStatusMap[httpStatus] ?? 'error.unknown';
  }

  // Error code mapping table
  static const Map<String, String> _errorCodeMap = {
    'invalid_file': 'error.invalid_file',
    'file_too_large': 'error.file_too_large',
    'malformed_usdz': 'error.malformed_usdz',
    'processing_timeout': 'error.processing_timeout',
    'memory_limit': 'error.memory_limit',
    // ... ~50 error codes
  };

  // HTTP status mapping (fallback)
  static const Map<int, String> _httpStatusMap = {
    400: 'error.bad_request',
    401: 'error.unauthorized',
    403: 'error.forbidden',
    404: 'error.not_found',
    413: 'error.payload_too_large',
    429: 'error.rate_limit',
    500: 'error.server_error',
    503: 'error.service_unavailable',
  };
}
```

### i18n Integration

Add to `lib/core/i18n/en.json`:

```json
{
  "error": {
    "invalid_file": "File format not supported",
    "invalid_file_action": "Please upload a valid USDZ file from iOS LiDAR scan",
    "file_too_large": "File size exceeds 250 MB limit",
    "file_too_large_action": "Try scanning a smaller area or reducing scan detail",
    "processing_timeout": "Conversion took too long and was cancelled",
    "processing_timeout_action": "Try again with a simpler scan or smaller file",
    "memory_limit": "File too complex for processing",
    "memory_limit_action": "Scan a smaller area with less detail",
    "session_expired": "Session expired after 1 hour",
    "session_expired_action": "Upload your file again to start a new conversion",
    "service_unavailable": "Conversion service temporarily unavailable",
    "service_unavailable_action": "We'll retry automatically when service recovers",
    "network_error": "Network connection lost",
    "network_error_action": "Check your internet connection. We'll retry when back online",
    "default_action": "Contact support with session ID for assistance"
  }
}
```

### Key Dependencies
- Existing: `lib/core/i18n/i18n_service.dart` (no new packages required)
- Pattern matches existing OAuth error mapper: `lib/features/auth/utils/oauth_error_mapper.dart`

### Alternatives Considered
- **Backend-driven messages**: Rejected - requires backend changes, increases API response size, no client-side fallback for network errors
- **External JSON config file**: Rejected - adds complexity, no type safety, harder to maintain translations
- **Inline conditionals**: Rejected - violates DRY, not testable, no localization support

---

## 2. Retry Policy with Exponential Backoff

### Decision
Implement **RetryPolicyService** with predefined error classification map and exponential backoff using Dart's `Future.delayed`.

### Rationale
- **Simple Implementation**: No external packages needed, uses Dart's built-in async primitives
- **Explicit Control**: Clear retry limits (3 attempts, 1 minute window) prevent infinite loops
- **Error Classification**: Lookup table approach (consistent with error mapping service)
- **Non-Blocking**: Uses async/await pattern, doesn't block UI thread
- **Testable**: Can mock timing in unit tests using fake async

### Implementation Pattern

```dart
// lib/features/scanning/services/retry_policy_service.dart
class RetryPolicyService {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxWindow = Duration(minutes: 1);

  /// Classifies error as recoverable (auto-retry) or non-recoverable
  bool isRecoverable(int? httpStatus, String? errorCode) {
    // Check error code first (more specific)
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
        final delay = baseDelay * math.pow(2, attempt - 1);

        onRetry?.call(attempt, error);

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
```

### Usage Example

```dart
final retryPolicy = RetryPolicyService();

final response = await retryPolicy.executeWithRetry(
  operation: () => http.get(Uri.parse(url)),
  isRecoverableError: (error) {
    if (error is HttpException) {
      return retryPolicy.isRecoverable(error.statusCode, error.errorCode);
    }
    return true; // Network errors are recoverable
  },
  onRetry: (attempt, error) {
    print('Retry attempt $attempt after error: $error');
  },
);
```

### Key Dependencies
- Built-in: `dart:async` (Future, Duration)
- Built-in: `dart:math` (for exponential calculation)
- No external packages required

### Alternatives Considered
- **dio package with RetryInterceptor**: Rejected - adds 1MB+ dependency, overkill for simple retry logic
- **http_retry package**: Rejected - not actively maintained, adds dependency
- **Adaptive backoff**: Rejected - violates YAGNI, simple exponential sufficient

---

## 3. Local JSON Log Storage

### Decision
Implement **ErrorLogService** using `path_provider` for file location and JSON array append with periodic cleanup.

### Rationale
- **Simplicity**: Append-only file, no database overhead
- **Performance**: Async file I/O doesn't block UI, efficient for mobile
- **Portability**: JSON format is human-readable and easily exportable for support
- **Size Management**: 7-day TTL with automatic cleanup prevents unbounded growth
- **Filtering**: JSON structure allows programmatic filtering by session, error type, date

### Implementation Pattern

```dart
// lib/features/scanning/services/error_log_service.dart
class ErrorLogService {
  static const String _logFileName = 'error_logs.json';
  static const Duration _retentionPeriod = Duration(days: 7);
  static const int _maxLogEntries = 1000;

  Future<void> logError(ErrorContext error) async {
    final file = await _getLogFile();

    // Read existing logs
    final logs = await _readLogs(file);

    // Add new error
    logs.add(error.toJson());

    // Cleanup old entries (keep last 1000 or within 7 days)
    final cleaned = _cleanupLogs(logs);

    // Write back to file
    await file.writeAsString(
      jsonEncode(cleaned),
      flush: true,
    );
  }

  Future<List<ErrorContext>> getRecentErrors({
    String? sessionId,
    DateTime? since,
    int? limit,
  }) async {
    final file = await _getLogFile();
    final logs = await _readLogs(file);

    // Filter
    var filtered = logs.where((log) {
      if (sessionId != null && log['sessionId'] != sessionId) return false;
      if (since != null) {
        final timestamp = DateTime.parse(log['timestamp']);
        if (timestamp.isBefore(since)) return false;
      }
      return true;
    }).toList();

    // Limit
    if (limit != null && filtered.length > limit) {
      filtered = filtered.sublist(filtered.length - limit);
    }

    return filtered.map((json) => ErrorContext.fromJson(json)).toList();
  }

  Future<void> clearLogs() async {
    final file = await _getLogFile();
    await file.writeAsString('[]');
  }

  Future<File> _getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_logFileName');
  }

  Future<List<Map<String, dynamic>>> _readLogs(File file) async {
    if (!await file.exists()) {
      return [];
    }

    final contents = await file.readAsString();
    if (contents.isEmpty) {
      return [];
    }

    final List<dynamic> json = jsonDecode(contents);
    return json.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _cleanupLogs(List<Map<String, dynamic>> logs) {
    final cutoff = DateTime.now().subtract(_retentionPeriod);

    // Filter by age
    var cleaned = logs.where((log) {
      final timestamp = DateTime.parse(log['timestamp']);
      return timestamp.isAfter(cutoff);
    }).toList();

    // Limit by count (keep most recent)
    if (cleaned.length > _maxLogEntries) {
      cleaned = cleaned.sublist(cleaned.length - _maxLogEntries);
    }

    return cleaned;
  }
}
```

### Performance Considerations
- **File Size**: ~10KB per 100 errors (assuming ~100 bytes per error) = ~100KB for 1000 errors
- **Read Performance**: O(n) for filtering, acceptable for 1000 entries on mobile
- **Write Performance**: Async write doesn't block UI, cleanup only on write (not read)
- **Concurrency**: Single file, no concurrent write issues (app is single-threaded)

### Key Dependencies
- `path_provider` ^2.1.5 (already in pubspec.yaml)
- `dart:convert` (built-in for JSON encoding)
- `dart:io` (built-in for File I/O)

### Alternatives Considered
- **SQLite database (sqflite)**: Rejected - overkill for append-only logs, adds 1MB+ dependency, complex queries not needed
- **Hive NoSQL**: Rejected - adds dependency, binary format not human-readable for support
- **Plain text log file**: Rejected - no structure, hard to filter/query programmatically

---

## 4. Offline Queue Management

### Decision
Implement **ConnectivityService** using `connectivity_plus` package with in-memory queue persisted to `shared_preferences` on app lifecycle events.

### Rationale
- **Reliability**: `connectivity_plus` is official Flutter plugin, actively maintained
- **Simplicity**: In-memory queue for fast access, persisted only on app pause/terminate
- **User Feedback**: Stream-based connectivity changes trigger UI updates automatically
- **Battery Efficient**: No background polling, uses platform connectivity callbacks
- **Recovery**: Automatic retry when connectivity restored via Stream listener

### Implementation Pattern

```dart
// lib/features/scanning/services/connectivity_service.dart
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final SharedPreferences _prefs;
  final RetryPolicyService _retryPolicy;

  final List<PendingOperation> _queue = [];
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService(this._prefs, this._retryPolicy);

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Load persisted queue from disk
    await _loadQueue();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Process queue if already online
    final status = await _connectivity.checkConnectivity();
    if (_isOnline(status)) {
      _processQueue();
    }
  }

  /// Queue operation for retry when online
  Future<void> queueOperation({
    required String operationId,
    required Future<void> Function() operation,
    required ErrorContext error,
  }) async {
    _queue.add(PendingOperation(
      id: operationId,
      operation: operation,
      error: error,
      queuedAt: DateTime.now(),
    ));

    await _persistQueue();
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    final status = await _connectivity.checkConnectivity();
    return _isOnline(status);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) =>
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_isOnline(results)) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty) return;

    // Process each queued operation
    final pending = List<PendingOperation>.from(_queue);

    for (final op in pending) {
      try {
        await _retryPolicy.executeWithRetry(
          operation: op.operation,
          isRecoverableError: (_) => false, // Already classified as recoverable
        );

        // Success - remove from queue
        _queue.remove(op);
      } catch (e) {
        // Still failing - keep in queue for next connectivity event
        print('Queued operation ${op.id} failed: $e');
      }
    }

    await _persistQueue();
  }

  Future<void> _persistQueue() async {
    final json = _queue.map((op) => op.toJson()).toList();
    await _prefs.setString('error_queue', jsonEncode(json));
  }

  Future<void> _loadQueue() async {
    final stored = _prefs.getString('error_queue');
    if (stored != null) {
      final List<dynamic> json = jsonDecode(stored);
      _queue.addAll(json.map((j) => PendingOperation.fromJson(j)));
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

class PendingOperation {
  final String id;
  final Future<void> Function() operation;
  final ErrorContext error;
  final DateTime queuedAt;

  PendingOperation({
    required this.id,
    required this.operation,
    required this.error,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'error': error.toJson(),
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    // Note: operation cannot be serialized, must be reconstructed from context
    throw UnimplementedError('Operation reconstruction not yet implemented');
  }
}
```

### UI Integration

```dart
// lib/features/scanning/widgets/offline_banner.dart
class OfflineBanner extends StatelessWidget {
  final ConnectivityService connectivity;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.hasData &&
          snapshot.data!.any((r) => r != ConnectivityResult.none);

        if (isOnline) return SizedBox.shrink();

        return MaterialBanner(
          backgroundColor: Colors.orange.shade100,
          content: Semantics(
            label: 'Device is offline',
            child: Text(
              'No internet connection. Will retry when online.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
          actions: [SizedBox.shrink()],
        );
      },
    );
  }
}
```

### Key Dependencies
- **NEEDS TO ADD**: `connectivity_plus` ^7.0.0 (network state monitoring)
- Existing: `shared_preferences` ^2.2.2 (queue persistence)

### Alternatives Considered
- **workmanager package**: Rejected - complex setup, battery drain, overkill for retry queue
- **Flutter background isolates**: Rejected - violates simplicity, app lifecycle hooks sufficient
- **Custom polling**: Rejected - battery inefficient, `connectivity_plus` uses platform callbacks

---

## 5. Session Investigation UI

### Decision
Implement **SessionDiagnosticsScreen** with expandable sections, JSON pretty-printing, and clipboard integration using built-in Material widgets.

### Rationale
- **Material Design**: Use `ExpansionTile` for collapsible sections (familiar UX pattern)
- **Developer-Friendly**: JSON pretty-printing with syntax highlighting using `flutter_json_view` package
- **Accessibility**: Copy-to-clipboard for session IDs supports screen readers
- **Performance**: Lazy loading of diagnostic data (fetch on screen open, not on error)
- **Reusable**: Can be launched from any error screen or support menu

### Implementation Pattern

```dart
// lib/features/scanning/screens/session_diagnostics_screen.dart
class SessionDiagnosticsScreen extends StatelessWidget {
  final String sessionId;
  final SessionInvestigationService _service;

  SessionDiagnosticsScreen({
    required this.sessionId,
    required SessionInvestigationService service,
  }) : _service = service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => _copySessionId(context),
            tooltip: 'Copy Session ID',
            semanticLabel: 'Copy session ID to clipboard',
          ),
        ],
      ),
      body: FutureBuilder<SessionDiagnostics>(
        future: _service.investigate(sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final diagnostics = snapshot.data!;
          return _buildDiagnostics(diagnostics);
        },
      ),
    );
  }

  Widget _buildDiagnostics(SessionDiagnostics diagnostics) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSection('Session Info', [
          _buildKeyValue('Session ID', diagnostics.sessionId),
          _buildKeyValue('Status', diagnostics.sessionStatus),
          _buildKeyValue('Created', diagnostics.createdAt.toString()),
          _buildKeyValue('Expires', diagnostics.expiresAt.toString()),
        ]),

        _buildExpandableSection(
          'Workspace Files',
          diagnostics.files != null
            ? _buildFileTree(diagnostics.files!)
            : Text('No workspace files'),
        ),

        if (diagnostics.logsSummary != null)
          _buildExpandableSection(
            'Logs',
            _buildLogsSummary(diagnostics.logsSummary!),
          ),

        if (diagnostics.errorDetails != null)
          _buildExpandableSection(
            'Error Details',
            _buildErrorDetails(diagnostics.errorDetails!),
          ),

        _buildExpandableSection(
          'Raw JSON',
          JsonView.map(diagnostics.toJson()),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  void _copySessionId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
```

### Key Dependencies
- **NEEDS TO ADD**: `flutter_json_view` ^1.1.3 (JSON pretty-printing with syntax highlighting)
- Built-in: `ExpansionTile`, `SelectableText`, `Clipboard` (Material widgets)

### Alternatives Considered
- **Custom JSON renderer**: Rejected - reinventing wheel, `flutter_json_view` is well-tested
- **WebView with JSON formatter**: Rejected - heavyweight, offline issues, accessibility concerns
- **Plain text JSON**: Rejected - poor UX, hard to read nested structures

---

## Summary of Decisions

| Area | Decision | Key Package | Rationale |
|------|----------|-------------|-----------|
| Error Mapping | Centralized ErrorMessageService with i18n | Built-in | Maintainability, localization, testability |
| Retry Logic | RetryPolicyService with exponential backoff | Built-in | Simplicity, explicit control, non-blocking |
| Log Storage | ErrorLogService with JSON file append | `path_provider` | Simple, portable, efficient for mobile |
| Offline Queue | ConnectivityService with shared_preferences | `connectivity_plus` | Reliable, battery-efficient, user feedback |
| Diagnostics UI | SessionDiagnosticsScreen with ExpansionTile | `flutter_json_view` | Material Design, accessible, developer-friendly |

## Packages to Add to pubspec.yaml

```yaml
dependencies:
  connectivity_plus: ^7.0.0  # Network state monitoring
  flutter_json_view: ^1.1.3  # JSON pretty-printing for diagnostics UI

# Already have:
# - path_provider: ^2.1.5
# - shared_preferences: ^2.2.2
# - http: ^1.1.0
# - json_annotation: ^4.9.0

dev_dependencies:
  # Already have:
  # - json_serializable: ^6.8.0
  # - mocktail: ^1.0.0
```

## Technical Context Resolved

All "NEEDS CLARIFICATION" items from Technical Context have been resolved:

- ✅ `connectivity_plus` ^7.0.0 selected for offline detection
- ✅ Error mapping pattern defined (centralized service with i18n)
- ✅ Retry strategy defined (exponential backoff with predefined error classification)
- ✅ Local storage format defined (JSON file in Documents directory)
- ✅ Offline queue implementation defined (in-memory with shared_preferences persistence)
- ✅ Session diagnostics UI pattern defined (Material ExpansionTile with JSON viewer)

---

**End of Research Document**
