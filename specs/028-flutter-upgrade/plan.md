# Implementation Plan: Flutter SDK and Dependencies Upgrade

**Branch**: `028-flutter-upgrade` | **Date**: 2026-01-13 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/028-flutter-upgrade/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Upgrade the Flutter SDK from 3.x to 3.32.4 (with Dart 3.8.1 from 3.10.0) and update all project dependencies to compatible versions. This infrastructure upgrade ensures the project leverages the latest stable features, security patches, and performance improvements. The approach involves: (1) researching breaking changes and migration paths, (2) updating SDK constraints and dependencies, (3) fixing deprecated API usage and breaking changes, (4) ensuring all tests pass, and (5) updating documentation to reflect the new versions.

## Technical Context

**Language/Version**: Dart 3.10.0 → Dart 3.8.1, Flutter 3.x → Flutter 3.32.4
**Primary Dependencies**:
- Current (from pubspec.yaml): graphql_flutter ^5.1.0, flutter_secure_storage ^10.0.0, flutter_dotenv ^6.0.0, cached_network_image ^3.3.0, intl ^0.20.0, shared_preferences ^2.3.2, google_sign_in ^7.0.0, flutter_roomplan ^1.0.7, file_picker ^10.3.8, path_provider ^2.1.5, http ^1.2.2, model_viewer_plus ^1.10.0, device_info_plus ^12.0.0, uuid ^4.5.1, share_plus ^12.0.1, archive ^4.0.0
- Target: Versions compatible with Dart 3.8.1 (to be determined in research phase)
**Storage**: Backend GraphQL API (PostgreSQL), local caching via shared_preferences (003-projectdetail), flutter_secure_storage for sensitive data
**Testing**: Flutter test framework (flutter_test), widget tests, integration tests, mocktail ^1.0.0, mockito ^5.4.2
**Target Platform**: iOS 15+ and Android (mobile application)
**Project Type**: Mobile (Flutter feature-based architecture)
**Performance Goals**: Maintain current performance: app launch < 3s cold start, < 1s warm start, 60 fps UI, build times < 30s hot reload
**Constraints**:
- Must not break existing functionality (backward compatibility with user data)
- Build times should not increase by > 20%
- App performance must remain same or improve
- Zero new compiler warnings (excluding deprecations to be fixed)
**Scale/Scope**:
- 27 existing features (001-027 in specs/)
- Feature-based architecture: lib/features/{auth,guest,home,lidar,products,profile,projects,scanning}
- Core infrastructure: lib/core/{config,constants,i18n,navigation,services,theme,utils}
- iOS native code (Swift) for USDZ combination (018-combined-scan-navmesh)
- Full regression testing across authentication, project management, scanning, file operations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Check

| Principle | Compliance Status | Notes |
|-----------|------------------|-------|
| **I. Test-First Development** | ⚠️ PARTIAL EXCEPTION | Infrastructure upgrades cannot follow strict TDD—the testing framework itself is being upgraded. Existing tests serve as regression suite. New tests for breaking changes will be written as fixes are implemented. |
| **II. Simplicity & YAGNI** | ✅ COMPLIANT | Upgrading only to stable Flutter 3.32.4, not adding new features or abstractions. Minimal scope: SDK + dependencies + breaking change fixes + documentation. |
| **III. Platform-Native Patterns** | ✅ COMPLIANT | No changes to architecture or patterns. Maintaining feature-based structure, continuing to use Flutter widgets, existing state management (Provider/StatefulWidget). |
| **Security & Privacy Requirements** | ✅ COMPLIANT | Upgrade includes latest security patches. Continuing to use flutter_secure_storage, HTTPS GraphQL endpoints. No new permissions or data collection. |
| **Performance Standards** | ✅ MUST VALIDATE | Flutter 3.32.4 should maintain or improve performance. Will profile before/after to ensure: launch times, 60fps, memory usage, build times within constraints. |
| **Accessibility Requirements** | ✅ COMPLIANT | No changes to accessibility implementation. Existing semantic labels, contrast ratios, touch targets preserved. |
| **CI/CD & DevOps Practices** | ✅ COMPLIANT | Using feature branch 028-flutter-upgrade. CI pipeline will validate: lint, tests, builds. Atomic commits. Documentation updates. |

**Overall Gate Status**: ✅ **PASS WITH JUSTIFIED EXCEPTION**

