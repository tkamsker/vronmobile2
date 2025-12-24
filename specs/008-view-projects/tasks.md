# Tasks: Complete Project Management Features

**Input**: Design documents from `/specs/008-view-projects/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Test tasks are included following TDD/Test-First Development (constitution requirement)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app with feature-based architecture:
- **Feature code**: `lib/features/home/`, `lib/features/projects/`, `lib/features/products/`
- **Core utilities**: `lib/core/utils/`, `lib/core/constants/`, `lib/core/navigation/`
- **Tests**: `test/core/utils/`, `test/features/home/`, `test/features/projects/`, `test/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create utilities and enums needed by multiple user stories

**Estimated Time**: 15 minutes

- [X] T001 [P] Create SlugGenerator utility class in lib/core/utils/slug_generator.dart with slugify() and isValidSlug() methods
- [X] T002 [P] Create ProjectSortOption enum in lib/features/home/models/project_sort_option.dart with 5 sort options (nameAscending, nameDescending, dateNewest, dateOldest, status)
- [X] T003 [P] Add create project UI strings to lib/core/constants/app_strings.dart (form labels, placeholders, error messages)

**Checkpoint**: Utilities and enums ready for use in user stories

---

## Phase 2: Foundational (Core Service Layer)

**Purpose**: Add service layer methods that user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 [P] Add createProject() method to ProjectService in lib/features/home/services/project_service.dart with GraphQL mutation
- [X] T005 [P] Add _sortProjects() helper method to ProjectService in lib/features/home/services/project_service.dart with switch statement for all sort options
- [X] T006 [P] Add _compareByStatus() helper method to ProjectService in lib/features/home/services/project_service.dart for status priority sorting
- [X] T007 Modify fetchProjects() method signature in lib/features/home/services/project_service.dart to accept optional sortBy parameter

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create New Project (Priority: P1) 🎯 MVP

**Goal**: Enable users to create new projects with name, auto-generated slug, and optional description

**Independent Test**: Tap FAB on home screen, fill form with "My Room", verify slug auto-generates as "my-room", save, verify new project appears in list

**Success Criteria**:
- Form renders < 300ms (NFR-001)
- Slug auto-generation responds < 100ms (NFR-002, SC-002)
- Project creation completes < 3 seconds (NFR-001, SC-001)
- Validation prevents invalid submissions (SC-003)

### Tests for User Story 1 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [X] T008 [P] [US1] Write unit tests for SlugGenerator.slugify() in test/core/utils/slug_generator_test.dart (valid transformations, edge cases)
- [X] T009 [P] [US1] Write unit tests for SlugGenerator.isValidSlug() in test/core/utils/slug_generator_test.dart (valid/invalid formats)
- [X] T010 [P] [US1] Write unit tests for ProjectService.createProject() in test/features/home/services/project_service_test.dart (success, duplicate slug, validation errors)
- [X] T011 [P] [US1] Write widget tests for CreateProjectScreen in test/features/projects/screens/create_project_screen_test.dart (form rendering, auto-generation, validation)
- [X] T012 [P] [US1] Write integration test for complete create flow in test/integration/create_project_flow_test.dart (tap FAB → fill form → save → verify in list)

**TDD Checkpoint**: ✅ All US1 tests written and FAILING - proceed to implementation

### Implementation for User Story 1

- [X] T013 [US1] Create CreateProjectScreen in lib/features/projects/screens/create_project_screen.dart with form structure (GlobalKey<FormState>, TextEditingControllers)
- [X] T014 [US1] Add name field with validation (3-100 chars) to CreateProjectScreen in lib/features/projects/screens/create_project_screen.dart
- [X] T015 [US1] Add slug field with validation (format check) and auto-generation listener to CreateProjectScreen in lib/features/projects/screens/create_project_screen.dart
- [X] T016 [US1] Add description field (optional) to CreateProjectScreen in lib/features/projects/screens/create_project_screen.dart
- [X] T017 [US1] Implement _handleSave() method with ProjectService.createProject() call in lib/features/projects/screens/create_project_screen.dart
- [X] T018 [US1] Add error handling for duplicate slug and validation errors in lib/features/projects/screens/create_project_screen.dart
- [X] T019 [US1] Add dirty state tracking and PopScope for unsaved changes warning in lib/features/projects/screens/create_project_screen.dart
- [X] T020 [US1] Add Semantics labels for accessibility in lib/features/projects/screens/create_project_screen.dart
- [X] T021 [US1] Wire /create-project route to CreateProjectScreen in lib/core/navigation/routes.dart or main.dart
- [X] T022 [US1] Update HomeScreen FAB onPressed in lib/features/home/screens/home_screen.dart to navigate to CreateProjectScreen and refresh on success
- [X] T023 [US1] Verify all US1 tests now PASS (Red → Green)

