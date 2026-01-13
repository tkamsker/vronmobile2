# Phase 0 Research: Flutter 3.32.4 & Dart 3.8.1 Upgrade

**Date**: 2026-01-13
**Feature**: 028-flutter-upgrade
**Scope**: Comprehensive research on breaking changes, deprecated APIs, and dependency compatibility for upgrading from Flutter 3.x/Dart 3.10.0 to Flutter 3.32.4/Dart 3.8.1

## Executive Summary

**Key Finding**: The upgrade path from Dart 3.10.0 to Dart 3.8.1 represents a **downgrade** in Dart version (3.10 → 3.8), which is unusual. This may be a user error in the requirements. Flutter 3.32.4 typically pairs with Dart 3.8.x (stable channel).

**Recommendation**: Verify the intended target versions. If Flutter 3.32.4 is correct, the paired Dart version should be **Dart 3.8.0** or **3.8.1**, which means we're downgrading Dart from 3.10.0 to 3.8.1.

**Alternative Scenario**: If the goal is to stay on latest stable, consider:
- Flutter 3.38.x + Dart 3.10.x (as of November 2025)
- Flutter 3.32.4 + Dart 3.8.1 (as specified in requirements)

**This research proceeds with the specified target: Flutter 3.32.4 + Dart 3.8.1**

---

## 1. Flutter 3.32 Breaking Changes & New Features

### 1.1 Major New Features