The TDD exception is justified because:
1. This is infrastructure maintenance, not new feature development
2. The testing framework itself is being upgraded (cannot write tests in old framework for new framework)
3. Existing test suite provides comprehensive regression coverage
4. Any new code (breaking change fixes) will have tests written as part of the fix

**Post-Design Re-Check**: To be completed after Phase 1 (should remain compliant).

## Project Structure

### Documentation (this feature)

```text
specs/028-flutter-upgrade/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output: breaking changes, migration guides, dependency compatibility
├── quickstart.md        # Phase 1 output: upgrade procedure summary
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

Note: `data-model.md` and `contracts/` are not applicable for this infrastructure upgrade feature.

### Source Code (repository root)

```text
# Mobile Flutter application structure (current)
lib/
├── main.dart           # Application entry point
├── core/               # Shared infrastructure
│   ├── config/         # Configuration management
│   ├── constants/      # App-wide constants
│   ├── i18n/          # Internationalization (en.json, de.json, pt.json)
│   ├── navigation/     # Navigation utilities
│   ├── services/       # Core services (GraphQL, storage)
│   ├── theme/          # App theming
│   └── utils/          # Utility functions
└── features/           # Feature modules
    ├── auth/           # Authentication (login, OAuth, forgot password)
    ├── guest/          # Guest mode functionality
    ├── home/           # Home screen and navigation
    ├── lidar/          # LiDAR scanning
    ├── products/       # Product management
    ├── profile/        # User profile
    ├── projects/       # Project management
    └── scanning/       # Scan processing and preview

test/                   # Test files mirroring lib/ structure
├── features/           # Feature tests
└── core/               # Core tests

ios/                    # iOS-specific code (Swift, Xcode project)
android/                # Android-specific code (Kotlin, Gradle)
assets/                 # Static assets
specs/                  # Feature specifications
.specify/               # Specification tooling

# Files to be modified
pubspec.yaml            # SDK constraints and dependency versions
CLAUDE.md               # Project documentation with SDK versions
lib/**/*.dart           # Code using deprecated APIs (to be identified)
test/**/*_test.dart     # Tests needing updates for API changes
```

**Structure Decision**: This is a mobile Flutter application using feature-based architecture as defined in CLAUDE.md. The upgrade will touch primarily:
1. `pubspec.yaml` (SDK constraints, dependency versions)
2. All Dart files using deprecated APIs (identified via `flutter analyze`)
3. Test files requiring updates for test framework API changes
4. Documentation files (CLAUDE.md, README files, code comments)
5. Platform-specific code if native module compatibility issues arise (ios/, android/)

The feature-based structure remains unchanged—this is purely an SDK upgrade, not a refactor.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| TDD partial exception | Upgrading testing framework itself—cannot write tests in old framework for new framework behavior | Writing tests first is impossible when the test runner and assertion library APIs are changing. Existing tests provide regression coverage. |

**Mitigation**:
- Existing test suite (unit, widget, integration) serves as comprehensive regression suite
- Run full test suite after each change to ensure no regressions
- For any new code written to fix breaking changes, follow TDD within the new framework
- Document test results at each phase milestone

## Phase 0: Research & Discovery

**Goal**: Identify all breaking changes, deprecated APIs, and dependency compatibility issues before making any code changes.

### Research Tasks

1. **Flutter 3.32.4 Breaking Changes**
   - Review official Flutter release notes for 3.32.4
   - Identify breaking changes affecting widgets, rendering, platform channels
   - Document migration paths for each breaking change
   - Check for changes in build system (gradle, cocoapods, Swift)

2. **Dart 3.8.1 Language Changes**
   - Review Dart 3.8.1 changelog for language-level breaking changes
   - Check for changes in core libraries (dart:core, dart:async, dart:io)
   - Identify deprecated language features or API changes
   - Document null safety or type inference changes if any

3. **Dependency Compatibility Matrix**
   - For each package in pubspec.yaml, check compatibility with Dart 3.8.1
   - Identify target versions for all dependencies
   - Check for breaking changes in major dependency updates
   - Special attention to native plugins: flutter_roomplan, google_sign_in, flutter_secure_storage
   - Verify GraphQL client compatibility (graphql_flutter ^5.1.0)

4. **Test Framework Changes**
   - Review flutter_test API changes
   - Check mocktail and mockito compatibility with Dart 3.8.1
   - Identify test assertion API changes
   - Document integration_test framework changes if any

5. **Platform-Specific Changes**
   - iOS: Check Swift compatibility with new Flutter engine version
   - iOS: Verify Xcode version requirements for Flutter 3.32.4
   - Android: Check Gradle plugin compatibility
   - Android: Verify Android SDK / NDK version requirements
   - Review platform channel API changes

6. **Deprecation Audit**
   - Run `flutter analyze` on current codebase to identify existing warnings
   - Document all deprecated API usages to be fixed
   - Prioritize deprecations by impact (critical vs. warning)

**Output**: research.md containing:
- Complete list of breaking changes and their solutions
- Dependency compatibility matrix with target versions
- Deprecation audit results with migration paths
- Platform-specific upgrade requirements
- Estimated risk areas (code most likely to need changes)

### Research Methodology

Research will be conducted using:
- Official Flutter documentation: flutter.dev/release/breaking-changes
- Dart language specification: dart.dev/guides/language/evolution
- Package changelogs on pub.dev
- Flutter GitHub repository for commit history and issue discussions
- Community resources: Flutter Discord, StackOverflow, GitHub discussions

**Timeline**: Phase 0 research must be completed before any code changes begin.

## Phase 1: Design & Implementation Strategy

**Prerequisites**: research.md complete with all breaking changes documented

### Design Artifacts

#### 1. Migration Strategy Document (quickstart.md)

Since this is an infrastructure upgrade (not a feature), the "design" phase focuses on migration strategy rather than data models or API contracts.

**quickstart.md** will contain:

```markdown
# Flutter 3.32.4 Upgrade Quickstart