**Refactor Checkpoint** (TDD): Refactor if needed while keeping tests green

**Checkpoint**: User Story 1 (MVP) is fully functional - users can create projects and see them in the list

---

## Phase 4: User Story 2 - Sort Projects (Priority: P2)

**Goal**: Enable users to sort project list by name (A-Z/Z-A), date (newest/oldest), or status

**Independent Test**: Tap sort button on home screen, select "Name A-Z", verify list reorders alphabetically

**Success Criteria**:
- Sort menu displays < 300ms (SC-004)
- Sort operation completes < 500ms for typical lists (NFR-003, SC-005)
- Sort persists during session (FR-012)
- Sort applies to filtered views (FR-013, FR-014)

### Tests for User Story 2 (TDD - Write FIRST) ⚠️

> **CRITICAL (Constitution)**: Write these tests FIRST, ensure they FAIL before implementation

- [ ] T024 [P] [US2] Write unit tests for ProjectService._sortProjects() in test/features/home/services/project_service_test.dart (all 5 sort options)
- [ ] T025 [P] [US2] Write unit tests for ProjectService._compareByStatus() in test/features/home/services/project_service_test.dart (status priority order)
- [ ] T026 [P] [US2] Write widget tests for SortMenu in test/features/home/widgets/sort_menu_test.dart (renders options, selection callback)
- [ ] T027 [P] [US2] Write widget tests for HomeScreen sort integration in test/features/home/screens/home_screen_test.dart (sort menu visible, changes list order)

**TDD Checkpoint**: ✅ All US2 tests written and FAILING - proceed to implementation

### Implementation for User Story 2

- [ ] T028 [P] [US2] Create SortMenu widget in lib/features/home/widgets/sort_menu.dart with PopupMenuButton displaying all ProjectSortOption values
- [ ] T029 [US2] Add _currentSort state variable (default: dateNewest) to HomeScreen in lib/features/home/screens/home_screen.dart
- [ ] T030 [US2] Add SortMenu to HomeScreen AppBar actions in lib/features/home/screens/home_screen.dart
- [ ] T031 [US2] Wire SortMenu onSortChanged callback to update _currentSort state and refresh projects in lib/features/home/screens/home_screen.dart
- [ ] T032 [US2] Update _refreshProjects() call to pass sortBy: _currentSort to ProjectService.fetchProjects() in lib/features/home/screens/home_screen.dart
- [ ] T033 [US2] Add Semantics labels for sort menu accessibility in lib/features/home/widgets/sort_menu.dart
- [ ] T034 [US2] Verify all US2 tests now PASS

**Refactor Checkpoint** (TDD): Refactor sort logic if needed while keeping tests green

**Checkpoint**: User Story 2 complete - users can sort projects and sorting persists during session

---

## Phase 5: User Story 3 - Create Product from Project (Priority: P3)

**Goal**: Enable users to add products to a project from the project detail products tab

**Independent Test**: Open project detail, navigate to products tab, tap "Add Product" FAB, verify product creation screen opens with project context pre-filled

**Success Criteria**:
- Navigation preserves project context (SC-007)
- Product automatically linked to project (FR-017)
- New product appears in project's products tab after creation (FR-017)

### Tests for User Story 3 (TDD - Write FIRST) ⚠️

- [X] T035 [P] [US3] Write widget tests for ProductsTab navigation in test/features/projects/widgets/project_products_tab_test.dart (FAB tap, navigation with arguments)
- [X] T036 [P] [US3] Write integration test for product creation from project in test/integration/product_creation_flow_test.dart (navigate → create → verify in products tab)

**TDD Checkpoint**: ✅ All US3 tests written and FAILING - proceed to implementation

### Implementation for User Story 3

- [X] T037 [US3] Add _navigateToCreateProduct() method to ProjectProductsTab in lib/features/projects/widgets/project_products_tab.dart with navigation arguments (projectId, projectName)
- [X] T038 [US3] Wire existing FAB onPressed (line ~107-108) to _navigateToCreateProduct() in lib/features/projects/widgets/project_products_tab.dart
- [X] T039 [US3] Update ProductsTab to refresh product list when navigation result is true in lib/features/projects/widgets/project_products_tab.dart
- [ ] T040 [US3] Verify product creation screen receives and uses project context (if not already implemented in CreateProductScreen)
- [ ] T041 [US3] Verify all US3 tests now PASS

