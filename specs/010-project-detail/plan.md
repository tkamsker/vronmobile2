# Implementation Plan: Project Detail Screen

**Branch**: `010-project-detail` | **Date**: 2025-12-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-project-detail/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement a project detail screen that displays comprehensive project information when a user taps "Enter project" from the projects list. The screen will show project name, description, and details, and provide navigation to "Project data" (edit screen) and "Products" (product list). The implementation extends the existing home screen navigation and uses the GraphQL API to fetch detailed project data.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.10+
**Primary Dependencies**:
- flutter (SDK)
- graphql_flutter (^5.1.0) - GraphQL client for API calls
- cached_network_image (^3.3.0) - Image loading and caching
- intl (^0.18.1) - Internationalization support
- existing i18n_service - Translation management

**Storage**: N/A (data fetched from GraphQL API, no local persistence for project details)
**Testing**:
- Widget tests (Flutter test framework)
- Integration tests for navigation flow
- Unit tests for ProjectService extensions

**Target Platform**: iOS 15+ and Android (Mobile)
**Project Type**: Mobile (Flutter)
**Performance Goals**:
- Project detail load < 1 second
- Smooth 60 fps scrolling
- Image loading with progressive placeholders

**Constraints**:
- Must integrate with existing home screen navigation (lib/features/home/screens/home_screen.dart)
- Must use existing GraphQL service (lib/core/services/graphql_service.dart)
- Must follow existing i18n patterns (lib/core/i18n/)
- Must match design specification in Requirements/ProjectDetail.jpg

**Scale/Scope**:
- Single new screen (ProjectDetailScreen)
- Extension of existing ProjectService with detail query
- 3-5 new widgets (header, info sections, action buttons)
- Navigation from home screen already implemented

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: Plan includes widget tests for ProjectDetailScreen
- ✅ **PASS**: Plan includes unit tests for ProjectService.fetchProjectDetail
- ✅ **PASS**: Plan includes integration tests for navigation flow
- ✅ **PASS**: TDD cycle will be followed (write failing tests first)

### II. Simplicity & YAGNI
- ✅ **PASS**: Implementing only required features from spec (detail display + navigation)
- ✅ **PASS**: Using existing GraphQL service, no new abstractions
- ✅ **PASS**: Using Flutter's built-in widgets (ListView, Card, etc.)
- ✅ **PASS**: No premature optimization or framework code

### III. Platform-Native Patterns
- ✅ **PASS**: Using Flutter widget composition
- ✅ **PASS**: Following Dart effective style guide
- ✅ **PASS**: Material Design widgets for Android, Cupertino-adaptive where needed
- ✅ **PASS**: Feature-based organization (lib/features/project_detail/)
- ✅ **PASS**: Using async/await for API calls

### Security & Privacy
- ✅ **PASS**: Using existing secure GraphQL client with authentication
- ✅ **PASS**: No sensitive data storage (all data fetched from API)
- ✅ **PASS**: Input validation not required (read-only screen)

### Performance Standards
- ✅ **PASS**: Target < 1 second load time (within requirement)
- ✅ **PASS**: Using cached_network_image for image optimization
- ✅ **PASS**: Progressive image loading with placeholders

### Accessibility
- ✅ **PASS**: Will add semantic labels to all widgets
- ✅ **PASS**: Touch targets will be minimum 44x44 px
- ✅ **PASS**: Using existing theme for contrast compliance

**GATE STATUS**: ✅ PASS - No constitution violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── project_detail/              # NEW - This feature
│   │   ├── screens/
│   │   │   └── project_detail_screen.dart
│   │   └── widgets/
│   │       ├── project_header.dart
│   │       ├── project_info_section.dart
│   │       └── project_action_buttons.dart
│   │
│   └── home/                         # EXISTING - Will update navigation
│       ├── screens/
│       │   └── home_screen.dart      # Update: _handleProjectTap navigation
│       ├── services/
│       │   └── project_service.dart  # Extend: Add fetchProjectDetail method
│       └── models/
│           └── project.dart          # Extend if needed for detail fields
│
├── core/
│   ├── i18n/
│   │   ├── en.json                   # UPDATE: Add project detail strings
│   │   ├── de.json                   # UPDATE: Add project detail strings
│   │   └── pt.json                   # UPDATE: Add project detail strings
│   └── navigation/
│       └── routes.dart                # UPDATE: Add projectDetail route handler
│
test/
├── features/
│   └── project_detail/               # NEW - Test files
│       ├── screens/
│       │   └── project_detail_screen_test.dart
│       └── widgets/
│           ├── project_header_test.dart
│           ├── project_info_section_test.dart
│           └── project_action_buttons_test.dart
│
└── integration/
    └── project_detail_navigation_test.dart  # NEW - Integration test
```

**Structure Decision**: Flutter mobile app with feature-based organization. The project_detail feature is a new module following the existing pattern. It integrates with the existing home feature for navigation and reuses core services (GraphQL, i18n).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations. This section is not applicable.
