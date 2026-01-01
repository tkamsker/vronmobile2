# Implementation Plan: Multi-Room Scanning Options

**Branch**: `016-multi-room-options` | **Date**: 2025-01-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/016-multi-room-options/spec.md`

## Summary

Implement remaining 40% of multi-room scanning features to enable complete property capture and stitching workflows. Core foundation (60%) already exists with session management and "Scan another room" functionality. This plan focuses on implementing room stitching (backend integration, progress tracking, preview), scan naming/organization, and batch operations on multiple scans.

**Primary Goals**:
1. Implement room stitching UI and backend API integration for merging multiple scans
2. Add scan naming and organization capabilities for better scan management
3. Enable batch operations (export all, upload all, delete all) for efficiency
4. Maintain TDD compliance and Flutter best practices throughout

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
  - http: ^1.1.0 (already in project - for backend API calls)
  - model_viewer_plus: ^1.10.0 (already in project - for 3D preview)
  - Existing scanning infrastructure from Feature 014
  - Existing offline queue from Feature 015

**Storage**:
  - Session-only (in-memory ScanSessionManager - already implemented)
  - Local device storage for downloaded stitched models
  - No new persistent storage needed beyond existing architecture

**Testing**: Flutter widget tests, unit tests (mocktail), integration tests
**Target Platform**: iOS 17.0+ (LiDAR + multi-room APIs), Android API 21+ (GLB upload/view only)
**Project Type**: Mobile (iOS + Android) - Feature-based architecture
**Performance Goals**:
  - Room stitching UI response: < 200ms to load scan selection screen
  - Progress polling: Every 2 seconds during stitching job
  - Stitched model preview: < 3 seconds to load merged GLB
  - Batch operations: Process N scans with progress updates every scan

**Constraints**:
  - Backend API for stitching not yet implemented (NEEDS RESEARCH: API contract design)
  - Stitching requires authenticated users (guest mode prompts account creation)
  - iOS 17.0+ requirement for stitching (multi-room capability detection already implemented)
  - Merged GLB files may be 2-3x larger than individual scans (device storage consideration)

**Scale/Scope**:
  - User Story 2: Room stitching (3 new screens, 1 service, 3 models)
  - User Story 3: Scan naming (1 dialog, model updates)
  - User Story 4: Batch operations (multi-select UI, 3 batch actions)
  - ~15-20 new Dart files across models, services, screens, widgets
  - ~30-40 test files (unit + widget + integration)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Test-First Development (NON-NEGOTIABLE)
- **Status**: COMPLIANT
- **Plan**:
  - Unit tests for RoomStitchingService (API calls, polling, error handling)
  - Unit tests for scan naming validation and filename sanitization
  - Unit tests for batch operation logic (export all, upload all, delete all)
  - Widget tests for RoomStitchingScreen, RoomStitchProgressScreen, StitchedModelPreviewScreen
  - Widget tests for scan name editor dialog
  - Widget tests for multi-select mode in scan list
  - Integration tests for end-to-end stitching flow
  - Integration tests for batch operations
  - All tests written BEFORE implementation (TDD red-green-refactor)

### ✅ II. Simplicity & YAGNI
- **Status**: COMPLIANT
- **Justification**:
  - Implementing only explicitly required user stories (US2-4 from spec)
  - Reusing existing ScanSessionManager (no new session storage)
  - Reusing existing offline queue from Feature 015 for stitching requests
  - Reusing existing GLB preview infrastructure (model_viewer_plus)
  - No premature abstractions (e.g., no "stitching algorithm" - backend handles that)
  - Room naming: simple string field, no complex taxonomy or categories
  - Batch operations: standard multi-select pattern, no custom state machine

### ✅ III. Platform-Native Patterns
- **Status**: COMPLIANT
- **Plan**:
  - Flutter widget composition for all new UI (RoomStitchingScreen, dialogs)
  - StatefulWidget for screens with state (progress tracking, multi-select mode)
  - Dart async/await for all API calls and file operations
  - Feature-based file organization: `lib/features/scanning/`
  - Material Design widgets (ListTile with checkboxes, BottomSheet for batch actions)
  - Platform-specific handling where needed (Platform.isIOS checks for capabilities)

### ✅ Security & Privacy Requirements
- **Status**: COMPLIANT
- **Plan**:
  - Stitching requires authentication (FR-020) - prompt guest users for account
  - Room names validated and sanitized before use in filenames
  - No sensitive data in scan names (user-controlled public strings)
  - Backend API calls use existing authenticated HTTP client
  - No new security considerations beyond existing scanning infrastructure

### ✅ Performance Standards
- **Status**: COMPLIANT
- **Plan**:
  - Room stitching selection screen: Lazy load scan thumbnails, < 200ms to display list
  - Progress polling: 2-second intervals (balances responsiveness vs. backend load)
  - Stitched model preview: Leverage model_viewer_plus caching, aim for < 3s load
  - Batch operations: Process sequentially with progress bar (no background threading for simplicity)
  - Maintain 60fps during animations (multi-select checkboxes, progress bars)
  - No performance regressions in existing scan list screen

### ✅ Accessibility Requirements
- **Status**: COMPLIANT
- **Plan**:
  - All new buttons and interactive elements: Semantic labels
  - Scan selection checkboxes: Announce selection state ("Kitchen scan selected")
  - Progress indicators: Semantic labels with percentage ("Stitching progress 45%")
  - Multi-select mode: Announce mode change ("Multi-select mode enabled")
  - Batch action buttons: Clear semantic labels ("Export all 3 selected scans")
  - Touch targets: 44x44 minimum for all interactive elements

### ✅ CI/CD & DevOps Practices
- **Status**: COMPLIANT
- **Plan**:
  - Feature branch: `016-multi-room-options` (already created)
  - Atomic commits for each logical unit (US2 stitching, US3 naming, US4 batch ops)
  - CI pipeline runs all tests on PR
  - Code review required before merge
  - Semantic versioning: MINOR increment (new features, backward compatible)

## Project Structure

### Documentation (this feature)

```text
specs/016-multi-room-options/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (already exists)
├── research.md          # Phase 0 output (to be generated)
├── data-model.md        # Phase 1 output (to be generated)
├── quickstart.md        # Phase 1 output (to be generated)
├── contracts/           # Phase 1 output (to be generated)
│   └── room-stitching-api.graphql or .yaml
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/features/scanning/
├── models/
│   ├── scan_data.dart                    # EXISTS - will add roomName field
│   ├── room_stitch_request.dart          # NEW - User Story 2
│   ├── room_stitch_job.dart              # NEW - User Story 2
│   └── stitched_model.dart               # NEW - User Story 2
├── services/
│   ├── scan_session_manager.dart         # EXISTS - already manages multiple scans
│   ├── room_stitching_service.dart       # NEW - User Story 2
│   └── [other existing services]
├── screens/
│   ├── scan_list_screen.dart             # MODIFY - add multi-select mode (US4)
│   ├── room_stitching_screen.dart        # NEW - User Story 2 (scan selection)
│   ├── room_stitch_progress_screen.dart  # NEW - User Story 2 (progress tracking)
│   └── stitched_model_preview_screen.dart # NEW - User Story 2 (preview + actions)
├── widgets/
│   ├── scan_name_editor_dialog.dart      # NEW - User Story 3
│   ├── batch_action_bottom_sheet.dart    # NEW - User Story 4
│   └── [other existing widgets]
└── utils/
    └── filename_sanitizer.dart           # NEW - User Story 3 (sanitize room names)

