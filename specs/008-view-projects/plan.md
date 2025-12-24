# Implementation Plan: Complete Project Management Features

**Branch**: `008-view-projects` | **Date**: 2025-12-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-view-projects/spec.md`

## Summary

Complete the remaining project management functionality by implementing:
1. **Create Project Screen** - Replace placeholder with full create flow including form validation and slug auto-generation
2. **Project Sorting** - Add sort logic to existing UI (Name A-Z/Z-A, Date Newest/Oldest, Status)
3. **Product Creation Integration** - Wire existing product creation to project context
4. **Product Search** - Add client-side search filtering within project products tab

This is a **completion feature** building on existing infrastructure (70% already implemented). The technical approach leverages established patterns from ProjectService, existing form components, and GraphQL mutations.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- flutter/material.dart (Material Design widgets)
- graphql_flutter (GraphQL client for API integration)
- shared_preferences (session-only sort preference storage)
- provider or setState (state management for form and list updates)

**Storage**:
- Backend: GraphQL API (PostgreSQL) for project persistence
- Local: shared_preferences for sort preference (session-only, no persistence across app restarts)
- No new local storage requirements

**Testing**:
- flutter_test (unit tests for services, models, utilities)
- Widget tests for UI components (create form, sort menu, search field)
- Integration tests for complete user flows (create → save → list refresh)

**Target Platform**: iOS 15+ and Android (cross-platform Flutter mobile app)

**Project Type**: Mobile application with feature-based architecture

**Performance Goals**:
- Create project form renders < 300ms
- Slug auto-generation responds < 100ms per keystroke
- Sort operation completes < 500ms for 1000 projects
- Product search filters < 200ms per keystroke
- Maintain 60 fps during all animations and list updates

**Constraints**:
- Must follow existing patterns from ProjectService and HomeScreen
- Must integrate with existing GraphQL schema (createProject mutation)
- Form validation must match backend constraints (3-100 char name, slug format)
- No new dependencies allowed (use existing packages only)
- Offline-capable: graceful degradation when backend unavailable

**Scale/Scope**:
- 4 user stories (1 MVP P1, 3 lower priority)
- 20 functional + 5 non-functional requirements
- ~8-12 implementation files (screens, widgets, utilities)
- ~10-15 test files (unit, widget, integration)
- No breaking changes to existing project functionality

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)

**Status**: ✅ PASS

- [X] TDD mandated in tasks (tests written before implementation)
- [X] Red-Green-Refactor cycle documented in task phases
- [X] Widget tests required for CreateProjectScreen, sort menu, search field
- [X] Integration tests required for create → save → refresh flow
- [X] Unit tests required for slug generation utility, sort logic

**Compliance Notes**:
- Task structure follows TDD: Test phase (T001-T010) precedes implementation phase (T011-T025)
- Test requirements specified in spec.md acceptance scenarios
- Existing test coverage pattern from home/projects features will be extended

### II. Simplicity & YAGNI

**Status**: ✅ PASS

- [X] Implements only explicitly required user stories (no speculative features)
- [X] Leverages existing ProjectService methods (no new abstractions)
- [X] Uses Flutter built-in TextEditingController and Form validation
- [X] Sort stored in memory only (no persistent database)
- [X] No framework code for hypothetical future requirements
- [X] Slug utility is single-purpose (only used in create flow)

**Compliance Notes**:
- Reuses ProjectCard, ProjectDetailScreen, existing navigation patterns
- No new state management complexity (uses existing setState/Provider patterns)
- Product search is client-side filtering (no backend query optimization premature)
- Rejected abstractions: custom form framework, complex sort persistence, search indexing

### III. Platform-Native Patterns

**Status**: ✅ PASS

- [X] Feature-based structure follows lib/features/projects/
- [X] Uses Material Design widgets (TextField, DropdownMenu, FloatingActionButton)
- [X] Async operations use Future/async-await patterns
- [X] State management explicit (setState for form, provider for project list)
- [X] Follows Dart effective style guide naming
- [X] Widget composition (not inheritance)

**Compliance Notes**:
- CreateProjectScreen follows HomeScreen and ProjectDetailScreen patterns
- Form validation follows ProjectDataTab pattern
- Navigation uses existing AppRoutes pattern
- Semantic labels for accessibility (WCAG AA compliance)

### Security & Privacy Requirements

**Status**: ✅ PASS

- [X] All API calls use GraphQL over HTTPS (existing infrastructure)
- [X] Input validation on form fields (name length, slug format, XSS prevention)
- [X] No sensitive data stored locally (sort preference is non-sensitive)
- [X] Authentication tokens managed by existing AuthService
- [X] No new permissions required

**Compliance Notes**:
- Leverages existing secure GraphQL client configuration
- Form input sanitized before mutation call
- No secrets or API keys in feature code

### Performance Standards

**Status**: ✅ PASS

- [X] Sort operation < 500ms for 1000 projects (in-memory sort)
- [X] Slug auto-generation < 100ms (synchronous string operation)
- [X] Product search < 200ms per keystroke (client-side filter)
- [X] Form render < 300ms (simple widget tree)
- [X] No memory leaks (controllers disposed in didDispose)
- [X] 60 fps maintained (no heavy computations in build methods)

**Compliance Notes**:
- Slug generation uses simple RegEx replace (O(n) where n = name length)
- Sort uses Dart List.sort with Comparable (O(n log n))
- Product search uses List.where filter (O(n))
- All operations profiled with Flutter DevTools in planning phase

### Accessibility Requirements

**Status**: ✅ PASS

- [X] Semantic labels on all form fields (name, slug, description)
- [X] Semantic labels on buttons (save, cancel, sort options)
- [X] Touch targets >= 44x44 (FAB, buttons, sort menu items)
- [X] Contrast ratios meet WCAG AA (uses Material theme colors)
- [X] Screen reader support (Semantics widgets throughout)
- [X] Error messages announced to screen readers

**Compliance Notes**:
- Follows accessibility pattern from existing screens (HomeScreen, MainScreen)
- Form validation errors display inline with semantic hints
- Sort menu uses Material DropdownMenu with built-in accessibility

### CI/CD & DevOps Practices

**Status**: ✅ PASS

- [X] Branch naming follows ###-feature-name pattern (008-view-projects)
- [X] Atomic commits planned per task (commit after each test/implementation pair)
- [X] All tests run in CI pipeline (flutter test command)
- [X] Code review required before merge to main
- [X] No breaking changes to existing functionality

**Compliance Notes**:
- Feature branch already created per convention
- Git workflow follows trunk-based development with feature branches
- PR to main will trigger CI: lint, format, test, build verification

### Violations Requiring Justification

**Status**: ✅ NONE

No constitution violations. All principles followed without compromise.

## Project Structure

### Documentation (this feature)

```text
specs/008-view-projects/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (implementation plan)
├── research.md          # Phase 0 output - technical decisions
├── data-model.md        # Phase 1 output - entity definitions
├── quickstart.md        # Phase 1 output - integration guide
├── contracts/           # Phase 1 output - GraphQL contracts
│   ├── create-project-mutation.graphql
│   └── slug-validation.md
├── checklists/          # Quality validation checklists
│   └── requirements.md  # Spec quality checklist (completed)
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_strings.dart         # NEW: Add create project strings
│   ├── navigation/
│   │   └── routes.dart               # MODIFIED: Wire createProject route
│   └── utils/
│       └── slug_generator.dart       # NEW: Slug auto-generation utility
├── features/
│   ├── home/
│   │   ├── models/
│   │   │   ├── project.dart          # EXISTING: Extend with createdAt field
│   │   │   └── project_sort_option.dart  # NEW: Sort enum
│   │   ├── services/
│   │   │   └── project_service.dart  # MODIFIED: Add createProject method, sort logic
│   │   ├── screens/
│   │   │   └── home_screen.dart      # MODIFIED: Add sort menu, wire sort logic
│   │   └── widgets/
│   │       ├── project_card.dart     # EXISTING: No changes
│   │       └── sort_menu.dart        # NEW: Sort options dropdown
│   └── projects/
│       ├── screens/
│       │   ├── create_project_screen.dart    # NEW: Form for project creation
│       │   └── project_detail_screen.dart    # EXISTING: No changes
│       └── widgets/
│           ├── project_form.dart             # NEW: Reusable form widget
│           ├── project_data_tab.dart         # EXISTING: No changes
│           └── project_products_tab.dart     # MODIFIED: Add search field, filter logic
└── main.dart                         # MODIFIED: Route setup for /create-project

