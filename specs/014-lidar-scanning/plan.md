# Implementation Plan: LiDAR Scanning

**Branch**: `014-lidar-scanning` | **Date**: 2025-12-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/014-lidar-scanning/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Implement LiDAR-based 3D room scanning for iOS devices using Apple's RoomPlan framework, with support for local USDZ capture, on-device USDZ→GLB conversion, and GLB file upload. The feature enables users to scan physical spaces with LiDAR-equipped devices (iPhone 12 Pro and newer), store scan data locally in USDZ format, optionally convert to GLB format on-device for immediate preview, and upload scan data to projects via the existing backend GraphQL API. The implementation is iOS-only for MVP, with Android users able to upload pre-existing GLB files.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)

**Primary Dependencies**:
- flutter_roomplan ^1.0.7 (iOS-only LiDAR scanning, multi-room support iOS 17.0+)
- graphql_flutter 5.1.0 (existing - for backend integration)
- flutter_secure_storage 9.0.0 (existing - optional for scan metadata)
- file_picker ^10.3.8 (cross-platform GLB file selection)
- path_provider ^2.1.5 (local USDZ/GLB storage management)
- USDZ→GLB conversion: Server-side via Sirv API or AWS Lambda (Phase 1), on-device preview evaluation deferred to Phase 2

**Storage**:
- Local filesystem for USDZ scan files (iOS Documents directory)
- Local filesystem for converted GLB files (cache directory)
- Backend PostgreSQL via GraphQL API for scan metadata and project associations

**Testing**: flutter_test (Dart SDK), widget tests for UI components, integration tests for scan workflow, platform channel tests for native RoomPlan integration

**Target Platform**: iOS 16.0+ (iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, iPad Pro 2020+ with LiDAR scanner), Android API 21+ (GLB upload only, no scanning)

**Project Type**: Mobile application (Flutter feature-based architecture)

**Performance Goals**:
- LiDAR scanning maintains 30fps minimum (SC-002)
- Scan initiates within 2 seconds of button tap (SC-001)
- USDZ→GLB conversion <10 seconds for typical rooms (≤200k triangles)
- Scan data captured without data loss (SC-003)

**Constraints**:
- iOS-only LiDAR scanning (no Android LiDAR support in MVP)
- Minimum iOS 16.0+ (RoomPlan framework requirement)
- 250 MB maximum file size for GLB uploads
- <512 MB memory usage during USDZ→GLB conversion
- Device must have LiDAR scanner hardware
- Requires camera/sensor permissions from user

**Scale/Scope**:
- Single feature addition to existing mobile app
- ~10-15 new files (scanning UI, native platform channels, file management)
- Integration with existing project management and GraphQL infrastructure
- Typical USDZ file size: 5-50 MB per room scan

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: TDD approach required for all implementation
- Tests MUST be written before code:
  - Unit tests for LiDAR capability detection (iOS device models)
  - Widget tests for scanning UI components (start/stop buttons, progress indicators)
  - Platform channel tests for RoomPlan integration
  - Unit tests for USDZ file handling and storage
  - Unit tests for USDZ→GLB conversion (if on-device)
  - Integration tests for complete scan workflow (initiate → capture → store → upload)
  - Widget tests for GLB file picker
- Red-Green-Refactor cycle enforced

### II. Simplicity & YAGNI
- ✅ **PASS**: Implementation focused only on stated requirements
- iOS-only LiDAR scanning for MVP (no premature Android support)
- Using Apple's RoomPlan framework (not building custom SLAM algorithms)
- User Story 3 (on-device USDZ→GLB conversion) is P2 - can be deferred if complexity exceeds value
- No abstractions for other 3D formats (OBJ, FBX, etc.) unless required
- Minimal file management: store locally, upload on demand
- **Decision Point**: US3 on-device conversion requires Pixar USD SDK integration (C++/Swift). If complexity too high, defer to server-side conversion (simpler, proven pattern from other features)

