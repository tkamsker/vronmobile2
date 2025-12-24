# Tasks: Product Search and Filtering

**Input**: Design documents from `/specs/005-product-search/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are included following TDD approach as required by the constitution (Test-First Development is NON-NEGOTIABLE).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Flutter mobile app structure:
- Models: `lib/features/products/models/`
- Services: `lib/features/products/services/`
- Screens: `lib/features/products/screens/`
- Widgets: `lib/features/products/widgets/`
- Tests: `test/features/products/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Verify Flutter SDK and dependencies (Dart 3.10+, Flutter 3.x, graphql_flutter ^5.1.0)
- [ ] T002 [P] Create ProductFilter model file at lib/features/products/models/product_filter.dart
- [ ] T003 [P] Create ProductSearchResult model file at lib/features/products/models/product_search_result.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 [P] Write unit tests for ProductFilter model in test/features/products/models/product_filter_test.dart
- [ ] T005 [P] Write unit tests for ProductSearchResult model in test/features/products/models/product_search_result_test.dart
- [ ] T006 Implement ProductFilter model with isActive, activeFilterCount, clear(), copyWith() methods
- [ ] T007 Implement ProductSearchResult model with factory constructors (initial, loading, error, success)
- [ ] T008 Run unit tests for ProductFilter and ProductSearchResult - verify they pass

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Quick Product Search by Title (Priority: P1) 🎯 MVP

**Goal**: Users can search products by typing part of the product name with real-time results

**Independent Test**: Type "Steam Punk" in search field and verify only products with "Steam Punk" in title appear in real-time. Clear search field and verify all products reappear.

### Tests for User Story 1 (TDD Required)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Write widget test for search TextField in test/features/products/screens/products_list_screen_search_test.dart - verify search field exists with hint text
- [ ] T010 [P] [US1] Write widget test for search query input in test/features/products/screens/products_list_screen_search_test.dart - verify typing updates state
- [ ] T011 [P] [US1] Write widget test for debouncing in test/features/products/screens/products_list_screen_search_test.dart - verify 400ms delay before search execution
- [ ] T012 [P] [US1] Write widget test for loading state in test/features/products/screens/products_list_screen_search_test.dart - verify CircularProgressIndicator shown during search
- [ ] T013 [P] [US1] Write widget test for empty results in test/features/products/screens/products_list_screen_search_test.dart - verify empty state message when no matches
- [ ] T014 [P] [US1] Write widget test for clear search in test/features/products/screens/products_list_screen_search_test.dart - verify clear button clears search query

### Implementation for User Story 1

- [ ] T015 [US1] Add ProductFilter and ProductSearchResult state variables to _ProductsListScreenState in lib/features/products/screens/products_list_screen.dart
- [ ] T016 [US1] Add Timer state variable for debouncing to _ProductsListScreenState in lib/features/products/screens/products_list_screen.dart
- [ ] T017 [US1] Update dispose() method to cancel debounce timer in lib/features/products/screens/products_list_screen.dart
- [ ] T018 [US1] Replace TODO search TextField (line 282) with working implementation including clear button in lib/features/products/screens/products_list_screen.dart
- [ ] T019 [US1] Implement _onSearchChanged method with 400ms debouncing in lib/features/products/screens/products_list_screen.dart
- [ ] T020 [US1] Implement _clearSearch method in lib/features/products/screens/products_list_screen.dart
- [ ] T021 [US1] Implement _executeSearch method calling ProductService.fetchProducts with search parameter in lib/features/products/screens/products_list_screen.dart
- [ ] T022 [US1] Update product list display to use _searchResult.products instead of _products in lib/features/products/screens/products_list_screen.dart
- [ ] T023 [US1] Add loading state display (CircularProgressIndicator) in lib/features/products/screens/products_list_screen.dart
- [ ] T024 [US1] Add error state display with retry button in lib/features/products/screens/products_list_screen.dart
- [ ] T025 [US1] Implement _buildNoResultsState method with clear search action in lib/features/products/screens/products_list_screen.dart
- [ ] T026 [US1] Add Semantics labels for search TextField (label: "Search products by title") in lib/features/products/screens/products_list_screen.dart
- [ ] T027 [US1] Run all User Story 1 widget tests - verify they pass
- [ ] T028 [US1] Manual test: Type "Steam Punk" and verify real-time filtering works with debouncing

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Filter by Product Status (Priority: P2)

