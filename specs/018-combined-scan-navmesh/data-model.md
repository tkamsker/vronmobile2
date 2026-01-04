# Data Model: Combined Scan to NavMesh Workflow

**Feature**: 018-combined-scan-navmesh
**Date**: 2026-01-04
**Status**: Complete

## Overview

This document defines the data models for the Combined Scan to NavMesh feature. The models support tracking combined scan state, managing upload/conversion progress, and storing navmesh metadata.

---

## Entity: ScanData (UPDATED)

**Location**: `lib/features/scanning/models/scan_data.dart`
**Status**: ✅ **Already Implemented** (positions added in Feature 017)

### Purpose
Stores individual room scan data with positioning information from the canvas arrangement.

### Fields

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | No | UUID | Unique identifier |
| `format` | ScanFormat | No | - | USDZ or GLB |
| `localPath` | String | No | - | Local filesystem path |
| `glbLocalPath` | String | Yes | null | Local GLB path (if converted) |
| `fileSizeBytes` | int | No | - | File size in bytes |
| `capturedAt` | DateTime | No | - | Scan completion timestamp |
| `status` | ScanStatus | No | - | Current scan status |
| `projectId` | String | Yes | null | Associated project ID |
| `remoteUrl` | String | Yes | null | Backend URL after upload |
| `metadata` | Map<String, dynamic> | Yes | null | Additional metadata |
| **`positionX`** | **double** | **Yes** | **null** | **X position on canvas** |
| **`positionY`** | **double** | **Yes** | **null** | **Y position on canvas** |
| **`rotationDegrees`** | **double** | **Yes** | **null** | **Rotation in degrees** |
| **`scaleFactor`** | **double** | **Yes** | **null** | **Scale factor (default 1.0)** |

### Enums

```dart
enum ScanFormat {
  usdz,  // Apple RoomPlan native output
  glb,   // glTF binary format
}

enum ScanStatus {
  capturing,   // Scan in progress
  completed,   // Scan finished, stored locally
  uploading,   // Upload to backend in progress
  uploaded,    // Successfully uploaded to backend
  failed,      // Scan or upload failed
}
```

### Methods

```dart
// JSON serialization
Map<String, dynamic> toJson()
factory ScanData.fromJson(Map<String, dynamic> json)

// Copy with
ScanData copyWith({...})

// Helpers
Future<bool> existsLocally()
Future<void> deleteLocally()
Future<List<int>> readBytes()
```

### Validation Rules

- `id`: Must be valid UUID v4
- `positionX`, `positionY`: Can be any double value (canvas coordinates)
- `rotationDegrees`: 0-360 degrees (wraps around)
- `scaleFactor`: Must be > 0.0 if not null (typical range 0.1-5.0)
- `localPath`: Must be absolute path to existing file
- `fileSizeBytes`: Must be > 0

### State Transitions

```
capturing → completed → uploading → uploaded
                     ↘
                      failed
```

---

## Entity: CombinedScan (NEW)

**Location**: `lib/features/scanning/models/combined_scan.dart` (to be created)
**Status**: 🔴 **Not Implemented**

### Purpose
Tracks the state of a combined scan through the combine → upload → GLB conversion → navmesh generation workflow.

### Fields

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | String | No | UUID | Unique identifier (also backend scan ID) |
| `projectId` | String | No | - | Associated project ID |
| `scanIds` | List<String> | No | [] | Source scan IDs (in combination order) |
| `localCombinedPath` | String | No | - | Local combined USDZ file path |
| `combinedGlbUrl` | String | Yes | null | Backend GLB URL (after conversion) |
| `combinedGlbLocalPath` | String | Yes | null | Local GLB file path (downloaded from backend) |
| `navmeshSessionId` | String | Yes | null | BlenderAPI session ID for navmesh generation |
| `navmeshUrl` | String | Yes | null | Downloaded navmesh GLB URL (from blenderapi session) |
| `localNavmeshPath` | String | Yes | null | Local navmesh file path (after download) |
| `status` | CombinedScanStatus | No | combining | Current status |
| `createdAt` | DateTime | No | now | Creation timestamp |
| `completedAt` | DateTime | Yes | null | Completion timestamp |
| `errorMessage` | String | Yes | null | Error message if failed |

### Enums

