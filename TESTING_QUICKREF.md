# Testing Quick Reference - Main Screen Feature

## ✅ Current Status
- **All 74 tests passing** (66 original + 8 auth service tests)
- **Real GraphQL authentication implemented**
- **Phases 1-4 complete + Real Authentication**, Phase 6 remaining

## 🚀 Quick Commands

### Run Tests
```bash
# All tests
flutter test

# Specific suite
flutter test test/features/auth/widgets/

# Single test
flutter test --name "displays all UI elements"

# With coverage
flutter test --coverage
```

### Launch App
```bash
# iOS Simulator (recommended for development)
flutter run -d 19EA67E6-6120-45A9-8D83-1A007D0306AA

# Physical iPhone (Thomas's device)
flutter run -d 00008140-0005185602DB001C

# macOS desktop
flutter run -d macos

# Chrome web
flutter run -d chrome
```

### While App is Running
- `r` - Hot reload (fast, preserves state)
- `R` - Hot restart (full restart)
- `p` - Show widget inspector overlay
- `q` - Quit

## 📊 Test Breakdown

### Unit Tests (11)
- ✓ EmailValidator: 11 test cases

### Service Tests (8)
- ✓ AuthService: 8 test cases (login, logout, isAuthenticated)

### Widget Tests (49)
- ✓ EmailInput: 7 tests
- ✓ PasswordInput: 8 tests
- ✓ SignInButton: 8 tests
- ✓ OAuthButton: 9 tests
- ✓ TextLink: 8 tests
- ✓ MainScreen: 10 tests

### Integration Tests (6)
- ✓ Sign In flow
- ✓ Google OAuth trigger
- ✓ Facebook OAuth trigger
- ✓ Forgot Password URL
- ✓ Create Account navigation
- ✓ Guest Mode navigation

## 🧪 Manual Test Checklist

### Quick Smoke Test (2 minutes)
1. ✓ App launches to main screen
2. ✓ All UI elements visible
3. ✓ Email validation works (try "invalid" then "user@test.com")
4. ✓ Password toggle shows/hides text
5. ✓ Tap "Create Account" → navigates
6. ✓ Tap back, scroll down, tap "Continue as Guest" → navigates

### Full Test (10 minutes)
See test_guide.md for complete scenarios

## 🐛 Troubleshooting

### Tests Failing?
```bash
flutter clean
flutter pub get
flutter test
```

### App Won't Launch?
```bash
# Check Flutter installation
flutter doctor -v

# Open iOS Simulator
open -a Simulator

# List devices again
flutter devices
```

### Simulator Issues?
```bash
# Reset iOS Simulator
xcrun simctl erase all

# Or open Simulator app manually
# Device → Erase All Content and Settings
```

## 📝 What's Implemented

### ✅ Working Features
- Email/password input with validation
- Password visibility toggle
- Sign In button (disabled until form valid)
- **Real email/password authentication with GraphQL (UC2)**
- **Secure token storage (iOS Keychain)**
- **Environment configuration from .env file**
- Google/Facebook OAuth buttons (show loading - UC3/UC4 not yet implemented)
- Forgot Password (opens browser)
- Create Account navigation
- Guest Mode navigation
- Error handling with user-friendly messages
- Accessibility labels
- Touch target sizes (44x44)

### ⏳ Not Yet Implemented
- Google OAuth integration (UC3)
- Facebook OAuth integration (UC4)
- Password reset backend (UC5)
- Create account form (UC6)
- Guest mode functionality (UC7/UC14)
- Home screen after successful login

## 🎯 Success Criteria Met
✓ All UI elements visible and accessible
✓ Email validation (RFC 5322 pattern)
✓ Form validation state management
✓ Navigation to all flows works
✓ Loading states show feedback
✓ Error handling with user-friendly messages
✓ WCAG 2.1 Level AA accessibility
✓ Responsive layout (SafeArea + scroll)

## 📦 File Locations

### Implementation
```
lib/features/auth/
├── screens/main_screen.dart
├── services/auth_service.dart
├── widgets/
│   ├── email_input.dart
│   ├── password_input.dart
│   ├── sign_in_button.dart
│   ├── oauth_button.dart
│   └── text_link.dart
└── utils/email_validator.dart

lib/core/
├── config/env_config.dart
├── services/
│   ├── graphql_service.dart
│   └── token_storage.dart
├── theme/app_theme.dart
├── navigation/routes.dart
└── constants/app_strings.dart
```

### Tests
```
test/features/auth/
├── services/auth_service_test.dart
├── utils/email_validator_test.dart
├── widgets/ (5 test files)
└── screens/main_screen_test.dart

test/integration/
└── auth_flow_test.dart
```

## 🔍 Viewing Test Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📚 Documentation
- `test_guide.md` - Comprehensive testing guide
- `specs/001-main-screen-login/quickstart.md` - Development setup
- `specs/001-main-screen-login/tasks.md` - Task breakdown
