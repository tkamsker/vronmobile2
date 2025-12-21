# Tasks: Project Data Edit Screen

**Input**: Design documents from `/specs/011-project-data/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: This feature follows TDD approach as required by constitution - tests are written FIRST before implementation.

**Organization**: Tasks are organized by implementation phase to enable systematic development of the edit screen functionality.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1)
- Include exact file paths in descriptions

## Path Conventions

- Mobile Flutter app: `lib/features/`, `test/features/`
- Feature-based organization per plan.md

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create directory structure and prepare dependencies

- [ ] T001 [P] Create feature directory structure lib/features/project_data/ with subdirectories: screens/, widgets/
- [ ] T002 [P] Create test directory structure test/features/project_data/ with subdirectories: screens/, widgets/
- [ ] T003 [P] Create unit test directory test/unit/services/ for ProjectService tests

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before user story implementation can begin

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 [P] Add i18n keys to lib/core/i18n/en.json for projectData section (title, subtitle, labels, validation, errors)
- [ ] T005 [P] Add i18n keys to lib/core/i18n/de.json for projectData section (German translations)
- [ ] T006 [P] Add i18n keys to lib/core/i18n/pt.json for projectData section (Portuguese translations)
- [ ] T007 Add route constant projectData to lib/core/navigation/routes.dart
- [ ] T008 Extend ProjectService in lib/features/home/services/project_service.dart with updateProject(String projectId, Map<String, dynamic> input) method implementing update-project-mutation.graphql

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Edit Project Data (Priority: P1) 🎯 MVP

**Goal**: Allow users to view and edit project properties (name, description) in an editable form, validate inputs, and save changes via GraphQL mutation

**Independent Test**: Navigate from ProjectDetailScreen → ProjectDataScreen → Edit name/description → Save → Verify changes persist and detail screen refreshes

### Tests for User Story 1 (TDD - Write FIRST, ensure FAIL) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Write widget test for ProjectForm in test/features/project_data/widgets/project_form_test.dart testing name field validation (required, min length 3, max length 100)
- [ ] T010 [P] [US1] Write widget test for ProjectForm in test/features/project_data/widgets/project_form_test.dart testing description field validation (optional, max length 500)
- [ ] T011 [P] [US1] Write widget test for ProjectDataScreen in test/features/project_data/screens/project_data_screen_test.dart testing initial form population with project data
- [ ] T012 [P] [US1] Write widget test for ProjectDataScreen in test/features/project_data/screens/project_data_screen_test.dart testing save button disabled during loading state
- [ ] T013 [P] [US1] Write widget test for ProjectDataScreen in test/features/project_data/screens/project_data_screen_test.dart testing error message display on save failure
- [ ] T014 [P] [US1] Write unit test for ProjectService.updateProject in test/unit/services/project_service_test.dart testing successful update with mocked GraphQL client
- [ ] T015 [P] [US1] Write unit test for ProjectService.updateProject in test/unit/services/project_service_test.dart testing error handling (not found, unauthorized, validation, conflict, network)
- [ ] T016 [US1] Run all tests with flutter test - VERIFY ALL TESTS FAIL as expected (no implementation exists yet)

### Implementation for User Story 1

#### Widgets (Bottom-Up)

- [ ] T017 [P] [US1] Create ProjectForm widget in lib/features/project_data/widgets/project_form.dart with Form, GlobalKey<FormState>, name and description TextFormFields
- [ ] T018 [P] [US1] Add validation logic to ProjectForm in lib/features/project_data/widgets/project_form.dart (_validateName and _validateDescription methods)
- [ ] T019 [P] [US1] Create SaveButton widget in lib/features/project_data/widgets/save_button.dart with loading state and disabled state support
- [ ] T020 [US1] Run widget tests for ProjectForm and SaveButton - VERIFY TESTS PASS

#### Screen Implementation

- [ ] T021 [US1] Create ProjectDataScreen StatefulWidget in lib/features/project_data/screens/project_data_screen.dart with constructor accepting projectId, initialName, initialDescription
- [ ] T022 [US1] Add State class _ProjectDataScreenState with TextEditingControllers (_nameController, _descriptionController) and _isLoading bool in lib/features/project_data/screens/project_data_screen.dart
- [ ] T023 [US1] Implement initState() in _ProjectDataScreenState initializing controllers with initial project data in lib/features/project_data/screens/project_data_screen.dart
- [ ] T024 [US1] Implement dispose() in _ProjectDataScreenState disposing controllers in lib/features/project_data/screens/project_data_screen.dart
- [ ] T025 [US1] Build Scaffold with AppBar (back button, title "Edit Project") in lib/features/project_data/screens/project_data_screen.dart
- [ ] T026 [US1] Add ProjectForm widget to body with controllers in lib/features/project_data/screens/project_data_screen.dart
- [ ] T027 [US1] Add Save and Cancel buttons to bottom of screen in lib/features/project_data/screens/project_data_screen.dart
- [ ] T028 [US1] Implement _saveChanges() method calling ProjectService.updateProject with form data in lib/features/project_data/screens/project_data_screen.dart
- [ ] T029 [US1] Add try-catch error handling in _saveChanges() with error message parsing (_parseErrorMessage helper) in lib/features/project_data/screens/project_data_screen.dart
- [ ] T030 [US1] Add loading state management (setState _isLoading during save) in lib/features/project_data/screens/project_data_screen.dart
- [ ] T031 [US1] Add success flow: show SnackBar with success message, navigate back with result true in lib/features/project_data/screens/project_data_screen.dart
- [ ] T032 [US1] Add error flow: show SnackBar with error message and retry action in lib/features/project_data/screens/project_data_screen.dart
- [ ] T033 [US1] Implement WillPopScope with unsaved changes detection (_hasUnsavedChanges getter) in lib/features/project_data/screens/project_data_screen.dart
- [ ] T034 [US1] Add unsaved changes confirmation dialog (AlertDialog with "Keep Editing" and "Discard" actions) in lib/features/project_data/screens/project_data_screen.dart
- [ ] T035 [US1] Run screen tests for ProjectDataScreen - VERIFY TESTS PASS

#### Navigation Integration

- [ ] T036 [US1] Register projectData route in lib/main.dart routes map pointing to ProjectDataScreen with arguments extraction
- [ ] T037 [US1] Update ProjectDetailScreen in lib/features/project_detail/screens/project_detail_screen.dart adding "Edit" IconButton to AppBar
- [ ] T038 [US1] Implement _handleEditTap() in ProjectDetailScreen navigating to AppRoutes.projectData with projectId, name, description arguments in lib/features/project_detail/screens/project_detail_screen.dart
- [ ] T039 [US1] Handle navigation result in ProjectDetailScreen: if result is true, refresh project data by calling setState and updating _projectFuture in lib/features/project_detail/screens/project_detail_screen.dart

#### Integration Testing

- [ ] T040 [US1] Manual test: Navigate ProjectDetailScreen → ProjectDataScreen → Edit name → Save → Verify detail screen shows updated name
- [ ] T041 [US1] Manual test: Test validation errors (empty name, name too short, description too long)
- [ ] T042 [US1] Manual test: Test unsaved changes dialog (edit field, tap back, verify dialog, tap "Discard")
- [ ] T043 [US1] Manual test: Test cancel button (tap cancel, verify navigates back without saving)

**Checkpoint**: At this point, User Story 1 should be fully functional - users can edit project data, validate inputs, save changes, and see updates reflected in detail screen

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Verification, performance, and quality improvements

- [ ] T044 [P] Verify design matches Requirements/ProjectDetailData.jpg (form layout, labels, buttons, spacing)
- [ ] T045 [P] Add semantic labels to all form fields for accessibility in lib/features/project_data/screens/project_data_screen.dart
- [ ] T046 [P] Verify touch targets are at least 44x44 px for all interactive elements
- [ ] T047 Run all tests with flutter test - VERIFY ALL TESTS PASS
- [ ] T048 Run flutter analyze - VERIFY NO WARNINGS OR ERRORS
- [ ] T049 Test save operation performance - VERIFY completes in < 2 seconds
- [ ] T050 Test validation feedback performance - VERIFY displays in < 100ms
- [ ] T051 Test error scenarios: network error (disconnect wifi, try save, verify error + retry)
- [ ] T052 Test error scenarios: unauthorized (expired token, try save, verify navigate to login)
- [ ] T053 Run quickstart.md validation scenarios - VERIFY all test scenarios pass
- [ ] T054 Code cleanup: remove debug prints, unused imports, commented code
- [ ] T055 [P] Update CLAUDE.md or project documentation if needed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS user story
- **User Story 1 (Phase 3)**: Depends on Foundational phase completion
- **Polish (Phase 4)**: Depends on User Story 1 being complete

### Within User Story 1

- **Tests (T009-T016)**: Must be written FIRST and FAIL before any implementation
- **Widget tests (T017-T020)**: Implement widgets, then verify tests pass
- **Screen (T021-T035)**: Build screen, implement logic, verify tests pass
- **Navigation (T036-T039)**: Integrate with existing ProjectDetailScreen
- **Integration testing (T040-T043)**: Manual verification of full flow

### Parallel Opportunities

**Phase 1 (All parallel)**:
- T001, T002, T003 can all run in parallel (different directories)

**Phase 2 (i18n files parallel)**:
- T004, T005, T006 can run in parallel (different files)
- T007 and T008 are sequential (different concerns)

**User Story 1 - Tests (All parallel)**:
- T009, T010, T011, T012, T013, T014, T015 can all run in parallel (different test files)

**User Story 1 - Widgets (Parallel)**:
- T017, T018, T019 can run in parallel (different widget files)

**Phase 4 - Polish (Many parallel)**:
- T044, T045, T046, T054, T055 can run in parallel (different concerns)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all test writing tasks for User Story 1 together:
Task: "Write widget test for ProjectForm name validation in test/features/project_data/widgets/project_form_test.dart"
Task: "Write widget test for ProjectForm description validation in test/features/project_data/widgets/project_form_test.dart"
Task: "Write widget test for ProjectDataScreen initial population in test/features/project_data/screens/project_data_screen_test.dart"
Task: "Write widget test for ProjectDataScreen loading state in test/features/project_data/screens/project_data_screen_test.dart"
Task: "Write widget test for ProjectDataScreen error display in test/features/project_data/screens/project_data_screen_test.dart"
Task: "Write unit test for ProjectService.updateProject success in test/unit/services/project_service_test.dart"
Task: "Write unit test for ProjectService.updateProject errors in test/unit/services/project_service_test.dart"
```

