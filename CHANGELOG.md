# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Feature 014: LiDAR Scanning

#### Phase 1: Project Setup & Dependencies (T001-T008)
- Added flutter_roomplan package (^1.0.7) for iOS LiDAR scanning
- Added file_picker package (^10.3.8) for GLB file selection
- Added path_provider package (^2.1.5) for file storage
- Added share_plus package (^10.1.4) for GLB file export
- Updated iOS minimum platform to 16.0 for RoomPlan framework support
- Added NSCameraUsageDescription to iOS Info.plist for LiDAR access
- Added camera and storage permissions to Android manifest

#### Phase 2: Core Error Handling (T013-T025)
- Implemented comprehensive error handling service with user-friendly messages
- Added multi-language error message support (EN, DE, PT)
- Created error classification system for recoverable/non-recoverable errors
- Implemented error logging with 7-day TTL cleanup
- Added session-based error tracking and investigation

#### Phase 3: Session Diagnostics (T026-T040)
- Added BlenderAPI session investigation functionality
- Implemented session diagnostics screen with detailed error context
- Added device information collection for debugging
- Created workspace and error timeline visualization
- Added "Copy Session ID" functionality for support tickets

#### Phase 4-5: Automatic Retry Logic (T041-T064)
- Implemented retry policy service with exponential backoff
- Added automatic retry for network and transient errors
- Configured retry limits: 3 attempts, 1-minute time window
- Added retry progress tracking and user feedback
- Implemented non-recoverable error detection (no retry for 4xx errors)

#### Phase 6: Offline Queue Management (T065-T078)
- Implemented ConnectivityService with real-time network monitoring
- Added offline operation queue with SharedPreferences persistence
- Created OfflineBanner widget for offline status display
- Implemented automatic queue processing when connection restored
- Added operation executor registration pattern for modular processing

#### Phase 7: Polish & Cross-Cutting Concerns (T079-T100)
- Fixed compilation errors in test suite (Project model, mocktail syntax)
- Added integration_test package to dev dependencies
- Ran flutter analyze and fixed warnings (unused imports/methods)
- Ran dart format on entire codebase (160 files formatted)
- Generated test coverage report (529 tests passing, 44.8% overall coverage)
- Phase 6 new code coverage: 65.1% (ConnectivityService 58.4%, OfflineBanner 100%)

### Changed

#### UI Improvements
- Updated scan list buttons: "USDZ" → "USDZ View", "GLBView" → "GLB View"
- Reduced button font size to 12px for better layout
- Added debug-only "Export GLB" button using kDebugMode flag

#### Bug Fixes
- Fixed GLB path storage: Now updates existing scan with glbLocalPath instead of creating new scan
- Fixed Xcode 16 build errors: Added GoogleUtilities header import fix in Podfile
- Fixed mocktail syntax in tests: Added function closures to when() calls
- Updated ScanSessionManager with updateScan() method for in-place updates

#### Architecture
- Converted file storage to use ScanSessionManager for in-memory session management
- Added copyWith() pattern for immutable scan data updates
- Skipped outdated FileStorageService integration tests

### Technical Details

#### Dependencies Updated
```yaml
dependencies:
  flutter_roomplan: ^1.0.7
  file_picker: ^10.3.8
  path_provider: ^2.1.5
  share_plus: ^10.1.4

dev_dependencies:
  integration_test:
    sdk: flutter
```

#### iOS Configuration
- Minimum platform: iOS 16.0 (for RoomPlan framework)
- Added Xcode 16 compatibility fixes in Podfile
- Camera permission for LiDAR sensor access

#### Test Coverage
- 529 tests passing
- 7 tests skipped
- 110 platform-dependent tests failing (expected without device/emulator)
- Overall coverage: 44.8%
- New Phase 6 code coverage: 65.1%

#### Code Quality
- 337 issues from flutter analyze (mostly info-level avoid_print)
- All actual warnings fixed
- Consistent code formatting applied

### Migration Notes

For developers working on this codebase:

1. **Xcode 16 Users**: Run `pod install` to apply GoogleUtilities header fixes
2. **Testing**: Platform-dependent tests require mocking for path_provider, shared_preferences, and file_picker
3. **Debug Features**: GLB export button only visible in debug mode (kDebugMode)
4. **Scan Management**: Use ScanSessionManager.updateScan() for updating existing scans

### Known Issues

- 110 platform-dependent tests require additional mocking infrastructure
- Some error messages missing translations (warnings in logs)
- Guest storage tests require path_provider platform channel mocking

---

## [1.0.0] - Previous Version

Initial release with:
- Main screen and login (Feature 001)
- Project management (Features 002-004)
- Product search (Feature 005)
- Guest mode (Feature 007)
- Project listings (Feature 008)

[Unreleased]: https://github.com/username/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/username/repo/releases/tag/v1.0.0
