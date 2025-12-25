# Implementation Plan: Search Projects (009)

**Feature Branch**: `009-search-projects` (implemented on `feat/02prosearch`)
**Status**: Implementation Complete - Testing Phase
**Created**: 2025-12-21

## Executive Summary

Feature 009 (Search Projects) has been **manually implemented** in the codebase. This plan focuses on:
1. **Testing the existing implementation** according to TDD principles
2. **Validating compliance** with the feature spec and constitution
3. **Merging to main** after all tests pass
4. **Archiving** the `feat/02prosearch` branch

## Constitution Check

### I. Test-First Development (NON-NEGOTIABLE)

**Status**: ⚠️ VIOLATION - Implementation before tests

**Justification**: The feature was manually implemented before comprehensive tests were written. This violates the TDD principle but is being rectified in this plan by:
1. Writing comprehensive tests now (retroactive TDD)
2. Ensuring all acceptance criteria from spec.md are covered
3. Adding tests for edge cases
4. Establishing test coverage baseline for future features

**Remediation Plan**:
- Create dedicated test file for search functionality
- Cover all functional requirements (FR-001 to FR-004)
- Test all edge cases specified in spec.md
- Verify success criteria (SC-001, SC-002)

### II. Simplicity & YAGNI

**Status**: ✅ COMPLIANT

The implementation:
- Uses Flutter's built-in TextField widget
- Implements client-side filtering (simple approach)
- No premature abstractions
- Direct integration with existing ProjectService

### III. Platform-Native Patterns

**Status**: ✅ COMPLIANT

The implementation:
- Uses Material Design widgets (TextField, SearchBar pattern)
- Follows Flutter state management with StatefulWidget
- Uses TextEditingController for search input
- Implements debouncing via listener pattern

## Technical Context

### Implementation Location
- **Main UI**: `lib/features/home/screens/home_screen.dart` (lines 24-110)
- **Service Layer**: `lib/features/home/services/project_service.dart` (lines 126-133)
- **Tests**: Existing basic tests in `test/features/home/screens/home_screen_test.dart` and `test/integration/home_screen_integration_test.dart`

### Key Implementation Details

1. **Search Controller**: TextEditingController at line 24
2. **Search State**: `_searchQuery` string state variable (line 30)
3. **Search Logic**: `_onSearchChanged()` method (lines 77-83)
4. **Filter Application**: `_applyFilters()` method (lines 85-110)
5. **Search UI**: `_buildSearchBar()` method (lines 229-263)

### Current Behavior
- ✅ Search bar renders in projects list
- ✅ Text input triggers filtering
- ✅ Case-insensitive search
- ✅ Clear button appears when text entered
- ✅ No results message displayed
- ⚠️ **No explicit debouncing** (spec requires 300ms - FR-003)
- ✅ Integrated with status filters (All/Active/Archived)

## Gaps Analysis

### Missing from Spec Requirements

**FR-003**: System MUST debounce search input (300ms)
- **Current Implementation**: Uses TextEditingController listener without debouncing
- **Impact**: May cause performance issues with large project lists
- **Resolution**: Add debouncing implementation

**Backend Integration**: Spec mentions "Backend projects query with search parameter"
- **Current Implementation**: Client-side filtering only
- **Status**: Acceptable for MVP - backend search can be added later if needed

### Test Coverage Gaps

Current tests exist but lack:
1. Dedicated search functionality tests
2. Debouncing behavior tests (once implemented)
3. Edge case testing (special characters, long queries)
4. Performance testing (100+ projects - SC-002)
5. No results state testing

## Phase 0: Research & Discovery

### Research Completed ✅

**Search Implementation Pattern**: ✅
- Decision: Client-side filtering using Dart's List.where()
- Rationale: Simpler for MVP, no backend changes required
- Alternative: Backend GraphQL search parameter (future enhancement)

**Debouncing Strategy**: 📝 NEEDS IMPLEMENTATION
- Decision: Use dart:async Timer for debouncing
- Rationale: Built-in Dart capability, no additional dependencies
- Pattern: Cancel previous timer on each keystroke, execute after 300ms delay

**Testing Strategy**: ✅
- Decision: Mix of unit tests (service) and widget tests (UI)
- Rationale: Follows constitution testing principles
- Coverage: Unit tests for searchProjects(), widget tests for search UI

## Phase 1: Design & Implementation

### Data Model

No new data models required. Uses existing:
- **Project** model (`lib/features/home/models/project.dart`)

### API Contract

No GraphQL changes required for MVP. Current implementation uses:
```graphql
query GetProjects($lang: Language!) {
  getProjects(input: {}) {
    id
    name { text(lang: $lang) }
    # ... other fields
  }
}
```

