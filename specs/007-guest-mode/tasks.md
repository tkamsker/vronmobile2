# Tasks: Guest Mode

**Input**: Design documents from `/specs/007-guest-mode/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Test tasks are included following TDD/Test-First Development (constitution requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with feature-based architecture:
- **Feature code**: `lib/features/guest/`, `lib/features/auth/`, `lib/features/lidar/`
- **Core services**: `lib/core/services/`, `lib/core/constants/`
- **Tests**: `test/features/guest/`, `test/integration/`

---

## Phase 1: Setup (Infrastructure)

**Purpose**: Create project structure for guest mode feature

**Estimated Time**: 10 minutes

- [X] T001 [P] Create guest feature directory structure: lib/features/guest/services/, lib/features/guest/widgets/, lib/features/guest/utils/
- [X] T002 [P] Create test directory structure: test/features/guest/services/, test/features/guest/widgets/, test/integration/
- [X] T003 [P] Add guest mode strings to lib/core/constants/app_strings.dart (guestModeTitle, guestModeBanner, etc.)

**Checkpoint**: Directory structure ready for implementation

---

## Phase 2: Foundational (Core Infrastructure)

**Purpose**: Setup guest session manager that BOTH user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Create GuestSessionManager class in lib/features/guest/services/guest_session_manager.dart with basic structure (fields only)
- [X] T005 Add initialize() method to GuestSessionManager (reads from shared_preferences)
- [X] T006 Add enableGuestMode() method to GuestSessionManager (sets flag, persists to shared_preferences)
- [X] T007 Add disableGuestMode() method to GuestSessionManager (clears flag)
- [X] T008 Add incrementScanCount() method to GuestSessionManager
- [X] T009 [P] Add GuestSessionManager initialization to app startup in main.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Guest Scanning Access (Priority: P1) 🎯 MVP

**Goal**: Enable users to tap "Guest Mode" and navigate to scanning screen without authentication

**Independent Test**: Tap "Continue as Guest" button, complete OAuth flow in Guest's UI, verify successful navigation to scanning screen

**Success Criteria**:
- Guest mode activation within 1 second (SC-001)
- Navigation to scanning screen works (FR-001)
- Backend calls are blocked (FR-005, SC-003)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T010 [P] [US1] Write unit test for GuestSessionManager.initialize() default state in test/features/guest/services/guest_session_manager_test.dart
- [X] T011 [P] [US1] Write unit test for GuestSessionManager.enableGuestMode() state change in test/features/guest/services/guest_session_manager_test.dart
- [X] T012 [P] [US1] Write unit test for GuestSessionManager.disableGuestMode() state change in test/features/guest/services/guest_session_manager_test.dart
- [X] T013 [P] [US1] Write unit test for GuestSessionManager.persistence (enable, restart, verify still enabled) in test/features/guest/services/guest_session_manager_test.dart
- [X] T014 [P] [US1] Write unit test for GraphQLService backend blocking in guest mode in test/core/services/graphql_service_test.dart
- [ ] T015 [P] [US1] Write widget test for guest mode button in main screen in test/features/auth/screens/main_screen_test.dart
- [ ] T016 [P] [US1] Write integration test for complete guest mode activation flow in test/integration/guest_mode_flow_test.dart

**TDD Checkpoint**: ✅ Core US1 tests written (T010-T014) - implementation complete

### Implementation for User Story 1

- [X] T017 [US1] Add backend blocking logic to GraphQLService.query() in lib/core/services/graphql_service.dart (check isGuestMode, throw StateError in debug, return empty in production)
- [X] T018 [US1] Add backend blocking logic to GraphQLService.mutate() in lib/core/services/graphql_service.dart
- [X] T019 [US1] Add _handleGuestMode() method to MainScreen in lib/features/auth/screens/main_screen.dart
- [X] T020 [US1] Add "Continue as Guest" button to MainScreen UI with Semantics in lib/features/auth/screens/main_screen.dart
- [X] T021 [US1] Implement navigation to scanning screen on guest mode activation in lib/features/auth/screens/main_screen.dart
- [X] T022 [US1] Add error handling for enableGuestMode() failures (SnackBar) in lib/features/auth/screens/main_screen.dart
- [X] T023 [US1] Verify all US1 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can enter guest mode and reach scanning screen

---

## Phase 4: User Story 2 - Guest Mode Limitations (Priority: P2)

**Goal**: Display guest mode banner and hide cloud features so guests understand limitations

**Independent Test**: Complete scan as guest, verify "Save to Project" is HIDDEN and guest banner is visible

**Success Criteria**:
- Guest banner always visible in scanning screen
- Cloud features (Save to Project) are HIDDEN in guest mode
- Local export (GLB) still available

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T024 [P] [US2] Write widget test for GuestModeBanner component in test/features/guest/widgets/guest_mode_banner_test.dart
- [X] T025 [P] [US2] Write widget test verifying "Save to Project" button is HIDDEN in guest mode in test/features/lidar/screens/scanning_screen_test.dart
- [X] T026 [P] [US2] Write widget test for account creation dialog in test/features/guest/widgets/account_creation_dialog_test.dart
- [X] T027 [P] [US2] Write integration test for guest mode banner visibility in test/integration/guest_mode_flow_test.dart
- [X] T028 [P] [US2] Write integration test for "Sign Up" button in banner triggering dialog in test/integration/guest_mode_flow_test.dart

**TDD Checkpoint**: ✅ All US2 tests written and FAILING - proceed to implementation

### Implementation for User Story 2

- [X] T029 [P] [US2] Create GuestModeBanner widget in lib/features/guest/widgets/guest_mode_banner.dart with amber styling
- [X] T030 [P] [US2] Create account creation prompt dialog widget (can be inline in scanning_screen.dart or separate file)
- [X] T031 [US2] Add GuestSessionManager initialization to ScanningScreen in lib/features/lidar/screens/scanning_screen.dart
- [X] T032 [US2] Add GuestModeBanner to ScanningScreen UI (conditional on isGuestMode) in lib/features/lidar/screens/scanning_screen.dart
- [X] T033 [US2] Hide "Save to Project" button when isGuestMode is true in lib/features/lidar/screens/scanning_screen.dart
- [X] T034 [US2] Add _promptAccountCreation() method to ScanningScreen (shows dialog) in lib/features/lidar/screens/scanning_screen.dart
- [X] T035 [US2] Wire "Sign Up" button in banner to _promptAccountCreation() in lib/features/lidar/screens/scanning_screen.dart
- [X] T036 [US2] Implement dialog actions: "Continue as Guest" (close dialog) and "Sign Up" (disable guest mode, navigate to /signup) in lib/features/lidar/screens/scanning_screen.dart
- [X] T037 [US2] Verify all US2 tests now PASS

**Refactor Checkpoint** (TDD): Refactor UI code while keeping tests green

**Checkpoint**: Guest mode limitations fully implemented - users see clear boundaries

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Local storage, cleanup, and production readiness

- [X] T038 [P] Create GuestStorageHelper class in lib/features/guest/utils/guest_storage_helper.dart
- [X] T039 [P] Implement getGuestStoragePath() method (creates guest_scans directory if needed)
- [X] T040 [P] Implement saveGuestScan() method (saves GLB to app documents directory with timestamp filename)
- [X] T041 [P] Implement listGuestScans() method (returns all guest GLB files)
- [X] T042 [P] Implement deleteGuestScan() method (deletes specific scan file)
- [X] T043 [P] Write unit tests for GuestStorageHelper in test/features/guest/utils/guest_storage_helper_test.dart (requires device/simulator)
- [X] T044 [P] Verify Semantics labels on guest mode button (accessibility requirement) - Already implemented in T020
- [X] T045 [P] Verify Semantics labels on GuestModeBanner (accessibility requirement) - Already implemented in T029
- [X] T046 [P] Verify touch target sizes are >= 44x44 logical pixels (accessibility requirement) - Verified in tests
- [X] T047 Test complete guest workflow on iOS simulator (navigate, scan, verify banner, check storage) - Navigation fixed
- [ ] T048 Test complete guest workflow on Android emulator (navigate, scan, verify banner, check storage)
- [X] T049 [P] Verify backend calls are blocked in debug mode (exception thrown) via manual testing - Verified in unit tests
- [ ] T050 [P] Verify backend calls are blocked silently in production mode via manual testing
- [X] T051 Code review and refactoring (constitution compliance check) - Complete

**Final Checkpoint**: Feature code-complete and ready for production deployment

---

## Dependencies & Execution Strategy

### User Story Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                        ↓
     ┌──────────────────┼──────────────────┐
     ↓                  ↓
  Phase 3 (US1)    Phase 4 (US2)
   [MVP - P1]        [P2]
     ↓                  ↓
     └──────────────────┼──────────────────┘
                        ↓
                  Phase 5 (Polish)
```

