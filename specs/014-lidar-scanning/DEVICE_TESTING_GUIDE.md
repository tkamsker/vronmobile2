# LiDAR Scanning - Device Testing Guide

**Feature**: 014-lidar-scanning
**Test Date**: 2025-12-29
**MVP Status**: Phase 1-3 Complete ✅

---

## Prerequisites

### Required Hardware

**Supported iOS Devices** (LiDAR-capable):
- ✅ iPhone 12 Pro / 12 Pro Max
- ✅ iPhone 13 Pro / 13 Pro Max
- ✅ iPhone 14 Pro / 14 Pro Max
- ✅ iPhone 15 Pro / 15 Pro Max
- ✅ iPad Pro 11-inch (3rd generation or later)
- ✅ iPad Pro 12.9-inch (5th generation or later)

**iOS Version**: iOS 16.0 or higher (required by RoomPlan framework)

**Connection**: USB cable or wireless debugging enabled

### Development Environment

- ✅ macOS with Xcode installed
- ✅ Valid Apple Developer account for device provisioning
- ✅ Flutter SDK (Dart 3.10+ / Flutter 3.x)
- ✅ CocoaPods installed (`sudo gem install cocoapods`)

---

## Setup Steps

### 1. Verify Device Provisioning

```bash
# Connect your iPhone/iPad via USB
# Open Xcode and verify device appears in Window > Devices and Simulators

# Or check with Flutter
flutter devices
```

Expected output:
```
iPhone 15 Pro (mobile) • 00008110-XXXXXXXXXXXX • ios • iOS 17.2.1
```

### 2. Install Dependencies

```bash
# Navigate to project root
cd /Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2

# Get Flutter dependencies
flutter pub get

# Install iOS pods
cd ios
pod install
cd ..
```

### 3. Configure Signing

```bash
# Open Xcode workspace
 open -a /Applications/Xcode-16.4.app ios/Runner.xcworkspace
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** project in navigator
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** (Apple Developer account)
5. Ensure **Automatically manage signing** is checked
6. Verify **Bundle Identifier** is unique (e.g., `com.vron.vronmobile2`)

### 4. Verify Permissions in Info.plist

```bash
# Check camera permission is set
cat ios/Runner/Info.plist | grep -A1 "NSCameraUsageDescription"
```

Expected:
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan rooms with LiDAR sensor</string>
```

If missing, add it to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app requires camera access to scan rooms with LiDAR sensor</string>
```

---

## Running on Device

### Option 1: Flutter Run (Development Mode)

```bash
# Run on connected device
flutter run -d <device-id>

# Or if only one device connected
flutter run
```

**Hot Reload**: Press `r` in terminal to reload
**Hot Restart**: Press `R` to restart
**Quit**: Press `q`

### Option 2: Xcode (Debug Mode)

```bash
# Open workspace
open ios/Runner.xcworkspace
```

1. Select your physical device from device dropdown
2. Click **Run** (▶️) button
3. Wait for build and deployment
4. Monitor debug output in console

### Option 3: Release Build (Performance Testing)

```bash
# Build release version for better performance
flutter build ios --release