## Parallel Example: User Story 1 Widgets

```bash
# Launch all widget creation tasks together:
Task: "Create ProjectForm widget in lib/features/project_data/widgets/project_form.dart"
Task: "Add validation logic to ProjectForm in lib/features/project_data/widgets/project_form.dart"
Task: "Create SaveButton widget in lib/features/project_data/widgets/save_button.dart"
```

---

## Implementation Strategy

### MVP First (Single User Story)

1. **Complete Phase 1**: Setup (T001-T003) - ~10 minutes
2. **Complete Phase 2**: Foundational (T004-T008) - ~30 minutes
   - i18n keys for all strings
   - Route registration
   - GraphQL mutation service method
3. **Complete Phase 3**: User Story 1 (T009-T043) - ~3-4 hours
   - Write ALL tests first (TDD)
   - Implement widgets bottom-up
   - Build screen with save logic
   - Integrate navigation
   - Manual testing
4. **STOP and VALIDATE**: Test full flow end-to-end
5. **Complete Phase 4**: Polish (T044-T055) - ~1 hour
6. **Deploy/Demo**: Feature complete and ready for PR

### TDD Workflow Per Task Group

1. **Write tests** (T009-T016) → Run tests → **ALL FAIL** ✋
2. **Implement widgets** (T017-T020) → Run tests → **WIDGET TESTS PASS** ✅
3. **Implement screen** (T021-T035) → Run tests → **SCREEN TESTS PASS** ✅
4. **Integrate navigation** (T036-T039) → Manual test → **FLOW WORKS** ✅
5. **Polish and verify** (T040-T055) → All tests → **EVERYTHING PASSES** ✅

