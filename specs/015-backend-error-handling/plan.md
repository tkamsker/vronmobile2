# Implementation Plan: Enhanced Backend Error Handling

**Branch**: `015-backend-error-handling` | **Date**: 2025-12-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-backend-error-handling/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement comprehensive error handling for BlenderAPI integration with automatic retry logic, user-friendly error messages, session investigation capabilities, and offline queue management. System captures detailed error context, distinguishes recoverable from non-recoverable errors using predefined mapping table, persists errors as structured JSON logs locally, and provides API-based session diagnostics via `/sessions/{id}/investigate` endpoint. Target 80% reduction in support tickets through enhanced error messages and self-service troubleshooting.

## Technical Context

**Language/Version**: Dart 3.10+, Flutter 3.x
**Primary Dependencies**:
- `http` ^1.1.0 (HTTP client for BlenderAPI calls with retry logic)
- `path_provider` ^2.1.5 (local storage for error logs)
- `json_annotation` ^4.9.0 / `json_serializable` ^6.8.0 (error context serialization)
- `connectivity_plus` (NEEDS CLARIFICATION - to be added for offline detection)
- Existing: `graphql_flutter` ^5.1.0, `flutter_secure_storage` ^9.0.0

**Storage**: Local file system (JSON error logs in Documents directory), shared_preferences for app state
**Testing**: flutter_test (unit, widget, integration), mocktail ^1.0.0 for mocking
**Target Platform**: iOS 16.0+ (LiDAR support), Android API 21+ (GLB upload only)
**Project Type**: Mobile (feature-based architecture)
**Performance Goals**:
- Error handling overhead < 50ms per error
- Log file I/O non-blocking
- Retry logic maintains 60fps UI responsiveness
- Session investigation API call < 2 seconds (p95)

**Constraints**:
- Offline-capable (queue errors when no connectivity)
- Max 3 automatic retries within 1 minute window
- Local error logs cleaned up after 7 days
- Must not block UI thread during error processing
- Binary size impact < 500KB for error handling subsystem

**Scale/Scope**:
- Handle 100+ errors per session without performance degradation
- Support 1000+ error log entries in local JSON file
- Error mapping table: ~50 error codes
- User message translations: 3 languages (en, de, pt)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)

✅ **PASS** - TDD approach confirmed:
- Write unit tests for ErrorMessageService lookup logic BEFORE implementation
- Write unit tests for RetryPolicy error classification BEFORE implementation
- Write unit tests for ErrorContext JSON serialization BEFORE implementation
- Write widget tests for error UI components (offline banner, error details screen) BEFORE implementation
- Write integration tests for end-to-end retry flow (mock BlenderAPI failures) BEFORE implementation
- Red-Green-Refactor cycle enforced throughout error handling subsystem

### II. Simplicity & YAGNI

✅ **PASS** - Simple, requirement-driven approach:
- Error mapping service is lookup table, not complex rules engine
- Retry policy is simple exponential backoff (2s, 4s, 8s), not adaptive algorithm
- Local JSON logging is append-only file, not database
- Offline queue is in-memory list persisted on app pause, not background worker service
- No abstraction until 3+ concrete use cases proven (only one use case: BlenderAPI errors)
- Reusing existing packages (`http`, `path_provider`, `connectivity_plus`) over custom implementations

### III. Platform-Native Patterns

✅ **PASS** - Flutter/Dart idioms followed:
- Using Dart's `Future`/`async-await` for retry logic
- Using Flutter's `StreamBuilder` for connectivity monitoring
- Using `json_serializable` for ErrorContext serialization (standard Dart pattern)
- Feature-based architecture: `lib/features/scanning/services/error_*`
- Material Design for error UI (SnackBar for offline banner, ExpansionTile for session details)
- Platform-adaptive error messages (no platform-specific error handling needed for this feature)

### Security & Privacy Requirements