Based on [Code with Andrea](https://codewithandrea.com/newsletter/may-2025/) and [Somnio Software](https://somniosoftware.com/blog/flutter-3-32-dart-3-8-whats-new-and-what-to-watch-out-for):

**Web Development:**
- Experimental hot reload for web: `flutter run -d chrome --web-experimental-hot-reload`
- Brings web development closer to mobile experience
- No changes required in codebase (opt-in via flag)

**iOS UI Improvements:**
- Cupertino Squircles: Rounded superellipse shapes for native iOS fidelity
- Applied to alert dialogs and action sheets automatically
- Enhances native appearance on Apple platforms

**Developer Tools:**
- Flutter Property Editor: Visual widget property editing in IDEs
- New `SemanticsRole` API for enhanced accessibility
- Desktop multi-window support (experimental, via Canonical)

**Impact on VronMobile2**: Low. These are additive features; existing code continues to work.

### 1.2 Breaking Changes

#### 1.2.1 Minimum OS Requirements

**iOS**: Minimum deployment target now **iOS 13.0**
**macOS**: Minimum **10.15** (Catalina) or higher

**Action Required**:
- Update `ios/Podfile`: Set `platform :ios, '13.0'`
- Update `ios/Runner.xcodeproj` iOS deployment target to 13.0
- Update `macos/Runner.xcodeproj` macOS deployment target to 10.15 (if building for macOS)

**Impact on VronMobile2**: Medium. We target iOS 15+ per CLAUDE.md, so we're already compliant. Verify Xcode project settings.

#### 1.2.2 Dart Formatter Changes (Language Versioned)

The Dart formatter handles trailing commas differently when formatting code with language version 3.8+.

**Breaking Behavior**:
- Formatter now decides split points before handling trailing commas
- Code with language version 3.7 or earlier is formatted the same as before
- Code with language version 3.8+ gets new formatting

**Migration**:
To preserve previous behavior, add to `analysis_options.yaml`:
```yaml
formatter:
  trailing_commas: preserve
```

**Action Required**:
- Decide on formatting strategy: adopt new style or preserve old
- Run `dart format` on entire codebase after SDK upgrade
- Commit formatting changes separately from functional changes

**Impact on VronMobile2**: Low-Medium. Formatting changes only; no functional impact. Recommend adopting new style for future-proofing.

#### 1.2.3 Theme Data Updates

**Breaking**: Theme data classes now require explicit types

Changes required:
- `cardTheme` → must use `CardThemeData`
- `dialogTheme` → must use `DialogThemeData`
- `tabBarTheme` → must use `TabBarThemeData`

**Action Required**:
- Search codebase for `ThemeData` usages
- Ensure theme properties use typed data classes
- Check `lib/core/theme/` directory

**Impact on VronMobile2**: Low. VronMobile2 uses theme management in `lib/core/theme/`. Verify theme configuration.

#### 1.2.4 Discontinued Packages

**Breaking**: The following packages are **no longer maintained** by Flutter team:
- `flutter_markdown`
- `ios_platform_images`
- `css_colors`
- `palette_generator`
- `flutter_image`
- `flutter_adaptive_scaffold`

**Impact on VronMobile2**: **None**. VronMobile2 does not use any of these packages (verified in `pubspec.yaml`).

#### 1.2.5 Swift Package Manager (Experimental)

**New Feature**: Optional migration to Swift Package Manager
- Enable: `flutter config --enable-swift-package-manager`
- Replaces CocoaPods for iOS dependency management
- Currently experimental

**Action Required**:
- **Do NOT enable for this upgrade** (experimental feature)
- Monitor for future stable release
- Current CocoaPods workflow remains supported

**Impact on VronMobile2**: None (no action required).

---

## 2. Dart 3.8 Language and Core Library Changes

### 2.1 Breaking Changes in Dart 3.8

Based on [Announcing Dart 3.8](https://medium.com/dartlang/announcing-dart-3-8-724eaaec9f47) and [Flutter 3.32 & Dart 3.8 Guide](https://somniosoftware.com/blog/flutter-3-32-dart-3-8-whats-new-and-what-to-watch-out-for):

#### 2.1.1 SecurityContext is Now Final

**Breaking**: `SecurityContext` class is now `final` and can no longer be subclassed.

**Impact on VronMobile2**: **Low**. Standard GraphQL HTTPS calls don't subclass `SecurityContext`. No action required unless custom certificate pinning implementation subclasses SecurityContext (unlikely).

**Action**: Verify no custom SecurityContext subclasses exist:
```bash
grep -r "extends SecurityContext" lib/
```

#### 2.1.2 Unmodifiable Typed Data Views Removed

**Breaking**: Unmodifiable view classes for typed data (deprecated in Dart 3.4) are now removed:
- `UnmodifiableUint8ListView`
- `UnmodifiableInt32ListView`
- etc.

**Impact on VronMobile2**: **None**. VronMobile2 uses native code for USDZ file handling (Swift in iOS), not Dart typed data views.

#### 2.1.3 NativeWrapperClasses Marked Base

**Breaking**: `NativeWrapperClass` subtypes can no longer be `implement`ed (only `extend`ed).

**Impact on VronMobile2**: **None**. Native wrappers are internal Flutter/Dart engine classes. User code doesn't typically extend or implement these.

#### 2.1.4 WebAssembly Compilation Changes

**Breaking**: When compiling to WebAssembly (dart2wasm):
- `dart:js_util`, `package:js`, `dart:js` are **disallowed**
- Use `dart:js_interop` and `dart:js_interop_unsafe` instead

**Impact on VronMobile2**: **None**. VronMobile2 is an iOS/Android mobile app, not a WebAssembly target.

### 2.2 New Features (Non-Breaking)

#### 2.2.1 Null-Aware Collection Elements

**New Syntax**: Add elements to collections conditionally if not null:

```dart
// Old way
final items = [
  'always',
  if (maybeValue != null) maybeValue,
];

// New way (Dart 3.8+)
final items = [
  'always',
  ?maybeValue,  // only adds if not null
];
```

**Impact on VronMobile2**: **Additive**. Can be adopted incrementally for cleaner code. Not required.

#### 2.2.2 Documentation Imports (@docImport)

**New Feature**: Reference external code in documentation without importing:

```dart
/// See also: {@macro SomeClass}
@docImport('package:other/other.dart');
library;
```

**Impact on VronMobile2**: **None**. Documentation enhancement; no code changes required.

#### 2.2.3 Cross-Platform Compilation Improvements

**New Feature**: Dart can now compile to Linux native binaries from macOS, Windows, or Linux.

**Impact on VronMobile2**: **None**. Mobile app (iOS/Android), not native Linux target.

---

## 3. Dependency Compatibility Matrix

### 3.1 Core Dependencies

Analysis of packages in `pubspec.yaml` for Dart 3.8 / Flutter 3.32 compatibility:

| Package | Current Version | Target Version | Compatibility | Notes |
|---------|----------------|----------------|---------------|-------|
| `flutter` | sdk: flutter | sdk: flutter | ✅ Compatible | SDK package |
| `cupertino_icons` | ^1.0.8 | ^1.0.8 | ✅ Compatible | No changes needed |
| `graphql_flutter` | ^5.1.0 | ^5.2.0 | ✅ Compatible | Latest: 5.2.0-beta.10 (Sep 2025). Requires Java 17 for Android. Source: [pub.dev](https://pub.dev/packages/graphql_flutter) |
| `flutter_secure_storage` | ^10.0.0 | ^10.0.0 | ✅ Compatible | Requires Dart SDK >=3.3.0, fully compatible with 3.8. Source: [pub.dev](https://pub.dev/packages/flutter_secure_storage) |
| `flutter_dotenv` | ^6.0.0 | ^6.0.0 | ✅ Compatible | No known issues |
| `cached_network_image` | ^3.3.0 | ^3.4.0+ | ✅ Compatible | Check for latest stable |
| `intl` | ^0.20.0 | ^0.20.0+ | ✅ Compatible | Standard Flutter package |
| `shared_preferences` | ^2.3.2 | ^2.3.2+ | ✅ Compatible | Flutter team package |
| `google_sign_in` | ^7.0.0 | ^7.0.0+ | ✅ Compatible | Minimum Flutter 3.29/Dart 3.7, compatible with 3.32/3.8. Source: [pub.dev](https://pub.dev/packages/google_sign_in) |
| `flutter_roomplan` | ^1.0.7 | ^1.0.7+ | ⚠️ VERIFY | Requires iOS 16.0+. Dart/Flutter SDK constraints not found in research. **Action: Check pub.dev directly**. Source: [pub.dev](https://pub.dev/packages/flutter_roomplan) |
| `file_picker` | ^10.3.8 | ^10.3.8+ | ✅ Compatible | Actively maintained |
| `path_provider` | ^2.1.5 | ^2.1.5+ | ✅ Compatible | Flutter team package |
| `http` | ^1.2.2 | ^1.2.2+ | ✅ Compatible | Dart team package |
| `model_viewer_plus` | ^1.10.0 | ^1.10.0+ | ✅ Compatible | Check for updates |
| `device_info_plus` | ^12.0.0 | ^12.0.0+ | ✅ Compatible | Active package |
| `uuid` | ^4.5.1 | ^4.5.1+ | ✅ Compatible | Pure Dart, no issues |
| `share_plus` | ^12.0.1 | ^12.0.1+ | ✅ Compatible | Flutter community plus |
| `archive` | ^4.0.0 | ^4.0.0+ | ✅ Compatible | Pure Dart compression |
| `vector_math` | ^2.1.4 | ^2.1.4+ | ✅ Compatible | Standard math package |
| `path_parsing` | ^1.0.1 | ^1.0.1+ | ✅ Compatible | SVG path parsing |
| `flutter_json_view` | ^1.1.4 | ^1.1.4+ | ✅ Compatible | Check for updates |
| `package_info_plus` | ^8.1.2 | ^8.1.2+ | ✅ Compatible | Flutter community plus |

### 3.2 Dev Dependencies

| Package | Current Version | Target Version | Compatibility | Notes |
|---------|----------------|----------------|---------------|-------|
| `flutter_test` | sdk: flutter | sdk: flutter | ✅ Compatible | SDK package |
| `flutter_lints` | ^6.0.0 | ^6.0.0+ | ✅ Compatible | Flutter team lints |
| `mocktail` | ^1.0.0 | ^1.0.0+ | ✅ Compatible | Active package |
| `mockito` | ^5.4.2 | ^5.4.2+ | ✅ Compatible | Compatible with Dart 3.8 |
| `build_runner` | ^2.4.6 | ^2.4.6+ | ✅ Compatible | Code generation tool |
| `json_serializable` | ^6.7.1 | ^6.8.0+ | ✅ Compatible | Check for latest |
| `flutter_launcher_icons` | ^0.14.3 | ^0.14.3+ | ✅ Compatible | Icon generation |
| `integration_test` | sdk: flutter | sdk: flutter | ✅ Compatible | SDK package |
| `webview_flutter_platform_interface` | ^2.14.0 | ^2.14.0+ | ✅ Compatible | Platform interface |

### 3.3 High-Risk Dependencies

**flutter_roomplan**: This is a **custom iOS-only package** for RoomPlan integration (LiDAR scanning). Compatibility concerns:
- iOS 16.0+ required for single room scanning
- iOS 17.0+ required for multi-room merge support
- Uses Swift 5.x native code (iOS)
- Dart/Flutter SDK constraints not confirmed in research

**Mitigation**:
1. Check latest version on [pub.dev/packages/flutter_roomplan](https://pub.dev/packages/flutter_roomplan)
2. Test iOS LiDAR scanning early in upgrade process (feature 014, 016, 017, 018)
3. Have fallback plan: pin to known working version if compatibility issues arise
4. Contact package maintainer if issues found

**graphql_flutter**: Requires **Java 17** for Android builds (up from Java 11).

**Action**:
1. Verify Android Studio Java version: `java -version`
2. Update Gradle JDK in Android Studio if needed
3. Update CI/CD pipeline to use Java 17+

---

## 4. Test Framework Changes

### 4.1 flutter_test API Changes

**Research Finding**: No major breaking changes found in flutter_test for Dart 3.8 / Flutter 3.32.

**Potential Changes**:
- Formatter changes affect test file formatting
- Widget test matchers remain stable
- Integration test framework stable

**Action**:
1. Run full test suite after SDK upgrade: `flutter test`
2. Fix any test failures due to formatting or minor API changes
3. Update test code to use typed theme data if tests create custom themes

### 4.2 Mocktail and Mockito

Both `mocktail` ^1.0.0 and `mockito` ^5.4.2 are compatible with Dart 3.8.

**Action**: Run tests after upgrade. No changes expected.

---

## 5. Platform-Specific Changes

### 5.1 iOS

**Xcode Requirements**:
- Flutter 3.32 requires **Xcode 15.0+** (verify via `flutter doctor`)
- iOS deployment target: 13.0+ (update from 12.0 if needed)
- Swift compatibility: Swift 5.x continues to work with Flutter 3.32

**CocoaPods**:
- No changes required
- Swift Package Manager is experimental (not recommended for this upgrade)

**Action**:
1. Verify Xcode version: `xcode-select --version` should be 15.0+
2. Update `ios/Podfile`: `platform :ios, '13.0'`
3. Clean iOS build: `flutter clean && cd ios && pod deintegrate && pod install`
4. Build: `flutter build ios --release`
5. Test flutter_roomplan LiDAR scanning on physical iOS device

**Risk Areas**:
- flutter_roomplan Swift code compatibility
- USDZ file combination (018-combined-scan-navmesh uses native Swift)

### 5.2 Android

**Gradle Requirements**:
- Android Gradle Plugin: 8.1.0+ recommended
- Gradle version: 8.0+ recommended
- Java: **17+** required (for graphql_flutter)

**Kotlin DSL**:
- Flutter 3.29+ uses Kotlin DSL for Gradle files by default
- Existing projects with Groovy DSL continue to work
- No immediate migration required

**Action**:
1. Verify Java version: `java -version` should be 17+
2. Update Android Studio JDK settings if needed
3. Update `android/gradle/wrapper/gradle-wrapper.properties` if needed
4. Update `android/build.gradle` AGP version if needed
5. Build: `flutter build apk --release`

**Risk Areas**:
- Gradle build configuration changes
- Java 17 requirement for graphql_flutter

---

## 6. Deprecation Audit

### 6.1 Current Codebase Analysis

**Action Required**: Run `flutter analyze` on current codebase (before upgrade) to establish baseline:

```bash
flutter analyze > /tmp/analyze_before.txt
```

This will identify:
- Current deprecated API usage
- Existing warnings and errors
- Code quality issues

**After Upgrade**: Run `flutter analyze` again and compare:

```bash
flutter analyze > /tmp/analyze_after.txt
diff /tmp/analyze_before.txt /tmp/analyze_after.txt
```

### 6.2 Common Deprecated APIs (Historical Context)

Based on Flutter 3.x series deprecations (may or may not affect VronMobile2):

**Widgets**:
- `FlatButton` → `TextButton` (deprecated in Flutter 2.0, removed in 3.0)
- `RaisedButton` → `ElevatedButton` (deprecated in Flutter 2.0, removed in 3.0)
- `OutlineButton` → `OutlinedButton` (deprecated in Flutter 2.0, removed in 3.0)

**Material**:
- `ThemeData` properties: ensure typed data classes
- `PopScope` vs `WillPopScope`: VronMobile2 already uses `PopScope` per CLAUDE.md ✅

**Colors**:
- `Colors.black.withOpacity()` → `Colors.black.withValues(alpha: ...)` (CLAUDE.md already documents this ✅)

**Status**: VronMobile2 appears to follow modern Flutter patterns per CLAUDE.md. Low risk of deprecated API usage.

### 6.3 Priority Deprecations

**Critical** (breaks build):
- None identified in research

**High** (generates warnings):
- Formatter trailing comma behavior
- Theme data type requirements

**Medium** (future deprecations):
- Monitor for new deprecations in Flutter 3.32 changelog

---

## 7. Migration Strategy Decisions

### 7.1 SDK Downgrade Clarification

**Decision Point**: Confirm intent to downgrade Dart from 3.10.0 to 3.8.1

**Recommendation**:
- **If goal is latest stable**: Use Flutter 3.38+ with Dart 3.10+ (as of Nov 2025)
- **If Flutter 3.32.4 is required**: Use Dart 3.8.0 or 3.8.1 (as specified)

**Rationale**: Dart 3.10 is newer than 3.8.1. Downgrading may remove features or introduce incompatibilities with code written for 3.10.

**Action**: Confirm with team before proceeding.

**Assumption for this plan**: Proceeding with Flutter 3.32.4 + Dart 3.8.1 as specified.

### 7.2 Formatter Strategy

**Decision**: Adopt new Dart 3.8 formatter style

**Rationale**:
- Future-proofs codebase
- Aligns with Dart team recommendations
- Minimal effort (one-time reformat)

**Alternative**: Add `trailing_commas: preserve` to `analysis_options.yaml`

**Action**: Run `dart format .` after SDK upgrade, commit formatting changes separately.

### 7.3 Dependency Update Strategy

**Decision**: Update dependencies incrementally

**Phase 1a (with SDK upgrade)**:
- Update only packages with known compatibility issues
- Pin flutter_roomplan to current version initially

**Phase 1b (after successful build)**:
- Update remaining packages to latest compatible versions
- Run `flutter pub outdated` to identify candidates
- Test after each major package update

**Rationale**: Minimize risk by isolating SDK changes from dependency updates.

### 7.4 Testing Strategy

**Decision**: Test-driven validation at each phase

**Approach**:
1. Capture baseline metrics before upgrade (startup time, memory, build time)
2. Run full test suite after SDK upgrade (before code changes)
3. Fix tests incrementally by feature module
4. Run regression testing after each fix
5. Capture final metrics and compare to baseline

**Critical Tests**:
- Authentication flows (features 001, 003, 004, 026)
- Project/product management (002, 006, 008, 010, 025)
- LiDAR scanning (014, 016, 017, 018) - **highest risk**
- Guest mode (007)
- Localization (022, 023)

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Dart downgrade incompatibility** | Medium | Critical | Verify no Dart 3.9+ or 3.10+ features used. Review git history for recent language feature adoption. Confirm intended target version. |
| **flutter_roomplan breaks** | Medium | High | Test early. Pin to current version if needed. Contact maintainer. Have fallback to disable LiDAR features temporarily. |
| **Java 17 requirement (graphql_flutter)** | Low | Medium | Update Android Studio JDK. Update CI/CD. Straightforward fix. |
| **iOS Swift compatibility** | Low | Medium | Test USDZ combination feature (018). Swift 5.x is stable with Flutter 3.32. |
| **Formatter changes disrupt code review** | High | Low | Commit formatting changes separately. Use `git blame --ignore-rev` for formatted commits. |
| **Test failures** | Medium | Medium | Budget time for test fixes. Most should be formatting or minor API changes. Existing tests provide regression coverage. |
| **Gradle build issues** | Low | Medium | Update AGP and Gradle versions if needed. Android builds are stable in Flutter 3.32. |
| **Performance regression** | Low | High | Profile before/after. Flutter 3.32 generally improves performance. Monitor startup time, memory, 60fps. |

---

## 9. Estimated Effort

Based on research findings and VronMobile2 codebase analysis:

**Phase 1a: Dependency Resolution**
- Update `pubspec.yaml` SDK constraint and dependencies: 30 minutes
- Resolve version conflicts: 1-2 hours
- Verify flutter_roomplan compatibility: 1 hour (research + testing)
- **Total**: 2.5-3.5 hours

**Phase 1b: Compilation Fixes**
- Address breaking changes (theme data, iOS deployment target): 1-2 hours
- Update formatter settings and reformat codebase: 1 hour
- Fix any compilation errors: 2-4 hours (contingency)
- **Total**: 4-7 hours

**Phase 1c: Deprecation Cleanup**
- Run flutter analyze and fix warnings: 2-4 hours
- Update test code if needed: 1-2 hours
- Achieve zero warnings: 1-2 hours (iterations)
- **Total**: 4-8 hours

**Phase 1d: Documentation & Validation**
- Update CLAUDE.md: 30 minutes
- Update code comments: 1 hour
- Performance profiling: 2 hours
- Regression testing: 4-8 hours (manual + automated)
- **Total**: 7.5-11.5 hours

**Grand Total**: 18.5-30 hours (2.5-4 days for one developer)

**Contingency**: +25% for unforeseen issues (flutter_roomplan, native modules) = **23-38 hours total**

---

## 10. Success Criteria (from spec.md)

All research findings support achievability of success criteria:

- ✅ **SC-001**: iOS and Android builds complete without errors - **Achievable** (no major breaking changes found)
- ✅ **SC-002**: All automated tests pass - **Achievable** (test framework stable)
- ✅ **SC-003**: `flutter analyze` zero errors/warnings - **Achievable** (known deprecations documented)
- ✅ **SC-004**: App startup time within 5% - **Achievable** (Flutter 3.32 performance neutral/positive)
- ✅ **SC-005**: Manual testing successful - **Achievable** (no architectural changes)
- ✅ **SC-006**: Documentation updated - **Achievable** (straightforward doc updates)
- ✅ **SC-007**: Local dev environment builds - **Achievable** (standard SDK upgrade)
- ✅ **SC-008**: No runtime crashes - **Achievable** (existing tests provide coverage)

**Risk Areas for Success Criteria**:
- SC-001: flutter_roomplan iOS builds (medium risk)
- SC-004: Performance validation (low risk, but requires profiling)

---

## 11. Next Steps

### Immediate Actions

1. **Confirm Target Versions**:
   - Verify with team: Is Dart 3.8.1 (downgrade from 3.10.0) intentional?
   - Alternative: Flutter 3.38+ with Dart 3.10+ for latest stable
   - Document decision in plan.md

2. **Environment Preparation**:
   - Install Flutter 3.32.4: `flutter version 3.32.4` or use fvm
   - Verify Xcode 15.0+ installed
   - Verify Java 17+ for Android builds
   - Capture baseline metrics (startup time, memory, build time)

3. **Pre-Upgrade Validation**:
   - Run `flutter analyze` on current codebase (save output)
   - Run full test suite (ensure 100% pass rate)
   - Build iOS and Android (ensure successful builds)
   - Capture performance metrics with Flutter DevTools

### Ready for Phase 1

Once immediate actions complete, proceed to Phase 1a: Dependency Resolution (documented in plan.md).

---

## 12. References

### Official Documentation
- [Flutter Release Notes](https://docs.flutter.dev/release/release-notes)
- [Flutter Breaking Changes](https://docs.flutter.dev/release/breaking-changes)
- [Dart Changelog](https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md)
- [Dart Breaking Changes](https://dart.dev/resources/breaking-changes)

### Community Resources
- [Code with Andrea: Flutter 3.32 & Dart 3.8](https://codewithandrea.com/newsletter/may-2025/)
- [Somnio Software: Flutter 3.32 Guide](https://somniosoftware.com/blog/flutter-3-32-dart-3-8-whats-new-and-what-to-watch-out-for)
- [Announcing Dart 3.8](https://medium.com/dartlang/announcing-dart-3-8-724eaaec9f47)

### Package Documentation
- [graphql_flutter on pub.dev](https://pub.dev/packages/graphql_flutter)
- [flutter_secure_storage on pub.dev](https://pub.dev/packages/flutter_secure_storage)
- [google_sign_in on pub.dev](https://pub.dev/packages/google_sign_in)
- [flutter_roomplan on pub.dev](https://pub.dev/packages/flutter_roomplan)

---

**Research Complete**: 2026-01-13
**Status**: Ready for Phase 1 (pending target version confirmation)
**Next Phase**: Phase 1a - Dependency Resolution
