# Implementation Plan: Project Detail and Data Management

**Branch**: `003-projectdetail` | **Date**: 2025-12-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-projectdetail/spec.md`

## Summary

This feature implements UC10 (Project Detail) and UC11 (Project Data), enabling logged-in users to view comprehensive project information and edit project master data fields. Users navigate from the projects list to a detail screen showing project metadata, a 3D/VR viewer placeholder, and navigation tabs (Viewer, Project data, Products). The "Project data" tab presents an editable form for project **name and description only** (slug is read-only per clarification).

**Technical Approach**: Extends existing project model with description field, creates new project detail and project data screens following Flutter's widget composition patterns, implements GraphQL query and mutation for fetching and updating project details, and maintains consistency with the established feature-based architecture.

**Key Clarifications from /speckit.clarify**:
1. **Concurrent edits**: Last-write-wins with automatic refresh after save
2. **Unsaved changes**: Warning dialog with "Discard Changes" / "Keep Editing" options
3. **Slug field**: Read-only (not editable in this feature; deferred to future iteration)

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- `graphql_flutter: ^5.1.0` for GraphQL client operations
- `cached_network_image: ^3.3.0` for project image loading
- `flutter_secure_storage: ^9.0.0` for auth token management
- `intl: ^0.18.1` for date formatting
- `shared_preferences: ^2.2.2` for local data persistence

**Storage**: Backend GraphQL API (PostgreSQL), local caching via shared_preferences
**Testing**: Flutter's built-in test framework (flutter_test SDK), widget tests for UI components, integration tests for user journeys
**Target Platform**: iOS (primary target based on PRD), Android (Flutter cross-platform support)
**Project Type**: Mobile - Flutter feature-based architecture
**Performance Goals**:
- Project detail screen loads in < 2 seconds
- Form validation response < 200ms
- Save operation completes within 3 seconds
- 60 fps for all UI interactions

**Constraints**:
- Must match Figma designs (UC10: node-id=1-317, UC11: node-id=16-1916)
- Read-only project viewer (3D/VR viewer is placeholder - "Live" indicator, not interactive)
- No project creation capability (creates lead on vron.one platform)
- **Edit only name and description fields (slug is read-only per clarification)**
- Offline capability not required (must be logged in with network access)

**Scale/Scope**:
- 2 new screens (project detail, project data edit)
- 1 extended model (Project with description field)
- 1 new GraphQL query (project detail), 1 new mutation (updateProject for name/description only)
- 4-6 new widgets (tab navigation, viewer placeholder, edit form components)
- Estimated 6-10 development hours (reduced from 8-12 due to slug being read-only)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Test-First Development (NON-NEGOTIABLE)

**Status**: COMPLIANT

- All new widgets will have widget tests written first (TDD)
- GraphQL service methods will have unit tests verifying request/response handling
- Integration tests will cover the full user journey: navigate to project detail → edit project data → save changes
- Red-Green-Refactor cycle will be enforced for all implementation tasks

**Implementation Commitment**:
- Task 1: Write failing widget test for ProjectDetailScreen → implement → refactor
- Task 2: Write failing test for project query → implement GraphQL operation → refactor
- Task 3: Write failing widget test for ProjectDataTab → implement → refactor
- Task 4: Write failing test for updateProject mutation → implement → refactor
- Task 5: Write integration test for full edit journey → verify all tests pass

### ✅ II. Simplicity & YAGNI

**Status**: COMPLIANT

- Implementing only the three prioritized user stories (view, edit name/description, navigate to products)
- No premature abstractions: using existing Project model with minimal extension (add description field)
- Reusing existing GraphQL service pattern from home feature
- No custom form framework: using Flutter's built-in TextFormField with validation
- No state management library needed: using StatefulWidget with setState for form state
- Deleting unused code: no commented-out sections, no "just in case" utilities
- **Slug read-only: Simpler implementation, fewer validation rules, reduced scope**

**YAGNI Decisions**:
- NOT implementing: slug editing (deferred per clarification)
- NOT implementing: offline editing (not required by spec)
- NOT implementing: undo/redo for edits (not in requirements)
- NOT implementing: field-level autosave (simple save button sufficient)
- NOT implementing: custom validation framework (Flutter's validator parameter sufficient)
- NOT implementing: 3D viewer (placeholder only per user input)

### ✅ III. Platform-Native Patterns

**Status**: COMPLIANT

- Using Material Design widgets for Android, Cupertino-adaptive widgets where needed for iOS
- Following Flutter widget composition (not inheritance)
- Following Dart's effective style guide for naming conventions
- Using existing feature-based file structure: `lib/features/projects/`
- Using StatefulWidget with setState for simple form state (no external state management needed)
- Async operations use Dart's async/await with proper error handling
- Navigation using Flutter's Navigator with named routes (existing pattern in routes.dart)

**Platform Patterns**:
- Tab navigation using TabBar/TabBarView (Material) with iOS-style colors
- Form inputs using TextFormField with platform-adaptive keyboards
- Loading states using CircularProgressIndicator (adaptive to platform)
- Error messages using SnackBar for transient feedback
- Warning dialog for unsaved changes (AlertDialog with Material/Cupertino styling)
- Back navigation respects platform conventions (iOS swipe, Android back button)

### ✅ Security & Privacy Requirements

**Status**: COMPLIANT

- Authentication tokens already managed via flutter_secure_storage (existing implementation)
- All GraphQL calls use HTTPS (configured in env_config.dart)
- Input validation prevents injection attacks (validating name and description fields only)
- No new sensitive data storage required (reusing existing auth infrastructure)
- No new permissions required (network already granted)
- Form validation sanitizes user input before transmission
- Error messages don't expose sensitive system details

### ✅ Performance Standards

**Status**: COMPLIANT

- Screen navigation and rendering target 60 fps (using Flutter's widget rendering)
- GraphQL queries optimized with field selection (only fetch required fields)
- Image caching via cached_network_image (already in use)
- Form validation is synchronous and lightweight (< 200ms target)
- No memory leaks: proper disposal of controllers in dispose() methods
- No background processing required for this feature
- **Reduced scope (slug read-only) improves performance: simpler validation, fewer GraphQL mutation fields**

### ✅ Accessibility Requirements

**Status**: COMPLIANT

- All interactive widgets will have Semantics labels
- Form fields have proper labels and hints for screen readers
- Warning dialog announced to screen readers
- Touch targets meet 44x44 minimum (Flutter's default button sizing)
- Text respects textScaleFactor for dynamic font sizing
- Contrast ratios meet WCAG AA (using app_theme.dart color scheme)
- Form validation errors announced to screen readers
- Focus order follows logical reading flow (top to bottom, left to right)

### ✅ CI/CD & DevOps Practices

**Status**: COMPLIANT

- Feature branch `003-projectdetail` created (current branch)
- Atomic commits for each logical task (TDD cycle: test → implement → refactor → commit)
- All tests must pass before merge to main
- Code follows flutter_lints rules (already configured in project)
- No CI/CD pipeline changes required (existing pipeline runs tests)

**Compliance Summary**: All constitution principles are satisfied. No violations require justification in Complexity Tracking section.

## Project Structure

### Documentation (this feature)

```text
specs/003-projectdetail/
├── spec.md              # Feature specification (completed, with clarifications)
├── plan.md              # This file (/speckit.plan command output)
├── checklists/
│   └── requirements.md  # Specification quality checklist (completed)
├── research.md          # Phase 0 output (completed)
├── data-model.md        # Phase 1 output (completed, updated for slug read-only)
├── quickstart.md        # Phase 1 output (completed, updated for reduced scope)
├── contracts/           # Phase 1 output (completed)
│   ├── project-detail-query.graphql
│   └── update-project-mutation.graphql
└── tasks.md             # Phase 2 output (/speckit.tasks command - to be generated)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── config/
│   │   └── env_config.dart              # Existing: GraphQL endpoints
│   ├── constants/
│   │   └── app_strings.dart             # Existing: Localized strings
│   ├── navigation/
│   │   └── routes.dart                  # Updated: Add project detail routes
│   ├── services/
│   │   ├── graphql_service.dart         # Existing: GraphQL client
│   │   └── token_storage.dart           # Existing: Auth token management
│   └── theme/
│       └── app_theme.dart               # Existing: Theme configuration
│
├── features/
│   ├── auth/                            # Existing: Authentication features
│   │   └── ...
│   ├── home/                            # Existing: Project list
│   │   ├── models/
│   │   │   ├── project.dart             # Updated: Add description field
│   │   │   ├── project_status.dart      # Existing
│   │   │   └── project_subscription.dart # Existing
│   │   ├── screens/
│   │   │   └── home_screen.dart         # Existing: Projects list
│   │   ├── services/
│   │   │   └── project_service.dart     # Updated: Add detail query & update mutation
│   │   └── widgets/
│   │       ├── project_card.dart        # Existing: Links to detail screen
│   │       └── ...
│   │
│   └── projects/                        # New: Project detail features
│       ├── models/
│       │   └── project_edit_form.dart   # New: Form state model (name & description only)
│       ├── screens/
│       │   ├── project_detail_screen.dart  # New: Main detail view with tabs
│       │   └── project_data_screen.dart    # New: REMOVED (integrated as tab)
│       ├── widgets/
│       │   ├── project_detail_header.dart  # New: Name, status, menu
│       │   ├── project_viewer_tab.dart     # New: 3D/VR viewer placeholder
│       │   ├── project_data_tab.dart       # New: Data edit form (name & desc only, slug display-only)
│       │   ├── project_products_tab.dart   # New: Products navigation
│       │   └── project_tab_navigation.dart # New: Tab bar component
│       └── utils/
│           └── project_validator.dart      # New: Form validation logic (name & desc only)
│
└── main.dart                            # Existing: App entry point