test/features/scanning/
├── models/
│   ├── room_stitch_request_test.dart     # NEW - User Story 2
│   ├── room_stitch_job_test.dart         # NEW - User Story 2
│   └── stitched_model_test.dart          # NEW - User Story 2
├── services/
│   ├── room_stitching_service_test.dart  # NEW - User Story 2
│   └── [other existing tests]
├── screens/
│   ├── scan_list_screen_test.dart        # MODIFY - test multi-select mode
│   ├── room_stitching_screen_test.dart   # NEW - User Story 2
│   ├── room_stitch_progress_screen_test.dart # NEW - User Story 2
│   └── stitched_model_preview_screen_test.dart # NEW - User Story 2
├── widgets/
│   ├── scan_name_editor_dialog_test.dart # NEW - User Story 3
│   └── batch_action_bottom_sheet_test.dart # NEW - User Story 4
└── integration/
    ├── room_stitching_flow_test.dart     # NEW - User Story 2 end-to-end
    ├── scan_naming_flow_test.dart        # NEW - User Story 3 end-to-end
    └── batch_operations_flow_test.dart   # NEW - User Story 4 end-to-end
```

**Structure Decision**: Mobile feature-based architecture (already established). All new code lives under `lib/features/scanning/` following existing patterns. Tests mirror source structure under `test/features/scanning/`. No changes to overall project structure needed.

## Complexity Tracking

> **Not Applicable** - Constitution Check shows no violations requiring justification.

---

## Phase 0: Research & Technology Validation

**Goal**: Resolve all NEEDS CLARIFICATION items and establish technology choices

**Status**: READY TO EXECUTE

### Research Tasks

1. **Backend API Contract for Room Stitching (NEEDS CLARIFICATION)**
   - **Question**: What is the API contract for room stitching backend endpoint?
   - **Research Needed**:
     - Endpoint URL pattern (REST or GraphQL)
     - Request format (scan IDs, alignment options, output format)
     - Response format (job ID, status, progress percentage, result URL)
     - Error codes (insufficient overlap, alignment failure, timeout, invalid input)
     - Authentication requirements (bearer token, API key)
   - **Output**: `/contracts/room-stitching-api.yaml` or `.graphql`

2. **Stitching Progress Polling Strategy**
   - **Question**: How should app poll for stitching job status?
   - **Research Needed**:
     - Polling interval (2 seconds recommended per spec SC-005: < 5 minute total time)
     - Timeout strategy (max polling duration, exponential backoff)
     - Status codes (pending, uploading, processing, aligning, merging, completed, failed)
     - Progress percentage calculation
   - **Best Practice**: Follow existing pattern from Feature 014 USDZ→GLB conversion polling

3. **Room Name Validation Rules**
   - **Question**: What characters are allowed in room names and how to sanitize for filenames?
   - **Research Needed**:
     - Allowed characters (alphanumeric + spaces per FR-012, emojis per FR-017)
     - Max length (50 characters per FR-012)
     - Filename sanitization rules (replace spaces with hyphens, remove special chars for filesystem)
     - Unicode handling (normalize diacritics, handle emojis)
   - **Best Practice**: Follow existing filename patterns from scan export

4. **Multi-Select UI Pattern**
   - **Question**: What is the best Flutter pattern for multi-select lists?
   - **Research Needed**:
     - Activation: Long-press vs. explicit "Select" button
     - Visual feedback: Checkboxes visible always or only in select mode
     - Bottom sheet vs. app bar for batch actions
     - Exit multi-select: Back button, tap outside, or explicit "Done"
   - **Best Practice**: Follow Material Design multi-select patterns

5. **Stitched Model Storage Strategy**
   - **Question**: Where to store downloaded stitched GLB files?
   - **Research Needed**:
     - Same directory as individual scans (Documents folder)
     - Naming convention (stitched-<timestamp>.glb or <room1>-<room2>-merged.glb)
     - Cleanup strategy (delete after upload to project? Keep indefinitely?)
   - **Best Practice**: Follow existing scan storage from Feature 014

### Deliverable: `research.md`

All research tasks will be consolidated into `research.md` with:
- Decision: [chosen approach]
- Rationale: [why chosen]
- Alternatives considered: [other options evaluated]
- Implementation notes: [specific details for tasks.md]

---

## Phase 1: Data Model & API Contracts

**Goal**: Define data structures and API contracts

**Prerequisites**: `research.md` complete

### Data Model Design (`data-model.md`)

Based on FR-007 to FR-020 and Key Entities from spec:

#### New Entities

**RoomStitchRequest**
- Purpose: Request payload for initiating room stitching job
- Fields:
  - `selectedScanIds`: List<String> - IDs of scans to stitch
  - `alignmentMode`: enum (auto, manual) - default: auto
  - `outputFormat`: enum (GLB, USDZ) - default: GLB
  - `roomNames`: Map<String, String> - scanId → room name (optional)
  - `userId`: String - authenticated user ID
- Validation:
  - selectedScanIds: minimum 2 scans (FR-007)
  - alignmentMode: only 'auto' supported in MVP
  - outputFormat: GLB or USDZ
- Serialization: JSON (for HTTP POST body)

**RoomStitchJob**
- Purpose: Track active stitching operation progress
- Fields:
  - `jobId`: String - backend-assigned unique ID
  - `status`: enum (pending, uploading, processing, aligning, merging, completed, failed)
  - `progress`: int (0-100) - percentage complete
  - `startedAt`: DateTime - job initiation timestamp
  - `completedAt`: DateTime? - job completion timestamp (null if in progress)
  - `errorMessage`: String? - error details if status == failed
  - `resultUrl`: String? - download URL for stitched model (if status == completed)
- State transitions:
  - pending → uploading → processing → aligning → merging → completed
  - Any status → failed (on error)
- Serialization: JSON (from HTTP polling response)

**StitchedModel**
- Purpose: Represents result of successful stitching operation
- Fields:
  - `jobId`: String - reference to RoomStitchJob
  - `mergedModelPath`: String - local file path to downloaded GLB
  - `originalScanIds`: List<String> - source scan IDs
  - `stitchParameters`: Map<String, dynamic> - alignment mode, format used
  - `createdAt`: DateTime - local download timestamp
  - `metadata`: Map<String, dynamic> - polygon count, file size, room names
- Lifecycle: Created after successful download of stitched model
- Serialization: JSON (for potential future persistence)

#### Modified Entities

**ScanData** (existing model)
- Add field: `roomName`: String? - user-assigned room name (FR-012, FR-013)
- Update serialization: Add roomName to JSON toMap/fromMap
- Validation: Max 50 characters, alphanumeric + spaces

### API Contract Design (`/contracts/`)

**Backend API Endpoint: Room Stitching** (Needs Backend Team Coordination)

Assuming GraphQL based on existing BlenderAPI pattern:

```graphql
# contracts/room-stitching-api.graphql