```dart
enum CombinedScanStatus {
  combining,            // Creating local USDZ on-device
  uploadingUsdz,        // Uploading combined USDZ to GraphQL backend
  processingGlb,        // Backend creating GLB from USDZ
  glbReady,             // GLB created and downloaded, ready for navmesh
  uploadingToBlender,   // Uploading GLB to BlenderAPI session
  generatingNavmesh,    // BlenderAPI creating navmesh from GLB
  downloadingNavmesh,   // Downloading navmesh from BlenderAPI
  completed,            // Both GLB and navmesh ready locally
  failed,               // Operation failed (see errorMessage)
}
```

### Methods

```dart
// JSON serialization
Map<String, dynamic> toJson()
factory CombinedScan.fromJson(Map<String, dynamic> json)

// Copy with
CombinedScan copyWith({...})

// Helpers
bool isInProgress() => status != CombinedScanStatus.completed &&
                       status != CombinedScanStatus.failed
bool canGenerateNavmesh() => status == CombinedScanStatus.glbReady
bool hasGlb() => combinedGlbUrl != null
bool hasNavmesh() => navmeshUrl != null && localNavmeshPath != null
Future<int?> getLocalCombinedFileSize()
Future<int?> getLocalNavmeshFileSize()
Future<void> deleteLocalFiles()
```

### Validation Rules

- `id`: Must be valid UUID v4
- `projectId`: Must be valid UUID v4
- `scanIds`: Must contain at least 2 scan IDs
- `localCombinedPath`: Must be absolute path
- Status transitions must follow valid flow (see State Transitions)
- `completedAt`: Must be after `createdAt` if not null
- `errorMessage`: Only set when status == failed

### State Transitions

```
combining → uploadingUsdz → processingGlb → glbReady → uploadingToBlender → generatingNavmesh → downloadingNavmesh → completed
    ↓            ↓               ↓             ↓               ↓                    ↓                    ↓                ↓
  failed       failed          failed        failed          failed              failed              failed           failed
```

**Valid Transitions**:
- `combining` → `uploadingUsdz`, `failed`
- `uploadingUsdz` → `processingGlb`, `failed`
- `processingGlb` → `glbReady`, `failed`
- `glbReady` → `uploadingToBlender`, `failed`
- `uploadingToBlender` → `generatingNavmesh`, `failed`
- `generatingNavmesh` → `downloadingNavmesh`, `failed`
- `downloadingNavmesh` → `completed`, `failed`
- `completed` → (terminal state)
- `failed` → (terminal state, can retry from beginning)

**Note**: The navmesh generation uses BlenderAPI session-based workflow:
1. Create session → Upload GLB → Start navmesh → Poll status → Download result → Delete session

---

## Entity: NavMeshMetadata (EMBEDDED)

**Location**: Part of `CombinedScan` model
**Status**: 🔴 **Not Implemented**

### Purpose
Stores metadata about the generated navigation mesh (embedded in CombinedScan, not separate entity).

### Fields (Embedded in CombinedScan)

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `navmeshUrl` | String | Yes | Backend URL for navmesh GLB file |
| `localNavmeshPath` | String | Yes | Local path after download |
| `navmeshSizeBytes` | int | Yes | File size of navmesh GLB |
| `navmeshGeneratedAt` | DateTime | Yes | Timestamp of generation |

### Rationale for Embedding
- One-to-one relationship with CombinedScan
- No independent lifecycle
- Simpler data model and queries
- Follows YAGNI principle

---

## Relationships

```
Project (existing)
    ↓ 1:N
ScanData (updated with positions)
    ↓ N:1
CombinedScan (references multiple scans)
    ↓ 1:1 (embedded)
NavMeshMetadata
```

### Relationship Details

1. **Project → ScanData** (existing)
   - One project has many scans
   - `ScanData.projectId` references project

2. **CombinedScan → ScanData** (new)
   - One combined scan references multiple source scans
   - `CombinedScan.scanIds` contains list of scan IDs
   - Many-to-one: Multiple combined scans could theoretically reference the same source scans

3. **CombinedScan → NavMeshMetadata** (embedded)
   - One combined scan has one navmesh
   - Embedded fields in CombinedScan model

---

## Storage Strategy

### Local Storage (SharedPreferences)

**Key**: `combined_scans`
**Value**: JSON array of CombinedScan objects
**Max Size**: ~100 KB (estimated 10-20 combined scans)

