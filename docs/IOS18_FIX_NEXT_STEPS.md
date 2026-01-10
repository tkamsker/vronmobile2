# iOS 18 Fix - Next Steps

## ✅ Current Status: App Working

The app is now functional on iOS 18 using:
- **Traditional AppDelegate window management** (UIScene temporarily disabled)
- **SharedPreferences disabled** (using defaults)
- **Guest session manager disabled** (null-safe fallbacks)

---

## 🎯 Next Steps (Priority Order)

### Phase 1: Fix UIScene Support (iOS 18 Required)

**Problem:** SceneDelegate class not found by iOS runtime
**Impact:** App works but uses deprecated AppDelegate window management

**Steps:**

1. **Add SceneDelegate.swift to Xcode Project Properly**
   ```bash
   # Open Xcode and manually add SceneDelegate.swift to Runner target
   open ios/Runner.xcworkspace
   ```
   - In Xcode: Right-click Runner folder → Add Files to "Runner"
   - Select `SceneDelegate.swift`
   - Ensure "Copy items if needed" is checked
   - Ensure "Runner" target is selected
   - Build → Verify SceneDelegate compiles

2. **Verify SceneDelegate Class Name**
   - Ensure `@objc(SceneDelegate)` annotation is present
   - Check that class is public/accessible

3. **Re-enable UIScene in Info.plist**
   - Uncomment `UIApplicationSceneManifest` section
   - Use `Runner.SceneDelegate` as delegate class name

4. **Re-enable UIScene Methods in AppDelegate**
   - Uncomment `configurationForConnecting` method

5. **Test**
   ```bash
   ./flutter_run_ios.sh run -d <device-id> --debug
   ```
   - Verify no "could not load class" errors
   - Verify SceneDelegate logs appear
   - Verify UI still renders correctly

---

### Phase 2: Fix SharedPreferences iOS 18 Compatibility

**Problem:** `shared_preferences_foundation` channel error on iOS 18
**Impact:** Language preferences and guest mode persistence disabled

**Steps:**

1. **Check for Plugin Updates**
   ```bash
   flutter pub outdated
   flutter pub upgrade shared_preferences
   ```

2. **Update CocoaPods**
   ```bash
   cd ios
   pod update shared_preferences_foundation
   pod install
   ```

3. **Test SharedPreferences**
   - Create a simple test to verify channel works:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('test', 'value');
   print('✅ SharedPreferences works: ${prefs.getString('test')}');
   ```

4. **If Still Failing - Alternative Solutions:**
   - **Option A:** Use `flutter_secure_storage` for sensitive data (already in project)
   - **Option B:** Use in-memory storage with `flutter_secure_storage` fallback
   - **Option C:** Wait for `shared_preferences` plugin update
   - **Option D:** File issue with `shared_preferences` maintainers

5. **Re-enable in Code**
   - Uncomment SharedPreferences imports
   - Restore `I18nService.initialize()` SharedPreferences calls
   - Restore guest session manager initialization

---

### Phase 3: Re-enable Guest Session Manager

**Problem:** Currently disabled (null-safe fallbacks in place)
**Impact:** Guest mode persistence not working

**Steps:**

1. **After SharedPreferences is Fixed:**
   ```dart
   // In lib/main.dart
   final prefs = await SharedPreferences.getInstance();
   guestSessionManager = GuestSessionManager(prefs: prefs);
   await guestSessionManager.initialize();
   ```

2. **Remove Null Checks**
   - Change `guestSessionManager?` back to `guestSessionManager`
   - Remove `?? false` fallbacks
   - Update all usages

3. **Test Guest Mode**
   - Test "Continue as Guest" button
   - Verify guest mode persists across app restarts
   - Verify guest mode disables after login

---

### Phase 4: Clean Up & Documentation

**Steps:**

1. **Remove Debug Logging**
   - Remove `NSLog` statements from SceneDelegate
   - Remove debug prints from AppDelegate
   - Clean up temporary comments

2. **Update Documentation**
   - Document iOS 18 requirements
   - Update setup guides
   - Document known issues and workarounds

3. **Update Xcode Configuration Guide**
   - Update `docs/XCODE_IOS18_RECONFIGURATION.md`
   - Add troubleshooting section for SceneDelegate
   - Document SharedPreferences workaround

---

## 🔧 Quick Reference: Re-enabling Features

### Re-enable UIScene

1. **Info.plist:**
   ```xml
   <key>UIApplicationSceneManifest</key>
   <dict>
       <key>UIApplicationSupportsMultipleScenes</key>
       <false/>
       <key>UISceneConfigurations</key>
       <dict>
           <key>UIWindowSceneSessionRoleApplication</key>
           <array>
               <dict>
                   <key>UISceneConfigurationName</key>
                   <string>Default Configuration</string>
                   <key>UISceneDelegateClassName</key>
                   <string>Runner.SceneDelegate</string>
               </dict>
           </array>
       </dict>
   </dict>
   ```

2. **AppDelegate.swift:**
   ```swift
   override func application(
     _ application: UIApplication,
     configurationForConnecting connectingSceneSession: UISceneSession,
     options: UIScene.ConnectionOptions
   ) -> UISceneConfiguration {
     return UISceneConfiguration(
       name: "Default Configuration",
       sessionRole: connectingSceneSession.role
     )
   }
   ```

### Re-enable SharedPreferences

1. **lib/core/i18n/i18n_service.dart:**
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';
   
   Future<void> initialize() async {
     final prefs = await SharedPreferences.getInstance();
     final savedLanguage = prefs.getString(_languagePreferenceKey);
     // ... rest of initialization
   }
   ```

2. **lib/main.dart:**
   ```dart
   import 'package:shared_preferences/shared_preferences.dart';
   
   final prefs = await SharedPreferences.getInstance();
   guestSessionManager = GuestSessionManager(prefs: prefs);
   await guestSessionManager.initialize();
   ```

---

## 📋 Testing Checklist

After each phase, verify:

- [ ] App builds without errors
- [ ] App launches on iOS 18 device
- [ ] Login screen displays correctly
- [ ] No console errors related to the feature
- [ ] Feature works as expected
- [ ] Hot reload works
- [ ] App can be backgrounded/foregrounded

---

## 🐛 Known Issues

1. **SceneDelegate Class Loading**
   - **Status:** Needs manual Xcode project configuration
   - **Workaround:** Using AppDelegate window management (works but deprecated)

2. **SharedPreferences Channel Error**
   - **Status:** iOS 18 compatibility issue
   - **Workaround:** Disabled, using defaults (works but no persistence)

3. **Guest Mode Persistence**
   - **Status:** Depends on SharedPreferences fix
   - **Workaround:** Null-safe fallbacks (works but no persistence)

---

## 📝 Notes

- All temporary workarounds are clearly marked with comments
- Code is structured to easily re-enable features
- No breaking changes to app functionality
- App is fully functional for development/testing

---

**Last Updated:** 2025-01-07
**Status:** App Working - Ready for Phase 1 (UIScene Fix)

