# Implementation Plan: Google OAuth Login

**Branch**: `003-google-oauth-login` | **Date**: 2025-12-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-google-oauth-login/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement Google OAuth 2.0 authentication as an alternative login method alongside existing email/password authentication using the Google Sign-In SDK. Users will tap "Sign in with Google" to launch the SDK authentication flow, complete authentication with Google via the native SDK UI, and receive an idToken. The app exchanges this idToken for an access token via the `signInWithGoogle` GraphQL mutation. The implementation handles token storage securely, supports automatic account linking for existing email addresses, and follows Flutter best practices using the existing AuthService pattern.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- google_sign_in ^7.0.0 (for Google OAuth SDK)
- graphql_flutter 5.1.0 (existing - for signInWithGoogle mutation)
- flutter_secure_storage 9.0.0 (existing - for access token storage)

**Storage**:
- flutter_secure_storage for OAuth tokens (existing TokenStorage service)
- Backend PostgreSQL for user accounts (via GraphQL API)

**Platform Configuration**:
- Android: Google Sign-In SDK requires SHA-1 certificate fingerprint in Firebase/Google Cloud Console
- iOS: Google Sign-In SDK requires URL scheme and client ID in Info.plist

**Testing**: flutter_test (Dart SDK), widget tests, unit tests, integration tests
**Target Platform**: iOS 15+ and Android API 21+ (dual platform mobile)
**Project Type**: Mobile application (Flutter feature-based architecture)

**Performance Goals**:
- OAuth flow completion < 30 seconds including SDK authentication (per SC-001)
- idToken exchange < 3 seconds (per SC-008)
- SDK initialization < 500ms
- Maintain 60 fps during authentication UI transitions
- Token storage operations < 100ms

**Constraints**:
- Must integrate with existing AuthService pattern
- Must use existing TokenStorage and GraphQLService
- Must follow accessibility requirements (Semantics widgets)
- Google Sign-In SDK v7.0+ API changes (initialize() and authenticate() methods)
- Backend must validate Google idTokens using Google's token validation API
- idTokens are short-lived JWT tokens from Google

**Scale/Scope**:
- Single feature addition to existing app
- ~4-6 modified files (AuthService extension, OAuth error mapping, tests)
- Integration with existing auth infrastructure
- Platform-specific SDK configuration (Android SHA-1, iOS URL scheme)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: TDD approach required for all implementation
- Tests MUST be written before code:
  - Unit tests for OAuth service methods (signInWithGoogle, silentSignIn)
  - Widget tests for OAuthButton (already exists, may need enhancement)
  - Integration tests for complete OAuth flow
- Red-Green-Refactor cycle enforced

### II. Simplicity & YAGNI
- ✅ **PASS**: Implementation focused only on stated requirements
- Using existing patterns (AuthService, TokenStorage, GraphQLService)
- No premature abstraction for other OAuth providers (Facebook already has widget stub but not implemented)
- Minimal new code: extend AuthService with Google SDK methods, enhance error mapping
- Reuse OAuthButton widget (already exists)
- Use google_sign_in SDK - proven solution for Google authentication
- **Scope**: Google only per YAGNI principle

### III. Platform-Native Patterns
- ✅ **PASS**: Following Flutter/Dart idioms
- Widget composition (reuse existing OAuthButton)
- Feature-based architecture: `lib/features/auth/`
- Async/await for OAuth flow and GraphQL mutation
- Platform-native Google Sign-In UI provided by SDK
- Future-based async patterns for SDK authentication
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
