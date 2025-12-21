# Tasks: Project Detail and Data Management

**Input**: Design documents from `/specs/003-projectdetail/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: TDD is MANDATORY per constitution - tests must be written FIRST and FAIL before implementation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile project with feature-based organization:
- `lib/features/home/` - Existing home feature (extended)
- `lib/features/projects/` - New project detail feature
- `lib/core/` - Shared core services
- `test/features/` - Feature tests
- `test/integration/` - Integration tests

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize project structure for new feature

- [ ] T001 Create feature directory structure for projects feature: lib/features/projects/{models,screens,widgets,utils}
- [ ] T002 Create test directory structure: test/features/projects/{screens,widgets,utils}
- [ ] T003 [P] Create integration test directory: test/integration/
- [ ] T004 [P] Verify all dependencies are installed: graphql_flutter, cached_network_image, flutter_secure_storage

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core model and service extensions that BLOCK all user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundation (TDD - Write First, Ensure FAIL)

- [ ] T005 [P] Write failing test for Project model with description field in test/features/home/models/project_test.dart
- [ ] T006 [P] Write failing test for Project.fromJson parsing description in test/features/home/models/project_test.dart
- [ ] T007 [P] Write failing test for Project.copyWith with description in test/features/home/models/project_test.dart
- [ ] T008 [P] Write failing test for Project equality including description in test/features/home/models/project_test.dart

### Implementation for Foundation

- [ ] T009 Extend Project model with description field in lib/features/home/models/project.dart
- [ ] T010 Update Project.fromJson to parse description from I18NField in lib/features/home/models/project.dart
- [ ] T011 Update Project.copyWith to include description parameter in lib/features/home/models/project.dart
- [ ] T012 Update Project equality operator and hashCode to include description in lib/features/home/models/project.dart
- [ ] T013 Run tests to verify Project model changes - all T005-T008 tests should now PASS

**Checkpoint**: Foundation ready - Project model extended with description field, all tests passing

---

## Phase 3: User Story 1 - View Project Details (Priority: P1) 🎯 MVP

**Goal**: Users can navigate from projects list to detailed project view with tabs (Viewer, Project data, Products)

**Independent Test**: Login, select project from list, verify detail screen displays with project info, tabs, and navigation options

### Tests for User Story 1 (TDD - Write First, Ensure FAIL)

#### Service Tests

- [ ] T014 [P] [US1] Write failing test for getProjectDetail query in test/features/home/services/project_service_test.dart
- [ ] T015 [P] [US1] Write failing test for getProjectDetail error handling in test/features/home/services/project_service_test.dart

#### Widget Tests

- [ ] T016 [P] [US1] Write failing widget test for ProjectDetailScreen loading state in test/features/projects/screens/project_detail_screen_test.dart
- [ ] T017 [P] [US1] Write failing widget test for ProjectDetailScreen displaying project data in test/features/projects/screens/project_detail_screen_test.dart
- [ ] T018 [P] [US1] Write failing widget test for ProjectDetailScreen showing tabs in test/features/projects/screens/project_detail_screen_test.dart
- [ ] T019 [P] [US1] Write failing widget test for ProjectDetailScreen error state in test/features/projects/screens/project_detail_screen_test.dart
- [ ] T020 [P] [US1] Write failing widget test for ProjectDetailHeader in test/features/projects/widgets/project_detail_header_test.dart
- [ ] T021 [P] [US1] Write failing widget test for ProjectViewerTab placeholder in test/features/projects/widgets/project_viewer_tab_test.dart
- [ ] T022 [P] [US1] Write failing widget test for ProjectTabNavigation in test/features/projects/widgets/project_tab_navigation_test.dart

### Implementation for User Story 1

#### GraphQL Service Layer

- [ ] T023 [US1] Add getProjectDetail GraphQL query constant in lib/features/home/services/project_service.dart
- [ ] T024 [US1] Implement getProjectDetail method with error handling in lib/features/home/services/project_service.dart
- [ ] T025 [US1] Run service tests - T014-T015 should now PASS

#### Navigation Setup

- [ ] T026 [P] [US1] Add projectDetail route to AppRoutes in lib/core/navigation/routes.dart
- [ ] T027 [P] [US1] Register ProjectDetailScreen route in MaterialApp routes in lib/main.dart
- [ ] T028 [US1] Update ProjectCard to navigate to detail screen with project ID in lib/features/home/widgets/project_card.dart

#### Screens and Widgets

- [ ] T029 [P] [US1] Create ProjectDetailScreen with TabController in lib/features/projects/screens/project_detail_screen.dart
- [ ] T030 [P] [US1] Implement loading, error, and success states in ProjectDetailScreen in lib/features/projects/screens/project_detail_screen.dart
- [ ] T031 [P] [US1] Create ProjectDetailHeader widget in lib/features/projects/widgets/project_detail_header.dart
- [ ] T032 [P] [US1] Create ProjectViewerTab placeholder widget in lib/features/projects/widgets/project_viewer_tab.dart
- [ ] T033 [P] [US1] Create ProjectTabNavigation widget in lib/features/projects/widgets/project_tab_navigation.dart
- [ ] T034 [P] [US1] Create stub ProjectDataTab widget (returns placeholder) in lib/features/projects/widgets/project_data_tab.dart
- [ ] T035 [P] [US1] Create stub ProjectProductsTab widget (returns placeholder) in lib/features/projects/widgets/project_products_tab.dart
- [ ] T036 [US1] Integrate all widgets into ProjectDetailScreen with TabBarView in lib/features/projects/screens/project_detail_screen.dart

#### Test Verification

- [ ] T037 [US1] Run all widget tests for US1 - T016-T022 should now PASS
- [ ] T038 [US1] Run flutter analyze to check for linting errors
- [ ] T039 [US1] Manual test: Navigate to project detail and verify all tabs display correctly

**Checkpoint**: User Story 1 complete - Users can view project details with tab navigation

---

## Phase 4: User Story 2 - Edit Project Data (Priority: P2)

**Goal**: Users can edit project name and description, with validation, unsaved changes warning, and save functionality

**Independent Test**: Navigate to project detail, tap "Project data" tab, modify fields, verify validation, save changes, verify persistence

### Tests for User Story 2 (TDD - Write First, Ensure FAIL)

#### Model Tests

- [ ] T040 [P] [US2] Write failing test for ProjectEditForm.fromProject in test/features/projects/models/project_edit_form_test.dart
- [ ] T041 [P] [US2] Write failing test for ProjectEditForm.isValid in test/features/projects/models/project_edit_form_test.dart
- [ ] T042 [P] [US2] Write failing test for ProjectEditForm.copyWith in test/features/projects/models/project_edit_form_test.dart
- [ ] T043 [P] [US2] Write failing test for ProjectEditForm.toUpdateInput in test/features/projects/models/project_edit_form_test.dart

#### Validator Tests

- [ ] T044 [P] [US2] Write failing test for validateName with valid input in test/features/projects/utils/project_validator_test.dart
- [ ] T045 [P] [US2] Write failing test for validateName with empty input in test/features/projects/utils/project_validator_test.dart
- [ ] T046 [P] [US2] Write failing test for validateName exceeding max length in test/features/projects/utils/project_validator_test.dart
- [ ] T047 [P] [US2] Write failing test for validateDescription max length in test/features/projects/utils/project_validator_test.dart

#### Service Tests

- [ ] T048 [P] [US2] Write failing test for updateProject mutation success in test/features/home/services/project_service_test.dart
- [ ] T049 [P] [US2] Write failing test for updateProject mutation validation error in test/features/home/services/project_service_test.dart
- [ ] T050 [P] [US2] Write failing test for updateProject mutation network error in test/features/home/services/project_service_test.dart

#### Widget Tests

- [ ] T051 [P] [US2] Write failing widget test for ProjectDataTab rendering form fields in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T052 [P] [US2] Write failing widget test for ProjectDataTab slug read-only display in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T053 [P] [US2] Write failing widget test for ProjectDataTab form validation in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T054 [P] [US2] Write failing widget test for ProjectDataTab dirty state tracking in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T055 [P] [US2] Write failing widget test for ProjectDataTab save button enabled/disabled in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T056 [P] [US2] Write failing widget test for ProjectDataTab unsaved changes warning dialog in test/features/projects/widgets/project_data_tab_test.dart
- [ ] T057 [P] [US2] Write failing widget test for ProjectDataTab successful save flow in test/features/projects/widgets/project_data_tab_test.dart

### Implementation for User Story 2

#### Models and Utilities

- [ ] T058 [P] [US2] Create ProjectEditForm model class in lib/features/projects/models/project_edit_form.dart
- [ ] T059 [P] [US2] Implement ProjectEditForm.fromProject factory in lib/features/projects/models/project_edit_form.dart
- [ ] T060 [P] [US2] Implement ProjectEditForm.isValid getter in lib/features/projects/models/project_edit_form.dart
- [ ] T061 [P] [US2] Implement ProjectEditForm.copyWith method in lib/features/projects/models/project_edit_form.dart
- [ ] T062 [P] [US2] Implement ProjectEditForm.toUpdateInput method in lib/features/projects/models/project_edit_form.dart
- [ ] T063 [US2] Run ProjectEditForm tests - T040-T043 should now PASS

- [ ] T064 [P] [US2] Create ProjectValidator utility class in lib/features/projects/utils/project_validator.dart
- [ ] T065 [P] [US2] Implement validateName method with length and required checks in lib/features/projects/utils/project_validator.dart
- [ ] T066 [P] [US2] Implement validateDescription method with max length check in lib/features/projects/utils/project_validator.dart
- [ ] T067 [US2] Run validator tests - T044-T047 should now PASS

#### GraphQL Service Layer

- [ ] T068 [US2] Add updateProject GraphQL mutation constant in lib/features/home/services/project_service.dart
- [ ] T069 [US2] Implement updateProject method with error handling in lib/features/home/services/project_service.dart
- [ ] T070 [US2] Run service mutation tests - T048-T050 should now PASS

#### Widgets Implementation

- [ ] T071 [US2] Implement ProjectDataTab with form state management using StatefulWidget in lib/features/projects/widgets/project_data_tab.dart
- [ ] T072 [US2] Add TextEditingControllers for name and description in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T073 [US2] Add TextFormField for name with validation in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T074 [US2] Add TextFormField for description with validation in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T075 [US2] Display slug as read-only Text widget in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T076 [US2] Implement dirty state tracking in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T077 [US2] Implement save button with enabled/disabled logic in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T078 [US2] Implement save operation calling updateProject service in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T079 [US2] Implement automatic refresh after successful save in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T080 [US2] Implement unsaved changes warning dialog with AlertDialog in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T081 [US2] Implement WillPopScope to detect back navigation in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T082 [US2] Add loading state with CircularProgressIndicator during save in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T083 [US2] Add error handling with SnackBar for save failures in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T084 [US2] Add success message with SnackBar after save in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T085 [US2] Add AutomaticKeepAliveClientMixin to preserve state across tab switches in ProjectDataTab in lib/features/projects/widgets/project_data_tab.dart
- [ ] T086 [US2] Implement proper controller disposal in ProjectDataTab dispose() in lib/features/projects/widgets/project_data_tab.dart

#### Test Verification

- [ ] T087 [US2] Run all widget tests for US2 - T051-T057 should now PASS
- [ ] T088 [US2] Run flutter analyze to check for linting errors
- [ ] T089 [US2] Manual test: Edit project data, verify validation, save changes, verify persistence

**Checkpoint**: User Story 2 complete - Users can edit project name and description with full validation and save functionality

---

## Phase 5: User Story 3 - Navigate to Products (Priority: P3)

**Goal**: Users can navigate from project detail to products list screen

**Independent Test**: Navigate to project detail, tap "Products" tab, verify navigation to products screen (stub implementation)

### Tests for User Story 3 (TDD - Write First, Ensure FAIL)

- [ ] T090 [P] [US3] Write failing widget test for ProjectProductsTab displaying "View Products" button in test/features/projects/widgets/project_products_tab_test.dart
- [ ] T091 [P] [US3] Write failing widget test for ProjectProductsTab navigation on button tap in test/features/projects/widgets/project_products_tab_test.dart

### Implementation for User Story 3

- [ ] T092 [P] [US3] Update ProjectProductsTab to display "View Products" button in lib/features/projects/widgets/project_products_tab.dart
- [ ] T093 [P] [US3] Add placeholder navigation to products screen (Navigator.pushNamed with placeholder route) in lib/features/projects/widgets/project_products_tab.dart
- [ ] T094 [P] [US3] Add Semantics labels for accessibility in ProjectProductsTab in lib/features/projects/widgets/project_products_tab.dart

#### Test Verification

- [ ] T095 [US3] Run widget tests for US3 - T090-T091 should now PASS
- [ ] T096 [US3] Run flutter analyze to check for linting errors
- [ ] T097 [US3] Manual test: Tap Products tab, verify placeholder navigation works

**Checkpoint**: User Story 3 complete - Users can access products section (placeholder navigation)

---

## Phase 6: Integration Testing

**Purpose**: Test complete user journeys across all user stories

### Integration Tests (TDD - Write First, Ensure FAIL)

- [ ] T098 [P] Write failing integration test for full project view journey in test/integration/project_edit_journey_test.dart
- [ ] T099 [P] Write failing integration test for full project edit journey in test/integration/project_edit_journey_test.dart
- [ ] T100 [P] Write failing integration test for tab state preservation in test/integration/project_edit_journey_test.dart
- [ ] T101 [P] Write failing integration test for unsaved changes warning flow in test/integration/project_edit_journey_test.dart

### Integration Test Implementation

- [ ] T102 Create integration test helper functions for common actions in test/integration/project_edit_journey_test.dart
- [ ] T103 Implement test: Navigate from projects list → detail screen → verify data loads in test/integration/project_edit_journey_test.dart
- [ ] T104 Implement test: Edit project → save → verify auto-refresh in test/integration/project_edit_journey_test.dart
- [ ] T105 Implement test: Switch tabs → verify form state preserved in test/integration/project_edit_journey_test.dart
- [ ] T106 Implement test: Edit → navigate back → verify unsaved warning in test/integration/project_edit_journey_test.dart

#### Test Verification

- [ ] T107 Run all integration tests - T098-T101 should now PASS
- [ ] T108 Run complete test suite: flutter test
- [ ] T109 Verify test coverage meets requirements

**Checkpoint**: All integration tests passing - Complete user journeys verified

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation

- [ ] T110 [P] Add accessibility labels to all interactive widgets for screen readers
- [ ] T111 [P] Verify touch targets meet 44x44 minimum size requirement
- [ ] T112 [P] Test with increased text scale factor (textScaleFactor: 2.0)
- [ ] T113 [P] Verify contrast ratios meet WCAG AA standards
- [ ] T114 [P] Add semantic labels for all form fields
- [ ] T115 [P] Test navigation with TalkBack (Android) / VoiceOver (iOS)
- [ ] T116 Code cleanup: Remove any debug prints or commented code
- [ ] T117 Run flutter analyze --no-fatal-infos and fix all warnings
- [ ] T118 Run quickstart.md validation end-to-end
- [ ] T119 Performance test: Verify < 2s project detail load time
- [ ] T120 Performance test: Verify < 200ms form validation response
- [ ] T121 Performance test: Verify 60 fps during tab navigation and scrolling
- [ ] T122 Update CLAUDE.md with any new patterns or decisions
- [ ] T123 Create PR with summary of changes and test results

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Integration Testing (Phase 6)**: Depends on desired user stories being complete
- **Polish (Phase 7)**: Depends on all functionality being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Enhances US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Adds to US1 but independently testable

### Within Each User Story

**TDD Cycle (MANDATORY)**:
1. **Red**: Write failing tests first (T014-T022 for US1, etc.)
2. **Green**: Implement minimum code to pass tests
3. **Refactor**: Clean up while keeping tests green

**Implementation Order**:
- Tests FIRST (must FAIL before implementation)
- Models/validators (foundation for logic)
- Services (backend integration)
- Widgets (UI components)
- Integration (wire everything together)

### Parallel Opportunities

#### Within Setup (Phase 1)
All tasks T001-T004 can run in parallel (different directories)

#### Within Foundational Tests (Phase 2)
All tests T005-T008 can run in parallel (different test cases)

#### Within User Story 1 Tests
All tests T014-T022 can run in parallel (different test files)

#### Within User Story 1 Implementation
- Service implementation T023-T025 can run in parallel with route setup T026-T028
- Widget creation T029-T035 can run in parallel (different widget files)

#### Within User Story 2 Tests
All tests T040-T057 can run in parallel (different test files)

#### Within User Story 2 Implementation
- Model T058-T063 and Validator T064-T067 can run in parallel (different files)

#### Within Integration Testing (Phase 6)
All integration test writing T098-T101 can run in parallel (different test scenarios)

#### Within Polish (Phase 7)
All accessibility tasks T110-T115 can run in parallel (different aspects)

#### Across User Stories (If Multiple Developers)
Once Foundational complete:
- Developer A: User Story 1 (T014-T039)
- Developer B: User Story 2 (T040-T089)
- Developer C: User Story 3 (T090-T097)

---

## Parallel Example: User Story 1

```bash
# RED Phase - Launch all test writing in parallel:
Task: "Write failing test for getProjectDetail query in test/features/home/services/project_service_test.dart"
Task: "Write failing test for getProjectDetail error handling in test/features/home/services/project_service_test.dart"
Task: "Write failing widget test for ProjectDetailScreen loading state..."
Task: "Write failing widget test for ProjectDetailScreen displaying project data..."
# ... all T014-T022 tests in parallel

