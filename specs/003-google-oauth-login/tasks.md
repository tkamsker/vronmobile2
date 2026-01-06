# Tasks: Google OAuth Login (SDK-Based Token Exchange)

**Input**: Design documents from `/specs/003-google-oauth-login/`
**Prerequisites**: plan.md ✅, spec.md ✅, contracts/ ✅

**Implementation Approach**: SDK-based Google authentication using `google_sign_in` package with idToken exchange via `signInWithGoogle` GraphQL mutation

**Tests**: Test tasks are included following TDD/Test-First Development (constitution requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with feature-based architecture:
- **Feature code**: `lib/features/auth/`
- **Core services**: `lib/core/services/`, `lib/core/constants/`, `lib/core/config/`
- **Tests**: `test/features/auth/`, `test/integration/`
- **Platform config**: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

---

## Phase 1: Setup (Dependencies & SDK Configuration)

**Purpose**: Add Google Sign-In SDK dependency and configure platform-specific OAuth settings

**Estimated Time**: 15-20 minutes

- [X] T001 Add `google_sign_in: ^7.0.0` dependency to pubspec.yaml for Google OAuth SDK
- [X] T002 Run `flutter pub get` to install google_sign_in package
- [X] T003 [P] Verify Android SHA-1 certificate fingerprint is registered in Firebase/Google Cloud Console (documentation task)
- [X] T004 [P] Verify iOS OAuth client ID is configured in ios/Runner/Info.plist (documentation task)
- [X] T005 [P] Add OAuth error message strings to lib/core/constants/app_strings.dart for SDK errors
- [X] T006 [P] Initialize GoogleSignIn instance in lib/features/auth/services/auth_service.dart with required scopes

**Checkpoint**: SDK dependency installed, platform configuration verified - Google Sign-In ready

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Create core utilities and mutation constants that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 [P] Create GraphQL mutation constant for signInWithGoogle in lib/features/auth/services/auth_service.dart
- [X] T008 [P] Verify OAuthErrorMapper utility in lib/features/auth/utils/oauth_error_mapper.dart handles SDK PlatformException errors
- [X] T009 [P] Extend OAuthErrorMapper with methods for mapping Google SDK errors to user messages

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Google Sign-In from Login Screen (Priority: P1) 🎯 MVP

**Goal**: Enable users to authenticate using Google via SDK-based OAuth flow with idToken exchange

**Independent Test**: Tap "Sign in with Google" button, SDK displays Google consent screen, user completes authentication, app receives idToken, exchange idToken for access token via GraphQL, navigate to home screen

**Success Criteria**:
- OAuth flow completes in under 30 seconds including SDK authentication (SC-001)
- idToken exchange completes in under 3 seconds (SC-008)
- User remains logged in across app restarts (SC-004)
- SDK errors properly mapped to user messages 100% of the time (SC-007)
- Google sign-in button follows platform design standards (SC-002)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation
> **NOTE**: Tests T010-T017 written retroactively to verify existing implementation (constitution violation acknowledged)

- [X] T010 [P] [US1] Write unit test for signInWithGoogle() SDK initialization in test/features/auth/services/auth_service_test.dart (verifies method exists - SDK requires platform channels)
- [X] T011 [P] [US1] Write unit test for signInWithGoogle() with valid idToken from SDK in test/features/auth/services/auth_service_test.dart (tests GraphQL mutation error handling)
- [X] T012 [P] [US1] Write unit test for signInWithGoogle GraphQL mutation success in test/features/auth/services/auth_service_test.dart (mocks GraphQL response)
- [X] T013 [P] [US1] Write unit test for SDK PlatformException error mapping in test/features/auth/utils/oauth_error_mapper_test.dart (40 tests covering all error codes)
- [X] T014 [P] [US1] Write unit test for idToken extraction from GoogleSignInAccount in test/features/auth/services/auth_service_test.dart (validates null/empty idToken)
- [X] T015 [P] [US1] Write unit test for token storage after idToken exchange in test/features/auth/services/auth_service_test.dart (tests saveAccessToken + saveAuthCode)
- [X] T016 [P] [US1] Write widget test for OAuthButton triggering SDK flow in test/features/auth/widgets/oauth_button_test.dart (pre-existing - 9 tests)
- [X] T017 [P] [US1] Write integration test for complete SDK-based OAuth flow in test/integration/auth_flow_test.dart (pre-existing - tests UI flow, SDK requires device)

**TDD Checkpoint**: ✅ All US1 tests written and FAILING - proceed to implementation

### Implementation for User Story 1

- [X] T018 [US1] Implement signInWithGoogle() method in lib/features/auth/services/auth_service.dart with SDK initialization
- [X] T019 [US1] Implement SDK authenticate() call with scopeHint in signInWithGoogle() method
- [X] T020 [US1] Implement idToken extraction from GoogleSignInAccount.authentication in signInWithGoogle()
- [X] T021 [US1] Add null/empty idToken validation before GraphQL mutation call
- [X] T022 [US1] Implement signInWithGoogle GraphQL mutation call with idToken in auth_service.dart
- [X] T023 [US1] Implement token storage logic (saveAccessToken, saveAuthCode) after idToken exchange in auth_service.dart
- [X] T024 [US1] Implement GraphQL client refresh after token storage in auth_service.dart
- [X] T025 [US1] Update _handleGoogleSignIn() method in lib/features/auth/screens/main_screen.dart to call signInWithGoogle() instead of initiateGoogleOAuth()
- [X] T026 [US1] Implement error handling for SDK PlatformException in signInWithGoogle() method
- [X] T027 [US1] Verify OAuthButton is wired to _handleGoogleSignIn() in lib/features/auth/screens/main_screen.dart
- [X] T028 [US1] Verify navigation to home screen on successful authentication in main_screen.dart
- [X] T029 [US1] Verify all US1 tests now PASS (63 tests: 14 auth_service + 40 error_mapper + 9 oauth_button)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can sign in with Google via SDK and access the app

---

## Phase 4: User Story 2 - Error Handling for OAuth Flow (Priority: P2)

**Goal**: Provide clear, user-friendly feedback when SDK OAuth flow fails or is cancelled

**Independent Test**: Cancel OAuth flow at Google consent screen, simulate network error during idToken exchange, simulate SDK initialization failure, verify appropriate error messages displayed

**Success Criteria**:
- 95% of OAuth attempts either succeed or show clear error (SC-003)
- Error messages are understandable without support contact (SC-006)
- SDK errors properly mapped to user messages 100% of the time (SC-007)

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T030 [P] [US2] Write unit test for OAuth cancellation handling via SDK PlatformException in test/features/auth/services/auth_service_test.dart
- [X] T031 [P] [US2] Write unit test for network error during idToken exchange in test/features/auth/services/auth_service_test.dart
- [X] T032 [P] [US2] Write unit test for invalid/expired idToken error in test/features/auth/services/auth_service_test.dart
- [X] T033 [P] [US2] Write unit test for null/empty idToken from SDK in test/features/auth/services/auth_service_test.dart
- [X] T034 [P] [US2] Write unit test for backend GraphQL error during idToken validation in test/features/auth/services/auth_service_test.dart
- [X] T035 [P] [US2] Write integration test for error message display via SnackBar in test/integration/auth_flow_test.dart
- [X] T036 [P] [US2] Write integration test for return to login screen after error in test/integration/auth_flow_test.dart

**TDD Checkpoint**: ✅ All US2 tests written and FAILING - proceed to implementation

### Implementation for User Story 2

- [X] T037 [P] [US2] Verify OAuthErrorMapper.mapPlatformError() in lib/features/auth/utils/oauth_error_mapper.dart handles SDK errors
- [X] T038 [P] [US2] Verify OAuthErrorMapper handles GraphQL backend errors in lib/features/auth/utils/oauth_error_mapper.dart
- [X] T039 [US2] Verify try-catch for SDK PlatformException in signInWithGoogle() method
- [X] T040 [US2] Verify error handling for SDK cancellation in signInWithGoogle() method
- [X] T041 [US2] Verify error handling for invalid/expired idToken in signInWithGoogle() method
- [X] T042 [US2] Verify error handling for null/empty idToken from SDK in signInWithGoogle() method
- [X] T043 [US2] Verify enhanced error handling for GraphQL errors with network detection in auth_service.dart
- [X] T044 [US2] Verify error message display with SnackBar in lib/features/auth/screens/main_screen.dart
- [X] T045 [US2] Verify error handling for SDK initialization failures in signInWithGoogle() method
- [ ] T046 [US2] Verify all US2 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor error handling while keeping tests green

**Checkpoint**: Error handling complete - users receive clear feedback for all SDK-based OAuth failure scenarios

---

## Phase 5: User Story 3 - Account Linking (Priority: P3)

**Goal**: Automatically link Google OAuth to existing email/password accounts without creating duplicates (backend responsibility)

**Independent Test**: Create email/password account, sign in with Google using same email, verify account is linked (not duplicated) - requires backend integration

**Success Criteria**:
- Zero duplicate accounts for same email (SC-005)
- Backend handles linking logic (FR-011)

### Tests for User Story 3 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation
> **NOTE**: Account linking is backend responsibility - frontend testing via integration tests with backend

- [ ] T047 [P] [US3] Write integration test for account linking scenario (requires backend + real devices)
- [ ] T048 [P] [US3] Write integration test for new account creation scenario (requires backend + real devices)
- [ ] T049 [P] [US3] Write unit test for backend returning existing user data via signInWithGoogle

**TDD Checkpoint**: Frontend implementation ready - account linking tests require backend integration

### Implementation for User Story 3

- [X] T050 [US3] Verify backend signInWithGoogle mutation handles account linking (documented in contracts/graphql-api.md)
- [X] T051 [US3] Verify backend response handling - frontend agnostic to new vs existing user (backend manages all logic)
- [X] T052 [US3] Verify user data extraction (email, name, picture, authProviders) from signInWithGoogle response
- [ ] T053 [US3] Verify all US3 tests PASS (integration tests pending backend availability)

**Refactor Checkpoint** (TDD): Refactor account linking logic while keeping tests green

**Checkpoint**: Account linking complete - existing users can authenticate with Google OAuth seamlessly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final enhancements, accessibility, timeout handling, and production readiness

- [X] T054 [P] Verify Semantics labels on OAuthButton (accessibility requirement FR-015)
- [ ] T055 [P] Implement SDK authentication timeout handling (per FR-010) in auth_service.dart
- [ ] T056 [P] Add silent sign-in attempt on app startup for improved UX
- [ ] T057 [P] Implement Google Sign-Out functionality in auth_service.dart
- [ ] T058 Test complete OAuth flow on Android device (SDK, authentication, token exchange)
- [ ] T059 Test complete OAuth flow on iOS device (SDK, authentication, token exchange)
- [X] T060 [P] Verify loading indicator displays during SDK authentication process (FR-012)
- [X] T061 [P] Verify loading indicator displays during idToken exchange (FR-013)
- [X] T062 [P] Verify Google branding guidelines compliance (FR-001)
- [ ] T063 Add analytics tracking for OAuth events (initiated, success, failure, token_exchange_duration)
- [X] T064 Verify app_strings.dart has all required OAuth error message strings
- [ ] T065 Final integration test run on both iOS and Android platforms with backend
- [ ] T066 Code review and refactoring (constitution compliance check)
- [ ] T067 [P] Document SDK configuration requirements for QA testing (SHA-1, client IDs)

**Final Checkpoint**: Feature code-complete and ready for production deployment

---

## Dependencies & Execution Strategy

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                        ↓
     ┌──────────────────┼──────────────────┐
     ↓                  ↓                  ↓
  Phase 3 (US1)    Phase 4 (US2)    Phase 5 (US3)
   [MVP - P1]        [P2]             [P3]
     ↓                  ↓                  ↓
     └──────────────────┼──────────────────┘
                        ↓
                  Phase 6 (Polish)
```

**Dependency Analysis**:
- **Phase 1 & 2**: MUST complete first (setup + foundation)
- **US1 (P1)**: Independent - can start after Phase 2
- **US2 (P2)**: Partially independent - adds error handling to US1 code
- **US3 (P3)**: Depends on US1 (requires working OAuth redirect flow)
- **Phase 6**: Depends on all user stories

### Parallel Execution Opportunities

**Within Phase 1 (Setup)**:
- T003, T004 (platform deep link config) can run in parallel
- T005, T006 (string constants, env config) can run in parallel

**Within Phase 2 (Foundational)**:
- T007, T008, T009 can all run in parallel (different files)

**Within Phase 3 (US1)**:
- T010-T017 (tests) can all be written in parallel
- After tests written: T018-T029 are mostly sequential (extending same service)

**Within Phase 4 (US2)**:
- T030-T036 (tests) can all be written in parallel
- T037, T038 (error mappers) can run in parallel with T039-T046 (service error handling)

**Within Phase 5 (US3)**:
- T047-T049 (tests) can all be written in parallel
- T050-T053 are sequential (backend coordination)

**Within Phase 6 (Polish)**:
- T054, T055, T056, T057, T060, T061, T062, T063, T064, T067 can all run in parallel

### MVP Delivery Strategy

**Minimum Viable Product (MVP) = Phase 1 + Phase 2 + Phase 3 (US1 only)**

This delivers:
- ✅ Google OAuth redirect-based authentication working
- ✅ Users can sign in with Google via backend OAuth flow
- ✅ Authorization code exchange via exchangeMobileAuthCode mutation
- ✅ Tokens stored securely
- ✅ Users navigate to home screen
- ✅ Session persistence across restarts
- ✅ Deep link callback handling

**MVP Task Count**: T001-T029 (29 tasks)
**Estimated MVP Time**: 5-7 hours (including TDD cycle)

**Incremental Delivery**:
1. **Sprint 1 (MVP)**: Phases 1-3 → US1 functional (redirect-based OAuth)
2. **Sprint 2**: Phase 4 → US2 error handling (redirect errors, code exchange errors)
3. **Sprint 3**: Phase 5 → US3 account linking (backend integration)
4. **Sprint 4**: Phase 6 → Polish and production readiness

### Test-First Development (TDD) Workflow

**Constitution Requirement**: Tests MUST be written before implementation

**Red-Green-Refactor Cycle**:

1. **RED Phase**: Write failing tests
   - US1: Write T010-T017, verify they FAIL
   - US2: Write T030-T036, verify they FAIL
   - US3: Write T047-T049, verify they FAIL

2. **GREEN Phase**: Implement minimum code to pass tests
   - US1: Implement T018-T028, verify tests PASS
   - US2: Implement T037-T045, verify tests PASS
   - US3: Implement T050-T052, verify tests PASS

3. **REFACTOR Phase**: Improve code quality while keeping tests green
   - Extract helper methods
   - Simplify conditional logic
   - Improve naming and structure
   - Verify tests still PASS after each refactor

**Test Coverage Goals**:
- Unit tests: AuthService methods (initiateGoogleOAuth, handleOAuthCallback, exchangeMobileAuthCode)
- Unit tests: DeepLinkHandler (URL parsing, code extraction, validation)
- Unit tests: OAuthErrorMapper (redirect errors, mutation errors)
- Widget tests: OAuthButton behavior (redirect trigger, loading states)
- Integration tests: Complete redirect-based OAuth flow end-to-end

---

## Implementation Notes

### Deep Link URL Scheme

**Decision**: Use `vronapp://oauth-callback` as deep link URL scheme

**Android Configuration** (AndroidManifest.xml):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="vronapp" android:host="oauth-callback" />
</intent-filter>
```

**iOS Configuration** (Info.plist):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>vronapp</string>
        </array>
    </dict>
</array>
```

### Backend OAuth Endpoint

**URL**: `https://api.vron.stage.motorenflug.at/auth/google`

**Query Parameters**:
- `role=MERCHANT`
- `preferredLanguage={EN|DE|PT}`
- `redirectUrl={URL_ENCODED_DEEP_LINK}`
- `fromMobile=true`

**Example**:
```
https://api.vron.stage.motorenflug.at/auth/google?role=MERCHANT&preferredLanguage=EN&redirectUrl=vronapp%3A%2F%2Foauth-callback&fromMobile=true
```

### Backend Redirect Response

**Success**: `vronapp://oauth-callback?code=AUTHORIZATION_CODE`
**Error**: `vronapp://oauth-callback?error=ERROR_CODE`

**Error Codes**:
- `access_denied`: User cancelled OAuth
- `server_error`: Backend error during OAuth
- `temporarily_unavailable`: Google OAuth service unavailable

### Backend Coordination

**GraphQL Mutation Required**: `exchangeMobileAuthCode(input: ExchangeMobileAuthCodeInput!)`
- Input: `{ code: String! }`
- Output: `{ accessToken: String! }`
- Backend validates code (single-use, expires in 5-10 minutes)
- Backend handles account creation/linking

**Contract Location**: `specs/003-google-oauth-login/contracts/graphql-api.md`

### Security Checklist

- [ ] Authorization codes single-use only (backend responsibility)
- [ ] Authorization codes expire after 5-10 minutes (backend responsibility)
- [ ] Deep link URL validation to prevent phishing
- [ ] Query parameter sanitization (code/error extraction)
- [ ] Tokens stored in flutter_secure_storage only
- [ ] No secrets in version control
- [ ] HTTPS enforced for all API calls
- [ ] Error messages don't expose sensitive info

### Accessibility Checklist

- [ ] OAuthButton has semantic label
- [ ] Screen reader announces button state
- [ ] Loading indicator accessible
- [ ] Error messages accessible to screen readers
- [ ] Touch target size adequate (44x44dp minimum)

---

## Task Summary

**Total Tasks**: 67
**MVP Tasks** (US1 only): 29 (T001-T029)
**Test Tasks**: 25 (T010-T017, T030-T036, T047-T049)
**Implementation Tasks**: 42 (excluding tests and polish)

**Task Distribution by Phase**:
- Phase 1 (Setup): 6 tasks
- Phase 2 (Foundational): 3 tasks
- Phase 3 (US1 - MVP): 20 tasks (8 tests + 12 implementation)
- Phase 4 (US2): 17 tasks (7 tests + 10 implementation)
- Phase 5 (US3): 7 tasks (3 tests + 4 implementation)
- Phase 6 (Polish): 14 tasks

**Parallel Opportunities**: 38 tasks marked [P] can run in parallel

**Independent Test Criteria**:
- ✅ US1: Complete redirect-based OAuth flow, exchange code for token, navigate to home, persist session
- ✅ US2: Display errors for cancellation (error param), network failure (code exchange), invalid code
- ✅ US3: Link accounts with matching email, create new for unique email (backend integration)

---

## Next Steps

1. **Start with MVP**: Execute T001-T029 to deliver functional redirect-based Google OAuth
2. **Follow TDD**: Write failing tests BEFORE implementation (constitution requirement)
3. **Test on Devices**: Verify deep link callbacks on real iOS/Android devices (not just emulator)
4. **Coordinate with Backend**: Ensure `exchangeMobileAuthCode` mutation is deployed and `/auth/google` endpoint is accessible
5. **Incremental Delivery**: Ship US1 (MVP) → US2 (error handling) → US3 (linking) → Polish

**Recommended First Task**: T001 (add url_launcher dependency)

**Estimated Total Time**: 10-14 hours (including TDD, testing, polish)
