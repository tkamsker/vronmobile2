# Implementation Plan: Combined Scan to NavMesh Workflow

**Branch**: `018-combined-scan-navmesh` | **Date**: 2026-01-04 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/018-combined-scan-navmesh/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Combine multiple positioned room scans into a single GLB file with navigation mesh generation for Unity/game engine integration. The feature creates ONE combined USDZ file on-device containing all room scans with their saved positions (x, y, rotation, scale), uploads it using the existing `uploadProjectScan` GraphQL mutation, leverages the existing USDZ→GLB conversion pipeline, and generates a navigation mesh from the combined GLB. This minimizes new code by reusing existing upload/polling infrastructure and following the established BYO (Bring Your Own) pattern for navmesh generation.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x, Swift 5.x (iOS native code for USDZ combination)
**Primary Dependencies**:
- Flutter: `flutter_roomplan` (RoomPlan integration), `path_provider`, `shared_preferences`, `http`, `uuid`
- iOS Native: SceneKit framework (built-in, for USDZ file manipulation)
- Backend: GraphQL API (existing for USDZ upload), BlenderAPI microservice (existing REST API for navmesh), PostgreSQL (existing)
**Storage**:
- Local: SharedPreferences for metadata persistence (JSON serialization)
- Local files: USDZ and GLB files in app documents directory
- Backend: S3/object storage for USDZ/GLB files (existing infrastructure)
**Testing**: Flutter widget tests, Flutter integration tests, iOS native unit tests (XCTest for USDZ combiner)
**Target Platform**: iOS 16.0+ (LiDAR scanning + USDZ combination), Android API 21+ (GLB download/upload only, no scanning)
**Project Type**: mobile (Flutter cross-platform with iOS-specific native code)
**Performance Goals**:
- USDZ combination: <10 seconds for 3 scans (~5MB each)
- Upload: <30 seconds on typical WiFi connection (15MB combined file)
- Backend GLB conversion: <60 seconds (handled by existing backend)
- NavMesh generation: <90 seconds (backend processing)
**Constraints**:
- iOS 16.0+ minimum (RoomPlan + SceneKit requirements)
- On-device USDZ combination required (privacy, offline capability)
- Must reuse existing upload/conversion APIs (no new REST endpoints)
- File sizes: Combined USDZ 10-50MB typical (2-10 rooms)
**Scale/Scope**:
- 2-10 rooms per combined scan (typical floor plans)
- 5-15 screens total (including existing scan screens)
- ~2000 LOC new code (services, UI, native bridge)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: Tests will be written before implementation
  - Widget tests for UI components (combine button, progress dialog, export dialog)
  - Unit tests for services (CombinedScanService, USDZCombinerService)
  - Integration tests for full combine-upload-download flow
  - iOS native tests for USDZ combination logic (XCTest)

### II. Simplicity & YAGNI
- ✅ **PASS**: Minimal new code, maximum reuse
  - Reuses existing `ScanUploadService` for USDZ upload/polling (no duplication)
  - Reuses existing `uploadProjectScan` GraphQL mutation (no new endpoints)
  - Reuses existing USDZ→GLB conversion pipeline (backend)
  - **Reuses existing BlenderAPI microservice for navmesh (ZERO new backend code)**
  - No premature abstractions - direct service implementations
  - Position fields already added to ScanData model (Phase 1 complete)

### III. Platform-Native Patterns
- ✅ **PASS**: Embraces Flutter and iOS native patterns
  - Uses iOS SceneKit framework (platform-native USDZ manipulation)
  - Flutter MethodChannel for native bridge (standard pattern)
  - Feature-based organization: `lib/features/scanning/`
  - State management via StatefulWidget and services (existing pattern)
  - Async operations use Future/async-await properly

### Security & Privacy
- ✅ **PASS**: Secure handling of scan data
  - HTTPS for all API calls (existing backend)
  - On-device USDZ combination (privacy-preserving, no cloud processing)
  - Existing secure token management for GraphQL (no changes needed)
  - Local files stored in secure app documents directory
  - No sensitive data in metadata (only file paths and UUIDs)

### Performance Standards
- ✅ **PASS**: Performance goals defined and realistic
  - USDZ combination: <10s for 3 scans (SceneKit is efficient)
  - Upload: <30s on WiFi (standard for 15MB files)
  - Frame rate: UI remains responsive during background upload
  - Memory: Streaming upload prevents memory spikes
  - No performance concerns with current design

### Accessibility
- ✅ **PASS**: UI will follow accessibility standards
  - Buttons will have semantic labels (Semantics widgets)
  - Progress indicators accessible to screen readers
  - Clear status messages for all states
  - Touch targets meet 44x44 minimum size
  - Error messages provide clear feedback

**GATE RESULT**: ✅ **PASS** - No violations. Feature follows all constitution principles.

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
│   ├── scan_data.dart (EXISTING - position fields already added)
│   └── combined_scan.dart (NEW - combined scan state model)
├── services/
│   ├── usdz_combiner_service.dart (NEW - Flutter → iOS native bridge)
│   ├── combined_scan_service.dart (NEW - orchestrates combine flow)
│   ├── blenderapi_service.dart (NEW - REST API client for navmesh generation)
│   └── scan_upload_service.dart (EXISTING - reused for USDZ upload/polling)
├── widgets/
│   ├── combine_progress_dialog.dart (NEW - progress UI)
│   └── export_combined_dialog.dart (NEW - export options UI)
└── screens/
    └── project_detail_screen.dart (UPDATED - add combine button)

ios/Runner/
├── USDZCombiner.swift (NEW - SceneKit USDZ combination logic)
└── USDZCombinerPlugin.swift (NEW - Flutter MethodChannel bridge)

test/features/scanning/
├── services/
│   ├── usdz_combiner_service_test.dart (NEW - unit tests)
│   ├── combined_scan_service_test.dart (NEW - unit tests)
│   └── blenderapi_service_test.dart (NEW - unit tests)
├── widgets/
│   ├── combine_progress_dialog_test.dart (NEW - widget tests)
│   └── export_combined_dialog_test.dart (NEW - widget tests)
└── integration/
    └── combine_scan_flow_test.dart (NEW - E2E test)

ios/RunnerTests/
└── USDZCombinerTests.swift (NEW - iOS native unit tests)
```

**Structure Decision**:
- **Mobile Flutter app** with iOS-specific native code
- Feature-based organization under `lib/features/scanning/` (existing pattern)
- iOS native code in `ios/Runner/` with Swift implementation
- Tests mirror source structure in `test/` directory
- Reuses existing `ScanUploadService` (no duplication)
- All new files clearly marked, existing files to be updated noted

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations to track**. All constitution principles are followed without exceptions.
