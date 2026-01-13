# Feature Specification: Flutter SDK and Dependencies Upgrade

**Feature Branch**: `028-flutter-upgrade`
**Created**: 2026-01-13
**Status**: Draft
**Input**: User description: "Upgrade Flutter SDK and dependencies to Flutter 3.32.4 (Dart 3.8.1). Update pubspec.yaml SDK constraints, upgrade all dependencies to compatible versions, fix any breaking changes or deprecated API usage, and update project documentation to reflect the new versions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - SDK and Core Dependencies Updated (Priority: P1)

Development team updates the Flutter SDK to version 3.32.4 (with Dart 3.8.1) and updates all project dependencies to versions compatible with the new SDK. This ensures the project can leverage the latest stable features, security patches, and performance improvements from the Flutter ecosystem.

**Why this priority**: This is the foundation of the upgrade. Without successfully updating the SDK and dependencies, no other upgrade tasks can proceed. The application must build and run with the new SDK version.

**Independent Test**: Can be fully tested by running `flutter pub get` successfully, building the application (`flutter build`), and launching the app on a test device without compilation errors. Delivers a working application on the upgraded SDK.

**Acceptance Scenarios**:

1. **Given** the project uses Dart SDK ^3.10.0, **When** pubspec.yaml SDK constraint is updated to ^3.8.1 and `flutter pub get` is run, **Then** all dependencies resolve without version conflicts
2. **Given** all dependencies are updated to compatible versions, **When** `flutter build apk` and `flutter build ios` are executed, **Then** builds complete successfully without errors
3. **Given** the application is built with the new SDK, **When** the app is launched on test devices (iOS and Android), **Then** the app starts successfully and displays the home screen
4. **Given** the upgraded application, **When** core features are tested (login, project list, scanning), **Then** all features function as expected without regression

---

### User Story 2 - Breaking Changes and Deprecated APIs Resolved (Priority: P2)

Development team identifies and resolves all breaking changes and deprecated API usage introduced by the Flutter 3.32.4 and Dart 3.8.1 upgrade. This ensures the codebase follows current best practices and avoids future compatibility issues.

**Why this priority**: After ensuring the application builds and runs (P1), resolving breaking changes and deprecations is critical to maintain code quality and prevent future issues. However, this can be done incrementally after the initial build succeeds.

**Independent Test**: Can be tested by running static analysis (`flutter analyze`) with zero errors and warnings related to deprecated APIs, and by performing manual testing of all application features to ensure no runtime errors occur. Delivers a clean, future-proof codebase.

**Acceptance Scenarios**:

1. **Given** the upgraded codebase, **When** `flutter analyze` is run, **Then** no errors or warnings about deprecated API usage are reported
2. **Given** code using deprecated APIs is updated, **When** the application is run through comprehensive manual testing, **Then** no runtime errors or unexpected behavior occurs
3. **Given** breaking changes in dependency APIs, **When** affected code is updated to use new API patterns, **Then** all functionality works correctly with the new APIs
4. **Given** the upgraded application, **When** automated tests are run, **Then** all existing tests pass without modification or with only minor updates to accommodate API changes

---

### User Story 3 - Documentation Updated (Priority: P3)

Development team updates all project documentation (CLAUDE.md, README files, and inline code comments referencing SDK versions) to reflect the new Flutter 3.32.4 and Dart 3.8.1 versions. This ensures future developers and AI assistants have accurate information about the project's technology stack.

**Why this priority**: Documentation updates are important for maintainability but don't affect the application's functionality. They can be completed after ensuring the application works correctly with the upgraded SDK.

**Independent Test**: Can be tested by reviewing all documentation files and verifying that version numbers are accurate and consistent. Delivers up-to-date project documentation.

**Acceptance Scenarios**:

1. **Given** CLAUDE.md contains references to Dart 3.10+ / Flutter 3.x, **When** the file is updated, **Then** all references reflect Dart 3.8.1 / Flutter 3.32.4
2. **Given** the project structure section in documentation, **When** new conventions or patterns from the upgrade are identified, **Then** documentation is updated to reflect these changes
3. **Given** code comments mentioning SDK versions, **When** the codebase is searched for version references, **Then** all version mentions are accurate and current
4. **Given** the updated documentation, **When** a new developer reviews the project setup instructions, **Then** they can successfully set up the development environment with the correct SDK version

---

### Edge Cases

- What happens when a dependency has no compatible version for Dart 3.8.1?
  - Resolution: Research alternative packages or consider pinning to a specific compatible version. Document any version constraints that limit future upgrades.

- How does the system handle platform-specific breaking changes (iOS vs Android)?
  - Resolution: Test on both platforms separately. Use platform-specific code updates where necessary (e.g., Swift code changes for iOS native modules).

- What happens when automated tests fail after the upgrade?
  - Resolution: Analyze test failures to determine if they're caused by breaking changes in the test framework, changes in application behavior, or legitimate bugs introduced during the upgrade. Update tests or fix code accordingly.