# Mutation: Initiate room stitching job
mutation StitchRooms($input: StitchRoomsInput!) {
  stitchRooms(input: $input) {
    jobId: ID!
    status: StitchJobStatus!
    estimatedDuration: Int  # seconds
  }
}

input StitchRoomsInput {
  scanIds: [ID!]!             # minimum 2 scans
  alignmentMode: AlignmentMode # default AUTO
  outputFormat: OutputFormat   # default GLB
  roomNames: [RoomNameInput!] # optional room names
}

input RoomNameInput {
  scanId: ID!
  name: String!  # max 50 chars
}

enum AlignmentMode {
  AUTO    # system determines alignment
  MANUAL  # future: user-specified alignment hints
}

enum OutputFormat {
  GLB
  USDZ
}

enum StitchJobStatus {
  PENDING     # job queued
  UPLOADING   # uploading scans to backend
  PROCESSING  # processing uploaded scans
  ALIGNING    # aligning room boundaries
  MERGING     # merging geometry
  COMPLETED   # stitched model ready
  FAILED      # stitching failed
}

# Query: Poll stitching job status
query GetStitchJobStatus($jobId: ID!) {
  stitchJob(jobId: $jobId) {
    jobId: ID!
    status: StitchJobStatus!
    progress: Int!         # 0-100 percentage
    errorMessage: String   # if status == FAILED
    resultUrl: String      # if status == COMPLETED
    createdAt: DateTime!
    completedAt: DateTime
  }
}
```

**Error Codes** (from FR-010):
- `INSUFFICIENT_OVERLAP`: Scans don't have enough common area (< 20%)
- `ALIGNMENT_FAILURE`: Cannot align scans (incompatible coordinate systems)
- `BACKEND_TIMEOUT`: Processing exceeded time limit
- `INCOMPATIBLE_FORMATS`: Mixed USDZ/GLB scans not supported
- `INVALID_SCAN_ID`: One or more scan IDs not found
- `UNAUTHORIZED`: User not authenticated or lacks permissions

### Quickstart Guide (`quickstart.md`)

Developer onboarding document with:
- How to test room stitching locally (mock backend, sample scans)
- How to test scan naming (long-press edit, filename generation)
- How to test batch operations (select multiple, tap batch actions)
- API contract reference (link to `/contracts/`)
- Key files and their responsibilities
- Testing strategy overview

---

## Phase 2: Execution Planning (Out of Scope for `/speckit.plan`)

**Note**: Task decomposition happens in `/speckit.tasks` command.

Expected task breakdown preview:
- **Phase 1**: Setup & Dependencies (pubspec.yaml updates if needed)
- **Phase 2**: User Story 2 - Room Stitching (~25-30 tasks)
  - Models (RoomStitchRequest, RoomStitchJob, StitchedModel)
  - Service (RoomStitchingService with polling)
  - Screens (RoomStitchingScreen, Progress, Preview)
  - Integration with offline queue (Feature 015)
  - Tests (unit, widget, integration)
- **Phase 3**: User Story 3 - Scan Naming (~8-10 tasks)
  - Model update (ScanData.roomName)
  - Dialog widget (ScanNameEditorDialog)
  - Validation & sanitization utility
  - Tests
- **Phase 4**: User Story 4 - Batch Operations (~12-15 tasks)
  - Multi-select mode in scan list
  - Batch action bottom sheet
  - Export all, upload all, delete all logic
  - Progress tracking for batch operations
  - Tests
- **Phase 5**: Polish & Integration (~8-10 tasks)
  - Error message translations
  - Accessibility semantic labels
  - End-to-end integration tests
  - Documentation updates

**Total Estimated Tasks**: 60-70 tasks across 5 phases

---

## Next Steps

1. ✅ **Phase 0 Complete** (when research.md exists)
2. ✅ **Phase 1 Complete** (when data-model.md, contracts/, quickstart.md exist)
3. **Run `/speckit.tasks`** to generate task decomposition
4. **Begin implementation** following TDD (tests first, then implementation)

---

## Notes

- **Backend Dependency**: Room stitching requires new backend API endpoint - coordinate with backend team before starting US2 implementation
- **Incremental Delivery**: Can implement US3 (naming) and US4 (batch ops) independently while waiting for backend API
- **Existing Infrastructure**: Leverage existing session manager, offline queue, error handling from Features 014-015
- **Testing Strategy**: Comprehensive test coverage for all new models, services, screens per constitution