**Checkpoint**: User Story 3 complete - users can create products from project detail screen

---

## Phase 6: User Story 4 - Search Products in Project (Priority: P3)

**Goal**: Enable users to search products within a specific project's products tab

**Independent Test**: Open project with 10+ products, type "chair" in search field, verify only matching products display

**Success Criteria**:
- Search filters in real-time < 200ms per keystroke (NFR-004, SC-006)
- Search works on product name and description (FR-018)
- Clear button removes search filter (FR-020)
- Results count displays (FR-019)

### Tests for User Story 4 (TDD - Write FIRST) ⚠️

- [X] T042 [P] [US4] Write widget tests for ProductsTab search field in test/features/projects/widgets/project_products_tab_test.dart (renders field, filters on input, clear button)

**TDD Checkpoint**: ✅ All US4 tests written and FAILING - proceed to implementation

### Implementation for User Story 4

- [X] T043 [P] [US4] Add _searchQuery state variable and TextEditingController to ProjectProductsTab in lib/features/projects/widgets/project_products_tab.dart
- [X] T044 [P] [US4] Create search TextField with search icon, clear button, and controller in lib/features/projects/widgets/project_products_tab.dart
- [X] T045 [US4] Add _onSearchChanged() listener to filter products list based on query in lib/features/projects/widgets/project_products_tab.dart
- [X] T046 [US4] Replace direct widget.project.products with filteredProducts in ListView.builder in lib/features/projects/widgets/project_products_tab.dart
- [X] T047 [US4] Add search results count display in lib/features/projects/widgets/project_products_tab.dart
- [X] T048 [US4] Add Semantics labels for search field accessibility in lib/features/projects/widgets/project_products_tab.dart
- [ ] T049 [US4] Verify all US4 tests now PASS

**Checkpoint**: User Story 4 complete - users can search products within projects

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quality assurance, performance validation, and production readiness

- [X] T050 [P] Verify all Semantics labels are present for accessibility (CreateProjectScreen, SortMenu, search field)
- [X] T051 [P] Verify touch target sizes are >= 44x44 logical pixels (FAB, buttons, sort menu items)
- [X] T052 [P] Run flutter analyze and fix any warnings or errors
- [X] T053 [P] Run flutter format on all modified files
- [ ] T054 Test slug auto-generation performance (<100ms) with DevTools profiler
- [ ] T055 Test sort operation performance (<500ms for 1000 projects) with DevTools profiler
- [ ] T056 Test product search performance (<200ms per keystroke) with DevTools profiler
- [ ] T057 Test complete create project workflow on iOS simulator (navigate → create → save → verify in list)
- [ ] T058 Test complete create project workflow on Android emulator (navigate → create → save → verify in list)
- [ ] T059 Test all sort options on both platforms (iOS + Android)
- [ ] T060 Test product search on both platforms (iOS + Android)
- [ ] T061 [P] Code review and refactoring (constitution compliance check)
- [ ] T062 [P] Update CLAUDE.md if new patterns introduced (already done in Phase 1, verify completeness)

**Final Checkpoint**: Feature code-complete and ready for production deployment

---

## Dependencies & Execution Strategy

### Phase Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational)
                        ↓
     ┌──────────────────┼──────────────────┬──────────────────┬──────────────────┐
     ↓                  ↓                  ↓                  ↓
  Phase 3 (US1)    Phase 4 (US2)    Phase 5 (US3)    Phase 6 (US4)
   [MVP - P1]        [P2]              [P3]              [P3]
     ↓                  ↓                  ↓                  ↓
     └──────────────────┼──────────────────┴──────────────────┘
                        ↓
                  Phase 7 (Polish)
