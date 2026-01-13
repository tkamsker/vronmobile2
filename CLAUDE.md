# vronmobile2 Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-13

## Active Technologies
- Backend GraphQL API (PostgreSQL), local caching via shared_preferences (003-projectdetail)
- Session-only state management using StatefulWidget or Provider (no persistence across app restarts) (025-product-search)
- Dart 3.8.1 / Flutter 3.32.4, Swift 5.x (iOS native code for USDZ combination) (018-combined-scan-navmesh)

- Dart 3.8.1 / Flutter 3.32.4 (matches pubspec.yaml SDK constraint ^3.8.1) (001-main-screen-login)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.8.1 / Flutter 3.32.4 (matches pubspec.yaml SDK constraint ^3.8.1)

## Code Style

Dart 3.8.1 / Flutter 3.32.4 (matches pubspec.yaml SDK constraint ^3.8.1): Follow standard conventions

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
- 028-flutter-upgrade: Upgraded to Flutter 3.32.4 and Dart 3.8.1 (from Flutter 3.x / Dart 3.10.0)
- 018-combined-scan-navmesh: Added Dart 3.8.1 / Flutter 3.32.4, Swift 5.x (iOS native code for USDZ combination)
- 016-multi-room-options: Added Dart 3.8.1 / Flutter 3.32.4 (matches pubspec.yaml SDK constraint ^3.8.1)
- 014-lidar-scanning: Added Dart 3.8.1 / Flutter 3.32.4 (matches pubspec.yaml SDK constraint ^3.8.1)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