test/
├── core/
│   └── utils/
│       └── slug_generator_test.dart  # NEW: Unit tests for slug generation
├── features/
│   ├── home/
│   │   ├── models/
│   │   │   └── project_sort_option_test.dart  # NEW: Enum tests
│   │   ├── services/
│   │   │   └── project_service_test.dart      # MODIFIED: Add createProject, sort tests
│   │   ├── screens/
│   │   │   └── home_screen_test.dart          # MODIFIED: Add sort menu tests
│   │   └── widgets/
│   │       └── sort_menu_test.dart            # NEW: Widget tests
│   └── projects/
│       ├── screens/
│       │   └── create_project_screen_test.dart  # NEW: Widget tests for form
│       ├── widgets/
│       │   ├── project_form_test.dart           # NEW: Form validation tests
│       │   └── project_products_tab_test.dart   # MODIFIED: Add search tests
│       └── integration/
│           └── create_project_flow_test.dart    # NEW: Full user journey test
```

**Structure Decision**:

This feature follows the established **feature-based architecture** with modifications to existing files and selective new additions:

1. **Existing Features Extended**:
   - `lib/features/home/` - Project list and search (add sort)
   - `lib/features/projects/` - Project detail management (add create)

2. **New Components**:
   - CreateProjectScreen - Primary UI for user story 1
   - SlugGenerator utility - Core logic for auto-slug
   - SortMenu widget - Dropdown for user story 2
   - ProjectSortOption enum - Sort state model

3. **Rationale**:
   - Follows existing pattern from ProductService (create + list)
   - Mirrors structure of ProductDetailScreen for consistency
   - Minimizes new abstractions (no separate "forms" layer)
   - Keeps project-related code co-located in features/projects/

4. **No Breaking Changes**:
   - All existing project viewing functionality preserved
   - Route `/create-project` transitions from PlaceholderScreen to CreateProjectScreen
   - HomeScreen sort button wired to actual logic (UI already exists)
   - ProductsTab search field wired to filter (UI already exists)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**Status**: N/A - No violations detected. All constitution principles followed.

This feature maintains the existing complexity level without introducing new patterns or abstractions.

## Phase 0: Research ✅ COMPLETED

The following research tasks were completed:

1. **Slug Generation Best Practices**
   - Research URL-friendly slug generation patterns in Dart
   - Investigate Unicode handling and special character edge cases
   - Decide on slug length limits and truncation strategy

2. **Sort Performance Optimization**
   - Benchmark List.sort() with 1000+ items on target devices
   - Evaluate whether caching sorted results is necessary
   - Determine sort stability requirements (preserve order for ties)

3. **Form Validation Patterns**
   - Review existing ProjectDataTab validation approach
   - Decide on real-time vs submit-time validation
   - Define error message display patterns

4. **GraphQL createProject Contract**
   - Confirm backend mutation signature and required fields
   - Verify slug uniqueness constraint handling (error codes)
   - Clarify default values for optional fields

**Output**: ✅ research.md created with decisions and rationale for each area (see `/specs/008-view-projects/research.md`)

## Phase 1: Design ✅ COMPLETED

The following artifacts were generated:

1. **data-model.md**:
   - ProjectSortOption enum definition
   - CreateProjectInput interface for mutation
   - Validation rule specifications

2. **contracts/**:
   - create-project-mutation.graphql (GraphQL schema)
   - slug-validation.md (validation rules and error codes)

3. **quickstart.md**:
   - Integration guide for wiring create project to other flows
   - Sort menu integration patterns
   - Product search implementation steps

4. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - Update CLAUDE.md with new patterns and conventions

**Output**: ✅ Complete design artifacts ready for task generation:
- data-model.md (`/specs/008-view-projects/data-model.md`)
- contracts/create-project-mutation.graphql (`/specs/008-view-projects/contracts/create-project-mutation.graphql`)
- contracts/slug-validation.md (`/specs/008-view-projects/contracts/slug-validation.md`)
- quickstart.md (`/specs/008-view-projects/quickstart.md`)
- CLAUDE.md updated with new technologies

## Next Steps

1. ✅ **Phase 0**: Run research agents to resolve all NEEDS CLARIFICATION items - COMPLETED
2. ✅ **Phase 1**: Generate data-model.md, contracts/, quickstart.md - COMPLETED
3. ✅ **Phase 2**: Run `/speckit.tasks` to generate implementation tasks - COMPLETED
4. ⏳ **Phase 3**: Run `/speckit.implement` to execute tasks

**Current Status**: Planning complete! All design artifacts and tasks generated. Ready for implementation.

**Tasks Generated**: 62 tasks organized by user story
- MVP (US1): 23 tasks - Create project functionality
- US2: 11 tasks - Sort projects
- US3: 7 tasks - Product creation from project
- US4: 8 tasks - Product search
- Setup + Foundational + Polish: 13 tasks

**Next**: Run `/speckit.implement` to execute the implementation plan.
