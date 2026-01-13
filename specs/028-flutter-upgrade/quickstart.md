# Flutter 3.32.4 Upgrade Quickstart

**Feature**: 028-flutter-upgrade
**Target**: Flutter 3.32.4 + Dart 3.8.1
**Current**: Flutter 3.x + Dart 3.10.0
**Date**: 2026-01-13

## Important Note

⚠️ **This upgrade involves a Dart SDK downgrade** from 3.10.0 to 3.8.1. Verify this is intentional before proceeding. See [research.md](./research.md#71-sdk-downgrade-clarification) for details.

---

## Pre-Upgrade Checklist

Complete these steps before making any changes:

- [ ] Confirm target versions with team: Flutter 3.32.4 + Dart 3.8.1
- [ ] All current tests passing (`flutter test`)
- [ ] Current app builds successfully on iOS (`flutter build ios`)
- [ ] Current app builds successfully on Android (`flutter build apk`)
- [ ] Baseline performance metrics captured (see "Capture Baseline Metrics" below)
- [ ] Git branch `028-flutter-upgrade` created and checked out
- [ ] Xcode 15.0+ installed and verified (`xcode-select --version`)
- [ ] Java 17+ installed and verified (`java -version`)
- [ ] Current deprecation warnings documented (`flutter analyze > analyze_before.txt`)
- [ ] Backup of current working state committed to Git

###Capture Baseline Metrics

Before upgrading, capture performance baselines:

```bash
# 1. Cold start time
# - Force quit app, then launch and time until home screen visible
# - Record time manually or use Flutter DevTools Timeline

# 2. Build times
time flutter build apk --release
time flutter build ios --release

# 3. Hot reload time
flutter run
# Make a trivial change, then:
# time hot reload (r key)

# 4. Memory usage
# Use Flutter DevTools Memory tab while running app
# Navigate through major features, record peak memory

# 5. Analyze output
flutter analyze > analyze_before.txt
wc -l analyze_before.txt  # Count warnings/errors
```

Store these metrics for post-upgrade comparison.

---

## Upgrade Steps

Follow these steps sequentially. Do not skip steps.

### Step 1: Verify Environment

Ensure your development environment meets requirements:

```bash
# 1. Check Xcode version (should be 15.0+)
xcode-select --version

# 2. Check Java version (should be 17+)
java -version

# 3. Verify current Flutter version
flutter --version

# 4. Verify you're on feature branch
git branch --show-current  # Should show: 028-flutter-upgrade
```

**If any checks fail**, resolve before continuing.

---

### Step 2: Install Flutter 3.32.4

Choose one method:

**Method A: Using Flutter Version Management (fvm)**

```bash
# Install fvm if not already installed
dart pub global activate fvm

# Install Flutter 3.32.4
fvm install 3.32.4

# Use Flutter 3.32.4 for this project
fvm use 3.32.4

# Verify
fvm flutter --version  # Should show 3.32.4 and Dart 3.8.x
```

**Method B: Using Flutter CLI**

```bash
# Switch to stable channel
flutter channel stable

# Upgrade to latest stable (should be 3.32.4 or higher)
flutter upgrade

# OR: Downgrade/switch to specific version
flutter version 3.32.4

# Verify
flutter --version  # Should show Flutter 3.32.4, Dart 3.8.1
```

**Method C: Using ASDF**

```bash
# Install specific version
asdf install flutter 3.32.4-stable

# Set project-local version
asdf local flutter 3.32.4-stable

# Verify
flutter --version
```

**Post-Install Verification**:

```bash
flutter doctor -v
# Resolve any issues shown before continuing
```

---

### Step 3: Update pubspec.yaml

Update SDK constraints and dependencies:

```yaml
# pubspec.yaml

environment:
  sdk: ^3.8.1  # Changed from: ^3.10.0

dependencies:
  # Core Flutter
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # Network & GraphQL
  graphql_flutter: ^5.2.0  # Updated from ^5.1.0 (optional, for latest features)
  http: ^1.2.2

  # Storage
  flutter_secure_storage: ^10.0.0  # Already compatible
  shared_preferences: ^2.3.2
  path_provider: ^2.1.5

  # Authentication
  google_sign_in: ^7.0.0  # Already compatible

  # Native features
  flutter_roomplan: ^1.0.7  # Pin initially, test early

  # UI & Assets
  cached_network_image: ^3.3.0
  model_viewer_plus: ^1.10.0
  flutter_dotenv: ^6.0.0

  # Utilities
  intl: ^0.20.0
  uuid: ^4.5.1
  file_picker: ^10.3.8
  share_plus: ^12.0.1
  device_info_plus: ^12.0.0
  archive: ^4.0.0
  vector_math: ^2.1.4
  path_parsing: ^1.0.1
  flutter_json_view: ^1.1.4
  package_info_plus: ^8.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Testing
  mocktail: ^1.0.0
  mockito: ^5.4.2
  build_runner: ^2.4.6
  json_serializable: ^6.7.1

  # Tools
  flutter_launcher_icons: ^0.14.3
  integration_test:
    sdk: flutter
  webview_flutter_platform_interface: ^2.14.0
```

**Then run**:

```bash
# Get dependencies with new SDK
flutter pub get

# Expected: All dependencies resolve successfully
# If version conflicts occur, see Troubleshooting section below
```

---

### Step 4: Update iOS Configuration

Update iOS deployment target and settings:

#### 4.1 Update Podfile

```bash
# Edit: ios/Podfile

# Line 1 or near top, change to:
platform :ios, '13.0'

# Save file
```

#### 4.2 Update Xcode Project

```bash
# Option A: Via Xcode GUI
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" project in navigator
# 2. Select "Runner" target
# 3. In "General" tab → "Deployment Info"
# 4. Set "iOS Deployment Target" to 13.0
# 5. Build Settings → Search "deployment target"
# 6. Set iOS Deployment Target to 13.0 for all configurations
# 7. Close Xcode

# Option B: Via command line (pbxproj file)
# (Advanced: edit ios/Runner.xcodeproj/project.pbxproj)
# Find IPHONEOS_DEPLOYMENT_TARGET and change to 13.0
```

#### 4.3 Clean and Reinstall Pods

```bash
cd ios
pod deintegrate
rm Podfile.lock
pod install
cd ..
```

---

### Step 5: Update Android Configuration

Verify Android build configuration:

#### 5.1 Check Java Version

```bash
# Must be Java 17+ (required for graphql_flutter)
java -version

# If not Java 17+:
# - Update Android Studio JDK settings
# - Or: install Java 17 via Homebrew, SDKMAN, etc.
```

#### 5.2 Verify Gradle Configuration

```bash
# Check: android/gradle/wrapper/gradle-wrapper.properties
# Should have Gradle 8.0+ (no changes needed unless errors occur)

# Check: android/build.gradle
# Should have AGP 8.1.0+ (no changes needed unless errors occur)
```

**Note**: Gradle configuration changes are NOT required for this upgrade unless build errors occur. Only update if troubleshooting.

---

### Step 6: Update Formatter Settings

Decide on formatter strategy:

**Option A: Adopt New Dart 3.8 Formatter Style** (Recommended)

```bash
# Simply run formatter after upgrade
dart format .

# Review changes, then commit separately:
git add -A
git commit -m "chore: apply Dart 3.8 formatter changes

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Option B: Preserve Old Formatter Style**

```yaml
# Edit: analysis_options.yaml

# Add this section:
formatter:
  trailing_commas: preserve
```

```bash
# Then run formatter
dart format .
```

**Recommendation**: Choose Option A (adopt new style) for future compatibility.

---

### Step 7: Fix Breaking Changes

#### 7.1 Run Flutter Analyze

```bash
flutter analyze > analyze_after.txt

# Compare before/after
diff analyze_before.txt analyze_after.txt

# Review all new errors/warnings
```

#### 7.2 Fix Theme Data Issues

Search for theme configuration:

```bash
grep -r "ThemeData(" lib/
```

Ensure theme properties use typed data classes:

```dart
// OLD (may cause errors):
ThemeData(
  cardTheme: CardTheme(  // Missing 'Data'
    elevation: 2.0,
  ),
)

// NEW (correct):
ThemeData(
  cardTheme: CardThemeData(  // Correct
    elevation: 2.0,
  ),
  dialogTheme: DialogThemeData(...),
  tabBarTheme: TabBarThemeData(...),
)
```

**Files to check**:
- `lib/core/theme/` directory
- Any feature-specific theme customizations

#### 7.3 Fix Colors API (if needed)

Per CLAUDE.md, VronMobile2 should already use `withValues()`:

```dart
// Correct (CLAUDE.md standard):
Colors.black.withValues(alpha: 0.1)

// Old (deprecated):
Colors.black.withOpacity(0.1)
```

**Verify**: Search for old pattern:

```bash
grep -r "withOpacity(" lib/
```

If found, replace with `withValues(alpha: ...)`.

#### 7.4 Fix Deprecated APIs

Based on `flutter analyze` output, fix any remaining deprecated API usage:

```bash
# Common patterns (if found):
# - Ensure PopScope used (not WillPopScope) ✅ Already done per CLAUDE.md
# - Ensure TextButton/ElevatedButton used (not FlatButton/RaisedButton)
# - Update any deprecated package APIs from graphql_flutter or other deps
```

---

### Step 8: Build and Verify

#### 8.1 Clean Build

```bash
# Clean all build artifacts
flutter clean

# Re-fetch dependencies
flutter pub get
```

#### 8.2 Build iOS

```bash
# Build for iOS (release mode)
flutter build ios --release

# Expected: Build succeeds with zero errors
# Warnings about minimum deployment target can be ignored if set to 13.0+
```

**If build fails**:
- Check Xcode version (must be 15.0+)
- Check iOS deployment target set to 13.0
- Check CocoaPods installation: `cd ios && pod install`
- Review build logs for specific errors
- See Troubleshooting section

#### 8.3 Build Android

```bash
# Build for Android (release mode)
flutter build apk --release

# Expected: Build succeeds with zero errors
```

**If build fails**:
- Check Java version (must be 17+)
- Check Gradle version in logs
- Try: `cd android && ./gradlew clean`
- See Troubleshooting section

#### 8.4 Test on Physical Devices

```bash
# iOS (real device or simulator)
flutter run -d <ios-device-id>

# Android (real device or emulator)
flutter run -d <android-device-id>

# Verify app launches and shows home screen
# Verify login flow works
# Verify navigation works
```

**Critical Test: flutter_roomplan (LiDAR Scanning)**

Since flutter_roomplan is high-risk:

```bash
# Run on physical iOS device with LiDAR support
flutter run -d <iphone-pro-device-id>

# Test features:
# - 014: LiDAR scanning
# - 016: Multi-room options
# - 017: Room stitching
# - 018: Combined scan navmesh, USDZ export

# Verify:
# - Scanning starts without crash
# - USDZ files are generated correctly
# - Multi-room merge works (iOS 17+)
```

**If flutter_roomplan fails**:
- Check package version on pub.dev
- Pin to known working version in pubspec.yaml
- Contact package maintainer
- See Troubleshooting section for native module issues

---

### Step 9: Run Test Suite

#### 9.1 Run Unit and Widget Tests

```bash
# Run all tests
flutter test

# Expected: 100% pass rate (same as before upgrade)
```

**If tests fail**:
- Review test failures for API changes
- Update test code to use new APIs
- Fix formatter issues in test files
- Update mock setup if test framework APIs changed
- See Troubleshooting: Test Failures

#### 9.2 Run Integration Tests

```bash
# Run integration tests (if present)
flutter test integration_test/

# Verify critical user flows:
# - Authentication (login, OAuth, guest mode)
# - Project/product management
# - Scanning workflows
```

#### 9.3 Validate with Flutter Analyze

```bash
flutter analyze

# Expected: Zero errors, zero warnings
# If warnings remain, fix before continuing
```

---

### Step 10: Update Documentation

#### 10.1 Update CLAUDE.md

```bash
# Edit: CLAUDE.md

# Find all references to SDK versions:
grep -n "Dart 3.10\|Flutter 3.x" CLAUDE.md

# Replace:
# - "Dart 3.10+" → "Dart 3.8.1"
# - "Flutter 3.x" → "Flutter 3.32.4"

# Specific sections to update:
# - Active Technologies
# - Commands (if SDK-specific)
# - Recent Changes (add entry for this upgrade)
```

**Example update**:

```markdown
## Active Technologies
- Dart 3.8.1 / Flutter 3.32.4 (upgraded from Dart 3.10.0 / Flutter 3.x on 2026-01-13)
- Backend GraphQL API (PostgreSQL), local caching via shared_preferences
- ...

## Recent Changes
- 028-flutter-upgrade: Upgraded to Flutter 3.32.4 and Dart 3.8.1
- 018-combined-scan-navmesh: Added Dart 3.10+ / Flutter 3.x, Swift 5.x...
```

#### 10.2 Update Inline Code Comments

Search for SDK version references in code:

```bash
# Search for version mentions
grep -r "Flutter 3\|Dart 3.10" lib/ --include="*.dart"

# Update any found references to reflect new versions
```

#### 10.3 Update README (if present)

```bash
# Check for README
ls README.md

# If exists, update:
# - SDK version requirements
# - Setup instructions
# - Any version-specific notes
```

---

### Step 11: Performance Validation

#### 11.1 Capture Post-Upgrade Metrics

Repeat baseline metrics capture:

```bash
# 1. Cold start time (same method as before)
# 2. Build times
time flutter build apk --release
time flutter build ios --release

# 3. Hot reload time
# 4. Memory usage (Flutter DevTools)
# 5. Analyze output
flutter analyze > analyze_final.txt
wc -l analyze_final.txt
```

#### 11.2 Compare Metrics

| Metric | Before | After | Δ | Status |
|--------|--------|-------|---|--------|
| Cold start (iOS) | ___ s | ___ s | ___ | ✅/⚠️ |
| Cold start (Android) | ___ s | ___ s | ___ | ✅/⚠️ |
| iOS build time | ___ s | ___ s | ___ | ✅/⚠️ |
| Android build time | ___ s | ___ s | ___ | ✅/⚠️ |
| Peak memory | ___ MB | ___ MB | ___ | ✅/⚠️ |
| Analyze warnings | ___ | ___ | ___ | ✅/⚠️ |

**Success Criteria** (from spec.md):
- Startup time within ±5% of baseline
- Build time increase < 20%
- Memory usage same or better
- Zero analyze warnings

**If metrics regress**: Profile with Flutter DevTools, investigate specific bottlenecks.

---

### Step 12: Final Validation

Complete these checks before marking upgrade complete:

- [ ] iOS app builds successfully (`flutter build ios --release`)
- [ ] Android app builds successfully (`flutter build apk --release`)
- [ ] All tests pass (`flutter test`)
- [ ] `flutter analyze` shows zero errors, zero warnings
- [ ] App launches on iOS device without crash
- [ ] App launches on Android device without crash
- [ ] Authentication flows work (login, OAuth, guest mode)
- [ ] Project/product management works
- [ ] LiDAR scanning works (flutter_roomplan tested on physical device)
- [ ] Performance metrics within acceptable range (±5% startup, <20% build time)
- [ ] CLAUDE.md updated with new SDK versions
- [ ] Code comments updated where SDK versions mentioned
- [ ] All changes committed to Git with clear commit messages

---

## Rollback Procedure

If critical issues arise during upgrade:

### Emergency Rollback

```bash
# 1. Checkout previous working state
git checkout stage  # Or: git reset --hard <commit-before-upgrade>

# 2. Downgrade Flutter
flutter version <previous-version>  # e.g., 3.27.0
# OR: fvm use <previous-version>

# 3. Restore dependencies
flutter pub get

# 4. Clean build
flutter clean
cd ios && pod install && cd ..

# 5. Verify rollback
flutter doctor
flutter --version
flutter build apk --release  # Should succeed
```

### Partial Rollback (Keep Some Changes)

```bash
# If only specific files cause issues:

# 1. Revert problematic files
git checkout stage -- lib/path/to/problematic_file.dart

# 2. Re-run tests
flutter test

# 3. Rebuild
flutter build apk --release
```

---

## Troubleshooting

### Issue: Version Conflicts in pubspec.yaml

**Symptom**: `flutter pub get` fails with "version solving failed"

**Solution**:

```bash
# 1. Run pub outdated to see compatibility
flutter pub outdated

# 2. Update conflicting packages individually
flutter pub upgrade <package-name>

# 3. If specific package incompatible, pin to older version:
# In pubspec.yaml:
dependencies:
  problematic_package: 1.2.3  # Pin to last known working version

# 4. Re-run pub get
flutter pub get
```

### Issue: flutter_roomplan Fails to Build (iOS)

**Symptom**: iOS build fails with errors related to flutter_roomplan

**Solution**:

```bash
# 1. Check flutter_roomplan version on pub.dev
open https://pub.dev/packages/flutter_roomplan

# 2. Update to latest version OR pin to current working version
# In pubspec.yaml:
dependencies:
  flutter_roomplan: ^1.0.7  # Or latest compatible version

# 3. Clean iOS build
flutter clean
cd ios
pod deintegrate
rm -rf Pods Podfile.lock
pod install
cd ..

# 4. Rebuild
flutter build ios --release

# 5. If still fails, check RoomPlan Swift code compatibility
# Review ios/Runner/* for any custom Swift code
# May need to update Swift code for new Flutter engine
```

### Issue: Java 17 Not Found (Android)

**Symptom**: Android build fails: "Java 17 or higher required"

**Solution**:

```bash
# Check current Java version
java -version

# If < 17, install Java 17:

# macOS (Homebrew):
brew install openjdk@17
sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jni /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# OR: Update Android Studio JDK
# Android Studio → Preferences → Build, Execution, Deployment → Build Tools → Gradle
# → Gradle JDK → Select Java 17

# Verify
java -version  # Should show 17.x.x

# Rebuild
flutter clean
flutter build apk --release
```

### Issue: Test Failures After Upgrade

**Symptom**: Tests that passed before now fail

**Common Causes**:

1. **Test Formatter Changes**:
   ```bash
   # Reformat test files
   dart format test/
   ```

2. **Matcher API Changes**:
   ```dart
   // Update test assertions if matcher APIs changed
   // Check test output for specific failures
   ```

3. **Mock Setup Changes**:
   ```dart
   // Update mockito/mocktail setup if package APIs changed
   when(() => mock.method()).thenReturn(value);
   ```

**Solution**:
```bash
# Run tests with verbose output
flutter test --reporter expanded

# Fix tests one file at a time
flutter test test/path/to/failing_test.dart

# Check mockito/mocktail documentation for API changes
```

### Issue: Gradle Build Errors (Android)

**Symptom**: Android build fails with Gradle errors

**Solution**:

```bash
# 1. Clean Gradle cache
cd android
./gradlew clean
cd ..
flutter clean

# 2. Update Gradle wrapper (if needed)
cd android
./gradlew wrapper --gradle-version 8.0
cd ..

# 3. Update Android Gradle Plugin (if needed)
# Edit: android/build.gradle
# Change: com.android.tools.build:gradle:8.1.0 (or higher)

# 4. Invalidate caches in Android Studio
# Android Studio → File → Invalidate Caches / Restart

# 5. Rebuild
flutter build apk --release
```

### Issue: Native Module Crashes (iOS/Android)

**Symptom**: App crashes at runtime when using specific features (e.g., LiDAR scanning)

**Solution**:

```bash
# 1. Check logs
flutter logs  # While app is running

# 2. For iOS, check Xcode console
open ios/Runner.xcworkspace
# Run from Xcode, check console for crash logs

# 3. For Android, check logcat
adb logcat | grep -i flutter

# 4. Identify crashing module
# - If flutter_roomplan: check iOS version, ARKit support
# - If google_sign_in: check OAuth configuration
# - If graphql_flutter: check network setup

# 5. Test in isolation
# Comment out feature, rebuild, verify app works

# 6. Report to package maintainer with logs
```

### Issue: Performance Regression

**Symptom**: App feels slower, startup time increased, or UI stutters

**Solution**:

```bash
# 1. Profile with Flutter DevTools
flutter run --profile
# Open DevTools, use Timeline and Memory tabs

# 2. Check for debug mode
# Ensure you're testing release builds:
flutter run --release

# 3. Compare before/after metrics
# Use baseline metrics captured in Step 11

# 4. Investigate specific bottlenecks
# - Startup: Check main.dart initialization
# - UI: Check for unnecessary rebuilds (use Timeline)
# - Memory: Check for leaks (use Memory tab)

# 5. Profile vs. baseline
# If regression confirmed, consider rollback or performance optimization
```

---

## Success Checklist

Mark each item when complete:

### Phase 1a: Dependency Resolution
- [ ] Flutter 3.32.4 installed and verified
- [ ] `pubspec.yaml` updated with SDK ^3.8.1
- [ ] All dependencies updated to compatible versions
- [ ] `flutter pub get` succeeds without errors
- [ ] Dependency compatibility matrix verified (see research.md)

### Phase 1b: Compilation Fixes
- [ ] iOS deployment target updated to 13.0
- [ ] iOS Podfile and Xcode project updated
- [ ] iOS CocoaPods reinstalled
- [ ] Android Java 17+ verified
- [ ] Theme data updated to use typed classes (if needed)
- [ ] Colors API updated to use `withValues()` (if needed)
- [ ] Formatter settings applied (new style or preserve)
- [ ] `flutter build ios --release` succeeds
- [ ] `flutter build apk --release` succeeds

### Phase 1c: Deprecation Cleanup
- [ ] `flutter analyze` run, output reviewed
- [ ] All deprecation warnings fixed
- [ ] All compilation errors fixed
- [ ] Test code updated for new APIs (if needed)
- [ ] `flutter test` passes with 100% success rate
- [ ] `flutter analyze` shows zero errors, zero warnings

### Phase 1d: Documentation & Validation
- [ ] CLAUDE.md updated with new SDK versions
- [ ] Inline code comments updated (if SDK versions mentioned)
- [ ] README updated (if present)
- [ ] Performance metrics captured and compared
- [ ] Manual testing completed: auth, projects, scanning, file ops
- [ ] flutter_roomplan LiDAR scanning tested on physical device
- [ ] All success criteria met (see spec.md)
- [ ] All changes committed to Git with clear messages

---

## Next Steps After Upgrade

Once all checklist items complete:

1. **Code Review**:
   - Request peer review of all changes
   - Verify constitution compliance (see plan.md)
   - Discuss any deviations from standard patterns

2. **CI/CD Update** (if applicable):
   - Update CI pipeline to use Flutter 3.32.4
   - Update build scripts to use Java 17+
   - Verify CI builds pass

3. **Merge to Stage**:
   - Create PR: `028-flutter-upgrade` → `stage`
   - Include summary of changes, metrics comparison
   - Merge after approval

4. **Monitor in Production**:
   - Deploy to TestFlight (iOS) and Internal Testing (Android)
   - Monitor crash reports
   - Gather user feedback
   - Watch performance metrics

5. **Retrospective**:
   - Document lessons learned
   - Update upgrade process documentation
   - Note any unexpected issues for future upgrades

---

**Quickstart Complete**
**Last Updated**: 2026-01-13
**Status**: Ready for implementation
**Estimated Duration**: 2.5-4 days (see research.md for detailed effort breakdown)