**Goal**: Users can filter products by Draft or Active status to focus their work

**Independent Test**: Select "Draft" from status filter and verify only draft products appear. Select "All" and verify products of all statuses shown. Combine with search text and verify both filters apply.

### Tests for User Story 2 (TDD Required)

- [ ] T029 [P] [US2] Write widget test for status filter chips in test/features/products/screens/products_list_screen_filter_test.dart - verify All, Draft, Active chips exist
- [ ] T030 [P] [US2] Write widget test for status selection in test/features/products/screens/products_list_screen_filter_test.dart - verify selecting Draft shows only draft products
- [ ] T031 [P] [US2] Write widget test for combined filters in test/features/products/screens/products_list_screen_filter_test.dart - verify search + status filter work together

### Implementation for User Story 2

- [ ] T032 [P] [US2] Add status filter UI (Row of ChoiceChip widgets for All/Draft/Active) above product list in lib/features/products/screens/products_list_screen.dart
- [ ] T033 [US2] Implement _updateFilter method for status changes in lib/features/products/screens/products_list_screen.dart
- [ ] T034 [US2] Update _executeSearch to pass status parameter to ProductService.fetchProducts in lib/features/products/screens/products_list_screen.dart
- [ ] T035 [US2] Add visual indication of selected status chip in lib/features/products/screens/products_list_screen.dart
- [ ] T036 [US2] Add Semantics labels for status filter chips (label: "Filter by status") in lib/features/products/screens/products_list_screen.dart
- [ ] T037 [US2] Update _buildNoResultsState to show active status filter in message in lib/features/products/screens/products_list_screen.dart
- [ ] T038 [US2] Run all User Story 2 widget tests - verify they pass
- [ ] T039 [US2] Manual test: Select "Draft" filter and verify only draft products shown

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Filter by Category (Priority: P3)

**Goal**: Users can filter products by category to organize their catalog

**Independent Test**: Select a category from category dropdown and verify only products in that category appear. Combine with search and status filters and verify all criteria apply.

### Tests for User Story 3 (TDD Required)

- [ ] T040 [P] [US3] Write widget test for category dropdown in test/features/products/screens/products_list_screen_filter_test.dart - verify dropdown exists with category options
- [ ] T041 [P] [US3] Write widget test for category selection in test/features/products/screens/products_list_screen_filter_test.dart - verify selecting category filters products
- [ ] T042 [P] [US3] Write widget test for combined filters in test/features/products/screens/products_list_screen_filter_test.dart - verify search + status + category work together

### Implementation for User Story 3

- [ ] T043 [US3] Extract unique categories from product list in _ProductsListScreenState in lib/features/products/screens/products_list_screen.dart
- [ ] T044 [P] [US3] Add DropdownButton for category selection in lib/features/products/screens/products_list_screen.dart
- [ ] T045 [US3] Wire category dropdown onChange to _updateFilter method in lib/features/products/screens/products_list_screen.dart
- [ ] T046 [US3] Update _executeSearch to pass categoryIds parameter to ProductService.fetchProducts in lib/features/products/screens/products_list_screen.dart
- [ ] T047 [US3] Add Semantics labels for category dropdown (label: "Filter by category") in lib/features/products/screens/products_list_screen.dart
- [ ] T048 [US3] Update _buildNoResultsState to show active category filter in message in lib/features/products/screens/products_list_screen.dart
- [ ] T049 [US3] Run all User Story 3 widget tests - verify they pass
- [ ] T050 [US3] Manual test: Select category and verify filtering works with other filters

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Filter by Tags (Priority: P3)