### III. Platform-Native Patterns
- ✅ **PASS**: Following Flutter and iOS idioms
- Widget composition for scanning UI
- Feature-based architecture: `lib/features/scanning/`
- Platform channels for RoomPlan integration (MethodChannel for iOS)
- Async/await for scan operations and file I/O
- Platform-specific handling:
  - iOS: RoomPlan + USDZ capture
  - Android: GLB upload only (file picker)
- Existing patterns preserved (GraphQLService, project management)

### Security & Privacy Requirements
- ✅ **PASS**: Secure handling of scan data and permissions
- Camera/sensor permissions requested with clear user justification ("Scan room with LiDAR")
- HTTPS enforced by GraphQL backend for file uploads
- Local USDZ files stored in sandboxed app directory
- No sensitive data in scan files (only geometric data)
- File size validation before upload (250 MB limit)
- Permissions: Camera, Photo Library (for saving scans)

### Performance Standards
- ✅ **PASS**: Performance targets defined
- Scanning maintains 30fps minimum (RoomPlan requirement)
- Scan initiation < 2 seconds
- USDZ→GLB conversion <10 seconds for typical rooms (if on-device)
- Memory usage <512 MB during conversion
- **Risk**: Pixar USD SDK binary size impact - monitor APK/IPA size increase
- Profile memory usage with Flutter DevTools during scan and conversion

### Accessibility Requirements
- ✅ **PASS**: Accessible scanning interface
- Semantic labels on all scan controls ("Start Scanning" button, "Stop" button, "Upload" button)
- Screen reader announcements for scan progress ("Scanning in progress", "Scan complete")
- Error messages accessible to screen readers
- Touch target size adequate (44x44 minimum) for scan controls
- Visual and audio feedback for scan start/stop

### CI/CD & DevOps Practices
- ✅ **PASS**: Feature branch `014-lidar-scanning`
- Tests required before merge to main
- Code review required
- Platform-specific CI: iOS simulator tests + real device LiDAR tests (manual)
- Binary size monitoring for USD SDK impact

**GATE RESULT**: ✅ **PASS** - Proceed to Phase 0 Research

**COMPLEXITY WARNING**: User Story 3 (on-device USDZ→GLB conversion) requires significant native development (C++ USD SDK integration). Recommend research phase evaluation: if complexity exceeds 2 weeks effort, defer US3 to future release and use server-side conversion instead.

---

## Post-Design Constitution Re-Check

*Re-evaluated after Phase 1 (Research, Data Model, Contracts, Quickstart) complete.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: Test requirements defined in quickstart.md
- Unit tests: ScanData serialization, LidarCapability detection, file validation
- Widget tests: Scanning UI, progress indicators, error messages
- Integration tests: Complete scan workflow, upload workflow, conversion polling
- Platform channel tests: RoomPlan integration with mock responses

### II. Simplicity & YAGNI
- ✅ **PASS**: Design maintains simplicity
- **Decision confirmed**: Server-side conversion (Hybrid approach) for US3 instead of on-device (saves 50-150 MB binary size, 6-8 weeks development)
- Using flutter_roomplan package (no custom RoomPlan integration)
- Using file_picker and path_provider (existing, proven packages)
- Data model limited to 3 entities (ScanData, LidarCapability, ConversionResult)
- No premature abstractions for other 3D formats

### III. Platform-Native Patterns
- ✅ **PASS**: Flutter and iOS patterns followed
- flutter_roomplan package encapsulates RoomPlan integration
- Platform channels via MethodChannel (control) and EventChannel (progress)
- Feature-based architecture: `lib/features/scanning/`
- Async/await throughout Dart layer
- SharedPreferences for metadata persistence

### Security & Privacy Requirements
- ✅ **PASS**: All requirements met
- Camera permission with user-facing justification in Info.plist
- HTTPS enforced by GraphQL backend
- Local USDZ files in sandboxed app directory
- Secure token management via existing TokenStorage
- File size validation (250 MB limit) before upload

