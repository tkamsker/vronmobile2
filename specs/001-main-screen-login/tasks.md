# Tasks: Main Screen (Not Logged-In)

**Input**: Design documents from `/specs/001-main-screen-login/`
**Prerequisites**: plan.md (✓), spec.md (✓), research.md (✓), data-model.md (✓)

**Tests**: Test-First Development is MANDATORY per constitution. All tests MUST be written and FAIL before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (Flutter)**: `lib/` for source code, `test/` for tests at repository root
- File structure follows feature-based organization per plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and directory structure for auth feature

- [X] T001 Create feature directory structure lib/features/auth/ with subdirectories: screens/, widgets/, utils/
- [X] T002 [P] Create core directory structure lib/core/ with subdirectories: constants/, theme/, navigation/
- [X] T003 [P] Create test directory structure test/features/auth/ with subdirectories: screens/, widgets/, utils/
- [X] T004 [P] Add url_launcher dependency to pubspec.yaml (version: ^6.2.0 or latest)
- [X] T005 [P] Configure Flutter analyzer options in analysis_options.yaml for strict linting

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Create app theme in lib/core/theme/app_theme.dart with colors and typography from Figma design
- [X] T007 [P] Create route definitions in lib/core/navigation/routes.dart with named route constants
- [X] T008 [P] Create i18n string keys stub in lib/core/constants/app_strings.dart (actual translations in UC22)
- [X] T009 Update lib/main.dart to register routes and apply theme

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Display Authentication Options (Priority: P1) 🎯 MVP

**Goal**: Display main screen with email/password inputs, auth buttons, and navigation links matching Figma design

**Independent Test**: Launch app in logged-out state, verify all UI elements visible and positioned per Figma

### Tests for User Story 1 (TDD - Write FIRST, ensure FAIL) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T010 [P] [US1] Write unit tests for email validator in test/features/auth/utils/email_validator_test.dart (empty email, invalid format, valid email cases)
- [X] T011 [P] [US1] Write widget test for EmailInput in test/features/auth/widgets/email_input_test.dart (displays label, shows email keyboard, obscures text correctly)
- [X] T012 [P] [US1] Write widget test for PasswordInput in test/features/auth/widgets/password_input_test.dart (displays label, obscures text, shows/hides password toggle)
- [X] T013 [P] [US1] Write widget test for SignInButton in test/features/auth/widgets/sign_in_button_test.dart (enabled/disabled states, loading indicator)
- [X] T014 [P] [US1] Write widget test for OAuthButton in test/features/auth/widgets/oauth_button_test.dart (Google/Facebook variants, loading states)
- [X] T015 [P] [US1] Write widget test for TextLink in test/features/auth/widgets/text_link_test.dart (tap behavior, touch target size 44x44)
- [X] T016 [US1] Write widget test for MainScreen in test/features/auth/screens/main_screen_test.dart (all elements present, layout matches Figma, accessibility labels)

**Run tests: All should FAIL (Red phase)**

### Implementation for User Story 1

- [X] T017 [P] [US1] Implement email validator in lib/features/auth/utils/email_validator.dart with RFC 5322 regex pattern
- [X] T018 [P] [US1] Create EmailInput widget in lib/features/auth/widgets/email_input.dart using TextFormField with email keyboard
- [X] T019 [P] [US1] Create PasswordInput widget in lib/features/auth/widgets/password_input.dart with obscured text
- [X] T020 [P] [US1] Create SignInButton widget in lib/features/auth/widgets/sign_in_button.dart with enabled/disabled/loading states
- [X] T021 [P] [US1] Create OAuthButton widget in lib/features/auth/widgets/oauth_button.dart supporting Google/Facebook variants
- [X] T022 [P] [US1] Create TextLink widget in lib/features/auth/widgets/text_link.dart with minimum 44x44 touch targets
- [X] T023 [US1] Compose MainScreen in lib/features/auth/screens/main_screen.dart using Scaffold, Form, and all widgets (depends on T018-T022)
- [X] T024 [US1] Add semantic labels to all widgets for screen reader accessibility in lib/features/auth/screens/main_screen.dart
- [X] T025 [US1] Register MainScreen route in lib/core/navigation/routes.dart and lib/main.dart

**Run tests: All should PASS (Green phase)**

**Checkpoint**: At this point, User Story 1 should be fully functional - all UI elements visible and accessible

---

## Phase 4: User Story 2 - Navigate to Authentication Flows (Priority: P2)

**Goal**: Enable navigation from main screen to all authentication targets (UC2-UC7)

**Independent Test**: Tap each button/link, verify correct navigation occurs (placeholder screens OK)

### Tests for User Story 2 (TDD - Write FIRST, ensure FAIL) ⚠️

