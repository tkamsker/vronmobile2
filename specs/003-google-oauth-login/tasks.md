# Tasks: Google OAuth Login (Redirect-Based Mobile Flow)

**Input**: Design documents from `/specs/003-google-oauth-login/`
**Prerequisites**: plan.md ✅, spec.md ✅, contracts/ ✅

**BREAKING CHANGE**: Tasks updated for redirect-based mobile OAuth flow with `exchangeMobileAuthCode` mutation (replacing old `signInWithGoogle` with idToken approach)

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

## Phase 1: Setup (Dependencies & Deep Link Configuration)

**Purpose**: Add dependencies and configure deep link URL schemes for OAuth callback

**Estimated Time**: 20-25 minutes

- [ ] T001 Add `url_launcher: ^6.2.0` dependency to pubspec.yaml for OAuth redirect functionality
- [ ] T002 Run `flutter pub get` to install url_launcher package
- [ ] T003 [P] Define deep link URL scheme in android/app/src/main/AndroidManifest.xml with intent filter for OAuth callback
- [ ] T004 [P] Define deep link URL scheme in ios/Runner/Info.plist with CFBundleURLTypes for OAuth callback
- [ ] T005 [P] Add OAuth error message strings to lib/core/constants/app_strings.dart for redirect-based errors
- [ ] T006 [P] Add OAuth endpoint URL configuration to lib/core/config/env_config.dart

**Checkpoint**: Dependencies installed, deep links configured - OAuth redirect infrastructure ready

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Create core utilities and mutation constants that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 [P] Create GraphQL mutation constant for exchangeMobileAuthCode in lib/features/auth/services/auth_service.dart
- [ ] T008 [P] Create DeepLinkHandler utility class in lib/features/auth/utils/deep_link_handler.dart for parsing OAuth callbacks
- [ ] T009 [P] Create OAuthErrorMapper utility in lib/features/auth/utils/oauth_error_mapper.dart for redirect error mapping

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Google Sign-In from Login Screen (Priority: P1) 🎯 MVP

**Goal**: Enable users to authenticate using Google via redirect-based OAuth flow with authorization code exchange

**Independent Test**: Tap "Sign in with Google" button, redirect to backend OAuth endpoint, complete Google authentication, receive deep link callback with authorization code, exchange code for token, navigate to home screen

**Success Criteria**:
- OAuth flow completes in under 45 seconds including redirect (SC-001)
- Authorization code exchange completes in under 3 seconds (SC-008)
- User remains logged in across app restarts (SC-004)
- Deep link callbacks handled correctly 100% of the time (SC-007)
- Google sign-in button follows platform design standards (SC-002)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T010 [P] [US1] Write unit test for initiateGoogleOAuth() URL construction in test/features/auth/services/auth_service_test.dart
- [ ] T011 [P] [US1] Write unit test for handleOAuthCallback() with valid authorization code in test/features/auth/services/auth_service_test.dart
- [ ] T012 [P] [US1] Write unit test for exchangeMobileAuthCode mutation success in test/features/auth/services/auth_service_test.dart
- [ ] T013 [P] [US1] Write unit test for deep link URL parsing in test/features/auth/utils/deep_link_handler_test.dart
- [ ] T014 [P] [US1] Write unit test for authorization code extraction in test/features/auth/utils/deep_link_handler_test.dart
- [ ] T015 [P] [US1] Write unit test for token storage after code exchange in test/features/auth/services/auth_service_test.dart
- [ ] T016 [P] [US1] Write widget test for OAuthButton redirect trigger in test/features/auth/widgets/oauth_button_test.dart
- [ ] T017 [P] [US1] Write integration test for complete redirect-based OAuth flow in test/integration/auth_flow_test.dart

**TDD Checkpoint**: ✅ All US1 tests written and FAILING - proceed to implementation

### Implementation for User Story 1

- [ ] T018 [US1] Implement initiateGoogleOAuth() method in lib/features/auth/services/auth_service.dart to construct and launch OAuth URL
- [ ] T019 [US1] Implement handleOAuthCallback() method in lib/features/auth/services/auth_service.dart to process deep link callbacks
- [ ] T020 [US1] Implement DeepLinkHandler.parseOAuthCallback() in lib/features/auth/utils/deep_link_handler.dart
- [ ] T021 [US1] Implement DeepLinkHandler.extractAuthorizationCode() in lib/features/auth/utils/deep_link_handler.dart
- [ ] T022 [US1] Implement exchangeMobileAuthCode GraphQL mutation call in lib/features/auth/services/auth_service.dart
- [ ] T023 [US1] Implement token storage logic (saveAccessToken, saveAuthCode) after code exchange in auth_service.dart
- [ ] T024 [US1] Implement GraphQL client refresh after token storage in auth_service.dart
- [ ] T025 [US1] Add _handleGoogleSignIn() method to lib/features/auth/screens/main_screen.dart for URL redirect
- [ ] T026 [US1] Configure deep link handler to route OAuth callbacks to handleOAuthCallback() in main_screen.dart
- [ ] T027 [US1] Wire OAuthButton to _handleGoogleSignIn() in lib/features/auth/screens/main_screen.dart
- [ ] T028 [US1] Add navigation to home screen on successful authentication in main_screen.dart
- [ ] T029 [US1] Verify all US1 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can sign in with Google via redirect and access the app

