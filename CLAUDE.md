# vronmobile2 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-21

## Active Technologies

- Dart 3.10+ / Flutter 3.10+
- GraphQL (gql, gql_http_link, gql_exec)
- Internationalization (i18n with JSON translation files)
- Secure Storage (flutter_secure_storage)
- Shared Preferences (shared_preferences)

## Project Structure

```text
lib/
  core/
    i18n/                    # Internationalization service and translations
      i18n_service.dart      # i18n service with ChangeNotifier
      en.json, de.json, pt.json  # Translation files
    services/
      graphql_service.dart   # GraphQL client configuration
  features/
    home/
      models/                # Project model
      services/              # ProjectService for GraphQL operations
    project_detail/          # Feature 010: Project detail view
      screens/
      widgets/
    project_data/            # Feature 011: Project data edit screen
      screens/
        project_data_screen.dart
      widgets/
        project_form.dart
        save_button.dart
test/
  features/                  # Feature tests
  unit/                      # Unit tests
  helpers/
    test_helper.dart         # Test utilities (i18n initialization)
```

## Commands

```bash
# Run all tests
flutter test

# Run specific feature tests
flutter test test/features/project_data/

# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Run app
flutter run
```

## Features Implemented

### Feature 010: Project Detail Screen
- **Status**: Complete (31/31 tasks)
- **Purpose**: Display comprehensive project information
- **Key Components**:
  - ProjectDetailScreen with FutureBuilder pattern
  - ProjectHeader, ProjectInfoSection, ProjectActionButtons widgets
  - GraphQL integration for fetching project details
  - Pull-to-refresh support
  - Error handling with retry logic

### Feature 011: Project Data Edit Screen
- **Status**: Complete (55/55 tasks)
- **Purpose**: Allow users to edit project name and description
- **Key Components**:
  - ProjectDataScreen with form validation
  - ProjectForm with name (required, 3-100 chars) and description (optional, max 500 chars)
  - SaveButton with loading state
  - Unsaved changes detection with confirmation dialog
  - GraphQL mutation for updating project data
- **Navigation**: ProjectDetailScreen → ProjectDataScreen (edit) → returns with refresh
- **Testing**: TDD approach with widget tests and unit tests
- **Accessibility**: Full semantic labels on all interactive elements

## Code Style

### Flutter/Dart Conventions
- Follow official Dart style guide
- Use `dart format` for consistent formatting
- Prefer `const` constructors where possible
- Use meaningful variable names
- Add documentation comments (`///`) for public APIs

### Testing Approach (TDD)
1. Write tests FIRST (widget tests, unit tests)
2. Ensure tests FAIL before implementation
3. Implement features to make tests pass
4. Verify all tests pass before marking complete

### Internationalization (i18n)
- All user-facing strings MUST use `.tr()` extension
- Translation keys use dot notation: `feature.section.key`
- Example: `'projectData.saveButton'.tr()`
- Translations in: `lib/core/i18n/{en,de,pt}.json`
- Initialize i18n in tests: `await initializeI18nForTest()`

### State Management
- Use StatefulWidget for local UI state
- Use ChangeNotifier for services (e.g., I18nService)
- TextEditingController for form inputs (dispose properly)
- FutureBuilder for async data loading

### Navigation
- Named routes in `lib/main.dart`
- Pass arguments via `ModalRoute.of(context).settings.arguments`
- Return values via `Navigator.pop(result)`
- Example: `Navigator.pushNamed(context, '/project-data', arguments: {...})`

### Accessibility
- Wrap interactive elements with `Semantics` widget
- Provide `label`, `hint`, `button`, and `enabled` properties
- Ensure touch targets are at least 44x44 pixels
- Test with screen reader (TalkBack/VoiceOver)

## Recent Changes

- 010-project-detail: Complete project detail view with GraphQL integration
- 011-project-data: Complete project edit screen with validation and i18n
- Added i18n service with EN/DE/PT translations
- Added test helper for i18n initialization in tests
- Added semantic labels for full accessibility support

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
