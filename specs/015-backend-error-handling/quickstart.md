# Quickstart: Enhanced Backend Error Handling

**Feature**: 015-backend-error-handling
**Date**: 2025-12-30
**Purpose**: Implementation guide for developers working on this feature

---

## Prerequisites

Before starting implementation, ensure you have:

1. ✅ Read and understood [spec.md](./spec.md) - Feature requirements and user stories
2. ✅ Read [research.md](./research.md) - Technical decisions and implementation patterns
3. ✅ Read [data-model.md](./data-model.md) - Entity definitions and relationships
4. ✅ Read [plan.md](./plan.md) - Architecture and constitution compliance
5. ✅ Have Flutter 3.x+ and Dart 3.10+ installed
6. ✅ Have access to BlenderAPI staging environment for testing

---

## Step 1: Add Dependencies

Add the following packages to `pubspec.yaml`:

```yaml
dependencies:
  # NEW - Add these packages
  connectivity_plus: ^7.0.0      # Network state monitoring
  flutter_json_view: ^1.1.3      # JSON pretty-printing for diagnostics UI

  # ALREADY HAVE - Verify versions
  path_provider: ^2.1.5          # Local file storage
  shared_preferences: ^2.2.2     # Queue persistence
  http: ^1.1.0                   # HTTP client
  json_annotation: ^4.9.0        # JSON serialization annotations

dev_dependencies:
  # ALREADY HAVE
  json_serializable: ^6.8.0      # JSON code generation
  mocktail: ^1.0.0               # Mocking for tests
```

Run:
```bash
flutter pub get
```

---

## Step 2: TDD Workflow Overview

**CRITICAL**: This feature MUST follow Test-Driven Development (Red-Green-Refactor):

```
For EACH component:
  1. RED:    Write failing test that defines expected behavior
  2. GREEN:  Write minimal code to make test pass
  3. REFACTOR: Improve code quality while keeping tests green
  4. COMMIT: Commit after each component completion
```

**Test execution order**:
1. Unit tests for models (ErrorContext serialization)
2. Unit tests for services (ErrorMessageService, RetryPolicyService, etc.)
3. Widget tests for UI components (OfflineBanner, SessionDiagnosticsScreen)
4. Integration tests for end-to-end flows

---

## Step 3: Implementation Order

Follow this sequence to maintain TDD discipline and minimize integration issues:

### Phase A: Data Models (Models-First)

**Why first**: All services depend on these models

1. **ErrorContext** model
   - File: `lib/features/scanning/models/error_context.dart`
   - Test: `test/features/scanning/models/error_context_test.dart`
   - Focus: JSON serialization, validation, `withRetry()` method

2. **SessionDiagnostics** models
   - File: `lib/features/scanning/models/session_diagnostics.dart`
   - Test: `test/features/scanning/models/session_diagnostics_test.dart`
   - Includes: SessionDiagnostics, WorkspaceFilesInfo, DirectoryInfo, FileInfo, LogSummary, ErrorDetails
   - Focus: JSON deserialization from API response, helper methods

3. **PendingOperation** model
   - File: `lib/features/scanning/models/pending_operation.dart`
   - Test: `test/features/scanning/models/pending_operation_test.dart`
   - Focus: JSON serialization for queue persistence, `withRetry()` method

**Generate JSON code**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Phase B: Core Services (Services Layer)

**Why second**: Services use models, UI uses services

4. **ErrorMessageService** - Error code → user message mapping
   - File: `lib/features/scanning/services/error_message_service.dart`
   - Test: `test/features/scanning/services/error_message_service_test.dart`
   - Focus: Lookup table accuracy, i18n integration, fallback messages
   - Dependencies: Existing `I18nService`

5. **RetryPolicyService** - Error classification & exponential backoff
   - File: `lib/features/scanning/services/retry_policy_service.dart`
   - Test: `test/features/scanning/services/retry_policy_service_test.dart`
   - Focus: `isRecoverable()` logic, `executeWithRetry()` retry limits, timing
   - Test with `fake_async` package for time manipulation