✅ **PASS** - Security considerations addressed:
- Session IDs stored in encrypted logs? NO - session IDs are not secrets, only used for support diagnostics
- API key authentication required for `/sessions/{id}/investigate` endpoint (per PRD_SESSION_INVESTIGATION_API.md)
- Local error logs do NOT contain API keys, user passwords, or auth tokens
- Stack traces sanitized to remove sensitive file paths before logging
- User ID stored in error context is non-sensitive identifier

### Performance Standards

✅ **PASS** - Performance targets defined:
- Error handling overhead < 50ms per error (measured with Flutter DevTools)
- Retry logic non-blocking (uses isolates if needed for JSON parsing)
- Log file I/O async (uses `path_provider` with `File.writeAsString` async methods)
- UI maintains 60fps during error display and retry (verified with performance overlay)

### Accessibility Requirements

✅ **PASS** - Accessibility planned:
- Offline banner has semantic label for screen readers
- Error details screen uses Semantics widgets
- Session ID copyable via accessibility actions
- Touch targets ≥44x44 for "View Session Details" button
- Error messages respect `textScaleFactor` for dynamic text sizing

### CI/CD & DevOps Practices

✅ **PASS** - CI/CD compliance:
- Feature branch: `015-backend-error-handling` ✓
- TDD enforced (tests written first, CI fails if coverage drops)
- Atomic commits after each component (ErrorMessageService, RetryPolicy, etc.)
- Code review before merge to main
- Linting and formatting checks in CI pipeline

**GATE RESULT**: ✅ **ALL CHECKS PASSED** - Proceed to Phase 0 research

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── features/
│   └── scanning/
│       ├── models/
│       │   ├── error_context.dart              # ErrorContext entity (JSON serializable)
│       │   └── session_diagnostics.dart        # SessionDiagnostics response model
│       ├── services/
│       │   ├── error_message_service.dart      # Centralized error message mapping
│       │   ├── error_log_service.dart          # Local JSON log persistence
│       │   ├── retry_policy_service.dart       # Error classification & retry logic
│       │   ├── connectivity_service.dart       # Offline detection & queue management
│       │   └── session_investigation_service.dart  # Call /sessions/{id}/investigate API
│       ├── screens/
│       │   └── session_diagnostics_screen.dart # UI for viewing session details
│       └── widgets/
│           └── offline_banner.dart             # Offline indicator banner widget
└── core/
    ├── config/
    │   └── env_config.dart                     # (existing - add investigation endpoint config)
    └── i18n/
        ├── en.json                             # (existing - add error message translations)
        ├── de.json                             # (existing - add error message translations)
        └── pt.json                             # (existing - add error message translations)

test/
├── features/
│   └── scanning/
│       ├── models/
│       │   ├── error_context_test.dart         # Unit tests for ErrorContext serialization
│       │   └── session_diagnostics_test.dart   # Unit tests for SessionDiagnostics parsing
│       ├── services/
│       │   ├── error_message_service_test.dart # Unit tests for error mapping
│       │   ├── error_log_service_test.dart     # Unit tests for JSON log I/O
│       │   ├── retry_policy_service_test.dart  # Unit tests for retry classification
│       │   ├── connectivity_service_test.dart  # Unit tests for offline queue
│       │   └── session_investigation_service_test.dart  # Unit tests for API calls
│       ├── screens/
│       │   └── session_diagnostics_screen_test.dart  # Widget tests for diagnostics UI
│       └── widgets/
│           └── offline_banner_test.dart        # Widget tests for offline banner
└── integration/
    └── error_handling_flow_test.dart           # End-to-end retry and error flow tests
```

**Structure Decision**: Mobile feature-based architecture. Error handling is scoped to `lib/features/scanning/` since it's specific to BlenderAPI integration (USDZ→GLB conversion errors). Follows existing project pattern where scanning feature owns BlenderAPI client and models. Core translations extended for error messages in 3 languages (en, de, pt).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations** - All constitution checks passed. No complexity justifications required.
