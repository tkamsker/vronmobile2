# Implementation Plan: Google OAuth Login

**Branch**: `003-google-oauth-login` | **Date**: 2025-12-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-google-oauth-login/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement Google OAuth 2.0 authentication as an alternative login method alongside existing email/password authentication using a redirect-based mobile OAuth flow. Users will tap "Sign in with Google" to redirect to the backend OAuth endpoint, complete authentication with Google, and return to the app via deep link callback with an authorization code. The app exchanges this code for an access token via the `exchangeMobileAuthCode` GraphQL mutation. The implementation handles token storage securely, supports automatic account linking for existing email addresses, and follows Flutter best practices using the existing AuthService pattern.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- url_launcher ^6.2.0 (for OAuth redirect to backend endpoint)
- graphql_flutter 5.1.0 (existing - for exchangeMobileAuthCode mutation)
- flutter_secure_storage 9.0.0 (existing - for access token storage)

**Storage**:
- flutter_secure_storage for OAuth tokens (existing TokenStorage service)
- Backend PostgreSQL for user accounts (via GraphQL API)

**Deep Link Configuration**:
- Android: Custom URL scheme in AndroidManifest.xml (e.g., `vronapp://oauth-callback`)
- iOS: Universal Links or Custom URL scheme in Info.plist

**Testing**: flutter_test (Dart SDK), widget tests, unit tests, integration tests
**Target Platform**: iOS 15+ and Android API 21+ (dual platform mobile)
**Project Type**: Mobile application (Flutter feature-based architecture)

**Performance Goals**:
- OAuth flow completion < 45 seconds including redirect (per SC-001)
- Authorization code exchange < 3 seconds (per SC-008)
- Deep link callback handling < 500ms
- Maintain 60 fps during authentication UI transitions
- Token storage operations < 100ms

**Constraints**:
- Must integrate with existing AuthService pattern
- Must use existing TokenStorage and GraphQLService
- Must follow accessibility requirements (Semantics widgets)
- Deep link URL scheme must not conflict with existing app URLs
- Backend OAuth endpoint must be accessible from mobile devices
- Authorization codes are single-use and expire in 5-10 minutes

**Scale/Scope**:
- Single feature addition to existing app
- ~6-10 new/modified files (deep link handlers, OAuth redirect logic, mutation, tests)
- Integration with existing auth infrastructure
- Platform-specific deep link configuration (Android manifest, iOS Info.plist)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: TDD approach required for all implementation
- Tests MUST be written before code:
  - Unit tests for OAuth service methods (signInWithGoogle, handleAuthCode)
  - Widget tests for OAuthButton (already exists, may need enhancement)
  - Integration tests for complete OAuth flow
- Red-Green-Refactor cycle enforced

### II. Simplicity & YAGNI
- ✅ **PASS**: Implementation focused only on stated requirements
- Using existing patterns (AuthService, TokenStorage, GraphQLService)
- No premature abstraction for other OAuth providers (Facebook already has widget stub but not implemented)
- Minimal new code: add deep link handler, implement redirect logic, extend AuthService
- Reuse OAuthButton widget (already exists)
- No Google Sign-In SDK needed - backend handles OAuth flow entirely
- **Scope**: Google only per YAGNI principle

### III. Platform-Native Patterns
- ✅ **PASS**: Following Flutter/Dart idioms
- Widget composition (reuse existing OAuthButton)
- Feature-based architecture: `lib/features/auth/`
- Async/await for OAuth flow and GraphQL mutation
- Platform-specific deep link handling (Android intent filters, iOS URL schemes)
- url_launcher for cross-platform URL opening
- Existing auth patterns preserved

### Security & Privacy Requirements
- ✅ **PASS**: Access tokens stored via flutter_secure_storage (existing TokenStorage)
- HTTPS enforced by GraphQL backend and OAuth redirect endpoint
- Token management with automatic refresh (existing pattern)
- Authorization codes are single-use and short-lived (5-10 minutes)
- No secrets in code - backend handles OAuth client credentials
- Deep link URL validation to prevent phishing attacks
- Query parameter sanitization (code/error extraction)

### Performance Standards
- ✅ **PASS**: OAuth flow < 45 seconds including redirect (SC-001)
- Authorization code exchange < 3 seconds (SC-008)
- Deep link callback handling < 500ms
- 60 fps maintained (standard Flutter performance)
- Memory efficient (single OAuth flow, no background processing)

### Accessibility Requirements
- ✅ **PASS**: OAuthButton already has Semantics implementation
- Screen reader support via semantic labels
- Touch target size adequate (ElevatedButton default)

### CI/CD & DevOps Practices
- ✅ **PASS**: Feature branch `003-google-oauth-login`
- Tests required before merge
- Code review required

**GATE RESULT**: ✅ **PASS** - Proceed to Phase 0 Research

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
lib/features/auth/
├── services/
│   └── auth_service.dart              # Extended with initiateGoogleOAuth() and handleOAuthCallback()
├── widgets/
│   └── oauth_button.dart               # Existing, already supports Google
├── screens/
│   └── main_screen.dart                # Updated to wire Google OAuth button
└── utils/
    ├── oauth_error_mapper.dart         # New: Map OAuth redirect errors to user messages
    └── deep_link_handler.dart          # New: Parse and validate deep link callbacks

lib/core/
├── services/
│   ├── graphql_service.dart            # Existing, used for exchangeMobileAuthCode mutation
│   └── token_storage.dart              # Existing, stores access tokens
├── config/
│   └── env_config.dart                 # Existing, contains OAuth endpoint URLs
└── constants/
    └── app_strings.dart                # Updated with OAuth error messages

test/
├── features/auth/
│   ├── services/
│   │   └── auth_service_test.dart      # Extended with OAuth redirect tests
│   ├── utils/
│   │   └── deep_link_handler_test.dart # New: Test deep link parsing
│   └── widgets/
│       └── oauth_button_test.dart      # Existing, may need updates
└── integration/
    └── auth_flow_test.dart             # Extended with redirect-based OAuth flow test

android/app/src/main/
└── AndroidManifest.xml                 # Updated: Add deep link intent filter

ios/Runner/
└── Info.plist                          # Updated: Add URL scheme for deep link callback
```

**Structure Decision**: Flutter mobile app with feature-based architecture. All OAuth implementation resides in `lib/features/auth/` alongside existing email/password authentication. Reuses existing infrastructure (AuthService, TokenStorage, GraphQLService) to maintain consistency. Deep link handling integrated into auth service with platform-specific configuration in AndroidManifest.xml and Info.plist per Flutter conventions. No Google Sign-In SDK required - backend handles OAuth flow entirely.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - all constitution checks passed. Implementation follows existing patterns and maintains simplicity.