test/
├── features/
│   ├── home/
│   │   ├── models/
│   │   │   └── project_test.dart        # Updated: Test new description field
│   │   └── services/
│   │       └── project_service_test.dart # Updated: Test new queries/mutations
│   │
│   └── projects/                        # New: Test files for project detail
│       ├── screens/
│       │   └── project_detail_screen_test.dart
│       ├── widgets/
│       │   ├── project_detail_header_test.dart
│       │   ├── project_viewer_tab_test.dart
│       │   ├── project_data_tab_test.dart
│       │   └── project_tab_navigation_test.dart
│       └── utils/
│           └── project_validator_test.dart
│
└── integration/
    └── project_edit_journey_test.dart   # New: Full user journey integration test
```

**Structure Decision**: Flutter mobile project with feature-based organization. This feature extends the existing `home` feature (adds description field to Project model and methods to project_service) and creates a new `projects` feature module for detail/edit screens. This separation follows the principle that the home feature is about listing/searching projects, while the projects feature is about viewing/editing individual project details.

## Complexity Tracking

No violations of constitution principles. This section remains empty as all checks passed without requiring justification.

---

## Phase 0 & Phase 1: Complete

All planning artifacts have been generated:

✅ **research.md** - All research questions resolved (see `specs/003-projectdetail/research.md`)
✅ **data-model.md** - Entity specifications complete (see `specs/003-projectdetail/data-model.md`)
✅ **contracts/** - GraphQL contracts defined (see `specs/003-projectdetail/contracts/`)
✅ **quickstart.md** - Implementation guide complete (see `specs/003-projectdetail/quickstart.md`)
✅ **Agent context** - CLAUDE.md updated with new technology stack

### Key Updates Based on Clarifications

The following design decisions have been updated to reflect clarifications from `/speckit.clarify`:

1. **Slug Field Handling** (from clarification #3):
   - Slug displayed as read-only in edit form
   - No validation logic needed for slug
   - updateProject mutation only includes name and description
   - ProjectEditForm only tracks name and description (not slug)
   - Reduces implementation complexity and testing surface

2. **Concurrent Edit Strategy** (from clarification #1):
   - Last-write-wins approach (no optimistic locking)
   - Automatic reload after successful save (FR-014 updated)
   - No conflict detection UI needed
   - Simpler implementation, better UX

3. **Unsaved Changes Warning** (from clarification #2):
   - AlertDialog with two options: "Discard Changes" / "Keep Editing"
   - Triggered only when form is dirty
   - No auto-save implementation needed
   - Clear user control over data loss

---

## Phase 2: Task Generation (Next Step)

Phase 2 (task breakdown into `tasks.md`) will be handled by the `/speckit.tasks` command.

**Estimated Implementation Time**: 6-10 hours (TDD approach with tests first)
- Reduced from original 8-12 hours due to slug being read-only
- Simpler validation (only 2 fields instead of 3)
- Fewer test cases needed

**Risk Assessment**: Low - extends existing patterns, no new dependencies, clear requirements, reduced scope from clarifications

**Blocking Dependencies**: None - all prerequisites (auth, project list) already implemented

---

## Design Review Checklist

Before proceeding to `/speckit.tasks`, verify:

- [x] All research questions resolved in research.md
- [x] Data model extends existing Project class without breaking changes
- [x] GraphQL contracts match backend schema (verified via research)
- [x] Screen layouts match Figma designs (ProjectDetail.jpg, ProjectDetailData.jpg)
- [x] Form validation rules documented and complete (name & description only)
- [x] Navigation routes integrated with existing routes.dart pattern
- [x] Test strategy covers widget tests, unit tests, and integration tests
- [x] No new dependencies required (reusing existing packages)
- [x] Constitution compliance verified (all checks passed)
- [x] Complexity tracking section remains empty (no violations)
- [x] Clarifications integrated into design (slug read-only, concurrent edits, unsaved warning)

---

## Constitution Re-Check (Post-Design)

After completing Phase 1 design, re-evaluate constitution compliance:

### ✅ Test-First Development
- Widget test files planned for all new UI components
- Unit test files planned for validator and service methods
- Integration test planned for full edit journey
- Test file structure matches implementation structure

### ✅ Simplicity & YAGNI
- No abstractions introduced beyond necessary form state model
- Reusing existing GraphQL service pattern
- Using built-in Flutter widgets (TabBar, TextFormField)
- No custom state management (StatefulWidget + setState)
- **Slug read-only further simplifies implementation**

### ✅ Platform-Native Patterns
- Feature-based file structure maintained
- Widget composition followed throughout
- Material Design widgets used appropriately
- Async operations use async/await pattern
- Warning dialog follows platform conventions

**Post-Design Assessment**: All constitution principles remain satisfied. Clarifications reduced complexity and risk. Design is ready for task generation.

---

## Next Steps

1. ✅ Review this implementation plan
2. ✅ Generated research.md by resolving all research tasks
3. ✅ Created data-model.md with complete entity specifications
4. ✅ Generated API contracts in contracts/ directory
5. ✅ Created quickstart.md guide
6. ✅ Updated agent context file
7. **→ Run `/speckit.tasks` to generate task breakdown** ← NEXT COMMAND

**Ready for**: Task generation via `/speckit.tasks`
