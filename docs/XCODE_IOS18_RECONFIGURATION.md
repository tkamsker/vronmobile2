# Xcode Environment Reconfiguration Guide - iOS 18.x Setup

## Current Environment Analysis

### Installed Xcode Versions
- **Xcode 16.4** (Build 16F6) - Currently active
  - Location: `/Applications/Xcode-16.4.app`
  - iOS SDK: 18.5 ✓
  - Status: Active (`xcode-select` points here)

- **Xcode 26.2** (Build 17C52) - Installed but inactive
  - Location: `/Applications/Xcode.app`
  - iOS SDK: 18.5 ✓
  - Status: Available but not active

### Current Project Configuration
- **Deployment Target**: iOS 16.0 (needs update to 18.0)
- **Last Upgrade Check**: Xcode 15.1 (outdated)
- **Podfile Platform**: iOS 16.0 (needs update)
- **Project Object Version**: 54 (Xcode 9.3 compatibility)

---

## Recommendation: Keep Both Xcode Versions

**Why keep both?**
1. ✅ **Xcode 16.4** is stable and well-tested for iOS 18.x development
2. ✅ **Xcode 26.2** allows testing newer features and future compatibility
3. ✅ Both support iOS 18.5 SDK, so you can switch as needed
4. ✅ No conflicts - they're separate applications
5. ✅ Easy switching with `xcode-select` or `DEVELOPER_DIR`

**Alternative (not recommended):**
- Removing and reinstalling would lose your current setup
- No benefit since both versions support iOS 18.x
- More time-consuming with no added value

---

## Step-by-Step Reconfiguration Guide

### Phase 1: Clean Current Environment

#### Step 1.1: Clean Flutter Build Artifacts
```bash
cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2

# Clean Flutter build cache
flutter clean

# Remove iOS build folders
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/Generated.xcconfig
rm -rf build/ios
```

#### Step 1.2: Clean Xcode Derived Data
```bash
# Remove Xcode derived data (safe - will be regenerated)
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Clean CocoaPods cache (optional but recommended)
pod cache clean --all
```

#### Step 1.3: Verify Xcode Installation
```bash
# Verify active Xcode version
xcode-select -p
# Should show: /Applications/Xcode-16.4.app/Contents/Developer

# Verify Xcode 16.4 license is accepted
sudo /Applications/Xcode-16.4.app/Contents/Developer/usr/bin/xcodebuild -license accept

# Verify iOS SDK availability
xcodebuild -showsdks | grep -i ios
# Should show: iOS 18.5 SDK available
```

---

### Phase 2: Update Project Configuration for iOS 18.x

#### Step 2.1: Update Podfile
Edit `ios/Podfile`:

```ruby
# Change from:
platform :ios, '16.0'

# To:
platform :ios, '18.0'
```

Also update the `post_install` block:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      # Change from '16.0' to '18.0'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
  # ... rest of post_install block remains the same
end
```

#### Step 2.2: Update Xcode Project Settings
The project.pbxproj file needs updates. You can do this via Xcode GUI or manually:

**Option A: Via Xcode (Recommended)**
1. Open project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select **Runner** project in Navigator
3. Select **Runner** target
4. Go to **General** tab → **Deployment Info**
   - Set **iOS Deployment Target** to **18.0**
5. Go to **Build Settings** tab
   - Search for `IPHONEOS_DEPLOYMENT_TARGET`
   - Set to **18.0** for all configurations (Debug, Release, Profile)
6. Go to **Project** (not target) → **Build Settings**
   - Set `IPHONEOS_DEPLOYMENT_TARGET` to **18.0**
7. **File** → **Project Settings** → **Build System**
   - Ensure "New Build System" is selected
8. **File** → **Project Settings** → **Shared Project Settings**
   - Set **Last Upgrade Check** to **1640** (Xcode 16.4)

**Option B: Manual Edit (Advanced)**
Edit `ios/Runner.xcodeproj/project.pbxproj`:
- Find all instances of `IPHONEOS_DEPLOYMENT_TARGET = 16.0;`
- Replace with `IPHONEOS_DEPLOYMENT_TARGET = 18.0;`
- Find `LastUpgradeCheck = 1510;`
- Replace with `LastUpgradeCheck = 1640;`

#### Step 2.3: Update Info.plist (if needed)
Check `ios/Runner/Info.plist` - it should already have iOS 18 compatible settings. Verify:
- `UIApplicationSceneManifest` is present (already configured ✓)
- No deprecated keys

---

### Phase 3: Reinstall Dependencies

#### Step 3.1: Ensure Correct Xcode is Active
```bash
# Verify Xcode 16.4 is active
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer

# Verify
xcodebuild -version
# Should show: Xcode 16.4
```

#### Step 3.2: Install CocoaPods Dependencies
```bash
cd ios

# Update CocoaPods (if needed)
sudo gem install cocoapods

# Install pods with iOS 18.0 target
pod deintegrate
pod install --repo-update

# Verify installation
pod --version
```

#### Step 3.3: Regenerate Flutter Files
```bash
cd ..

# Get Flutter dependencies
flutter pub get

# This will regenerate ios/Flutter/Generated.xcconfig
flutter precache --ios
```

---

### Phase 4: Verify Configuration

#### Step 4.1: Flutter Doctor Check
```bash
flutter doctor -v

# Expected output:
# [✓] Xcode - develop for iOS and macOS (Xcode 16.4)
# [✓] CocoaPods version 1.x.x
# [✓] iOS toolchain - develop for iOS devices
```

#### Step 4.2: Verify iOS SDK
```bash
# Check active SDK
xcrun --show-sdk-version --sdk iphoneos
# Should show: 18.5

# Check deployment target in project
xcodebuild -project ios/Runner.xcodeproj -target Runner -showBuildSettings | grep IPHONEOS_DEPLOYMENT_TARGET
# Should show: IPHONEOS_DEPLOYMENT_TARGET = 18.0
```

#### Step 4.3: Test Build
```bash
# Clean build
flutter clean
flutter pub get

# Build for iOS (simulator)
flutter build ios --simulator

# Or build for device
flutter build ios
```

---

### Phase 5: Configure Xcode Switching (Optional)

If you want to easily switch between Xcode versions:

#### Option A: System-Wide Switch
```bash
# Switch to Xcode 16.4 (iOS 18.x stable)
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer

# Switch to Xcode 26.2 (newer features)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Verify current selection
xcode-select -p
```

#### Option B: Per-Terminal Switch (Recommended)
Create a script for project-specific builds:

**Create `ios_build.sh`:**
```bash
#!/bin/bash
# Force Xcode 16.4 for this project
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer

# Run Flutter commands
flutter "$@"
```

**Make it executable:**
```bash
chmod +x ios_build.sh
```

**Usage:**
```bash
./ios_build.sh build ios
./ios_build.sh run
```

---

## Troubleshooting

### Issue: "Error -10664 when running flutter run" (Xcode-16.4.app cannot open workspace)

**Problem:**
When using `flutter run` with Xcode 16.4, you may encounter:
```
_LSOpenURLsWithCompletionHandler() failed for the application /Applications/Xcode-16.4.app with error -10664
```

**Root Cause:**
macOS Launch Services cannot open renamed Xcode applications (Xcode-16.4.app) directly. The `open` command requires the default `Xcode.app` path.

**Solution:**
Use Xcode 26.2 for `flutter run` (which needs GUI access), but keep Xcode 16.4 for command-line builds:

**Option 1: Use wrapper script (Recommended)**
```bash
# Use the provided flutter_run_ios.sh script
./flutter_run_ios.sh run -d <device-id> --debug
```

**Option 2: Set DEVELOPER_DIR per terminal**
```bash
# For flutter run (needs GUI)
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
flutter run -d <device-id> --debug

# For builds (command-line only)
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer
flutter build ios
```

**Option 3: Switch system-wide (requires sudo)**
```bash
# Switch to Xcode 26.2 for flutter run
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
flutter run -d <device-id> --debug

# Switch back to Xcode 16.4 for builds
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer
flutter build ios
```

**Note:** Both Xcode versions support iOS 18.5 SDK, so either works for builds. The issue is only with GUI opening.

---

### Issue: "No iOS SDK found"
**Solution:**
```bash
# Verify SDK exists
xcodebuild -showsdks