- [ ] T026 [P] [US2] Write integration test for email/password sign-in flow in test/integration/auth_flow_test.dart (tap Sign In triggers UC2)
- [ ] T027 [P] [US2] Write integration test for Google OAuth flow in test/integration/auth_flow_test.dart (tap Google button triggers UC3)
- [ ] T028 [P] [US2] Write integration test for Facebook OAuth flow in test/integration/auth_flow_test.dart (tap Facebook button triggers UC4)
- [ ] T029 [P] [US2] Write integration test for Forgot Password flow in test/integration/auth_flow_test.dart (tap link opens browser)
- [ ] T030 [P] [US2] Write integration test for Create Account flow in test/integration/auth_flow_test.dart (tap link navigates to UC6 screen)
- [ ] T031 [P] [US2] Write integration test for Guest Mode flow in test/integration/auth_flow_test.dart (tap button navigates to UC14 screen)

**Run tests: All should FAIL (Red phase)**

### Implementation for User Story 2

- [ ] T032 [P] [US2] Implement Sign In button handler in lib/features/auth/screens/main_screen.dart to trigger email auth (UC2 integration point)
- [ ] T033 [P] [US2] Implement Google OAuth button handler in lib/features/auth/screens/main_screen.dart to trigger UC3
- [ ] T034 [P] [US2] Implement Facebook OAuth button handler in lib/features/auth/screens/main_screen.dart to trigger UC4
- [ ] T035 [P] [US2] Implement Forgot Password link handler in lib/features/auth/screens/main_screen.dart using url_launcher to open browser
- [ ] T036 [P] [US2] Implement Create Account link handler in lib/features/auth/screens/main_screen.dart to navigate to UC6 route
- [ ] T037 [P] [US2] Implement Guest Mode button handler in lib/features/auth/screens/main_screen.dart to navigate to UC14 route
- [ ] T038 [US2] Add navigation error handling in lib/features/auth/screens/main_screen.dart (handle route not found, url_launcher failures)

**Run tests: All should PASS (Green phase)**

**Checkpoint**: At this point, User Stories 1 AND 2 work - UI displays and all navigation triggers function

---

## Phase 5: User Story 3 - Input Validation and User Feedback (Priority: P3)

**Goal**: Add real-time validation, error messages, and loading states for enhanced UX

**Independent Test**: Interact with inputs, verify validation messages appear/clear, buttons show loading states

### Tests for User Story 3 (TDD - Write FIRST, ensure FAIL) ⚠️

- [ ] T039 [P] [US3] Write widget test for email validation feedback in test/features/auth/widgets/email_input_test.dart (error message on blur with invalid email)
- [ ] T040 [P] [US3] Write widget test for password validation feedback in test/features/auth/widgets/password_input_test.dart (error message when empty)
- [ ] T041 [P] [US3] Write widget test for Sign In button disabled state in test/features/auth/widgets/sign_in_button_test.dart (disabled when form invalid)
- [ ] T042 [P] [US3] Write widget test for loading indicator in test/features/auth/widgets/sign_in_button_test.dart (shows CircularProgressIndicator during auth)
- [ ] T043 [US3] Write widget test for form validation in test/features/auth/screens/main_screen_test.dart (button enabled only when both fields valid)

**Run tests: All should FAIL (Red phase)**

### Implementation for User Story 3

- [ ] T044 [P] [US3] Add validator callback to EmailInput in lib/features/auth/widgets/email_input.dart using EmailValidator
- [ ] T045 [P] [US3] Add validator callback to PasswordInput in lib/features/auth/widgets/password_input.dart for required field check
- [ ] T046 [US3] Wire Form validation in lib/features/auth/screens/main_screen.dart using GlobalKey<FormState> (depends on T044, T045)
- [ ] T047 [US3] Implement Sign In button enable/disable logic in lib/features/auth/screens/main_screen.dart based on form validity
- [ ] T048 [P] [US3] Add loading state management to SignInButton in lib/features/auth/widgets/sign_in_button.dart with CircularProgressIndicator
- [ ] T049 [P] [US3] Add loading state management to OAuthButton in lib/features/auth/widgets/oauth_button.dart
- [ ] T050 [US3] Add validation timing in lib/features/auth/widgets/email_input.dart to validate on blur (300ms feedback per success criteria)

**Run tests: All should PASS (Green phase)**

**Checkpoint**: All user stories complete - full authentication screen with validation and UX polish

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting the entire feature