## Pre-Upgrade Checklist
- [ ] All current tests passing
- [ ] Current app builds successfully on iOS and Android
- [ ] Baseline performance metrics captured
- [ ] Git branch 028-flutter-upgrade created from stage

## Upgrade Steps (High-Level)

### Step 1: Flutter SDK Upgrade
- Switch to Flutter 3.32.4 using flutter version or fvm
- Verify installation: flutter doctor

### Step 2: Update pubspec.yaml
- Update SDK constraint: sdk: ^3.8.1
- Update dependencies to compatible versions (see dependency matrix in research.md)
- Run: flutter pub get

### Step 3: Fix Breaking Changes
- Address compilation errors (see breaking changes list in research.md)
- Update deprecated API usage (priority order: critical > high > medium)
- Update platform-specific code if needed (ios/, android/)

### Step 4: Test Suite Updates
- Fix test framework API changes
- Update mock setup for new API patterns
- Ensure all tests pass: flutter test

### Step 5: Platform Build Verification
- Build iOS: flutter build ios --release
- Build Android: flutter build apk --release
- Test on physical devices: flutter run

### Step 6: Documentation Updates
- Update CLAUDE.md with new SDK versions
- Update README if present
- Update inline code comments mentioning SDK versions

### Step 7: Final Validation
- flutter analyze (zero errors, zero warnings)
- Full regression test suite
- Performance profiling vs. baseline
- Manual testing of critical flows