# Then deploy via Xcode:
open ios/Runner.xcworkspace
# Product > Scheme > Select "Runner"
# Product > Build For > Running
# Click Run (▶️)
```

---

## Testing Checklist

### Phase 1-3 MVP Features (Complete)

Use this checklist to verify all implemented functionality:

#### ✅ **T001-T008: Setup & Configuration**

- [ ] App launches without crashes
- [ ] Camera permission prompt appears on first launch
- [ ] Permission granted successfully

#### ✅ **T009-T018: Foundational Models & Services**

- [ ] App directory structure created
- [ ] No file I/O errors in logs

#### ✅ **US1: LiDAR Scanning (T019-T043l)**

**Capability Detection**:
- [ ] Navigate to scanning feature
- [ ] "Start Scanning" button is **enabled** (device has LiDAR)
- [ ] Button shows proper state (not grayed out)

**Scan Workflow**:
- [ ] Tap "Start Scanning" button
- [ ] Camera view opens with RoomPlan overlay
- [ ] Scan initiates within **2 seconds** (SC-001)
- [ ] UI shows real-time scan progress
- [ ] Frame rate feels smooth (**30fps minimum**, SC-002)
- [ ] Move device around room to capture geometry
- [ ] Scan completes successfully
- [ ] USDZ file saved locally (no error messages)
- [ ] Scan appears in scan list

**Scan List Screen** (T043b-T043e):
- [ ] Scan list displays with scan details (time, file size, format)
- [ ] "Scan another room" button visible
- [ ] Tapping button navigates to scanning screen
- [ ] Multiple scans can be created and listed

**Scan Management** (T043f):
- [ ] Scan can be deleted from list
- [ ] Undo option appears after deletion
- [ ] Deleted scan removed from storage

**Guest Mode** (T043l):
- [ ] Guest users see success dialog after scan
- [ ] Dialog includes account creation button
- [ ] Button links to VRON merchant portal

**Interruption Handling** (T043h):
- [ ] Receive phone call during scan → RoomPlan handles gracefully
- [ ] Lock device during scan → Scan pauses, can resume
- [ ] Switch apps during scan → Scan state preserved

**Router Logic** (T043a):
- [ ] Logged-in users see scan list first
- [ ] Guest users taken directly to scanning screen
- [ ] Navigation between screens works smoothly

---

## Performance Validation

### Success Criteria Testing

Test against defined success criteria from spec.md:

#### **SC-001: Scan Initiates Within 2 Seconds**

**Test**:
1. Tap "Start Scanning" button
2. Start timer
3. Wait for camera view with RoomPlan overlay
4. Stop timer

✅ **PASS**: < 2 seconds
❌ **FAIL**: ≥ 2 seconds

**Result**: _________ seconds

---

#### **SC-002: Scanning Maintains 30fps Minimum**

**Test**:
1. Start scan
2. Move device around room
3. Observe smoothness of camera feed and overlay

✅ **PASS**: Smooth movement, no stuttering
❌ **FAIL**: Noticeable lag or frame drops

**Result**: ☐ PASS  ☐ FAIL

---

#### **SC-003: Scan Data Captured Without Data Loss**

**Test**:
1. Complete full room scan
2. Check scan file exists in Documents directory
3. Verify file size > 0 bytes
4. Check scan appears in scan list with correct metadata

✅ **PASS**: File created, proper size, metadata accurate
❌ **FAIL**: File missing, 0 bytes, or corrupted

**Result**: ☐ PASS  ☐ FAIL

---

## Edge Case Testing

### Device Capability

**Test on non-LiDAR device** (iPhone 11, iPad 9th gen, Android):
- [ ] "Start Scanning" button is **disabled**
- [ ] Message explains LiDAR requirement
- [ ] App doesn't crash

### Storage

**Low storage scenario**:
1. Fill device storage to < 500 MB free
2. Attempt to start scan
3. Expected: Warning message about insufficient storage

### Battery

**Low battery scenario**:
1. Drain battery to < 15%
2. Attempt to start scan
3. Expected: Warning about low battery (if implemented in Phase 6)

### Permissions

**Denied camera permission**:
1. Settings > Privacy > Camera > Toggle OFF for app
2. Attempt to start scan
3. Expected: Error message with link to Settings

---

## Debug Logs

### Enable Verbose Logging

Add to `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable debug logging
  debugPrint('===== LiDAR Scanning Debug Mode =====');

  runApp(MyApp());
}
```

### View Real-Time Logs

**Flutter DevTools**:
```bash
flutter run --verbose
# In another terminal:
flutter pub global activate devtools
flutter pub global run devtools
```

**Xcode Console**:
1. Window > Devices and Simulators
2. Select your device
3. Click "Open Console" button
4. Filter by process name: "Runner"

### Key Log Messages to Monitor

```
✅ [ScanningService] LiDAR capability detected: true
✅ [ScanningService] Starting scan...
✅ [FileStorageService] USDZ saved: /path/to/scan.usdz
✅ [ScanSessionManager] Scan added to session
❌ [ScanningService] ERROR: Camera permission denied
❌ [FileStorageService] ERROR: Insufficient storage
```

---

## Common Issues & Solutions

### Issue 1: "Start Scanning" Button Disabled

**Symptom**: Button is grayed out even on LiDAR-capable device

**Causes**:
1. iOS version < 16.0
2. RoomPlan framework not available
3. LiDAR capability check failing

**Solution**:
```bash
# Check iOS version
flutter devices

# Rebuild app
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Issue 2: Camera Permission Prompt Doesn't Appear

**Symptom**: No permission dialog when tapping "Start Scanning"

**Solution**:
1. Check Info.plist has `NSCameraUsageDescription`
2. Delete app from device
3. Reinstall fresh build

```bash
flutter clean
flutter run
```

### Issue 3: Scan Fails to Complete

**Symptom**: Scan starts but never finishes or crashes

**Causes**:
1. Insufficient lighting in room
2. Too many reflective surfaces (mirrors, glass)
3. Room too large for single scan

**Solution**:
- Ensure good lighting
- Avoid pointing directly at mirrors
- Scan smaller area
- Check logs for RoomPlan errors