```

**Dependency Analysis**:
- **Phase 1 & 2**: MUST complete first (setup + foundation)
- **US1 (P1)**: Independent - can start after Phase 2 (MVP)
- **US2 (P2)**: Independent - can start after Phase 2 (runs in parallel with US1 if staffed)
- **US3 (P3)**: Independent - can start after Phase 2 (modifies existing ProductsTab)
- **US4 (P3)**: Independent - can start after Phase 2 (modifies existing ProductsTab, different section than US3)
- **Phase 7**: Can start in parallel with later user stories (polish tasks are independent)

### User Story Dependencies

All user stories are **independent** and can be implemented in parallel after Phase 2 completes:

- **User Story 1 (P1)**: Creates new screen (CreateProjectScreen) + service method
- **User Story 2 (P2)**: Creates new widget (SortMenu) + service method
- **User Story 3 (P3)**: Modifies ProductsTab (navigation section)
- **User Story 4 (P3)**: Modifies ProductsTab (search section)

**Note**: US3 and US4 both modify ProductsTab but in different sections (navigation vs search), so they can run in parallel with careful merge coordination.

### Parallel Execution Opportunities

**Within Phase 1 (Setup)**:
- T001, T002, T003 can all run in parallel (different files)

**Within Phase 2 (Foundational)**:
- T004, T005, T006 can run in parallel (different methods, same file - merge carefully)
- T007 runs sequentially after T005/T006 (modifies same method)

**Within Phase 3 (US1)**:
- T008-T012 (tests) can all be written in parallel
- T013-T020 are mostly sequential (modifying same CreateProjectScreen file)
- T021-T022 can run in parallel (different files)

**Within Phase 4 (US2)**:
- T024-T027 (tests) can all be written in parallel
- T028 can run in parallel with T029-T032 (different files)
- T033 runs after T028 (same file)

**Within Phase 5 (US3)**:
- T035-T036 (tests) can be written in parallel
- T037-T039 are sequential (same file)
- T040 is verification only

**Within Phase 6 (US4)**:
- T043-T044 can run in parallel (different concerns in same file)
- T045-T048 are sequential (same file, dependent logic)

**Within Phase 7 (Polish)**:
- T050-T053, T061-T062 can all run in parallel
- T054-T060 are sequential (performance testing requires completed features)

### MVP Delivery Strategy

**Minimum Viable Product (MVP) = Phase 1 + Phase 2 + Phase 3 (US1 only)**

This delivers:
- ✅ Slug generator utility
- ✅ Create project service method
- ✅ Create project screen with form validation
- ✅ Auto-generated slug from name
- ✅ Unsaved changes protection
- ✅ New project appears in list
- ✅ Users can create projects end-to-end

**MVP Task Count**: T001-T023 (23 tasks)
**Estimated MVP Time**: 3-4 hours (including TDD cycle)

**Incremental Delivery**:
1. **Sprint 1 (MVP)**: Phases 1-3 → US1 functional, users can create projects
2. **Sprint 2**: Phase 4 → US2 adds sorting capability
3. **Sprint 3**: Phases 5-6 → US3 & US4 add product management features
4. **Sprint 4**: Phase 7 → Polish and production readiness

### Test-First Development (TDD) Workflow

**Constitution Requirement**: Tests MUST be written before implementation

**Red-Green-Refactor Cycle**:

1. **RED Phase**: Write failing tests
   - US1: Write T008-T012, verify they FAIL
   - US2: Write T024-T027, verify they FAIL
   - US3: Write T035-T036, verify they FAIL
   - US4: Write T042, verify it FAILS

2. **GREEN Phase**: Implement minimum code to pass tests
   - US1: Implement T013-T022, verify tests PASS
   - US2: Implement T028-T032, verify tests PASS
   - US3: Implement T037-T040, verify tests PASS
   - US4: Implement T043-T048, verify tests PASS

3. **REFACTOR Phase**: Improve code quality while keeping tests green
   - Extract helper methods
   - Simplify conditional logic
   - Improve naming and structure
   - Verify tests still PASS after each refactor

**Test Coverage Goals**:
- Unit tests: SlugGenerator methods, ProjectService methods (create, sort)
- Widget tests: CreateProjectScreen, SortMenu, ProductsTab modifications
- Integration tests: Complete user flows (create → save → list refresh)

---

## Parallel Example: User Story 1 (Create Project)

```bash
# Launch all tests for User Story 1 together:
Task: "Write unit tests for SlugGenerator.slugify() in test/core/utils/slug_generator_test.dart"
Task: "Write unit tests for SlugGenerator.isValidSlug() in test/core/utils/slug_generator_test.dart"
Task: "Write unit tests for ProjectService.createProject() in test/features/home/services/project_service_test.dart"
Task: "Write widget tests for CreateProjectScreen in test/features/projects/screens/create_project_screen_test.dart"
Task: "Write integration test for complete create flow in test/integration/create_project_flow_test.dart"

