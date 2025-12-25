# Feature Specification: LiDAR Scanning

**Feature Branch**: `014-lidar-scanning`
**Created**: 2025-12-20
**Status**: Draft

## Clarifications

### Session 2025-12-25

- Q: What format should the LiDAR scan data be stored in locally after capture? → A: USDZ (Apple's native format) - Use Room Plan's native output, convert to GLB server-side
- Q: What is the maximum file size limit for GLB uploads? → A: 250 MB - Larger limit to support complex commercial spaces
- Q: When should the USDZ scan data be uploaded to the backend server? → A: User-initiated upload - Store locally first, upload when user explicitly saves to project
- Q: Which platforms should support LiDAR scanning in MVP? → A: iOS only (iPhone 12 Pro and newer with LiDAR) - Use flutter_roomplan (iOS-only), defer Android
- Q: What should happen when a scan is interrupted (phone call, app backgrounded, low battery)? → A: Prompt user to choose - Ask whether to save partial, discard, or continue

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start Scan (Priority: P1)

User with LiDAR-capable device initiates room scan.

**Why this priority**: Core app functionality - room capture.

**Independent Test**: Tap Start Scanning, verify camera/sensor permissions requested and scan begins.

**Acceptance Scenarios**:

1. **Given** user logged in or guest, **When** navigates to scanning, **Then** "Start Scanning" button visible
2. **Given** button visible, **When** device has LiDAR, **Then** button enabled
3. **Given** button tapped, **When** permissions granted, **Then** scan interface appears
4. **Given** scanning active, **When** room captured, **Then** scan data stored locally as USDZ (not uploaded yet)
5. **Given** scan stored locally, **When** user saves to project (UC20), **Then** USDZ uploaded to backend for GLB conversion

### User Story 2 - Upload GLB (Priority: P2)

User can upload existing GLB file instead of scanning. To use Pre view feature with that data.

**Why this priority**: Alternative input method for pre-existing models.

**Independent Test**: Select file picker, choose GLB, verify uploaded.

**Acceptance Scenarios**:

1. **Given** scanning screen, **When** user taps upload, **Then** file picker opens
2. **Given** GLB selected, **When** upload completes, **Then** file stored locally

### User Story 3 - On-Device USDZ→GLB Conversion (Priority: P2)

User can convert USDZ scan to GLB format locally on-device for immediate web preview, offline validation, and cross-platform compatibility without requiring server upload or network connectivity.

**Why this priority**: Enables instant validation of scans in web viewers (Three.js, Babylon.js, WebXR) within the app, provides offline capability for privacy-sensitive users, and reduces server load. Essential for professional users who need immediate quality checks before committing scans to projects.

**Independent Test**: Complete room scan, trigger local conversion, verify GLB file created on device, load in web preview successfully.

**Acceptance Scenarios**:

1. **Given** USDZ scan completed and stored locally, **When** user taps "Preview" or "Convert to GLB", **Then** on-device conversion begins with progress indicator
2. **Given** conversion in progress (typical room <200k triangles), **When** processing completes, **Then** GLB file created locally within 10 seconds
3. **Given** GLB conversion successful, **When** user opens web preview, **Then** GLB loads in Three.js/WebGL viewer with correct geometry, materials, and textures
4. **Given** conversion fails (unsupported geometry, memory limit), **When** error occurs, **Then** clear error message displayed with specific error code (e.g., "UNSUPPORTED_PRIM", "MEMORY_EXCEEDED")
5. **Given** GLB file created, **When** user saves to project, **Then** both USDZ and GLB uploaded to backend (GLB cached for faster web delivery)

**Technical Architecture** (from PRD):

- **Core**: C++ static library wrapping Pixar USD SDK (read USDZ) + glTF/GLB writer (export binary GLB 2.0)
- **iOS Binding**: Swift wrapper framework `UsdToGlbConverter` with async APIs
- **Flutter Interface**:
  ```dart
  Future<GlbConversionResult> convertUsdzToGlb(
    String usdzPath,
    {String? outPath, GlbConversionOptions? options}
  )
  ```
- **Result Object**:
  - `bool success`
  - `String? glbPath`
  - `String? errorCode` (e.g., UNSUPPORTED_PRIM, MISSING_TEXTURE, READ_ERROR)
  - `String? errorMessage`
  - `ConversionStats? stats` (triangle count, mesh count, duration)

**Conversion Rules**:

1. **Geometry**: Triangulate non-triangle faces, preserve vertex positions/normals/UVs/indices
2. **Materials**: Map USD PBR → glTF PBR (baseColor, metallicRoughness, normal, AO), fallback to flat baseColor if unsupported
3. **Textures**: Embed textures as PNG/JPEG in GLB binary, downscale if exceeds maxTextureSize option
4. **Coordinate System**: Convert USD right-handed Z-up → glTF right-handed Y-up, bake corrections into node transforms
5. **Scene Structure**: Support single scene, single root, multiple nodes (no animations/rigs in v1)

**Performance Requirements**:

- Typical room (≤200k triangles): <10 seconds on mid-range iOS devices (iPhone 13 Pro baseline)
- Peak memory usage: <512 MB for typical models
- Deterministic output: Same USDZ input → identical GLB bytes (given same options)

**Conversion Options** (user configurable via settings):

- `optimizeMeshes` (bool): Enable vertex deduplication and mesh merging by material
- `maxTextureSize` (int): Downscale textures larger than threshold (default: 2048px)
- `bakeTransforms` (bool): Bake node transforms into vertices for simpler scene graph

**Error Handling**:

- `UNSUPPORTED_PRIM`: USDZ contains geometry types not supported in glTF (e.g., NURBS, volumes)
- `MISSING_TEXTURE`: Referenced texture file not found in USDZ bundle
- `READ_ERROR`: Cannot read USDZ file (corrupted, access denied)
- `MEMORY_EXCEEDED`: Conversion requires more than 512 MB RAM
- `TIMEOUT`: Conversion exceeds 30 second timeout (abnormally complex model)

### Edge Cases

- Device lacks LiDAR sensor (all Android devices, iOS devices pre-iPhone 12 Pro)
- Permissions denied (camera/sensor access)
- Insufficient device storage for USDZ and/or GLB files
- Scan interrupted by phone call or app backgrounding (user prompted to save partial, discard, or continue)
- GLB file exceeds 250 MB size limit
- USDZ→GLB conversion fails due to unsupported geometry (NURBS, volumes)
- USDZ→GLB conversion exceeds memory limit (>512 MB)
- USDZ→GLB conversion timeout (>30 seconds for abnormally complex models)
- Missing or corrupted textures in USDZ bundle during conversion
- Device thermal throttling during conversion (performance degradation)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST check device LiDAR capability (iOS only: iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro and iPad Pro 2020+ with LiDAR scanner)
- **FR-002**: System MUST disable scanning button if device lacks LiDAR (all Android devices and older iOS devices without LiDAR sensor)
- **FR-003**: System MUST request camera/sensor permissions
- **FR-004**: System MUST use flutter_roomplan for scanning
- **FR-005**: System MUST store scan data locally in USDZ format (Apple's native Room Plan output) without immediate upload
- **FR-006**: System MUST support GLB file upload with maximum file size of 250 MB
- **FR-007**: System MUST validate GLB file size before upload and reject files exceeding 250 MB with clear error message
- **FR-008**: System MUST upload USDZ scan data to backend only when user explicitly saves to project (via UC20 Save to Project)
- **FR-009**: System MUST detect scan interruptions (phone call, app backgrounded, low battery warning) and prompt user with options: "Save Partial Scan", "Discard", or "Continue Scanning"

### Data Model

**Scan Data Entity**:
- Format: USDZ (Universal Scene Description, Apple's AR format)
- Source: flutter_roomplan native output
- Storage: Local device filesystem
- Conversion: USDZ → GLB conversion happens server-side for cross-platform compatibility
- Size: Typical room scan 5-50 MB

### Platform Constraints

**LiDAR Scanning (MVP)**:
- **Supported**: iOS only (iPhone 12 Pro and newer, iPad Pro 2020+ with LiDAR)
- **Not Supported**: Android devices (deferred to future release)
- **Technology**: flutter_roomplan (Apple RoomPlan API wrapper)
- **Minimum iOS**: iOS 16.0+ (required by RoomPlan framework)
- **Fallback**: Users on unsupported devices can use GLB file upload (US2)

## Success Criteria *(mandatory)*

- **SC-001**: Scan initiates within 2 seconds of button tap
- **SC-002**: Scanning maintains 30fps minimum
- **SC-003**: Scan data captured without data loss

## Dependencies

- **Depends on**: UC7 (Guest Mode) or UC2 (Auth) for access
- **Blocks**: UC15 (Post-Scan Preview)
- **Enables**: UC20 (Save to Project) - scan data upload triggered via save flow