---

## Phase 4: User Story 2 - Error Handling for OAuth Flow (Priority: P2)

**Goal**: Provide clear, user-friendly feedback when OAuth redirect flow fails or is cancelled

**Independent Test**: Cancel OAuth flow at Google consent screen, simulate network error during code exchange, simulate invalid authorization code, verify appropriate error messages displayed

**Success Criteria**:
- 95% of OAuth attempts either succeed or show clear error (SC-003)
- Error messages are understandable without support contact (SC-006)
- Deep link error callbacks handled correctly (SC-007)

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T030 [P] [US2] Write unit test for OAuth cancellation handling via deep link error parameter in test/features/auth/services/auth_service_test.dart
- [ ] T031 [P] [US2] Write unit test for network error during code exchange in test/features/auth/services/auth_service_test.dart
- [ ] T032 [P] [US2] Write unit test for invalid/expired authorization code error in test/features/auth/services/auth_service_test.dart
- [ ] T033 [P] [US2] Write unit test for malformed deep link callback URL in test/features/auth/utils/deep_link_handler_test.dart
- [ ] T034 [P] [US2] Write unit test for backend GraphQL error during code exchange in test/features/auth/services/auth_service_test.dart
- [ ] T035 [P] [US2] Write integration test for error message display via SnackBar in test/integration/auth_flow_test.dart
- [ ] T036 [P] [US2] Write integration test for return to login screen after error in test/integration/auth_flow_test.dart

**TDD Checkpoint**: ✅ All US2 tests written and FAILING - proceed to implementation

### Implementation for User Story 2

- [ ] T037 [P] [US2] Implement OAuthErrorMapper.mapRedirectError() in lib/features/auth/utils/oauth_error_mapper.dart for deep link errors
- [ ] T038 [P] [US2] Implement OAuthErrorMapper.mapMutationError() in lib/features/auth/utils/oauth_error_mapper.dart for GraphQL errors
- [ ] T039 [US2] Add try-catch for URL launch failures in initiateGoogleOAuth() method
- [ ] T040 [US2] Add error parameter detection in handleOAuthCallback() method for redirect errors
- [ ] T041 [US2] Add error handling for invalid/expired authorization code in exchangeMobileAuthCode call
- [ ] T042 [US2] Add error handling for malformed deep link URLs in DeepLinkHandler
- [ ] T043 [US2] Add enhanced error handling for GraphQL errors with network detection in auth_service.dart
- [ ] T044 [US2] Implement error message display with SnackBar in lib/features/auth/screens/main_screen.dart
- [ ] T045 [US2] Add error handling for null authorization code scenario in handleOAuthCallback()
- [ ] T046 [US2] Verify all US2 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor error handling while keeping tests green

**Checkpoint**: Error handling complete - users receive clear feedback for all redirect-based OAuth failure scenarios

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
- [ ] T049 [P] [US3] Write unit test for backend returning existing user data via exchangeMobileAuthCode

**TDD Checkpoint**: Frontend implementation ready - account linking tests require backend integration

### Implementation for User Story 3

- [ ] T050 [US3] Verify backend exchangeMobileAuthCode mutation handles account linking (documented in contracts/graphql-api.md)
- [ ] T051 [US3] Handle backend response - frontend agnostic to new vs existing user (backend manages all logic)
- [ ] T052 [US3] Extract user data (email, name, picture) from exchangeMobileAuthCode response if available
- [ ] T053 [US3] Verify all US3 tests PASS (integration tests pending backend availability)

**Refactor Checkpoint** (TDD): Refactor account linking logic while keeping tests green

**Checkpoint**: Account linking complete - existing users can authenticate with Google OAuth seamlessly

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final enhancements, accessibility, timeout handling, and production readiness

- [ ] T054 [P] Verify Semantics labels on OAuthButton (accessibility requirement FR-015)
- [ ] T055 [P] Implement OAuth redirect timeout handling (5 minutes per FR-010) in auth_service.dart
- [ ] T056 [P] Add deep link validation to prevent phishing attacks in DeepLinkHandler
- [ ] T057 [P] Add query parameter sanitization for code/error extraction in DeepLinkHandler
- [ ] T058 Test complete OAuth flow on Android device (redirect, callback, authentication)
- [ ] T059 Test complete OAuth flow on iOS device (redirect, callback, authentication)
- [ ] T060 [P] Verify loading indicator displays during OAuth redirect process (FR-012)
- [ ] T061 [P] Verify loading indicator displays during code exchange (FR-013)
- [ ] T062 [P] Verify Google branding guidelines compliance (FR-001)
- [ ] T063 Add analytics tracking for OAuth events (initiated, success, failure, code_exchange_duration)
- [ ] T064 Update app_strings.dart with any missing error message localization strings
- [ ] T065 Final integration test run on both iOS and Android platforms with backend
- [ ] T066 Code review and refactoring (constitution compliance check)
- [ ] T067 [P] Document deep link URL scheme for QA testing and backend team

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