- [ ] T051 [P] Run flutter analyze and fix all linting issues
- [ ] T052 [P] Run flutter format . to ensure code formatting consistency
- [ ] T053 Verify Figma design match in lib/features/auth/screens/main_screen.dart (colors, spacing, typography)
- [ ] T054 [P] Run accessibility audit using Flutter semantic tree in test/features/auth/screens/main_screen_test.dart
- [ ] T055 [P] Verify all touch targets are minimum 44x44 logical pixels
- [ ] T056 Test keyboard handling on iPhone SE (smallest supported device) - ensure no scrolling required
- [ ] T057 [P] Run performance profiling with Flutter DevTools - confirm 60fps and <1s load time
- [ ] T058 Validate quickstart.md instructions work end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001-T005) - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational (T006-T009) - No dependencies on other stories
- **User Story 2 (Phase 4)**: Depends on User Story 1 (T017-T025) - Needs UI to add navigation
- **User Story 3 (Phase 5)**: Depends on User Story 1 (T017-T025) - Adds validation to existing UI
- **Polish (Phase 6)**: Depends on all user stories (T010-T050) being complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent - Can start after Foundational (Phase 2)
- **User Story 2 (P2)**: Depends on US1 implementation (needs widgets to wire navigation)
- **User Story 3 (P3)**: Depends on US1 implementation (needs widgets to add validation)

**Note**: US2 and US3 could be implemented in parallel after US1 is done, as they modify different aspects (navigation vs validation).

### Within Each User Story

- **TDD Order**: Tests FIRST (marked T0XX), implementation SECOND (marked T0YY where YY > XX)
- **Widget dependencies**: Utility classes (validators) → individual widgets → composed screen
- **Tests are parallelizable**: All test files marked [P] can be written simultaneously
- **Widgets are parallelizable**: Individual widget implementations marked [P] can be done simultaneously
- **Screen composition**: MainScreen (T023) depends on all widgets (T018-T022) being complete

### Parallel Opportunities

- **Setup Phase**: All tasks (T001-T005) can run in parallel
- **Foundational Phase**: Theme, routes, and constants (T006-T008) can run in parallel
- **US1 Tests**: All test files (T010-T016) can be written in parallel
- **US1 Widgets**: Validator and all widgets (T017-T022) can be implemented in parallel
- **US2 Integration Tests**: All navigation tests (T026-T031) can be written in parallel
- **US2 Navigation Handlers**: All button handlers (T032-T037) can be implemented in parallel
- **US3 Tests**: All validation tests (T039-T043) can be written in parallel
- **US3 Validation Logic**: Validator callbacks and loading states (T044-T045, T048-T049) can be done in parallel
- **Polish Phase**: Linting, formatting, accessibility, performance (T051-T052, T054-T055, T057) can run in parallel

---

## Parallel Example: User Story 1

```bash
# Write all tests in parallel (Red phase):
Task T010: "Write email validator unit tests"
Task T011: "Write EmailInput widget test"
Task T012: "Write PasswordInput widget test"
Task T013: "Write SignInButton widget test"
Task T014: "Write OAuthButton widget test"
Task T015: "Write TextLink widget test"
Task T016: "Write MainScreen widget test"

# Implement all components in parallel (Green phase):
Task T017: "Implement email validator"
Task T018: "Create EmailInput widget"
Task T019: "Create PasswordInput widget"
Task T020: "Create SignInButton widget"
Task T021: "Create OAuthButton widget"
Task T022: "Create TextLink widget"

# Then compose screen (depends on all widgets):
Task T023: "Compose MainScreen from widgets"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T009) - CRITICAL checkpoint
3. Write all US1 tests (T010-T016) - should FAIL
4. Implement all US1 components (T017-T025) - tests should PASS
5. **STOP and VALIDATE**: Launch app, verify main screen displays correctly
6. Demo/review before proceeding to US2

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (T010-T025) → Test independently → Demo (MVP!)
3. Add User Story 2 (T026-T038) → Test independently → Demo (navigation works)
4. Add User Story 3 (T039-T050) → Test independently → Demo (validation/UX polish)
5. Polish (T051-T058) → Final QA → Deploy

### Parallel Team Strategy

With multiple developers:

1. **Team completes Setup + Foundational together** (T001-T009)
2. **US1 Split**:
   - Developer A: Write all tests (T010-T016)
   - Developer B: Implement validator + widgets (T017-T022)
   - Developer A: Compose screen after widgets ready (T023-T025)
3. **After US1 Complete**:
   - Developer A: User Story 2 (navigation) (T026-T038)
   - Developer B: User Story 3 (validation) (T039-T050)
4. **Polish together** (T051-T058)

---

## Notes

- **TDD is mandatory**: All tests MUST be written before implementation per constitution
- **[P] tasks** = different files, no dependencies - can execute in parallel
- **[US#] label** maps task to specific user story for traceability
- Each user story is independently testable and delivers incremental value
- **Red-Green-Refactor**: Write failing test → Implement minimal code → Refactor
- Commit after each task or logical group (e.g., all US1 tests, all US1 widgets)
- Stop at checkpoints to validate story independently before proceeding
- All file paths are absolute from repository root
- Figma design is source of truth for visual implementation
- Touch targets, semantic labels, keyboard handling verified in tests
