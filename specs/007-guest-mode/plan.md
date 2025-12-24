# Implementation Plan: Guest Mode

**Branch**: `007-guest-mode` | **Date**: 2025-12-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-guest-mode/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement guest mode to allow users to access LiDAR scanning functionality without authentication. Guest users can scan rooms and export GLB files locally but cannot save scans to cloud projects. This reduces friction for new users trying the app while maintaining clear boundaries for authenticated features. The implementation uses local storage only, with no backend API calls during guest sessions.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- shared_preferences ^2.2.2 (existing - for guest session state)
- path_provider (existing - for local file storage paths)
- graphql_flutter ^5.1.0 (existing - will be conditionally bypassed in guest mode)

**Storage**:
- Local device storage using shared_preferences for guest session flag
- App documents directory for guest scan data (GLB files)
- No backend/cloud storage in guest mode

**Testing**: flutter_test (Dart SDK), widget tests, unit tests, integration tests

**Target Platform**: iOS 15+ and Android API 21+ (dual platform mobile)

**Project Type**: Mobile application (Flutter feature-based architecture)

**Performance Goals**:
- Guest mode activation < 1 second (SC-001)
- Maintain 60 fps during navigation
- Local file operations < 500ms

**Constraints**:
- MUST NOT make any backend API calls in guest mode (FR-005, SC-003)
- Guest data is device-local only (no cloud sync)
- Guest scans lost if app uninstalled
- Must integrate with existing AuthService pattern

**Scale/Scope**:
- Single feature addition to existing app
- ~3-5 new files (guest session manager, state tracking, UI modifications)
- Modifications to existing navigation and scanning screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: TDD approach required for all implementation
- Tests MUST be written before code:
  - Unit tests for GuestSessionManager (session state, mode detection)
  - Widget tests for guest mode button and navigation
  - Integration tests for complete guest workflow
- Red-Green-Refactor cycle enforced

### II. Simplicity & YAGNI
- ✅ **PASS**: Implementation focused only on stated requirements
- Using existing patterns (shared_preferences for state, feature-based architecture)
- No premature abstraction for guest data migration (stated as not supported)
- Minimal new code: GuestSessionManager service, UI modifications only
- **Question**: Single GuestSessionManager or separate concerns? (Recommend: Single manager per YAGNI)

### III. Platform-Native Patterns
- ✅ **PASS**: Following Flutter/Dart idioms
- Widget composition for guest mode button
- Feature-based architecture: `lib/features/guest/`
- Async/await for local storage operations
- Platform-specific handling via path_provider
- Existing navigation patterns preserved

### Security & Privacy Requirements
- ✅ **PASS**: Guest mode reduces security requirements (no auth, no cloud data)
- Local storage only (shared_preferences and local files)
- No sensitive data in guest mode
- Clear disclosure that guest data is not backed up
- Privacy-preserving: no tracking, no backend calls

### Performance Standards
- ✅ **PASS**: Guest mode activation < 1 second (SC-001)
- 60 fps maintained (standard Flutter performance)
- Local file operations < 500ms
- Memory efficient (no network operations, no caching)

### Accessibility Requirements
- ✅ **PASS**: Guest mode button will have Semantics implementation
- Screen reader support via semantic labels
- Touch target size adequate (ElevatedButton default)
- Clear indication of guest vs authenticated state

### CI/CD & DevOps Practices
- ✅ **PASS**: Feature branch `007-guest-mode`
- Tests required before merge
- Code review required

**GATE RESULT**: ✅ **PASS** - Proceed to Phase 0 Research

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
lib/features/guest/
├── services/
│   └── guest_session_manager.dart    # Manages guest session state
├── widgets/
│   └── guest_mode_button.dart         # Guest mode entry point button (optional - may add to main_screen)
└── utils/
    └── guest_storage_helper.dart      # Helper for local file operations

lib/features/auth/
└── screens/
    └── main_screen.dart                # Modified: Add guest mode button

lib/features/lidar/                     # Existing (UC14 reference)
└── screens/
    └── scanning_screen.dart            # Modified: Respect guest mode limitations

lib/core/
├── services/
│   └── graphql_service.dart            # Modified: Skip API calls in guest mode
└── constants/
    └── app_strings.dart                # Add guest mode strings

test/
├── features/guest/
│   ├── services/
│   │   └── guest_session_manager_test.dart
│   └── widgets/
│       └── guest_mode_button_test.dart (if widget created)
└── integration/
    └── guest_mode_flow_test.dart       # Complete guest workflow test
```

**Structure Decision**: Flutter mobile app with feature-based architecture. New `lib/features/guest/` directory contains guest-specific code. The GuestSessionManager service handles all guest state management, while existing features (auth, lidar) are modified to respect guest mode. No separate platform-specific code needed as guest mode is purely app-level logic.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - all constitution checks passed. Implementation follows existing patterns and maintains simplicity.
