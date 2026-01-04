# Testing Quick Reference - Main Screen Feature
# neu
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && flutter run -d 00008140-0005185602DB001C --debug
now ok 
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer && flutter run -d 00008140-0005185602DB001C --debug
# 16.4
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer
xcodebuild -version


Solution: Use Xcode IDE for flutter run equivalent

  Since flutter run from command line won't work with your dual Xcode setup (error -10664), you should run directly from Xcode IDE:

  1. Open the project in Xcode 16.4:
  xcode16
  2. In Xcode:
    - Select your iPhone device from the device dropdown (top bar)
    - Click the "Play" button (or Product → Run)
    - This gives you full debugging support with hot reload!
  3. To stop the app:
    - Click the "Stop" button in Xcode

  This approach gives you everything flutter run --debug would give you:
  - Hot reload (type r in terminal or ⌘\ in Xcode)
  - Full debugging with breakpoints
  - Flutter DevTools integration
  - Console output

  Alternative: Quick deploy without debugging

  For quick deployments without debugging, use your existing script:
  ./ios_deploy.sh

  Would you like me to document these approaches or help you set up Xcode for optimal Flutter development?

## ✅ Current Status
- **All 74 tests passing** (66 original + 8 auth service tests)
- **Real GraphQL authentication implemented**
- **Phases 1-4 complete + Real Authentication**, Phase 6 remaining
## ---
 ios-deploy

  This script will:
  1. Build your Flutter app
  2. Build with Xcode 16.4
  3. Install on your device
  4. Launch the app

  ---
  To Fix the Permission Issue Permanently:

  The error says: "You may be prompted to give access to control Xcode."

  Steps:

  1. Try running flutter run again - it should prompt you for permission
  2. If no prompt appears, manually grant permission:
    - Open System Settings
    - Go to Privacy & Security → Automation
    - Find your Terminal app (Terminal, iTerm, or whatever you use)
    - Enable the checkbox for Xcode.app
  3. If Xcode isn't listed under Terminal, you may need to:
  sudo tccutil reset AppleEvents
  3. Then try flutter run again to trigger the permission prompt

  ---
  Your Options:

  | Method                                 | Hot Reload | Debugging | Command                              |
  |----------------------------------------|------------|-----------|--------------------------------------|
  | Deploy Script                          | ❌         | ❌        | ios-deploy                           |
  | Release Mode                           | ❌         | ❌        | flutter run --release -d 00008140... |
  | Flutter Run (after fixing permissions) | ✅         | ✅        | flutter run -d 00008140...           |
  | Simulator                              | ✅         | ✅        | flutter run -d 351D64FB              |

## 🚀 Quick Commands
flutter devices
 xcrun simctl list devices | grep -A 2 "351D64FB-8160-40B2-AB60-1066C28C84BF"
flutter run -d 351D64FB-8160-40B2-AB60-1066C28C84BF

flutter devices

xcrun simctl list devices | grep "iPhone 16 Pro"

xcrun simctl shutdown 351D64FB-8160-40B2-AB60-1066C28C84BF

Would you like me to add an alias to quickly launch this simulator? For example:
alias sim16pro='xcrun simctl boot 351D64FB-8160-40B2-AB60-1066C28C84BF && open -a Simulator'

xcrun devicectl device install app --device 00008140-0005185602DB001C /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2/build/ios/iphoneos/Runner.…
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

## 2026.01.04 
To launch the app:

  On your iPhone:
  - Open the app from your home screen (look for "Runner" or your app name)
  - If you see "Untrusted Developer", go to Settings > General > VPN & Device Management and trust your developer profile

  Or from command line:
  xcrun devicectl device process launch --device 00008140-0005185602DB001C com.vron.vronmobile2

  ---
  For future builds:

  The -10664 Xcode error prevents flutter run from working. Instead, use this workflow:

  # Build with xcodebuild
  cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2/ios
  /Applications/Xcode-16.4.app/Contents/Developer/usr/bin/xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Debug \
    -destination 'id=00008140-0005185602DB001C' \
    -allowProvisioningUpdates

  # Install the app
  xcrun devicectl device install app \
    --device 00008140-0005185602DB001C \
    ../build/ios/iphoneos/Runner.app

  Or create an alias for this workflow!


# ------
You're right - flutter run doesn't work with Xcode 16.4 because of the -10664 error when trying to open the GUI app. This is the dual Xcode installation issue.

  However, I noticed the earlier background process did work - that was using Xcode 26.2. The key difference:

  - Xcode 26.2 (/Applications/Xcode.app) - flutter run ✅ WORKS
  - Xcode 16.4 (/Applications/Xcode-16.4.app) - flutter run ❌ FAILS (-10664 error)

  Solution: Use the right Xcode for each task

  For flutter run --debug (interactive development with hot reload):

  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  flutter run -d 00008140-0005185602DB001C --debug
  This works because Xcode 26.2's GUI app can be opened by the open command.

  For build scripts (ios_deploy.sh):

  Keep using Xcode 16.4 - it works fine for command-line builds:
  ./ios_deploy.sh  # Uses Xcode 16.4

  Would you like me to:
  1. Create a wrapper script that sets the correct Xcode version for flutter run?
  2. Or update everything to use Xcode 26.2 (which supports both flutter run and builds)?

  Which Xcode version do you prefer for your Flutter development?

# ---