6. **ErrorLogService** - Local JSON log persistence
   - File: `lib/features/scanning/services/error_log_service.dart`
   - Test: `test/features/scanning/services/error_log_service_test.dart`
   - Focus: File I/O, log cleanup (7-day TTL), filtering
   - Dependencies: `path_provider`

7. **ConnectivityService** - Offline queue management
   - File: `lib/features/scanning/services/connectivity_service.dart`
   - Test: `test/features/scanning/services/connectivity_service_test.dart`
   - Focus: Queue persistence, connectivity monitoring, automatic retry
   - Dependencies: `connectivity_plus`, `shared_preferences`

8. **SessionInvestigationService** - API client for `/investigate` endpoint
   - File: `lib/features/scanning/services/session_investigation_service.dart`
   - Test: `test/features/scanning/services/session_investigation_service_test.dart`
   - Focus: HTTP request/response, error handling, retry integration
   - Dependencies: `http`, `RetryPolicyService`

---

### Phase C: UI Components (Presentation Layer)

**Why third**: UI depends on services and models

9. **OfflineBanner** widget - Offline indicator banner
   - File: `lib/features/scanning/widgets/offline_banner.dart`
   - Test: `test/features/scanning/widgets/offline_banner_test.dart`
   - Focus: StreamBuilder for connectivity, accessibility labels
   - Dependencies: `connectivity_plus`

10. **SessionDiagnosticsScreen** - Diagnostic details screen
    - File: `lib/features/scanning/screens/session_diagnostics_screen.dart`
    - Test: `test/features/scanning/screens/session_diagnostics_screen_test.dart`
    - Focus: FutureBuilder for API call, expandable sections, JSON display
    - Dependencies: `SessionInvestigationService`, `flutter_json_view`

---

### Phase D: Integration & Error Handling

**Why last**: Integrates all components into existing BlenderAPI client

11. **Integrate with BlenderApiClient**
    - File: `lib/features/scanning/services/blender_api_client.dart` (MODIFY existing)
    - Test: `test/features/scanning/services/blender_api_client_test.dart` (UPDATE existing)
    - Changes:
      - Wrap API calls with `RetryPolicyService.executeWithRetry()`
      - Use `ErrorMessageService` for user-facing error messages
      - Log errors to `ErrorLogService`
      - Queue failed operations in `ConnectivityService` when offline

12. **Update i18n translations**
    - Files: `lib/core/i18n/en.json`, `de.json`, `pt.json` (MODIFY existing)
    - Add error message translations per research.md section 1
    - Test: Manual verification, i18n service unit tests

13. **Integration tests**
    - File: `test/integration/error_handling_flow_test.dart`
    - Focus: End-to-end retry flow, offline → online transition, error display

---

## Step 4: TDD Example (ErrorMessageService)

Here's a concrete TDD example for implementing ErrorMessageService:

### RED: Write Failing Test First

```dart
// test/features/scanning/services/error_message_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/features/scanning/services/error_message_service.dart';

class MockI18nService extends Mock implements I18nService {}

void main() {
  group('ErrorMessageService', () {
    late MockI18nService mockI18n;
    late ErrorMessageService service;

    setUp(() {
      mockI18n = MockI18nService();
      service = ErrorMessageService(mockI18n);
    });

    test('getUserMessage returns translated message for error code', () {
      // Arrange
      when(() => mockI18n.translate('error.invalid_file'))
          .thenReturn('File format not supported');

      // Act
      final message = service.getUserMessage('invalid_file', null);

      // Assert
      expect(message, 'File format not supported');
      verify(() => mockI18n.translate('error.invalid_file')).called(1);
    });

    test('getUserMessage returns HTTP status fallback when error code unknown', () {
      // Arrange
      when(() => mockI18n.translate('error.not_found'))
          .thenReturn('Session not found or expired');

      // Act
      final message = service.getUserMessage('unknown_code', 404);

      // Assert
      expect(message, 'Session not found or expired');
      verify(() => mockI18n.translate('error.not_found')).called(1);
    });

    // ... more test cases
  });
}
```

**Run test**:
```bash
flutter test test/features/scanning/services/error_message_service_test.dart
```

