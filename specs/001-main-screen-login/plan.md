# Implementation Plan: Main Screen (Not Logged-In)

**Branch**: `001-main-screen-login` | **Date**: 2025-12-20 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-main-screen-login/spec.md`

## Summary

Implement the main authentication screen for non-logged-in users. This screen serves as the entry point to the app, presenting email/password input fields and buttons for Sign In, Google OAuth, Facebook OAuth, along with links to Forgot Password, Create Account, and Guest Mode. The screen must match Figma design specifications, validate inputs, provide accessibility support, and maintain 60fps performance while handling navigation to various authentication flows.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
- Flutter SDK (UI framework)
- flutter_test (widget & integration testing)
- url_launcher (for opening password reset URL in browser)
- Internationalization packages (for de/en/pt support)

**Storage**: N/A (this screen only handles UI - no local data storage)

**Testing**:
- Widget tests for UI components using flutter_test
- Integration tests for navigation flows
- Accessibility tests using Flutter semantic tree

**Target Platform**: iOS 15.0+ (per spec assumptions)

**Project Type**: Mobile (Flutter cross-platform, but spec indicates iOS focus)

**Performance Goals**:
- Screen loads within 1 second
- Maintains 60fps (16ms frame budget) for animations
- Input validation feedback within 300ms

**Constraints**:
- Touch targets minimum 44x44 logical pixels (accessibility)
- Must work on iPhone SE and larger without scrolling
- Keyboard must not obscure UI elements
- WCAG 2.1 Level AA compliance for accessibility

**Scale/Scope**: Single screen with 8 interactive elements (2 input fields, 3 buttons, 3 links)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)

**Status**: ✅ **PASS** - Plan enforces TDD

- Widget tests will be written FIRST for all UI components before implementation
- Integration tests for navigation flows will be written before routing logic
- All tests must fail initially to demonstrate feature gap
- Red-Green-Refactor cycle will be followed strictly

### II. Simplicity & YAGNI

**Status**: ✅ **PASS** - Simple, focused implementation

- Uses Flutter's built-in widgets (TextFormField, ElevatedButton, TextButton)
- No custom frameworks or unnecessary abstractions
- Email validation uses standard regex, not custom library
- Navigation handled by Flutter's Navigator (no routing packages yet)
- No state management library needed - screen is stateless with form validation only

### III. Platform-Native Patterns

**Status**: ✅ **PASS** - Follows Flutter best practices

- Uses Material Design widgets (primary target is iOS but Material is acceptable for auth screens)
- Can add Cupertino widgets later if iOS-specific feel is required
- Widget composition pattern (not inheritance)
- Feature-based file structure: `lib/features/auth/screens/main_screen.dart`

### Security & Privacy Requirements

**Status**: ✅ **PASS** - No sensitive data handled on this screen

- No credential storage (delegated to UC2)
- Input validation prevents injection attacks
- OAuth flows delegated to dedicated features (UC3, UC4)

### Performance Standards

**Status**: ✅ **PASS** - Performance targets achievable

- Simple static UI loads instantly
- No heavy computations or network calls on this screen
- Keyboard handling uses Flutter's built-in resizing

### Accessibility Requirements

**Status**: ✅ **PASS** - Full accessibility support planned

- Semantic labels for all interactive widgets
- Touch targets will be 44x44 minimum
- Screen reader testing using Flutter's semantic tree
- Keyboard dismissal supported

### CI/CD & DevOps Practices

**Status**: ✅ **PASS** - Follows branch and testing strategy

- Feature branch: `001-main-screen-login`
- Tests run before merge
- Commits atomic per task

**OVERALL**: ✅ **ALL GATES PASS** - No violations, no complexity justification needed

## Project Structure

### Documentation (this feature)

```text
specs/001-main-screen-login/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A for this feature - no API contracts)
└── checklists/
    └── requirements.md  # Already exists
```

### Source Code (repository root)

This is a Flutter mobile app with standard structure:

```text
lib/
├── features/
│   └── auth/
│       ├── screens/
│       │   └── main_screen.dart           # Main authentication screen widget
│       ├── widgets/
│       │   ├── email_input.dart           # Email TextField widget
│       │   ├── password_input.dart        # Password TextField widget
│       │   ├── sign_in_button.dart        # Primary action button
│       │   ├── oauth_button.dart          # Google/Facebook button
│       │   └── text_link.dart             # Forgot Password/Create Account/Guest links
│       └── utils/
│           └── email_validator.dart       # Email validation logic
│
├── core/
│   ├── constants/
│   │   └── app_strings.dart              # i18n string keys
│   ├── theme/
│   │   └── app_theme.dart                # Colors, typography per Figma
│   └── navigation/
│       └── routes.dart                    # Route definitions
│
└── main.dart                              # App entry point

test/
├── features/
│   └── auth/
│       ├── screens/
│       │   └── main_screen_test.dart      # Widget tests for screen
│       ├── widgets/
│       │   ├── email_input_test.dart      # Email input widget tests
│       │   ├── password_input_test.dart   # Password input widget tests
│       │   └── sign_in_button_test.dart   # Button widget tests
│       └── utils/
│           └── email_validator_test.dart  # Validation logic tests
│
└── integration/
    └── auth_flow_test.dart                # Integration test for navigation

```

**Structure Decision**: Flutter follows a feature-based organization. The `features/auth/` directory contains all authentication-related code. Core app infrastructure (theme, navigation, constants) lives in `core/`. This structure supports the constitution's Platform-Native Patterns principle and enables independent feature development.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - table empty.
