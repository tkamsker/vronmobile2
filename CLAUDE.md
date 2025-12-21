# vronmobile2 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-12-20

## Active Technologies
- Backend GraphQL API (PostgreSQL), local caching via shared_preferences (003-projectdetail)

- Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0) (001-main-screen-login)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)

## Code Style

Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0): Follow standard conventions

## Patterns and Best Practices

### Accessibility
- **ALWAYS use Semantics widgets** for interactive elements (buttons, images, tabs)
- Provide `label` and `hint` properties for screen reader support
- Use `button: true` for button elements
- Use `header: true` for heading/title elements
- Use `image: true` for images with descriptive labels
- Test with TalkBack (Android) / VoiceOver (iOS) for screen reader compatibility

### Navigation and State Management
- **PopScope over WillPopScope**: Use `PopScope` with `canPop` and `onPopInvokedWithResult` for handling back navigation
- Example: Unsaved changes warning in forms
  ```dart
  PopScope(
    canPop: !_isDirty,
    onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
    child: ...
  )
  ```

### GraphQL API Integration
- Use `GraphQLService` for all API calls
- Service layer pattern: `lib/features/[feature]/services/[feature]_service.dart`
- Handle exceptions and provide user-friendly error messages
- Backend note: Projects are implemented as Products in the backend

### Color Usage
- **Use withValues() not withOpacity()**: `Colors.black.withValues(alpha: 0.1)` for opacity
- Ensures precision and avoids deprecation warnings

### Feature-Based Architecture
- Organize by feature: `lib/features/[feature]/{models,screens,widgets,utils,services}`
- Keep feature code self-contained
- Share common code via `lib/core/`

## Recent Changes
- 003-projectdetail: Added comprehensive Semantics labels for accessibility
- 003-projectdetail: Migrated to PopScope from deprecated WillPopScope
- 003-projectdetail: Updated color opacity API to withValues()
- 003-projectdetail: Implemented project detail viewing and editing (Phase 1-5, 7 complete)
- 003-projectdetail: Added Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)

- 001-main-screen-login: Added Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