```dart
// Storage service methods
class CombinedScanStorage {
  Future<List<CombinedScan>> getAllCombinedScans()
  Future<CombinedScan?> getCombinedScan(String id)
  Future<void> saveCombinedScan(CombinedScan scan)
  Future<void> deleteCombinedScan(String id)
  Future<List<CombinedScan>> getCombinedScansForProject(String projectId)
}
```

### Local Files

**Location**: App documents directory
**Structure**:
```
/Documents/
  scans/
    combined/
      {combined_scan_id}.usdz        # Combined USDZ file
      {combined_scan_id}_navmesh.glb # Downloaded navmesh
```

### Backend Storage (Existing Infrastructure)

- Combined USDZ: S3 bucket (same as individual scans)
- Combined GLB: S3 bucket (converted from USDZ)
- NavMesh GLB: S3 bucket (generated from combined GLB)
- Metadata: PostgreSQL database (scan records)

---

## Data Flow

```
1. User arranges scans on canvas
   ↓
   ScanData.positionX/Y/rotation/scale updated

2. User taps "Combine Scans to GLB"
   ↓
   CombinedScan created (status: combining)
   ↓
   Native iOS code combines USDZ files → localCombinedPath
   ↓
   status → uploadingUsdz

3. Upload USDZ to GraphQL backend
   ↓
   status → processingGlb
   ↓
   Backend converts USDZ → GLB (existing pipeline)
   ↓
   Download GLB to local device
   ↓
   combinedGlbUrl set, combinedGlbLocalPath set, status → glbReady

4. User taps "Generate NavMesh"
   ↓
   status → uploadingToBlender
   ↓
   Create BlenderAPI session → navmeshSessionId
   ↓
   Upload GLB file to session
   ↓
   status → generatingNavmesh
   ↓
   Start navmesh generation with parameters
   ↓
   Poll session status (every 2 seconds)
   ↓
   status → downloadingNavmesh
   ↓
   Download navmesh GLB from session
   ↓
   Delete BlenderAPI session (cleanup)
   ↓
   localNavmeshPath set, navmeshUrl set, status → completed
```

---

## Migration Considerations

### Existing Data

- `ScanData` model already updated with position fields (Feature 017)
- No migration needed for existing scans
- Position fields are nullable, default to null for old scans

### New Data

- `CombinedScan` is entirely new entity
- No migration scripts needed
- SharedPreferences key `combined_scans` created on first use

---

## Testing Data

### Unit Test Fixtures

```dart
// Mock ScanData with positions
final mockScan1 = ScanData(
  id: 'scan-1',
  format: ScanFormat.usdz,
  localPath: '/path/to/scan1.usdz',
  fileSizeBytes: 5242880, // 5 MB
  capturedAt: DateTime(2026, 1, 4, 10, 0),
  status: ScanStatus.completed,
  projectId: 'project-1',
  positionX: 0.0,
  positionY: 0.0,
  rotationDegrees: 0.0,
  scaleFactor: 1.0,
);

final mockScan2 = ScanData(
  id: 'scan-2',
  format: ScanFormat.usdz,
  localPath: '/path/to/scan2.usdz',
  fileSizeBytes: 4194304, // 4 MB
  capturedAt: DateTime(2026, 1, 4, 10, 5),
  status: ScanStatus.completed,
  projectId: 'project-1',
  positionX: 150.0,
  positionY: 0.0,
  rotationDegrees: 90.0,
  scaleFactor: 1.0,
);

// Mock CombinedScan
final mockCombinedScan = CombinedScan(
  id: 'combined-1',
  projectId: 'project-1',
  scanIds: ['scan-1', 'scan-2'],
  localCombinedPath: '/path/to/combined_scan_1.usdz',
  combinedGlbUrl: 'https://api.example.com/scans/combined-1.glb',
  navmeshUrl: 'https://api.example.com/scans/combined-1_navmesh.glb',
  localNavmeshPath: '/path/to/combined_scan_1_navmesh.glb',
  status: CombinedScanStatus.completed,
  createdAt: DateTime(2026, 1, 4, 11, 0),
  completedAt: DateTime(2026, 1, 4, 11, 5),
);
```

---

## References

- Feature Specification: `specs/018-combined-scan-navmesh/spec.md`
- Research Document: `specs/018-combined-scan-navmesh/research.md`
- Existing ScanData Model: `lib/features/scanning/models/scan_data.dart`