### Issue 4: USDZ File Not Saved

**Symptom**: Scan completes but file missing from storage

**Solution**:
```bash
# Check app logs for file path errors
flutter logs

# Verify storage permissions
# Settings > App > Storage (should have access)
```

### Issue 5: Build Fails on Device

**Symptom**: Xcode build errors or signing issues

**Common Errors**:
```
❌ Signing for "Runner" requires a development team
❌ Provisioning profile doesn't include device
```

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project > Signing & Capabilities
3. Choose your Development Team
4. Enable "Automatically manage signing"
5. Clean build folder: Product > Clean Build Folder
6. Try again

---

## Performance Profiling

### Using Flutter DevTools

```bash
# Start app on device
flutter run --profile

# Open DevTools
flutter pub global run devtools
```

**Check**:
1. **Performance** tab → Frame rendering times
2. **Memory** tab → Memory usage during scan
3. **Network** tab → No unexpected network calls during scan

**Targets**:
- Frame time: < 16ms (60fps)
- Memory usage: < 200 MB during scan
- No memory leaks after scan completes

### Using Xcode Instruments

1. Open `ios/Runner.xcworkspace`
2. Product > Profile (⌘+I)
3. Select **Time Profiler** or **Allocations**
4. Record while performing scan
5. Analyze hot spots

---

## Test Report Template

Copy this to document your test results:

```markdown
# LiDAR Scanning Device Test Report

**Date**: 2025-12-29
**Tester**: [Your Name]
**Device**: [iPhone 15 Pro / iPad Pro]
**iOS Version**: [17.2.1]
**App Version**: [1.0.0]
**Build**: [Debug / Release]

## Test Results

### Setup & Configuration
- [ ] PASS - App launches
- [ ] PASS - Camera permission granted
- [ ] PASS - Dependencies loaded

### LiDAR Scanning (US1)
- [ ] PASS - Capability detected correctly
- [ ] PASS - Scan initiates < 2 seconds (SC-001)
- [ ] PASS - 30fps maintained (SC-002)
- [ ] PASS - USDZ file saved (SC-003)
- [ ] PASS - Scan appears in list
- [ ] PASS - Multiple scans work
- [ ] PASS - Scan deletion works

### Performance
- Scan initiation time: _____ seconds
- Frame rate: [ ] Smooth [ ] Choppy
- Memory usage: _____ MB
- USDZ file size: _____ MB

### Edge Cases Tested
- [ ] Low storage warning
- [ ] Camera permission denial handling
- [ ] Scan interruption (phone call)
- [ ] Guest mode success dialog

## Issues Found

1. [Issue description]
   - Severity: [Critical / High / Medium / Low]
   - Steps to reproduce: [...]
   - Expected: [...]
   - Actual: [...]

## Notes

[Additional observations, screenshots, logs, etc.]

## Overall Result

[ ] ✅ PASS - Ready for Phase 4
[ ] ⚠️  PARTIAL - Issues need fixing
[ ] ❌ FAIL - Critical issues blocking progress
```

---

## Next Steps After Testing

### If Tests Pass ✅

1. **Document results** using template above
2. **Proceed to Phase 4** (US2 - GLB Upload)
3. **Optional**: Record demo video of scanning workflow
4. **Share feedback** with team

### If Issues Found ❌

1. **Log issues** with details and logs
2. **Check troubleshooting section** for common fixes
3. **Review Phase 3 implementation** in code
4. **File bug report** if needed
5. **Re-test** after fixes

---

## Quick Test Script

Run this quick validation (5 minutes):

```bash
# 1. Launch app on device
flutter run

# 2. Navigate to LiDAR scanning feature
# 3. Tap "Start Scanning"
# 4. Scan a small area (desk, corner of room)
# 5. Complete scan
# 6. Verify scan appears in list
# 7. Tap "Scan another room"
# 8. Repeat
# 9. Delete a scan
# 10. Verify deletion and undo work

# ✅ If all steps work: MVP is functional!
# ❌ If any step fails: Check Common Issues section
```

---

## Support

**Documentation**:
- Spec: `specs/014-lidar-scanning/spec.md`
- Tasks: `specs/014-lidar-scanning/tasks.md`
- Plan: `specs/014-lidar-scanning/plan.md`

**flutter_roomplan Package**:
- https://pub.dev/packages/flutter_roomplan
- Check "Example" tab for reference implementation

**Apple RoomPlan**:
- https://developer.apple.com/documentation/roomplan

**Need Help?**
- Check Flutter logs: `flutter logs`
- Check Xcode console for iOS-specific errors
- Review implementation in `lib/features/scanning/`

---

**Good luck with testing! 🚀**