**Goal**: Users can filter products by tags for custom organization

**Independent Test**: Enter or select a tag and verify only products with that tag appear. Combine with other filters and verify all criteria apply.

**⚠️ NOTE**: This story is DEFERRED per research.md - Product model doesn't expose tags in VRonGetProducts response. Requires backend changes. Placeholder tasks included for future implementation.

### Tests for User Story 4 (TDD Required - DEFERRED)

- [ ] T051 [P] [US4] Write widget test for tag filter input in test/features/products/screens/products_list_screen_filter_test.dart - verify tag input exists (DEFERRED)
- [ ] T052 [P] [US4] Write widget test for tag selection in test/features/products/screens/products_list_screen_filter_test.dart - verify selecting tag filters products (DEFERRED)

### Implementation for User Story 4 (DEFERRED)

- [ ] T053 [US4] Add tags to Product model and VRonGetProducts query response (requires backend change - DEFERRED)
- [ ] T054 [US4] Add tag filter UI (TextField or Chip selector) in lib/features/products/screens/products_list_screen.dart (DEFERRED)
- [ ] T055 [US4] Update _executeSearch to pass tags parameter to ProductService.fetchProducts in lib/features/products/screens/products_list_screen.dart (DEFERRED)

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T056 [P] Add "Clear all filters" button with Badge showing active filter count in lib/features/products/screens/products_list_screen.dart
- [ ] T057 [P] Add result count display ("Showing X of Y products") in lib/features/products/screens/products_list_screen.dart
- [ ] T058 [P] Implement proper error handling for network failures with user-friendly messages in lib/features/products/screens/products_list_screen.dart
- [ ] T059 [P] Add screen reader announcements for result count changes in lib/features/products/screens/products_list_screen.dart
- [ ] T060 [P] Verify minimum 44x44 touch targets for all filter controls in lib/features/products/screens/products_list_screen.dart
- [ ] T061 [P] Verify clear focus indicators for keyboard navigation in lib/features/products/screens/products_list_screen.dart
- [ ] T062 [P] Add integration test for complete search flow in test/features/products/integration/product_search_integration_test.dart
- [ ] T063 [P] Performance test with 1000+ products - verify no lag or frame drops
- [ ] T064 [P] Test with poor network connectivity - verify error handling and cached results
- [ ] T065 Code review and refactoring for code quality
- [ ] T066 Update CLAUDE.md with search feature patterns using .specify/scripts/bash/update-agent-context.sh claude
- [ ] T067 Run quickstart.md validation - verify all integration scenarios work

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User Story 1 (P1): Can start after Foundational - No dependencies on other stories
  - User Story 2 (P2): Can start after Foundational - Integrates with US1 but independently testable
  - User Story 3 (P3): Can start after Foundational - Integrates with US1/US2 but independently testable
  - User Story 4 (P3): DEFERRED - Requires backend changes
- **Polish (Phase 7)**: Depends on User Stories 1-3 being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 search but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Integrates with US1/US2 but should be independently testable
- **User Story 4 (P3)**: DEFERRED - Cannot start until backend adds tags support

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD approach)
- Models before services
- Services before UI updates
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- Phase 1: T002 and T003 can run in parallel (different model files)
- Phase 2: T004 and T005 can run in parallel (different test files)
- Within User Story 1:
  - Tests T009-T014 can all run in parallel (different test scenarios in same file)
  - T023, T024, T025, T026 can run in parallel after T022 (different UI sections)
- Within User Story 2:
  - Tests T029-T031 can run in parallel
- Within User Story 3:
  - Tests T040-T042 can run in parallel
  - T044 can run in parallel with T043
- Phase 7: Most tasks marked [P] can run in parallel (different concerns)

