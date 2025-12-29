# Feature Specification: LiDAR Scanning

**Feature Branch**: `014-lidar-scanning`
**Created**: 2025-12-20
**Status**: Phase 1-3 Complete (MVP deployed), Phase 4-6 In Planning

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
5. **Given** scan stored locally, **When** user saves to project (US3), **Then** USDZ uploaded to BlenderAPI for GLB conversion

### User Story 2 - Upload GLB (Priority: P2)

User can upload existing GLB file instead of scanning. To use Pre view feature with that data.

**Why this priority**: Alternative input method for pre-existing models.

**Independent Test**: Select file picker, choose GLB, verify uploaded.

**Acceptance Scenarios**:

1. **Given** scanning screen, **When** user taps upload, **Then** file picker opens
2. **Given** GLB selected, **When** upload completes, **Then** file stored locally

### User Story 3 - Save Scan to Project with Server-Side Conversion (Priority: P2)

User can upload USDZ scan to backend BlenderAPI service where it is converted to GLB format, enabling cross-platform preview and project integration without requiring on-device conversion complexity.

**Why this priority**: Enables scans to be saved to projects and viewed in web-based 3D viewers (Three.js, Babylon.js, WebXR). Server-side conversion reduces app complexity, avoids 50-150 MB binary size increase from USD SDK, and leverages proven cloud conversion services (BlenderAPI with Blender's USDZ import and GLB export).

**Independent Test**: Complete LiDAR scan, tap "Save to Project", select project, verify USDZ uploaded to BlenderAPI, poll for conversion status, verify GLB download URL returned and scan associated with project.

**Acceptance Scenarios**:

1. **Given** USDZ scan completed and stored locally, **When** authenticated user taps "Save to Project", **Then** project selection screen appears
2. **Given** project selected, **When** user confirms save, **Then** BlenderAPI session created and USDZ file uploads with progress indicator showing upload percentage
3. **Given** upload completes successfully, **When** BlenderAPI begins USDZ→GLB conversion, **Then** app polls conversion status every 2 seconds with "Converting scan..." progress message and percentage
4. **Given** conversion in progress (typical room <200k triangles), **When** server processing completes, **Then** GLB download URL returned within 5-30 seconds
5. **Given** conversion successful, **When** GLB downloaded and scan data saved, **Then** both USDZ source and GLB preview files stored in backend project storage and scan metadata saved to GraphQL database
6. **Given** conversion fails (unsupported geometry, server timeout, invalid USDZ), **When** error occurs, **Then** clear error message displayed with retry option and scan remains in local storage
7. **Given** guest user taps "Save to Project", **When** not authenticated, **Then** prompt to create account or sign in appears with link to VRON merchant portal

**Backend Integration - BlenderAPI Service**:

- **API Base URL**: Stored in `.env` file as `BLENDER_API_BASE_URL` (default: `https://blenderapi.stage.motorenflug.at`)
- **API Key**: Stored in `.env` file as `BLENDER_API_KEY` (obtained from administrator, min 16 characters)
- **Authentication**: All requests require `X-API-Key` header
- **Rate Limiting**: Maximum 3 concurrent sessions per API key
- **File Size Limit**: 500MB per file (USDZ scans typically 5-50 MB)
- **Processing Timeout**: 15 minutes (900 seconds) maximum

**Conversion Workflow** (see `Requirements/FLUTTER_API_PRD.md` for complete API details):

1. **Create Session**: `POST /sessions`
   - Returns: `session_id` (UUID), `expires_at` (1 hour expiration)

2. **Upload USDZ**: `POST /sessions/{session_id}/upload`
   - Headers: `X-Asset-Type: model/vnd.usdz+zip`, `X-Filename: scan.usdz`
   - Body: Binary USDZ file content
   - Returns: Upload confirmation with file size and timestamp

3. **Start Conversion**: `POST /sessions/{session_id}/convert`
   - Body:
     ```json
     {
       "job_type": "usdz_to_glb",
       "input_filename": "scan.usdz",
       "output_filename": "scan.glb",
       "conversion_params": {
         "apply_scale": false,
         "merge_meshes": false,
         "target_scale": 1.0
       }
     }
     ```
   - Returns: Processing started confirmation

4. **Poll Status**: `GET /sessions/{session_id}/status` (every 2 seconds)
   - Returns: `session_status` (processing/completed/failed), `progress` (0-100%), `result` object
   - Status values: `pending`, `uploading`, `validating`, `processing`, `completed`, `failed`, `expired`

5. **Download GLB**: `GET /sessions/{session_id}/download/{filename}`
   - Returns: Binary GLB file content
   - Content-Type: `model/gltf-binary`

6. **Cleanup**: `DELETE /sessions/{session_id}` (optional, sessions auto-expire after 1 hour)

**GraphQL Integration** (after BlenderAPI conversion completes):

- **Mutation**: `uploadProjectScan(input: UploadProjectScanInput!)`
  - Input: `projectId` (ID), `usdzUrl` (String), `glbUrl` (String), `format` (ScanFormat.USDZ), `metadata` (JSON with file sizes, polygon counts)
  - Output: `scan` (Scan with id, usdzUrl, glbUrl, status), `success` (Boolean), `message` (String)
- **Storage**: USDZ and GLB files stored in S3 or equivalent cloud storage (URLs returned by BlenderAPI)
- **Association**: Scan entity linked to Project entity in PostgreSQL database

**Performance Requirements**:

- Upload time: <30 seconds for 50 MB file on 10 Mbps connection
- Server conversion time: 5-30 seconds for typical room (BlenderAPI SLA)
- Polling interval: 2 seconds (balance between responsiveness and server load)
- Timeout: 15 minutes maximum (BlenderAPI processing timeout), show "Taking longer than expected" after 60 seconds with manual refresh option
- GLB download time: <15 seconds for typical converted file

**Error Handling**:

- **Network failure during upload**: Show "Upload failed. Check your connection and try again." with retry button
- **BlenderAPI session creation failure (401 Unauthorized)**: Show "Service authentication failed. Please contact support." (indicates .env API key issue)
- **BlenderAPI rate limit (429 Too Many Requests)**: Show "Service busy. Maximum 3 scans can be processed simultaneously. Please try again in a moment."
- **BlenderAPI conversion timeout (>15 minutes)**: Show "Conversion timed out. The scan file may be too complex. Please try a smaller area."
- **Conversion failure (session_status: failed)**: Show "Unable to convert scan. The scan file may be corrupted or contain unsupported geometry." with retry or contact support options
- **File size exceeded (>500MB)**: Show "Scan file too large. Maximum file size is 500MB." (should not occur with typical LiDAR scans)
- **Authentication expired during upload**: Prompt user to re-authenticate and resume upload
- **GraphQL save failure**: Show "Scan converted successfully but failed to save to project. Please try again."

**Configuration** (.env file):

```env
# BlenderAPI Configuration
BLENDER_API_BASE_URL=https://blenderapi.stage.motorenflug.at
BLENDER_API_KEY=your-api-key-here-min-16-chars

# Optional: Override default timeouts
BLENDER_API_TIMEOUT_SECONDS=900
BLENDER_API_POLL_INTERVAL_SECONDS=2
```

### Edge Cases

- Device lacks LiDAR sensor (all Android devices, iOS devices pre-iPhone 12 Pro)
- Permissions denied (camera/sensor access)
- Insufficient device storage for USDZ and/or GLB files
- Scan interrupted by phone call or app backgrounding (user prompted to save partial, discard, or continue)
- GLB file exceeds 250 MB size limit (GLB upload via US2)
- USDZ file exceeds 500 MB size limit (rare, typical scans 5-50 MB)
- Network failure during USDZ upload to BlenderAPI
- BlenderAPI service unavailable (503 Service Unavailable)
- BlenderAPI conversion timeout (>15 minutes for abnormally complex models)
- BlenderAPI conversion fails due to unsupported USDZ geometry or corrupted file
- BlenderAPI rate limit exceeded (>3 concurrent sessions per API key)
- User authentication token expires during upload/conversion (requires re-authentication)
- User loses network connectivity while polling conversion status (resume on reconnect)
- Project storage quota exceeded (cannot save additional scans to project)
- User navigates away from app during upload/conversion (background upload handling or cancellation prompt)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST check device LiDAR capability (iOS only: iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro and iPad Pro 2020+ with LiDAR scanner)
- **FR-002**: System MUST disable scanning button if device lacks LiDAR (all Android devices and older iOS devices without LiDAR sensor)
- **FR-003**: System MUST request camera/sensor permissions
- **FR-004**: System MUST use flutter_roomplan for scanning
- **FR-005**: System MUST store scan data locally in USDZ format (Apple's native Room Plan output) without immediate upload
- **FR-006**: System MUST support GLB file upload with maximum file size of 250 MB
- **FR-007**: System MUST validate GLB file size before upload and reject files exceeding 250 MB with clear error message
- **FR-008**: System MUST upload USDZ scan data to BlenderAPI backend only when user explicitly saves to project (via US3 Save Scan to Project)
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

- **Depends on**: Feature 007 (Guest Mode) or Feature 003 (Auth) for access
- **Blocks**: Feature 015 (Post-Scan Preview)
- **Enables**: US3 (Save Scan to Project) - USDZ upload to BlenderAPI and GLB conversion triggered via save flow