# GREEN Phase - Launch parallelizable implementation:
Task: "Add getProjectDetail GraphQL query constant..."
Task: "Add projectDetail route to AppRoutes..."  # Parallel - different file
Task: "Register ProjectDetailScreen route in MaterialApp..."  # Parallel - different file
Task: "Create ProjectDetailHeader widget..."  # Parallel - different file
Task: "Create ProjectViewerTab placeholder widget..."  # Parallel - different file
# ... all [P] marked tasks in parallel

# REFACTOR Phase - Run in sequence:
Task: "Integrate all widgets into ProjectDetailScreen..."  # Sequential - depends on widgets
Task: "Run all widget tests for US1..."  # Sequential - verify everything works
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T013) - CRITICAL
3. Complete Phase 3: User Story 1 (T014-T039)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo MVP (view project details)

**Time Estimate**: 2-3 hours for MVP

### Incremental Delivery

1. Setup + Foundational → Foundation ready (30 min)
2. User Story 1 → Test independently → Deploy (MVP - 2 hours)
3. User Story 2 → Test independently → Deploy (3-4 hours)
4. User Story 3 → Test independently → Deploy (30 min)
5. Integration + Polish → Final release (1 hour)

**Total Time Estimate**: 6-10 hours

### Parallel Team Strategy

With 2-3 developers:

1. **Together**: Complete Setup + Foundational (30 min)
2. **Split**:
   - Dev A: User Story 1 (2 hours)
   - Dev B: User Story 2 (3-4 hours)
   - Dev C: User Story 3 (30 min)
3. **Together**: Integration testing and polish (1 hour)

**Total Time with Parallel**: 4-5 hours

---

## TDD Compliance Checklist

✅ All test tasks explicitly marked "Write failing test"
✅ Tests ordered before implementation within each user story
✅ "Ensure FAIL" reminders in test sections
✅ Explicit verification tasks to run tests and confirm PASS
✅ Red-Green-Refactor cycle enforced
✅ Integration tests included for full user journeys

---

## Notes

- **[P] tasks** = different files, no dependencies
- **[Story] label** = maps task to specific user story for traceability
- **TDD is non-negotiable** per constitution - tests MUST be written first
- Each user story is independently completable and testable
- Verify tests fail (RED) before implementing (GREEN)
- Refactor while keeping tests green
- Commit after each logical task or group
- Stop at any checkpoint to validate story independently
- **Slug field is read-only** - no editing, validation, or update logic needed
- **Description and name only** are editable fields
- **Automatic refresh after save** to handle concurrent edits (last-write-wins)