### Performance Standards
- ✅ **PASS**: Performance targets achievable
- Scan initiation <2 seconds (RoomPlan native performance)
- 30fps scanning (RoomPlan requirement)
- Server-side conversion 5-30 seconds (proven via research)
- File upload <30 seconds for 50 MB on 10 Mbps connection

### Accessibility Requirements
- ✅ **PASS**: Accessibility considered
- Semantic labels defined in quickstart examples
- Screen reader announcements for scan progress
- Error messages accessible
- Touch targets 44x44 (Flutter default)

### CI/CD & DevOps Practices
- ✅ **PASS**: Deployment strategy clear
- Feature branch 014-lidar-scanning
- Tests required before merge
- Platform-specific CI: iOS simulator tests + manual device tests
- Binary size monitoring for USD SDK impact (n/a - server-side chosen)

**GATE RESULT**: ✅ **PASS** - All constitution requirements met post-design. Ready for task generation (`/speckit.tasks`).

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/features/scanning/
├── models/
│   ├── scan_data.dart              # USDZ/GLB file metadata model
│   ├── lidar_capability.dart       # Device capability model
│   └── conversion_result.dart      # USDZ→GLB conversion result (US3)
├── services/
│   ├── scanning_service.dart       # LiDAR scan orchestration
│   ├── file_storage_service.dart   # Local USDZ/GLB storage
│   ├── conversion_service.dart     # USDZ→GLB conversion (US3)
│   └── scan_upload_service.dart    # Backend GraphQL integration
├── screens/
│   ├── scanning_screen.dart        # Main LiDAR scanning UI (iOS)
│   └── file_upload_screen.dart     # GLB file picker UI (Android/iOS)
├── widgets/
│   ├── scan_button.dart            # "Start Scanning" button with capability check
│   ├── scan_progress.dart          # Real-time scan progress indicator
│   └── scan_preview.dart           # Post-scan USDZ/GLB preview widget
└── utils/
    └── platform_utils.dart         # iOS/Android detection, capability checks

lib/core/
├── services/
│   ├── graphql_service.dart        # Existing - extended with scan upload mutations
│   └── token_storage.dart          # Existing - used for authenticated uploads
└── constants/
    └── app_strings.dart            # Existing - extended with scanning error messages

ios/
├── Runner/
│   ├── RoomPlanBridge.swift        # Platform channel for RoomPlan integration
│   ├── UsdzConverter.swift         # Native USDZ→GLB conversion (US3)
│   └── Info.plist                  # Camera usage description added
└── Podfile                         # RoomPlan framework dependency

android/
└── app/
    └── src/main/AndroidManifest.xml # File picker permissions (GLB upload only)

test/
├── features/scanning/
│   ├── services/
│   │   ├── scanning_service_test.dart
│   │   ├── file_storage_service_test.dart
│   │   └── conversion_service_test.dart
│   └── widgets/
│       ├── scan_button_test.dart
│       └── scan_progress_test.dart
└── integration/
    ├── scanning_flow_test.dart      # Complete iOS scan workflow
    └── file_upload_flow_test.dart   # GLB upload workflow
```

**Structure Decision**: Flutter mobile app with feature-based architecture. All LiDAR scanning implementation resides in `lib/features/scanning/` alongside existing features (auth, projects, products). Native iOS integration via `ios/Runner/RoomPlanBridge.swift` platform channel. Reuses existing GraphQL infrastructure for backend communication. Android support limited to GLB file upload (no LiDAR scanning).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations - all checks passed. Implementation follows existing patterns and maintains simplicity.

**Complexity Note** (not a violation):
- User Story 3 (on-device USDZ→GLB conversion) adds significant native complexity (C++ USD SDK + Swift wrapper + Flutter platform channels)
- **Decision deferred to Phase 0 Research**: If implementation effort exceeds 2 weeks or binary size impact exceeds 20 MB, recommend server-side conversion instead
- Server-side alternative: Upload USDZ to backend, convert via cloud service, return GLB URL (proven pattern, simpler implementation)