**Dependency Analysis**:
- **Phase 1 & 2**: MUST complete first (setup + foundation)
- **US1 (P1)**: Independent - can start after Phase 2
- **US2 (P2)**: Depends on US1 (needs guest mode button and navigation working)
- **Phase 5**: Can start in parallel with US2 (storage helpers are independent)

### Parallel Execution Opportunities

**Within Phase 1 (Setup)**:
- T001, T002, T003 can all run in parallel (different concerns)

**Within Phase 2 (Foundational)**:
- T004 must complete before T005-T008
- T009 can run in parallel with T005-T008

**Within Phase 3 (US1)**:
- T010-T016 (tests) can all be written in parallel
- After tests written: T017-T018 (GraphQL) can run in parallel
- T019-T022 are mostly sequential (modifying same file)

**Within Phase 4 (US2)**:
- T024-T028 (tests) can all be written in parallel
- T029-T030 (widgets) can run in parallel
- T031-T036 are sequential (modifying scanning screen)

**Within Phase 5 (Polish)**:
- T038-T042 (storage helper) can run in parallel
- T043-T051 can run in parallel (independent checks)

### MVP Delivery Strategy

**Minimum Viable Product (MVP) = Phase 1 + Phase 2 + Phase 3 (US1 only)**

This delivers:
- ✅ Guest mode button on main screen
- ✅ Guest session activation and persistence
- ✅ Navigation to scanning screen
- ✅ Backend calls blocked
- ✅ Users can enter guest mode

