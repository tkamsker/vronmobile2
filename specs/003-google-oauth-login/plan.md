# Implementation Plan: Google OAuth Login

**Branch**: `003-google-oauth-login` | **Date**: 2025-12-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-google-oauth-login/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement Google OAuth 2.0 authentication as an alternative login method alongside existing email/password authentication. Users will be able to sign in with their Google account through a native OAuth flow, with the system handling token exchange via the backend API, secure token storage, and automatic account linking for existing email addresses. The implementation follows Flutter best practices using the existing AuthService pattern and integrates with the current GraphQL backend.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- google_sign_in (NEEDS CLARIFICATION: version selection)
- graphql_flutter 5.1.0 (existing)
- flutter_secure_storage 9.0.0 (existing)

**Storage**:
- flutter_secure_storage for OAuth tokens (existing TokenStorage service)
- Backend PostgreSQL for user accounts (via GraphQL API)

**Testing**: flutter_test (Dart SDK), widget tests, unit tests, integration tests
**Target Platform**: iOS 15+ and Android API 21+ (dual platform mobile)
**Project Type**: Mobile application (Flutter feature-based architecture)

**Performance Goals**:
- OAuth flow completion < 30 seconds (per SC-001)
- Maintain 60 fps during authentication UI transitions
- Token storage operations < 100ms

**Constraints**:
- Must integrate with existing AuthService pattern
- Must use existing TokenStorage and GraphQLService
- Must follow accessibility requirements (Semantics widgets)
- Platform-specific OAuth implementations (iOS Sign in with Apple requirement consideration)

**Scale/Scope**:
- Single feature addition to existing app
- ~5-8 new files (service methods, OAuth screen/widgets, tests)
- Integration with existing auth infrastructure

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
- Minimal new code: extend existing AuthService, reuse OAuthButton widget
- **Question**: Scope limited to Google only or prepare for multi-provider? (Recommend: Google only per YAGNI)

### III. Platform-Native Patterns
- ✅ **PASS**: Following Flutter/Dart idioms
- Widget composition (reuse existing OAuthButton)
- Feature-based architecture: `lib/features/auth/`
- Async/await for OAuth flow
- Platform-specific handling (google_sign_in handles iOS/Android differences)
- Existing auth patterns preserved

### Security & Privacy Requirements
- ✅ **PASS**: OAuth tokens stored via flutter_secure_storage (existing TokenStorage)
- HTTPS enforced by GraphQL backend
- Token management with automatic refresh (existing pattern)
- OAuth scopes (NEEDS CLARIFICATION: email, profile, openid?)
- No secrets in code (Google OAuth client IDs in platform config files)

### Performance Standards
- ✅ **PASS**: OAuth flow < 30 seconds (SC-001)
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
│   └── auth_service.dart          # Extended with signInWithGoogle method
├── widgets/
│   └── oauth_button.dart           # Existing, already supports Google
├── screens/
│   └── main_screen.dart            # Updated to wire Google OAuth button
└── utils/
    └── oauth_error_mapper.dart     # New: Map OAuth errors to user messages

lib/core/
├── services/
│   ├── graphql_service.dart        # Existing, used for backend token exchange
│   └── token_storage.dart          # Existing, stores OAuth tokens
└── constants/
    └── app_strings.dart            # Updated with OAuth error messages

test/
├── features/auth/
│   ├── services/
│   │   └── auth_service_test.dart  # Extended with OAuth tests
│   └── widgets/
│       └── oauth_button_test.dart  # Existing, may need updates
└── integration/
    └── auth_flow_test.dart         # Extended with Google OAuth flow test

android/app/
└── google-services.json            # Google OAuth Android config (platform-specific)

ios/Runner/
└── GoogleService-Info.plist        # Google OAuth iOS config (platform-specific)
```

**Structure Decision**: Flutter mobile app with feature-based architecture. All OAuth implementation resides in `lib/features/auth/` alongside existing email/password authentication. Reuses existing infrastructure (AuthService, TokenStorage, GraphQLService) to maintain consistency. Platform-specific OAuth configuration files placed in native platform directories per Flutter conventions.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - all constitution checks passed. Implementation follows existing patterns and maintains simplicity.