- How do we handle deprecation warnings that don't have clear migration paths?
  - Resolution: Research Flutter/Dart migration guides, check package changelogs, and consult community resources. If no solution exists, document the deprecation warning and monitor for future updates.

- What happens if the upgrade breaks third-party native modules (e.g., flutter_roomplan)?
  - Resolution: Check for updated versions of native plugins. If unavailable, review native code (Swift/Kotlin) for compatibility issues and apply necessary fixes or seek community support.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST update the Dart SDK constraint in pubspec.yaml from ^3.10.0 to ^3.8.1
- **FR-002**: System MUST update all dependencies in pubspec.yaml to versions compatible with Dart 3.8.1 and Flutter 3.32.4
- **FR-003**: System MUST resolve all version conflicts during dependency resolution
- **FR-004**: System MUST successfully compile the application for both iOS and Android platforms
- **FR-005**: System MUST identify all deprecated API usage in the codebase through static analysis
- **FR-006**: System MUST update all deprecated API calls to use current equivalents
- **FR-007**: System MUST update all code affected by breaking changes in Flutter 3.32.4 and Dart 3.8.1
- **FR-008**: System MUST update CLAUDE.md to reflect the new SDK versions (Dart 3.8.1, Flutter 3.32.4)
- **FR-009**: System MUST ensure all existing automated tests pass or are updated to accommodate non-breaking API changes
- **FR-010**: System MUST maintain backward compatibility with existing user data and app state
- **FR-011**: System MUST preserve all existing application functionality without regression
- **FR-012**: System MUST update any inline documentation or code comments that reference specific SDK versions

### Non-Functional Requirements

- **NFR-001**: The upgrade process SHOULD complete without requiring changes to the application's architecture
- **NFR-002**: Build times SHOULD NOT increase by more than 20% compared to the previous SDK version
- **NFR-003**: Application performance (startup time, memory usage, responsiveness) SHOULD remain the same or improve
- **NFR-004**: The upgrade SHOULD NOT introduce new compiler warnings (excluding deprecation warnings that will be addressed)

### Key Entities

- **SDK Configuration**: Represents the Dart SDK version constraint and Flutter SDK version used by the project
  - Current state: Dart ^3.10.0, Flutter 3.x
  - Target state: Dart ^3.8.1, Flutter 3.32.4

- **Dependency Package**: Represents each third-party package used by the application
  - Attributes: package name, current version, target version, compatibility status
  - Relationships: dependencies may have transitive dependencies that also require updates

- **Deprecated API Usage**: Represents locations in the codebase using deprecated Flutter or Dart APIs
  - Attributes: file path, line number, deprecated API name, recommended replacement
  - Relationships: may span multiple files and require coordinated updates

- **Breaking Change**: Represents incompatible changes between SDK versions
  - Attributes: affected API/feature, required code modification, impact scope
  - Relationships: may affect multiple features or modules

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Application builds successfully for both iOS and Android without compilation errors
- **SC-002**: All automated tests pass with a success rate of 100%
- **SC-003**: Static analysis (`flutter analyze`) completes with zero errors and zero deprecation warnings
- **SC-004**: Application startup time remains within 5% of the pre-upgrade baseline
- **SC-005**: Manual testing confirms all major features (authentication, project management, scanning, file operations) function correctly
- **SC-006**: Documentation accurately reflects the new SDK versions in all relevant files
- **SC-007**: Development team can build and run the application on local development environments using Flutter 3.32.4
- **SC-008**: No runtime crashes or exceptions occur during standard user workflows that were stable before the upgrade

## Assumptions *(optional)*

1. Flutter 3.32.4 is a stable release available through the official Flutter channel
2. All currently used dependencies have versions compatible with Dart 3.8.1
3. The development team has access to Flutter version management tools (e.g., fvm, asdf) to switch between SDK versions
4. Test devices and emulators are available for both iOS and Android platforms
5. The codebase does not rely on undocumented or experimental Flutter APIs that may have changed
6. Breaking changes in Flutter 3.32.4 are documented in the official Flutter release notes
7. The CI/CD pipeline can be updated to use Flutter 3.32.4 for builds

## Dependencies *(optional)*

- Official Flutter SDK 3.32.4 must be available and downloadable
- Flutter migration guides and changelog documentation for version 3.32.4
- Updated versions of all dependencies must be available on pub.dev
- Access to platform-specific development tools:
  - Xcode (with compatible iOS SDK) for iOS builds
  - Android Studio (with compatible Android SDK) for Android builds
- Existing test coverage to validate that functionality remains intact after upgrade

## Out of Scope *(optional)*

- Adding new features or functionality beyond what currently exists
- Refactoring code that works correctly but doesn't follow current best practices (unless required by breaking changes)
- Updating UI designs or user experience improvements
- Performance optimizations beyond maintaining current performance levels
- Upgrading dependencies beyond what's necessary for Flutter 3.32.4 compatibility
- Adding new tests (only updating existing tests to accommodate API changes)
- Updating CI/CD pipeline configurations (will be handled separately if needed)
- Migrating to new Flutter features or APIs that aren't required by deprecations or breaking changes