# If missing, open Xcode and install additional components
open /Applications/Xcode-16.4.app
# Xcode → Settings → Platforms → Download iOS 18.5 Simulator
```

### Issue: "Pod install fails"
**Solution:**
```bash
cd ios
pod deintegrate
rm Podfile.lock
pod cache clean --all
pod install --repo-update
```

### Issue: "Build fails with deployment target error"
**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Check all targets have `IPHONEOS_DEPLOYMENT_TARGET = 18.0`
3. Clean build folder: **Product** → **Clean Build Folder** (Shift+Cmd+K)
4. Rebuild

### Issue: "Flutter doctor shows wrong Xcode"
**Solution:**
```bash
# Ensure correct Xcode is active
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer

# Restart terminal or run:
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developer
flutter doctor -v
```

---

## Verification Checklist

After completing all steps, verify:

- [ ] `xcode-select -p` shows Xcode 16.4 path
- [ ] `xcodebuild -version` shows Xcode 16.4
- [ ] `xcrun --show-sdk-version --sdk iphoneos` shows 18.5
- [ ] `ios/Podfile` has `platform :ios, '18.0'`
- [ ] Xcode project shows `IPHONEOS_DEPLOYMENT_TARGET = 18.0` in all configs
- [ ] `flutter doctor -v` shows no iOS-related issues
- [ ] `flutter build ios` completes successfully
- [ ] App runs on iOS 18.x simulator/device

---

## Quick Reference Commands

```bash
# Switch to Xcode 16.4
sudo xcode-select -s /Applications/Xcode-16.4.app/Contents/Developer

# Switch to Xcode 26.2
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Check active Xcode
xcode-select -p
xcodebuild -version

# Check iOS SDK
xcodebuild -showsdks | grep -i ios
xcrun --show-sdk-version --sdk iphoneos

# Clean and rebuild
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter build ios
```

---

## Summary

**Recommended Approach:**
1. ✅ **Keep both Xcode versions** (16.4 and 26.2)
2. ✅ **Use Xcode 16.4 as primary** for iOS 18.x development
3. ✅ **Update project to iOS 18.0** deployment target
4. ✅ **Clean and reconfigure** the environment
5. ✅ **Switch Xcode versions** as needed using `xcode-select` or `DEVELOPER_DIR`

This setup gives you:
- Stable iOS 18.x development environment
- Flexibility to test newer Xcode features
- Clean, reproducible builds
- Easy version switching when needed

---

## Next Steps After Reconfiguration

1. **Test the app** on iOS 18.x simulator
2. **Test on physical device** running iOS 18.x
3. **Update CI/CD** (if applicable) to use Xcode 16.4
4. **Document any issues** encountered during migration
5. **Monitor Flutter updates** for iOS 18.x compatibility improvements

---

**Last Updated:** 2025-01-06
**Xcode Versions:** 16.4 (primary), 26.2 (secondary)
**Target iOS Version:** 18.0+
**SDK Version:** 18.5

## ----

Solution: Use Xcode 26.2 for flutter run
Problem: macOS Launch Services cannot open Xcode-16.4.app directly (error -10664) because it's not the default Xcode.app. This only affects flutter run when it tries to open the Xcode GUI.
Solution: Use Xcode 26.2 for flutter run (GUI access), and keep Xcode 16.4 for command-line builds.
Quick fix — use the wrapper script
A wrapper script is available. Run:
./flutter_run_ios.sh run -d 00008140-0005185602DB001C --debug
This automatically uses Xcode 26.2 for flutter run.
Alternative: set DEVELOPER_DIR manually
If you prefer to run flutter directly:
# Set Xcode 26.2 for this terminal sessionexport DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer# Now flutter run will workflutter run -d 00008140-0005185602DB001C --debug
Why this works
Xcode 26.2 (/Applications/Xcode.app) can be opened by macOS Launch Services
Xcode 16.4 (/Applications/Xcode-16.4.app) cannot be opened directly (renamed apps issue)
Both support iOS 18.5 SDK, so either works for builds
The issue only affects GUI opening, not command-line builds
For builds (no GUI needed)
For command-line builds, you can keep using Xcode 16.4:
export DEVELOPER_DIR=/Applications/Xcode-16.4.app/Contents/Developerflutter build ios
Try running your app with the wrapper script or by setting DEVELOPER_DIR to Xcode 26.2.