**Key Insight**: Once Foundational phase completes, User Stories 1, 2, and 3 can be worked on in parallel by different developers since they modify different parts of the same file but focus on different features.

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (TDD - write first):
Task T009: "Write widget test for search TextField - verify search field exists"
Task T010: "Write widget test for search query input - verify typing updates state"
Task T011: "Write widget test for debouncing - verify 400ms delay"
Task T012: "Write widget test for loading state - verify CircularProgressIndicator"
Task T013: "Write widget test for empty results - verify empty state message"
Task T014: "Write widget test for clear search - verify clear button works"

# After tests written and failing, implement in sequence (dependencies exist):
# T015 → T016 → T017 (state setup)
# T018 → T019 → T020 (search UI)
# T021 → T022 (search logic and display)
# T023, T024, T025, T026 can run in parallel (different UI sections)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T008) - CRITICAL - blocks all stories
3. Complete Phase 3: User Story 1 (T009-T028)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Type "Steam Punk" and verify real-time filtering
   - Clear search and verify all products reappear
   - Test with no results and verify empty state
5. Deploy/demo if ready

**MVP Scope**: Tasks T001-T028 (28 tasks total)

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready (T001-T008)
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!) (T009-T028)
3. Add User Story 2 → Test independently → Deploy/Demo (T029-T039)
4. Add User Story 3 → Test independently → Deploy/Demo (T040-T050)
5. Polish and accessibility → Final release (T056-T067)
6. User Story 4 deferred until backend support available

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T008)
2. Once Foundational is done:
   - **Developer A**: User Story 1 - Quick Search (T009-T028)
   - **Developer B**: User Story 2 - Status Filter (T029-T039)
   - **Developer C**: User Story 3 - Category Filter (T040-T050)
3. Stories complete and integrate independently (same file, different features)
4. Team together: Polish phase (T056-T067)

**Note**: Since all user stories modify the same file (products_list_screen.dart), careful coordination needed. Recommend sequential implementation (P1 → P2 → P3) for solo developer, or use feature flags/branches for parallel development.

---

## Task Summary

**Total Tasks**: 67 tasks
- Phase 1 (Setup): 3 tasks
- Phase 2 (Foundational): 5 tasks
- Phase 3 (User Story 1 - P1): 20 tasks (6 tests + 14 implementation)
- Phase 4 (User Story 2 - P2): 11 tasks (3 tests + 8 implementation)
- Phase 5 (User Story 3 - P3): 11 tasks (3 tests + 8 implementation)
- Phase 6 (User Story 4 - P3): 5 tasks (DEFERRED - backend dependency)
- Phase 7 (Polish): 12 tasks

**MVP Scope**: 28 tasks (Phases 1-3 only)

**Parallel Opportunities**: 35 tasks marked [P] can run in parallel with other tasks

**Independent Test Criteria**:
- US1: Type "Steam Punk" → see real-time filtered results → clear → see all products
- US2: Select "Draft" → see only draft products → combine with search → see filtered results
- US3: Select category → see only category products → combine with other filters → see results
- US4: DEFERRED pending backend support

**Key Files Modified**:
- `lib/features/products/models/product_filter.dart` (new)
- `lib/features/products/models/product_search_result.dart` (new)
- `lib/features/products/screens/products_list_screen.dart` (modified - main file)
- `test/features/products/models/product_filter_test.dart` (new)
- `test/features/products/models/product_search_result_test.dart` (new)
- `test/features/products/screens/products_list_screen_search_test.dart` (new)
- `test/features/products/screens/products_list_screen_filter_test.dart` (new)

---

## Notes

- [P] tasks = different files or different sections, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- TDD approach required by constitution: Write tests FIRST, verify they FAIL, then implement
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- User Story 4 (tags) is deferred - requires backend changes per research.md
- Main implementation file (products_list_screen.dart) modified by all user stories - coordinate carefully
- Search TextField already exists at line 282 with TODO - wire it up in US1
- ProductService.fetchProducts() already supports all needed filter parameters - no service changes needed
