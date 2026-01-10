# Quickstart: Main Screen (Not Logged-In)

**Feature**: 001-main-screen-login
**Date**: 2025-12-20
**Purpose**: Get this feature running locally for development and testing

## Prerequisites

- Flutter SDK 3.10+ installed ([installation guide](https://docs.flutter.dev/get-started/install))
- Dart 3.10+
- iOS Simulator (for iOS development) or Android Emulator
- VS Code with Flutter extension OR Android Studio
- Git (to checkout feature branch)

## Setup Steps

### 1. Checkout Feature Branch

```bash
cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2
git checkout 001-main-screen-login
```

### 2. Install Dependencies

```bash
flutter pub get
```

This will install:
- `flutter_test` (included in SDK)
- `url_launcher` (for opening password reset URL)

### 3. Verify Flutter Setup

```bash
flutter doctor
```

Ensure iOS/Android toolchain is installed. Fix any issues shown.

### 4. Run Tests (TDD - Start Here!)

**Important**: Following constitution's Test-First principle, tests are written BEFORE implementation.

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/screens/main_screen_test.dart

# Run with coverage
flutter test --coverage
```

**Expected**: Tests should FAIL initially (Red phase of TDD). This confirms tests are working and feature is not yet implemented.

### 5. Run App

```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Specific device
flutter devices  # list available devices
flutter run -d <device-id>
```

**Expected**: App launches, but main screen is not yet implemented (placeholder or error). This is normal at start of development.

### 6. Hot Reload During Development

While app is running:
- Press `r` to hot reload (fast, preserves state)
- Press `R` to hot restart (full restart)
- Press `q` to quit

---

## File Structure

Key files for this feature:

```
lib/features/auth/
├── screens/
│   └── main_screen.dart         # Main screen widget (START HERE)
├── widgets/
│   ├── email_input.dart         # Email TextField
│   ├── password_input.dart      # Password TextField
│   ├── sign_in_button.dart      # Primary button
│   ├── oauth_button.dart        # Google/Facebook buttons
│   └── text_link.dart           # Links (Forgot Password, etc.)
└── utils/
    └── email_validator.dart     # Validation logic

test/features/auth/
├── screens/
│   └── main_screen_test.dart    # Screen widget tests (WRITE FIRST)
├── widgets/
│   ├── email_input_test.dart    # Email widget tests
│   ├── password_input_test.dart # Password widget tests
│   └── sign_in_button_test.dart # Button widget tests
└── utils/
    └── email_validator_test.dart # Validation tests (WRITE FIRST)
```

---

## Development Workflow (TDD)

### Phase 1: Email Validator (Unit Tests)

1. **Red**: Write failing test in `test/features/auth/utils/email_validator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/utils/email_validator.dart';

void main() {
  group('EmailValidator', () {
    test('returns error for empty email', () {
      final result = EmailValidator.validate('');
      expect(result, 'Email is required');
    });

    test('returns error for invalid email format', () {
      final result = EmailValidator.validate('notanemail');
      expect(result, 'Invalid email format');
    });

    test('returns null for valid email', () {
      final result = EmailValidator.validate('user@example.com');
      expect(result, isNull);
    });
  });
}
```

2. **Red**: Run test, confirm failure

```bash
flutter test test/features/auth/utils/email_validator_test.dart
```

3. **Green**: Implement minimal code in `lib/features/auth/utils/email_validator.dart`

```dart
class EmailValidator {
  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }
}
```

4. **Green**: Run test, confirm pass
5. **Refactor**: Improve code quality if needed

### Phase 2: Email Input Widget (Widget Tests)

1. **Red**: Write widget test
2. **Red**: Run test, confirm failure
3. **Green**: Implement widget
4. **Green**: Run test, confirm pass
5. **Refactor**: Improve

### Phase 3: Main Screen (Integration Tests)

1. **Red**: Write integration test for full screen
2. **Red**: Run test, confirm failure
3. **Green**: Compose screen from widgets
4. **Green**: Run test, confirm pass
5. **Refactor**: Improve

---

## Running Specific Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/features/auth/utils/email_validator_test.dart

# Specific test by name
flutter test --name "returns error for empty email"

# With verbose output
flutter test --verbose

# Watch mode (re-run on file changes)
# (requires entr or similar tool)
ls test/**/*.dart | entr flutter test
```

---

## Debugging

### VS Code

1. Set breakpoints in Dart code
2. Press F5 or "Run > Start Debugging"
3. Select device (iOS/Android)
4. App runs in debug mode

### Flutter DevTools

```bash
# Run app
flutter run

# Open DevTools (URL printed in console)
# Or visit: http://127.0.0.1:9100
```

DevTools provides:
- Widget inspector
- Performance profiler
- Memory profiler
- Network inspector

---

## Common Issues

### 1. "Flutter SDK not found"

```bash
export PATH="$PATH:`which flutter`"
# Add to ~/.zshrc or ~/.bashrc
```

### 2. "No devices available"

```bash
# Start iOS Simulator
open -a Simulator

# Start Android Emulator
emulator -avd <avd-name>
```

### 3. "pub get failed"

```bash
flutter clean
flutter pub get
```

### 4. Tests not finding imports

```bash
# Ensure you're in project root
cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2
flutter pub get
```

---

## Viewing Figma Design

The visual design is the source of truth for UI implementation:

**Figma Link**: [Main Screen Design](https://www.figma.com/design/yLDwcYYxrZKf2u59TO8FjO/vron?node-id=1-34)

Extract from Figma:
- Colors (exact hex codes)
- Typography (font sizes, weights)
- Spacing (padding, margins)
- Component dimensions
- Assets (logos, icons)

---

## Next Steps After This Feature

Once 001-main-screen-login is complete and all tests pass:

1. Merge to main branch
2. Move to UC2: Email & Password Authentication (`026-email-password-auth`)
3. Or move to UC6: Create Account (`027-create-account`)
4. Or move to UC7: Guest Mode (`007-guest-mode`)

Dependencies from spec:
- This feature BLOCKS: UC2, UC3, UC4, UC5, UC6, UC7

---

## Success Criteria

Feature is complete when:

- ✅ All widget tests pass
- ✅ All integration tests pass
- ✅ Screen matches Figma design pixel-perfect
- ✅ Email validation works (valid/invalid cases)
- ✅ Navigation buttons trigger correct flows (even if stub implementations)
- ✅ Accessibility: Semantic labels present, touch targets 44x44+
- ✅ Performance: Loads within 1 second, 60fps
- ✅ Keyboard handling: Doesn't obscure inputs, can be dismissed
- ✅ No linting errors: `flutter analyze` passes
- ✅ Code formatted: `flutter format .` makes no changes

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [Flutter Testing Guide](https://docs.flutter.dev/cookbook/testing)
- [Material Design Guidelines](https://m3.material.io/)
