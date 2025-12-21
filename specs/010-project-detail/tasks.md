# Tasks: Project Detail Screen

**Input**: Design documents from `/specs/010-project-detail/`
**Prerequisites**: Home screen complete (002-home-screen-projects), navigation wired

**Tests**: Following constitution - TDD is mandatory. All tests MUST be written and FAIL before implementation.

**Organization**: Tasks organized by implementation phase to enable systematic development.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1 for this feature)
- Include exact file paths in descriptions

## Path Conventions

- **Mobile (Flutter)**: `lib/` for source code, `test/` for tests at repository root
- File structure follows feature-based organization per plan.md

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create directory structure for project detail feature

- [ ] T001 [P] Create feature directory structure lib/features/project_detail/ with subdirectories: screens/, widgets/
- [ ] T002 [P] Create test directory structure test/features/project_detail/ with subdirectories: screens/, widgets/
- [ ] T003 [P] Create integration test directory test/integration/ if not exists

**Checkpoint**: Directory structure ready for implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data and service extensions that MUST be complete before user story implementation

**⚠️ CRITICAL**: User story work cannot begin until this phase is complete

- [ ] T004 Add i18n keys to lib/core/i18n/en.json for projectDetail section (title, loading, error, retry, projectData, products, liveStatus, subscription, lastUpdated)
- [ ] T005 [P] Add i18n keys to lib/core/i18n/de.json with German translations
- [ ] T006 [P] Add i18n keys to lib/core/i18n/pt.json with Portuguese translations
- [ ] T007 Extend ProjectService in lib/features/home/services/project_service.dart with fetchProjectDetail(String projectId) method
- [ ] T008 Add GraphQL query constant _getProjectDetailQuery to ProjectService matching contracts/project-detail-query.graphql

**Checkpoint**: Service layer and i18n ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Project Info (Priority: P1) 🎯 MVP

**Goal**: Display detailed project information when user taps "Enter project" from projects list

**Independent Test**: Navigate from projects list, tap project card, verify detail screen displays with all project information

### Tests for User Story 1 (TDD - Write FIRST, ensure FAIL) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Write widget test for ProjectHeader in test/features/project_detail/widgets/project_header_test.dart (test image display, name, status badge)
- [ ] T010 [P] [US1] Write widget test for ProjectInfoSection in test/features/project_detail/widgets/project_info_section_test.dart (test description, subscription, dates)
- [ ] T011 [P] [US1] Write widget test for ProjectActionButtons in test/features/project_detail/widgets/project_action_buttons_test.dart (test button rendering and tap handlers)
- [ ] T012 [US1] Write widget test for ProjectDetailScreen in test/features/project_detail/screens/project_detail_screen_test.dart (test loading, success, error states with FutureBuilder)
- [ ] T013 [US1] Write integration test in test/integration/project_detail_navigation_test.dart (test full navigation flow from home to detail)

**Run tests: All should FAIL (Red phase)**

### Implementation for User Story 1

- [ ] T014 [P] [US1] Create ProjectHeader widget in lib/features/project_detail/widgets/project_header.dart (display cached image, project name, status badge)
- [ ] T015 [P] [US1] Create ProjectInfoSection widget in lib/features/project_detail/widgets/project_info_section.dart (display description, subscription info, live date, last updated)
- [ ] T016 [P] [US1] Create ProjectActionButtons widget in lib/features/project_detail/widgets/project_action_buttons.dart (navigation buttons for "Project Data" and "Products")
- [ ] T017 [US1] Create ProjectDetailScreen in lib/features/project_detail/screens/project_detail_screen.dart (StatefulWidget with FutureBuilder, compose all widgets)
- [ ] T018 [US1] Implement loading state with CircularProgressIndicator in ProjectDetailScreen
- [ ] T019 [US1] Implement error state with error message and retry button in ProjectDetailScreen
- [ ] T020 [US1] Implement success state with project data display in ProjectDetailScreen
- [ ] T021 [US1] Add pull-to-refresh functionality with RefreshIndicator in ProjectDetailScreen
- [ ] T022 [US1] Update main.dart routes to use ProjectDetailScreen instead of PlaceholderScreen for AppRoutes.projectDetail
- [ ] T023 [US1] Add semantic labels to all widgets for screen reader accessibility

**Run tests: All should PASS (Green phase)**

**Checkpoint**: User Story 1 complete - project detail screen fully functional and tested

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements affecting the entire feature

- [ ] T024 [P] Run flutter analyze and fix all linting issues
- [ ] T025 [P] Run dart format . to ensure code formatting consistency
- [ ] T026 [P] Verify all touch targets are minimum 44x44 logical pixels
- [ ] T027 [P] Verify image loading with progressive placeholders using cached_network_image
- [ ] T028 [P] Verify contrast ratios meet WCAG AA standards for all text
- [ ] T029 Verify design match with Requirements/ProjectDetail.jpg
- [ ] T030 Test on physical device with real API data (verify < 1 second load time)
- [ ] T031 [P] Verify all i18n strings display correctly in English, German, and Portuguese

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion (T001-T003) - BLOCKS user story
- **User Story 1 (Phase 3)**: Depends on Foundational (T004-T008) - Independent after foundation complete
- **Polish (Phase 4)**: Depends on User Story 1 (T009-T023) being complete

### Within Each Phase

- **Setup Phase**: All tasks (T001-T003) can run in parallel
- **Foundational Phase**: i18n tasks (T004-T006) can run in parallel, T007-T008 sequential
- **US1 Tests**: All test files (T009-T013) can be written in parallel
- **US1 Widgets**: All widgets (T014-T016) can be implemented in parallel
- **US1 Screen**: T017-T021 must be sequential (screen depends on widgets)
- **Polish Phase**: Most tasks (T024-T028, T031) can run in parallel

### Parallel Opportunities

- **Setup**: All 3 tasks in parallel
- **i18n**: T004-T006 in parallel (3 language files)
- **US1 Tests**: T009-T013 in parallel (5 test files)
- **US1 Widgets**: T014-T016 in parallel (3 widget files)
- **Polish**: T024-T028, T031 in parallel (7 tasks)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T008) - CRITICAL checkpoint
3. Write all US1 tests (T009-T013) - should FAIL
4. Implement all US1 components (T014-T023) - tests should PASS
5. **STOP and VALIDATE**: Navigate from home screen, verify detail screen works
6. Polish (T024-T031) → Final QA → Deploy

### Parallel Team Strategy

With multiple developers:

1. **Team completes Setup + Foundational together** (T001-T008)
2. **US1 Split**:
   - Developer A: Write all tests (T009-T013)
   - Developer B: Implement widgets (T014-T016)
   - Developer C: Implement screen (T017-T021) after widgets ready
   - Developer A: Update routes and add accessibility (T022-T023)
3. **Polish together** (T024-T031)

---

## Notes

- **TDD is mandatory**: All tests MUST be written before implementation per constitution
- **[P] tasks** = different files, no dependencies - can execute in parallel
- **[US1] label** maps task to user story for traceability
- **Red-Green-Refactor**: Write failing test → Implement minimal code → Refactor
- Commit after each task or logical group (e.g., all US1 tests, all US1 widgets)
- Stop at checkpoints to validate independently before proceeding
- All file paths are absolute from repository root
- Design file (Requirements/ProjectDetail.jpg) is source of truth for visual implementation
- Navigation is already wired from home screen (002-home-screen-projects)
- GraphQL query contract defined in contracts/project-detail-query.graphql
- Reuses existing Project and ProjectSubscription models - no new models needed
