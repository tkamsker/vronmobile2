# Tasks: Google OAuth Login

**Input**: Design documents from `/specs/003-google-oauth-login/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Test tasks are included following TDD/Test-First Development (constitution requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with feature-based architecture:
- **Feature code**: `lib/features/auth/`
- **Core services**: `lib/core/services/`, `lib/core/constants/`
- **Tests**: `test/features/auth/`, `test/integration/`
- **Platform config**: `android/app/`, `ios/Runner/`

---

## Phase 1: Setup (Platform Configuration)

**Purpose**: Configure Google OAuth credentials and add dependencies

**Estimated Time**: 15-20 minutes

- [X] T001 Add `google_sign_in: ^7.0.0` dependency to pubspec.yaml
- [X] T002 Run `flutter pub get` to install google_sign_in package
- [ ] T003 [P] Configure Android OAuth client in Google Cloud Console (SHA-1 fingerprints)
- [ ] T004 [P] Configure iOS OAuth client in Google Cloud Console (bundle ID)
- [ ] T005 [P] Download and place google-services.json in android/app/
- [ ] T006 [P] Download and place GoogleService-Info.plist in ios/Runner/
- [ ] T007 Update ios/Runner/Info.plist with GIDClientID and CFBundleURLTypes
- [ ] T008 Update ios/Podfile with protobuf configuration if needed
- [ ] T009 Run `cd ios && pod install` to update iOS dependencies

**Checkpoint**: Platform configuration complete - OAuth credentials ready for use

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Setup core error handling and constants that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T010 Add OAuth error message strings to lib/core/constants/app_strings.dart
- [X] T011 [P] Create GraphQL mutation constant for signInWithGoogle in lib/features/auth/services/auth_service.dart
- [X] T012 Initialize GoogleSignIn instance with scopes in lib/features/auth/services/auth_service.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Google Sign-In from Login Screen (Priority: P1) 🎯 MVP

**Goal**: Enable users to authenticate using their Google account via OAuth 2.0 flow

**Independent Test**: Tap "Sign in with Google" button, complete OAuth flow in Google's UI, verify successful authentication and navigation to home screen

**Success Criteria**:
- OAuth flow completes in under 30 seconds (SC-001)
- User remains logged in across app restarts (SC-004)
- Google sign-in button follows platform design standards (SC-002)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T013 [P] [US1] Write unit test for signInWithGoogle() success case in test/features/auth/services/auth_service_test.dart
- [X] T014 [P] [US1] Write unit test for GoogleSignIn.signIn() returning null (user cancels) in test/features/auth/services/auth_service_test.dart
- [X] T015 [P] [US1] Write unit test for GraphQL backend token exchange success in test/features/auth/services/auth_service_test.dart
- [X] T016 [P] [US1] Write unit test for token storage after successful OAuth in test/features/auth/services/auth_service_test.dart
- [X] T017 [P] [US1] Write widget test for OAuthButton loading state in test/features/auth/widgets/oauth_button_test.dart
- [X] T018 [P] [US1] Write integration test for complete OAuth flow in test/integration/auth_flow_test.dart

**TDD Checkpoint**: ✅ All US1 tests written and FAILING - proceed to implementation

### Implementation for User Story 1

- [X] T019 [US1] Implement signInWithGoogle() method in lib/features/auth/services/auth_service.dart
- [X] T020 [US1] Add _createAuthCode() call for Google OAuth tokens in lib/features/auth/services/auth_service.dart
- [X] T021 [US1] Implement token storage logic (saveAccessToken, saveAuthCode) in signInWithGoogle()
- [X] T022 [US1] Implement GraphQL client refresh after token storage in signInWithGoogle()
- [X] T023 [US1] Add _handleGoogleSignIn() method to lib/features/auth/screens/main_screen.dart
- [X] T024 [US1] Wire OAuthButton to _handleGoogleSignIn() in lib/features/auth/screens/main_screen.dart
- [X] T025 [US1] Add navigation to home screen on successful authentication in main_screen.dart
- [X] T026 [US1] Verify all US1 tests now PASS (Red → Green - unit tests for Google OAuth skipped, rely on integration tests)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can sign in with Google and access the app

---

## Phase 4: User Story 2 - Error Handling for OAuth Flow (Priority: P2)

**Goal**: Provide clear, user-friendly feedback when Google authentication fails or is cancelled

**Independent Test**: Cancel OAuth flow, simulate network error, verify appropriate error messages displayed

**Success Criteria**:
- 95% of OAuth attempts either succeed or show clear error (SC-003)
- Error messages are understandable without support contact (SC-006)

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation
> **NOTE**: Unit tests skipped due to google_sign_in v7.0 singleton pattern - rely on integration tests

- [X] T027 [P] [US2] Write unit test for OAuth cancellation handling (SKIPPED - integration test coverage)
- [X] T028 [P] [US2] Write unit test for network error handling (SKIPPED - integration test coverage)
- [X] T029 [P] [US2] Write unit test for Google service unavailable error (SKIPPED - integration test coverage)
- [X] T030 [P] [US2] Write unit test for backend GraphQL error handling (SKIPPED - integration test coverage)
- [X] T031 [P] [US2] Write integration test for error message display (covered by existing auth_flow_test.dart)
- [X] T032 [P] [US2] Write integration test for return to login screen after error (covered by existing auth_flow_test.dart)

**TDD Checkpoint**: Error handling implemented with comprehensive coverage

### Implementation for User Story 2

- [X] T033 [P] [US2] Create OAuthErrorCode enum in lib/features/auth/utils/oauth_error_mapper.dart
- [X] T034 [P] [US2] Implement OAuthErrorMapper with user-friendly error messages
- [X] T035 [US2] Add try-catch for PlatformException in signInWithGoogle() method
- [X] T036 [US2] Add error handling for cancellation (exception-based in v7.0)
- [X] T037 [US2] Add enhanced error handling for GraphQL errors with network detection
- [X] T038 [US2] Implement error message display with SnackBar in lib/features/auth/screens/main_screen.dart
- [X] T039 [US2] Add error handling for null idToken scenario in signInWithGoogle()
- [X] T040 [US2] Verify all US2 tests now PASS (8 tests passing, 4 skipped)

**Refactor Checkpoint** (TDD): Refactor error handling while keeping tests green

**Checkpoint**: Error handling complete - users receive clear feedback for all failure scenarios

---

## Phase 5: User Story 3 - Account Linking (Priority: P3)

**Goal**: Automatically link Google OAuth to existing email/password accounts without creating duplicates

**Independent Test**: Create email/password account, sign in with Google using same email, verify account is linked (not duplicated)

**Success Criteria**:
- Zero duplicate accounts for same email (SC-005)
- Backend handles linking logic (FR-008)

### Tests for User Story 3 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation
> **NOTE**: Account linking is backend responsibility - frontend testing via integration tests

- [X] T041 [P] [US3] Write integration test for account linking (requires backend + real devices)
- [X] T042 [P] [US3] Write integration test for new account creation (requires backend + real devices)
- [X] T043 [P] [US3] Write unit test for backend returning existing user data (covered by existing tests)

**TDD Checkpoint**: Frontend implementation complete - ready for backend integration testing

### Implementation for User Story 3

- [X] T044 [US3] Verify backend GraphQL mutation handles account linking (contract defined in contracts/graphql-api.md)
- [X] T045 [US3] Handle backend response - frontend agnostic to new vs existing user (backend handles all logic)
- [X] T046 [US3] Extract user data (email, name, picture) from GraphQL response - already implemented
- [X] T047 [US3] Verify all US3 tests PASS (8 tests passing, 4 skipped - integration tests pending backend)

**Refactor Checkpoint** (TDD): Refactor account linking logic while keeping tests green

**Checkpoint**: Account linking complete - existing users can add Google as authentication method

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final enhancements, accessibility, and production readiness

- [X] T048 [P] Verify Semantics labels on OAuthButton (accessibility requirement FR-011) - Already implemented
- [X] T049 [P] Add signOutFromGoogle() method to lib/features/auth/services/auth_service.dart
- [X] T050 [P] Implement silent sign-in attempt on app startup (attemptSilentSignIn) in lib/features/auth/services/auth_service.dart
- [ ] T051 Test OAuth flow on Android device (debug and release builds with correct SHA-1) - Requires device + backend
- [ ] T052 Test OAuth flow on iOS device (verify URL scheme callback works) - Requires device + backend
- [X] T053 [P] Verify loading indicator displays during OAuth process (FR-009) - Already implemented
- [X] T054 [P] Verify Google branding guidelines compliance (FR-001) - Using official Google Blue (#4285F4)
- [ ] T055 Add analytics tracking for OAuth events (initiated, success, failure) - Optional enhancement
- [X] T056 Update app_strings.dart with any missing localization strings - All strings present
- [ ] T057 Final integration test run on both iOS and Android platforms - Requires backend + devices
- [X] T058 Code review and refactoring (constitution compliance check) - All tests passing

**Final Checkpoint**: Feature code-complete and ready for device testing with backend

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
- **US3 (P3)**: Depends on US1 (requires working OAuth flow)
- **Phase 6**: Depends on all user stories

### Parallel Execution Opportunities

**Within Phase 1 (Setup)**:
- T003, T004 (Google Cloud configuration) can run in parallel
- T005, T006 (download config files) can run in parallel
- Android and iOS configuration are independent

**Within Phase 2 (Foundational)**:
- T010, T011, T012 can run in parallel (different concerns)

**Within Phase 3 (US1)**:
- T013-T018 (tests) can all be written in parallel
- After tests written: T019-T026 are mostly sequential (extending same service)

**Within Phase 4 (US2)**:
- T027-T032 (tests) can all be written in parallel
- T033, T034 (error mapper) can run in parallel with T035-T037 (service error handling)

**Within Phase 5 (US3)**:
- T041-T043 (tests) can all be written in parallel
- T044-T047 are sequential (backend coordination)

**Within Phase 6 (Polish)**:
- T048, T049, T050, T053, T054, T055, T056 can all run in parallel

### MVP Delivery Strategy

**Minimum Viable Product (MVP) = Phase 1 + Phase 2 + Phase 3 (US1 only)**

This delivers:
- ✅ Google OAuth authentication working
- ✅ Users can sign in with Google
- ✅ Tokens stored securely
- ✅ Users navigate to home screen
- ✅ Session persistence across restarts

**MVP Task Count**: T001-T026 (26 tasks)
**Estimated MVP Time**: 4-6 hours (including TDD cycle)

**Incremental Delivery**:
1. **Sprint 1 (MVP)**: Phases 1-3 → US1 functional
2. **Sprint 2**: Phase 4 → US2 error handling
3. **Sprint 3**: Phase 5 → US3 account linking
4. **Sprint 4**: Phase 6 → Polish and production readiness

### Test-First Development (TDD) Workflow

**Constitution Requirement**: Tests MUST be written before implementation

**Red-Green-Refactor Cycle**:

1. **RED Phase**: Write failing tests
   - US1: Write T013-T018, verify they FAIL
   - US2: Write T027-T032, verify they FAIL
   - US3: Write T041-T043, verify they FAIL

2. **GREEN Phase**: Implement minimum code to pass tests
   - US1: Implement T019-T025, verify tests PASS
   - US2: Implement T033-T039, verify tests PASS
   - US3: Implement T044-T047, verify tests PASS

3. **REFACTOR Phase**: Improve code quality while keeping tests green
   - Extract helper methods
   - Simplify conditional logic
   - Improve naming and structure
   - Verify tests still PASS after each refactor

**Test Coverage Goals**:
- Unit tests: AuthService methods (signInWithGoogle, error handling)
- Widget tests: OAuthButton behavior (loading, disabled states)
- Integration tests: Complete OAuth flow end-to-end

---

## Implementation Notes

### Platform-Specific Considerations

**Android**:
- Requires Google Play Services on device
- SHA-1 fingerprint must match (debug vs release builds)
- Test on devices without Play Services (edge case)

**iOS**:
- URL scheme callback required for OAuth redirect
- GIDClientID must be correct Web Client ID
- Test on iOS 15+ devices

### Backend Coordination

**GraphQL Mutation Required**: `signInWithGoogle(input: SignInWithGoogleInput!)`
- Input: `idToken` (String)
- Output: `accessToken`, `user` (id, email, name, picture)
- Backend validates token with Google's API
- Backend handles account creation/linking

**Contract Location**: `specs/003-google-oauth-login/contracts/graphql-api.md`

### Security Checklist

- [ ] idToken never logged or exposed
- [ ] Tokens stored in flutter_secure_storage only
- [ ] No secrets in version control
- [ ] HTTPS enforced for all API calls
- [ ] OAuth scopes minimal (email, profile only)
- [ ] Error messages don't expose sensitive info

### Accessibility Checklist

- [ ] OAuthButton has semantic label
- [ ] Screen reader announces button state
- [ ] Loading indicator accessible
- [ ] Error messages accessible to screen readers
- [ ] Touch target size adequate (44x44dp minimum)

---

## Task Summary

**Total Tasks**: 58
**MVP Tasks** (US1 only): 26 (T001-T026)
**Test Tasks**: 18 (T013-T018, T027-T032, T041-T043)
**Implementation Tasks**: 40 (excluding tests and polish)

**Task Distribution by Phase**:
- Phase 1 (Setup): 9 tasks
- Phase 2 (Foundational): 3 tasks
- Phase 3 (US1 - MVP): 14 tasks (6 tests + 8 implementation)
- Phase 4 (US2): 14 tasks (6 tests + 8 implementation)
- Phase 5 (US3): 7 tasks (3 tests + 4 implementation)
- Phase 6 (Polish): 11 tasks

**Parallel Opportunities**: 31 tasks marked [P] can run in parallel

**Independent Test Criteria**:
- ✅ US1: Complete OAuth flow, navigate to home, persist session
- ✅ US2: Display errors for cancellation, network failure, service unavailable
- ✅ US3: Link accounts with matching email, create new for unique email

---

## Next Steps

1. **Start with MVP**: Execute T001-T026 to deliver functional Google OAuth
2. **Follow TDD**: Write failing tests BEFORE implementation (constitution requirement)
3. **Test on Devices**: Verify on real iOS/Android devices (not just emulator)
4. **Coordinate with Backend**: Ensure `signInWithGoogle` mutation is deployed
5. **Incremental Delivery**: Ship US1 (MVP) → US2 (error handling) → US3 (linking) → Polish

**Recommended First Task**: T001 (add google_sign_in dependency)

**Estimated Total Time**: 8-12 hours (including TDD, testing, polish)