**Expected**: ❌ Test fails (ErrorMessageService doesn't exist yet)

### GREEN: Implement Minimal Code

```dart
// lib/features/scanning/services/error_message_service.dart
import 'package:vronmobile2/core/i18n/i18n_service.dart';

class ErrorMessageService {
  final I18nService _i18n;

  ErrorMessageService(this._i18n);

  String getUserMessage(String errorCode, int? httpStatus) {
    // Lookup error code first
    final key = _errorCodeMap[errorCode];
    if (key != null) {
      return _i18n.translate(key) ?? 'An error occurred';
    }

    // Fallback to HTTP status
    if (httpStatus != null) {
      final statusKey = _httpStatusMap[httpStatus];
      if (statusKey != null) {
        return _i18n.translate(statusKey) ?? 'An error occurred';
      }
    }

    return _i18n.translate('error.unknown') ?? 'An error occurred';
  }

  static const Map<String, String> _errorCodeMap = {
    'invalid_file': 'error.invalid_file',
    // ... more mappings
  };

  static const Map<int, String> _httpStatusMap = {
    404: 'error.not_found',
    // ... more mappings
  };
}
```

**Run test**:
```bash
flutter test test/features/scanning/services/error_message_service_test.dart
```

**Expected**: ✅ Tests pass

### REFACTOR: Improve Code Quality

- Add `getRecommendedAction()` method
- Extract constants to separate class
- Add comprehensive error code mappings
- Add documentation comments

**Run tests after each refactor** to ensure they stay green.

### COMMIT

```bash
git add lib/features/scanning/services/error_message_service.dart
git add test/features/scanning/services/error_message_service_test.dart
git commit -m "feat(error-handling): implement ErrorMessageService with i18n integration

- Add centralized error code → user message mapping
- Integrate with existing I18nService
- Support fallback to HTTP status messages
- Add comprehensive unit tests with mocktail

Tests: 5 passing
Coverage: 100% (error_message_service.dart)

Related: #015-backend-error-handling"
```

---

## Step 5: Running Tests

### Unit Tests (Service/Model Layer)

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/scanning/services/error_message_service_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Target**: 90%+ code coverage for services and models

### Widget Tests (UI Layer)

```bash
# Run specific widget test
flutter test test/features/scanning/widgets/offline_banner_test.dart

# Run all widget tests
flutter test --tags widget
```

### Integration Tests

```bash
# Run integration tests
flutter test test/integration/error_handling_flow_test.dart
```

---

## Step 6: Manual Testing Checklist

After automated tests pass, perform manual testing:

### Error Message Display
- [ ] Trigger invalid file error → Verify user-friendly message displayed
- [ ] Trigger network error → Verify "Will retry when online" banner shown
- [ ] Trigger rate limit error → Verify automatic retry after delay
- [ ] Trigger server error → Verify retry with exponential backoff

### Offline Queue
- [ ] Enable airplane mode → Upload file → Verify queued
- [ ] Disable airplane mode → Verify automatic retry
- [ ] Multiple errors queued → Verify all processed when online

### Session Investigation
- [ ] Tap "View Session Details" on error → Verify diagnostics screen opens
- [ ] Verify session ID displayed and copyable
- [ ] Verify file structure displayed
- [ ] Verify logs summary displayed
- [ ] Verify error details displayed (for failed sessions)

### Retry Logic
- [ ] Verify retry attempts logged (2s, 4s, 8s delays)
- [ ] Verify max 3 retries enforced
- [ ] Verify non-recoverable errors NOT retried (400, 404)

### Accessibility
- [ ] Enable TalkBack (Android) / VoiceOver (iOS)
- [ ] Verify offline banner announced
- [ ] Verify error details screen navigable
- [ ] Verify session ID copyable via accessibility actions

---

## Step 7: Debugging Tips

### Common Issues

**Issue**: JSON serialization fails
```
Solution: Run build_runner again
flutter pub run build_runner build --delete-conflicting-outputs
```

**Issue**: Tests fail with "Bad state: No element"
```
Solution: Check mock setup, ensure all required mocks are configured
```

**Issue**: Retry logic not triggering
```
Solution: Verify RetryPolicy.isRecoverable() classification is correct
Add debug logging to see error code and HTTP status
```

**Issue**: Offline queue not persisting
```
Solution: Verify SharedPreferences mocked correctly in tests
Check queue serialization in _persistQueue()
```

### Debugging Tools

1. **Flutter DevTools**: Monitor network calls, performance
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```

2. **Network inspection**: Use Charles Proxy or mitmproxy to inspect BlenderAPI calls

3. **Log filtering**:
   ```dart
   import 'package:flutter/foundation.dart';

   if (kDebugMode) {
     print('[ErrorHandler] Retry attempt $attempt for error: $errorCode');
   }
   ```

---

## Step 8: Integration with Existing Code

### Update BlenderApiClient

**Before** (existing code):
```dart
final response = await http.post(uri, body: body);
if (response.statusCode != 200) {
  throw Exception('Upload failed: ${response.body}');
}
```

**After** (with error handling):
```dart
try {
  final response = await _retryPolicy.executeWithRetry(
    operation: () => http.post(uri, body: body),
    isRecoverableError: (error) {
      if (error is http.Response) {
        return _retryPolicy.isRecoverable(error.statusCode, null);
      }
      return true; // Network errors are recoverable
    },
    onRetry: (attempt, error) {
      _logError(ErrorContext(
        timestamp: DateTime.now(),
        httpStatus: error is http.Response ? error.statusCode : null,
        message: 'Upload failed, retrying (attempt $attempt)',
        retryCount: attempt,
        isRecoverable: true,
      ));
    },
  );

  if (response.statusCode != 200) {
    throw BlenderApiException(
      statusCode: response.statusCode,
      message: _errorMessageService.getUserMessage(null, response.statusCode),
    );
  }
} catch (e) {
  // Log error
  await _errorLogService.logError(ErrorContext(
    timestamp: DateTime.now(),
    httpStatus: e is BlenderApiException ? e.statusCode : null,
    message: _errorMessageService.getUserMessage(null, null),
    technicalMessage: e.toString(),
    retryCount: 3, // Max retries exhausted
    isRecoverable: false,
  ));

  // Queue for offline retry if no connectivity
  if (!(await _connectivityService.isOnline())) {
    await _connectivityService.queueOperation(
      operationId: 'upload_${DateTime.now().millisecondsSinceEpoch}',
      operation: () => http.post(uri, body: body),
      error: ErrorContext(/* ... */),
    );
  }

  rethrow;
}
```

---

## Step 9: Performance Optimization

### Checklist

- [ ] Error logging is async (doesn't block UI)
- [ ] JSON parsing runs in isolate for large logs (>1MB)
- [ ] Connectivity stream subscription disposed properly
- [ ] File I/O uses `writeAsString` async variant
- [ ] UI maintains 60fps during error display (test with performance overlay)

### Performance Testing

```dart
// Performance test example
test('logError completes in <50ms', () async {
  final stopwatch = Stopwatch()..start();
  await errorLogService.logError(testErrorContext);
  stopwatch.stop();

  expect(stopwatch.elapsedMilliseconds, lessThan(50));
});
```

---

## Step 10: Documentation

### Required Documentation

1. **Update CHANGELOG.md**:
   ```markdown
   ## [Unreleased]
   ### Added
   - Enhanced backend error handling with automatic retry logic
   - User-friendly error messages with actionable guidance
   - Session investigation diagnostics screen
   - Offline queue for failed operations
   ```

2. **Update README.md** (if applicable):
   - Add section on error handling capabilities
   - Document new environment variables (if any)

3. **Code comments**:
   - Document complex retry logic
   - Explain error classification rules
   - Add examples for error mapping

---

## Next Steps

After completing implementation and testing:

1. ✅ Run full test suite: `flutter test`
2. ✅ Check code coverage: Target 90%+ for new code
3. ✅ Run linter: `flutter analyze`
4. ✅ Format code: `flutter format lib test`
5. ✅ Manual testing checklist completed
6. ✅ Create pull request with detailed description
7. ✅ Request code review from team

**For task breakdown**, run:
```bash
/speckit.tasks
```

This will generate `tasks.md` with detailed implementation tasks derived from this quickstart guide.

---

**End of Quickstart Guide**