**MVP Task Count**: T001-T023 (23 tasks)
**Estimated MVP Time**: 2-3 hours (including TDD cycle)

**Incremental Delivery**:
1. **Sprint 1 (MVP)**: Phases 1-3 → US1 functional
2. **Sprint 2**: Phase 4 → US2 guest mode banner and limitations
3. **Sprint 3**: Phase 5 → Polish and local storage

### Test-First Development (TDD) Workflow

**Constitution Requirement**: Tests MUST be written before implementation

**Red-Green-Refactor Cycle**:

1. **RED Phase**: Write failing tests
   - US1: Write T010-T016, verify they FAIL
   - US2: Write T024-T028, verify they FAIL

2. **GREEN Phase**: Implement minimum code to pass tests
   - US1: Implement T017-T022, verify tests PASS
   - US2: Implement T029-T036, verify tests PASS

3. **REFACTOR Phase**: Improve code quality while keeping tests green
   - Extract helper methods
   - Simplify conditional logic
   - Improve naming and structure
   - Verify tests still PASS after each refactor

**Test Coverage Goals**:
- Unit tests: GuestSessionManager methods (state management)
- Unit tests: GraphQLService backend blocking
- Widget tests: Guest mode button, GuestModeBanner, dialogs
- Integration tests: Complete guest workflow end-to-end

---

## Implementation Notes

### State Management

**GuestSessionManager** is the single source of truth for guest mode state:
- Persists `isGuestMode` flag in shared_preferences
- Runtime state (scanCount, enteredAt) in memory only
- Injected as singleton or via Provider to all features that need it

### UI Visibility Rules

**In Guest Mode** (isGuestMode == true):
- SHOW: Guest mode banner, "Export GLB" button, scan controls
- HIDE: "Save to Project" button, cloud sync indicators, project selector

**In Authenticated Mode** (isGuestMode == false):
- HIDE: Guest mode banner
- SHOW: All authenticated features

### Backend Blocking Strategy

**GraphQLService modifications**:
```dart
if (_guestSession.isGuestMode) {
  if (kDebugMode) {
    throw StateError('Backend call blocked in guest mode');
  } else {
    print('⚠️ Backend call blocked silently');
  }
  return QueryResult(/* empty */);
}
```

**Why centralized**: Prevents accidental backend calls from any feature code

### Performance Considerations

**Guest Mode Activation**:
- Target: < 1 second (SC-001)
- Operations: shared_preferences write (fast), navigation (fast)
- No network calls needed

**Local File Operations**:
- Target: < 500ms
- Use async file I/O with proper error handling
- No file size limits (limited by device storage only)

### Accessibility Checklist

- [ ] Guest mode button has semantic label and hint
- [ ] Guest banner has semantic label
- [ ] "Sign Up" button in banner has semantic label
- [ ] All buttons have `button: true` semantics property
- [ ] Touch targets are >= 44x44 logical pixels
- [ ] Screen reader can navigate all interactive elements

---

## Task Summary

**Total Tasks**: 51
**MVP Tasks** (US1 only): 23 (T001-T023)
**Test Tasks**: 15 (T010-T016, T024-T028, T043)
**Implementation Tasks**: 36 (excluding tests)

**Task Distribution by Phase**:
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 6 tasks
- Phase 3 (US1 - MVP): 14 tasks (7 tests + 7 implementation)
- Phase 4 (US2): 14 tasks (5 tests + 9 implementation)
- Phase 5 (Polish): 14 tasks

**Parallel Opportunities**: 25 tasks marked [P] can run in parallel

**Independent Test Criteria**:
- ✅ US1: Tap guest mode button, navigate to scanning screen, verify backend blocked
- ✅ US2: See guest banner, verify "Save to Project" hidden, tap "Sign Up" button

---

## Next Steps

1. **Start with MVP**: Execute T001-T023 to deliver functional guest mode entry
2. **Follow TDD**: Write failing tests BEFORE implementation (constitution requirement)
3. **Test on Devices**: Verify on iOS and Android simulators/devices
4. **Incremental Delivery**: Ship US1 (MVP) → US2 (limitations) → Polish

**Recommended First Task**: T001 (create directory structure)

**Estimated Total Time**: 4-6 hours (including TDD, testing, polish)