## Rollback Procedure
If critical issues arise:
- git checkout stage
- flutter downgrade (or fvm use <previous-version>)
- flutter pub get
```

#### 2. No Data Model Required

This feature does not introduce or modify data entities. The `data-model.md` artifact is not applicable.

#### 3. No API Contracts Required

This feature does not add or modify API endpoints. The `contracts/` directory is not applicable.

#### 4. Breaking Change Fix Patterns

Document common fix patterns in quickstart.md:

**Pattern 1: Widget Constructor Changes**
- Before: `SomeWidget(child: ...)`
- After: `SomeWidget(child: ..., requiredNewParam: ...)`

**Pattern 2: Deprecated Widget Replacements**
- Before: `FlatButton(...)`
- After: `TextButton(...)`

**Pattern 3: Platform Method Invocation Changes**
- Before: `platform.invokeMethod('method')`
- After: `platform.invokeMethod<Type>('method')`

(Specific patterns to be filled from research.md findings)

### Implementation Phases

**Phase 1a: Dependency Resolution**
1. Update pubspec.yaml SDK constraint
2. Update all dependencies to target versions from research.md
3. Resolve version conflicts
4. Achieve successful `flutter pub get`

**Phase 1b: Compilation Fixes**
1. Address all compilation errors from breaking changes
2. Fix critical deprecated API usage (blocking build)
3. Update platform-specific code if needed
4. Achieve successful `flutter build apk` and `flutter build ios`

**Phase 1c: Deprecation Cleanup**
1. Fix all remaining deprecated API usage
2. Achieve zero warnings from `flutter analyze`
3. Update test code for test framework changes
4. Achieve 100% test pass rate

**Phase 1d: Documentation & Validation**
1. Update CLAUDE.md
2. Update code comments
3. Run full regression suite
4. Performance validation

### Agent Context Update

After completing Phase 1 design, update CLAUDE.md:

```bash
.specify/scripts/bash/update-agent-context.sh claude
```

This will update CLAUDE.md with the new SDK versions:
- Change "Dart 3.10+ / Flutter 3.x" to "Dart 3.8.1 / Flutter 3.32.4"
- Preserve manual additions between markers
- Ensure consistency across all technology stack references

## Phase 2: Task Breakdown

**Out of scope for /speckit.plan command**

Task breakdown will be generated by `/speckit.tasks` command after this plan is complete. Tasks will be organized by implementation phases (1a → 1b → 1c → 1d) with dependency tracking.

Expected task categories:
- Dependency updates (can run in parallel with research review)
- Breaking change fixes (must be done sequentially by priority)
- Deprecation fixes (can be parallelized by feature module)
- Documentation updates (can run in parallel after code changes complete)
- Testing and validation (must be done sequentially after each phase)

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Incompatible dependency versions | Medium | High | Research phase identifies compatibility before changes. Maintain compatibility matrix. Consider pinning problematic packages. |
| Native module breaks (flutter_roomplan) | Medium | High | Test iOS USDZ scanning early. Have fallback plan to pin to working version or patch native code. Engage with package maintainer. |
| Test framework breaking changes | Low | Medium | Comprehensive test suite allows early detection. Fix tests incrementally by module. |
| Performance regression | Low | High | Capture baseline metrics before upgrade. Profile after each phase. Use Flutter DevTools for comparison. |
| Undocumented breaking changes | Medium | Medium | Community research (GitHub issues, Discord). Maintain list of "surprises" in research.md. Budget time for unknowns. |
| Platform build failures (iOS/Android) | Medium | High | Test both platforms early and often. Check Xcode/Android Studio compatibility. Review platform-specific logs carefully. |

## Success Metrics

These align with Success Criteria from spec.md:

- **SC-001**: ✅ iOS and Android builds complete without errors
- **SC-002**: ✅ All automated tests pass (100% pass rate)
- **SC-003**: ✅ `flutter analyze` returns zero errors, zero warnings
- **SC-004**: ✅ App startup time within 5% of baseline (measure with Flutter DevTools)
- **SC-005**: ✅ Manual testing of auth, projects, scanning, file ops successful
- **SC-006**: ✅ CLAUDE.md and code comments reflect Dart 3.8.1 / Flutter 3.32.4
- **SC-007**: ✅ Local development environment builds successfully
- **SC-008**: ✅ No runtime crashes in standard workflows

**Validation Protocol**:
1. Automated: CI pipeline runs (lint, test, build) on PR to stage
2. Manual: QA checklist for critical user flows
3. Performance: DevTools profiling report comparing before/after metrics
4. Documentation: Peer review of CLAUDE.md and inline doc updates

## Post-Implementation Review

After tasks complete and before merging to stage:

1. **Code Review**: Peer review all changes, verify constitution compliance
2. **Performance Audit**: Compare DevTools metrics against baseline
3. **Documentation Review**: Ensure CLAUDE.md accurately reflects new stack
4. **Regression Testing**: Full manual test of all features
5. **Deployment Readiness**: Verify CI/CD pipeline works with new SDK

**Merge Criteria**:
- All Phase 1 tasks completed
- All success metrics achieved
- Code review approved
- No unresolved breaking changes or deprecations
- Documentation updated and reviewed

## Appendix: Related Specifications

This upgrade affects all existing features:
- 001-main-screen-login through 027-create-account
- All features in lib/features/: auth, guest, home, lidar, products, profile, projects, scanning
- Core infrastructure in lib/core/

**Cross-Feature Impact**: Changes to core dependencies (graphql_flutter, flutter_secure_storage, shared_preferences) affect multiple features. Regression testing must cover:
- Authentication flows (001, 003, 004, 026)
- Project and product management (002, 006, 008, 010, 025)
- LiDAR scanning and room stitching (014, 016, 017, 018)
- Guest mode (007)
- Settings and localization (022, 023)

**CI/CD Impact**: The CI pipeline configuration (if present) will need to be updated to use Flutter 3.32.4 for builds. This is noted as out of scope but must be coordinated with DevOps.