Future enhancement could add search parameter:
```graphql
query GetProjects($lang: Language!, $search: String) {
  getProjects(input: { search: $search }) {
    # ...
  }
}
```

## Phase 2: Testing Plan

### Test Coverage Required

#### 1. Widget Tests (Feature-Specific)

File: `test/features/home/search_functionality_test.dart` (NEW)

Tests:
- ✅ Search bar renders with correct placeholder
- ✅ Search input triggers project filtering
- ✅ Case-insensitive search matching
- ✅ Clear button appears/disappears correctly
- ✅ No results message displays when no matches
- ✅ Search preserves filter state (Active/Archived)
- 📝 Debouncing delays search execution (300ms)
- ✅ Special characters handled correctly
- ✅ Long search queries handled

#### 2. Unit Tests (Service Layer)

File: `test/unit/services/project_service_search_test.dart` (NEW)

Tests:
- ✅ searchProjects() returns filtered results
- ✅ searchProjects() handles empty query
- ✅ searchProjects() handles no matches
- ✅ searchProjects() is case-insensitive
- ✅ searchProjects() with special characters
- ✅ searchProjects() performance with 100+ projects

#### 3. Integration Tests (Enhancement)

File: `test/integration/home_screen_integration_test.dart` (EXISTS)

Current coverage at lines 81-105:
- ✅ Search filters projects correctly

Additional tests needed:
- 📝 Search + status filter combination
- 📝 Search + pull-to-refresh interaction
- 📝 Search persistence across navigation (if required)

### Success Criteria Validation

**SC-001**: Search results appear within 500ms of typing
- Test: Measure time from input to UI update
- Method: Widget test with stopwatch or frame counting
- Note: Debouncing may extend to 300ms + rendering time

**SC-002**: Search handles 100+ projects smoothly
- Test: Unit test with mock 100+ projects
- Method: Verify filtering completes within performance budget
- Benchmark: < 100ms for filtering operation

## Phase 3: Implementation Tasks

### Task 1: Add Debouncing (REQUIRED)
- Update `_onSearchChanged()` to use Timer
- Set 300ms delay per FR-003
- Cancel previous timer on new input
- Test debouncing behavior

### Task 2: Create Search-Specific Widget Tests
- Create `test/features/home/search_functionality_test.dart`
- Implement all widget tests from Phase 2
- Achieve >90% coverage for search logic

### Task 3: Create Service-Level Unit Tests
- Create `test/unit/services/project_service_search_test.dart`
- Test `searchProjects()` method comprehensively
- Include edge cases and performance tests

### Task 4: Update Integration Tests
- Add search + filter combination tests
- Test search interaction with other features

### Task 5: Run Full Test Suite
- Execute `flutter test`
- Verify all tests pass
- Check test coverage report

### Task 6: Merge to Main
- Create PR from `feat/02prosearch` to `main`
- Include test results and coverage report
- Request code review
- Merge after approval

### Task 7: Archive Feature Branch
- Keep `feat/02prosearch` for reference
- Tag commit before archiving
- Update documentation

## Implementation Notes

### Files to Create
1. `test/features/home/search_functionality_test.dart` (widget tests)
2. `test/unit/services/project_service_search_test.dart` (unit tests)

### Files to Modify
1. `lib/features/home/screens/home_screen.dart` (add debouncing)
2. `test/integration/home_screen_integration_test.dart` (enhance tests)

### Dependencies
No new dependencies required. Uses:
- `flutter_test` (existing)
- `dart:async` (built-in for Timer)

## Risks & Mitigation

### Risk: Debouncing Breaks Existing Tests
- **Mitigation**: Update all tests to await debounce delay
- **Resolution**: Use `await tester.pump(Duration(milliseconds: 350))`

### Risk: Performance Issues with Large Lists
- **Mitigation**: Benchmark with 100+ mock projects
- **Fallback**: Implement backend search if client-side filtering is too slow

### Risk: i18n Issues with Search
- **Mitigation**: Test search with multi-language project names
- **Note**: Current implementation searches translated text (correct behavior)

## Success Metrics

- ✅ All FR-001 to FR-004 requirements met
- ✅ All edge cases tested
- ✅ SC-001 and SC-002 success criteria validated
- ✅ Test coverage > 90% for search functionality
- ✅ All tests pass
- ✅ Feature merged to main
- ✅ No regressions in existing features

## Next Steps

1. Implement debouncing (Task 1)
2. Create comprehensive tests (Tasks 2-4)
3. Run test suite and verify (Task 5)
4. Merge to main (Task 6)
5. Archive branch (Task 7)

---

**Plan Version**: 1.0
**Author**: Claude Code
**Last Updated**: 2025-12-21