### Checkpoint Strategy

- After T008: Foundation ready ✓
- After T016: Tests written and failing ✓
- After T020: Widgets working, tests passing ✓
- After T035: Screen working, tests passing ✓
- After T039: Navigation integrated ✓
- After T043: Manual testing complete ✓
- After T055: Feature polished and complete ✓

---

## Task Summary

**Total Tasks**: 55

**By Phase**:
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 5 tasks
- Phase 3 (User Story 1): 35 tasks
  - Tests: 8 tasks (T009-T016)
  - Widgets: 4 tasks (T017-T020)
  - Screen: 15 tasks (T021-T035)
  - Navigation: 4 tasks (T036-T039)
  - Integration: 4 tasks (T040-T043)
- Phase 4 (Polish): 12 tasks

**Parallel Opportunities**: 24 tasks can run in parallel (marked with [P])

**MVP Scope**: All 55 tasks (this is a single-story feature)

**Estimated Time**: 5-7 hours for full implementation

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [US1] label maps all tasks to User Story 1
- TDD approach: tests MUST be written first and MUST fail before implementation
- Verify tests fail before implementing (T016)
- Verify tests pass after implementing widgets (T020) and screen (T035)
- Commit after each logical group of tasks
- Stop at checkpoints to validate progress
- Constitution-compliant: Test-first, simple patterns, Flutter-native widgets