# After tests written, launch route wiring in parallel with screen development:
# (Sequential within CreateProjectScreen, but route wiring can be done separately)
Task: "Wire /create-project route to CreateProjectScreen in lib/core/navigation/routes.dart"
Task: "Update HomeScreen FAB onPressed in lib/features/home/screens/home_screen.dart"
```

---

## Parallel Example: User Story 2 (Sort Projects)

```bash
# Launch all tests for User Story 2 together:
Task: "Write unit tests for ProjectService._sortProjects() in test/features/home/services/project_service_test.dart"
Task: "Write unit tests for ProjectService._compareByStatus() in test/features/home/services/project_service_test.dart"
Task: "Write widget tests for SortMenu in test/features/home/widgets/sort_menu_test.dart"
Task: "Write widget tests for HomeScreen sort integration in test/features/home/screens/home_screen_test.dart"

# After tests written, create SortMenu widget in parallel with HomeScreen modifications:
Task: "Create SortMenu widget in lib/features/home/widgets/sort_menu.dart"
# (HomeScreen tasks T029-T032 are sequential within same file)
```

---

## Task Summary

**Total Tasks**: 62
**MVP Tasks** (US1 only): 23 (T001-T023)
**Test Tasks**: 17 (T008-T012, T024-T027, T035-T036, T042)
**Implementation Tasks**: 45 (excluding tests)

**Task Distribution by Phase**:
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 4 tasks
- Phase 3 (US1 - MVP): 16 tasks (5 tests + 11 implementation)
- Phase 4 (US2): 11 tasks (4 tests + 7 implementation)
- Phase 5 (US3): 7 tasks (2 tests + 5 implementation)
- Phase 6 (US4): 8 tasks (1 test + 7 implementation)
- Phase 7 (Polish): 13 tasks

**Parallel Opportunities**: 29 tasks marked [P] can run in parallel

**Independent Test Criteria**:
- ✅ US1: Tap FAB, fill form, save, verify new project in list
- ✅ US2: Tap sort button, select option, verify list reorders
- ✅ US3: Navigate to products tab, tap FAB, verify product creation screen opens with context
- ✅ US4: Type in search field, verify products filter in real-time

---

## Implementation Notes

### File Modification Summary

**New Files** (17):
- lib/core/utils/slug_generator.dart
- lib/features/home/models/project_sort_option.dart
- lib/features/projects/screens/create_project_screen.dart
- lib/features/home/widgets/sort_menu.dart
- test/core/utils/slug_generator_test.dart
- test/features/home/models/project_sort_option_test.dart (optional)
- test/features/home/services/project_service_test.dart (extend existing)
- test/features/projects/screens/create_project_screen_test.dart
- test/features/home/widgets/sort_menu_test.dart
- test/features/home/screens/home_screen_test.dart (extend existing)
- test/features/projects/widgets/project_products_tab_test.dart (extend existing)
- test/integration/create_project_flow_test.dart
- test/integration/product_creation_flow_test.dart

**Modified Files** (6):
- lib/core/constants/app_strings.dart (add strings)
- lib/features/home/services/project_service.dart (add methods)
- lib/features/home/screens/home_screen.dart (add sort menu)
- lib/core/navigation/routes.dart (wire create route)
- lib/features/projects/widgets/project_products_tab.dart (add navigation + search)
- CLAUDE.md (update patterns - already done)

### Performance Targets

| Feature | Target | Expected |
|---------|--------|----------|
| Slug generation | <100ms | <10ms ✅ |
| Sort 1000 projects | <500ms | 10-50ms ✅ |
| Product search filter | <200ms | <50ms ✅ |
| Form render | <300ms | <100ms ✅ |
| Create project (network) | <3s | ~1-2s ✅ |

### Accessibility Checklist

- [ ] CreateProjectScreen: Semantic labels on all form fields and buttons
- [ ] SortMenu: Semantic labels on menu items
- [ ] Search field: Semantic labels and hints
- [ ] All buttons: Touch targets >= 44x44 logical pixels
- [ ] Screen reader navigation: All interactive elements accessible

---

## Next Steps

1. **Start with MVP**: Execute T001-T023 to deliver functional project creation
2. **Follow TDD**: Write failing tests BEFORE implementation (constitution requirement)
3. **Test on Devices**: Verify on iOS and Android simulators/devices
4. **Incremental Delivery**: Ship US1 (MVP) → US2 (sort) → US3 & US4 (product features) → Polish

**Recommended First Task**: T001 (create slug generator utility)

**Estimated Total Time**: 6-8 hours (including TDD, testing, polish)
