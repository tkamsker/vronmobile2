# Feature 018: Combined Scan to NavMesh Workflow

**Status**: Planning
**Created**: 2026-01-04
**Priority**: High

## Overview

Combine multiple positioned room scans into a single GLB file with navmesh generation for Unity/game engine integration.

## Clarifications

### Session 2026-01-04

- Q: How should navmesh parameters be configured (cell_size, agent_height, etc.)? → A: Hard-code Unity-standard defaults (agent_height: 2.0, agent_radius: 0.6, cell_size: 0.3) with no user configuration

### Key Architecture Decisions

1. **ONE Combined File**
   - App creates **ONE combined USDZ** file on-device containing all scans
   - This single file is uploaded, converted, and used for navmesh generation
   - Simplifies workflow and reduces backend complexity

2. **Reuse Existing APIs**
   - Uses existing `uploadProjectScan` GraphQL mutation
   - Uses existing USDZ→GLB conversion pipeline
   - Uses existing `ScanUploadService` for upload/polling
   - **Reuses existing BlenderAPI microservice** for navmesh generation (ZERO new backend code required)

3. **Follows BYO Pattern**
   - NavMesh generation follows same pattern as existing BYO project service
   - Backend already handles navigation mesh GLB files
   - Consistent with existing architecture

## User Story

As a user, I want to combine multiple room scans that I've arranged on the canvas into a single 3D model file with a navigation mesh, so I can use the complete floor plan in Unity or other game engines.

## Feature Flow

```
1. User arranges rooms on canvas → Positions saved to ScanData
2. User navigates to Project Detail screen
3. User taps "Combine Scans to GLB" button
4. App creates ONE combined USDZ file on-device with all scans + transforms
5. App uploads combined USDZ using existing uploadProjectScan mutation
6. Backend converts combined USDZ → GLB (existing conversion flow)
7. App polls for GLB conversion completion (existing polling)
8. App shows "Generate NavMesh" button when GLB ready
9. User taps "Generate NavMesh"
10. Backend generates navmesh from Combined GLB
11. App downloads and stores navmesh GLB
12. User can export both Combined GLB + NavMesh GLB
```

**Key Points**:
- ✅ **ONE combined USDZ** created on-device (not multiple files)
- ✅ **Reuses existing upload flow** (`uploadProjectScan` mutation)
- ✅ **Reuses existing conversion** (USDZ → GLB backend pipeline)
- ✅ **Follows BYO pattern** for navmesh generation

## Data Model Changes

### ScanData (COMPLETED)
```dart
class ScanData {
  // ... existing fields ...

  // New fields for positioning
  final double? positionX;      // X position from canvas
  final double? positionY;      // Y position from canvas
  final double? rotationDegrees; // Rotation in degrees
  final double? scaleFactor;    // Scale factor (default 1.0)
}
```

### CombinedScan (NEW)
```dart
class CombinedScan {
  final String id;                    // UUID
  final String projectId;             // Associated project
  final List<String> scanIds;         // Source scans
  final String localCombinedPath;     // Local combined USDZ
  final String? combinedGlbUrl;       // Backend GLB URL
  final String? navmeshUrl;           // Backend navmesh URL
  final String? localNavmeshPath;     // Local navmesh file
  final CombinedScanStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
}

enum CombinedScanStatus {
  combining,        // Creating local USDZ
  uploading,        // Uploading to backend
  processing,       // Backend creating GLB
  glbReady,         // GLB created, ready for navmesh
  generatingNavmesh, // Creating navmesh
  completed,        // Both GLB and navmesh ready
  failed,
}
```

## UI Components

### 1. Project Detail Screen Enhancement

**Location**: `lib/features/projects/screens/project_detail_screen.dart`

**Add Button**:
```dart
ElevatedButton.icon(
  icon: Icon(Icons.view_in_ar),
  label: Text('Combine Scans to GLB'),
  onPressed: _hasScanWithPositions() ? _startCombineFlow : null,
)
```

**Conditions**:
- Enabled only if project has ≥2 scans with position data
- Shows scan count: "Combine 3 Scans to GLB"

### 2. Combine Progress Dialog

**Shows during**:
- Combining USDZ files (on-device)
- Uploading to backend
- Backend GLB creation

**UI**:
```
┌─────────────────────────────────┐
│ Combining Room Scans            │
│                                 │
│ ● Combining scans... ✓          │
│ ● Uploading to server... ⟳     │
│ ○ Creating Combined GLB         │
│                                 │
│ [Progress Bar]                  │
│                                 │
│        [Cancel]                 │
└─────────────────────────────────┘
```

### 3. Generate NavMesh Button

**Appears after**: Combined GLB is ready (status = glbReady)

**Location**: Same as Combine button, but replaces it

```dart
ElevatedButton.icon(
  icon: Icon(Icons.grid_on),
  label: Text('Generate NavMesh'),
  onPressed: _generateNavmesh,
)
```

### 4. Export Options

**After completion**, show export dialog:
```
┌─────────────────────────────────┐
│ Combined Scan Ready             │
│                                 │
│ ✓ Combined GLB (12.4 MB)        │
│ ✓ Navigation Mesh (1.2 MB)      │
│                                 │
│ [Export Combined GLB]           │
│ [Export NavMesh]                │
│ [Export Both as ZIP]            │
│                                 │
│        [Close]                  │
└─────────────────────────────────┘
```

## Technical Implementation

### Phase 1: Save Positions After Stitching

**File**: `lib/features/scanning/screens/room_stitching_screen.dart`

**Task**: When user completes room arrangement, save positions to ScanData

```dart
Future<void> _saveRoomPositions(RoomLayout layout) async {
  for (final room in layout.rooms) {
    final scan = scans.firstWhere((s) => s.id == room.scanId);
    final updatedScan = scan.copyWith(
      positionX: room.positionOffset.dx,
      positionY: room.positionOffset.dy,
      rotationDegrees: room.rotationDegrees,
      scaleFactor: room.scaleFactor,
    );
    await _scanService.updateScan(updatedScan);
  }
}
```

### Phase 2: On-Device USDZ Combination

**File**: `lib/features/scanning/services/usdz_combiner_service.dart` (NEW)

**Objective**: Create **ONE combined USDZ file** containing all room scans

**Requirements**:
- Use SceneKit (iOS native) to load and combine multiple USDZ files
- Apply saved transforms (position, rotation, scale) to each scan's root node
- Merge all scenes into ONE combined scene
- Export as **single USDZ file** ready for upload
- File naming: `combined_scan_{projectId}_{timestamp}.usdz`

**Platform Channel** (iOS native code required):
```swift
// ios/Runner/USDZCombiner.swift
class USDZCombiner {
    func combineScans(
        scanPaths: [String],
        transforms: [Transform]
    ) -> String {
        // 1. Load each USDZ into SCNScene
        // 2. Apply transforms to root nodes
        // 3. Combine into single scene
        // 4. Export as USDZ
        // 5. Return combined file path
    }
}

struct Transform {
    let position: SIMD3<Float>
    let rotation: Float // degrees
    let scale: Float
}
```

**Dart Service**:
```dart
class USDZCombinerService {
  static const platform = MethodChannel('com.vron.usdz_combiner');

  Future<String> combineScans(List<ScanData> scans) async {
    final transforms = scans.map((s) => {
      'positionX': s.positionX ?? 0.0,
      'positionY': s.positionY ?? 0.0,
      'rotation': s.rotationDegrees ?? 0.0,
      'scale': s.scaleFactor ?? 1.0,
    }).toList();

    final paths = scans.map((s) => s.localPath).toList();

    final combinedPath = await platform.invokeMethod(
      'combineScans',
      {
        'paths': paths,
        'transforms': transforms,
      },
    );

    return combinedPath;
  }
}
```

### Phase 3: Backend API Integration

**Uses EXISTING API patterns - NO new routes needed!**

#### 1. Upload Combined USDZ (EXISTING)

**Uses**: `uploadProjectScan` mutation (already exists)

```graphql
mutation UploadProjectScan($projectId: UUID!, $file: Upload!) {
  uploadProjectScan(input: {
    projectId: $projectId
    file: $file
  }) {
    scan {
      id
      projectId
      format
      usdzUrl
      glbUrl
      conversionStatus  # "processing", "completed", "failed"
      error { code, message }
    }
    success
    message
  }
}
```

**Implementation**:
```dart
// Use existing ScanUploadService
final result = await ScanUploadService().uploadScan(
  scanData: combinedScanData,
  projectId: projectId,
  onProgress: (progress) => print('Upload: $progress'),
);
```

#### 2. Poll GLB Conversion (EXISTING)

**Uses**: `pollConversionStatus` method (already exists)

```dart
// Use existing polling from ScanUploadService
await ScanUploadService().pollConversionStatus(
  scanId: result.scan.id,
  onStatusChange: (status) => print('Status: $status'),
);
```

#### 3. Generate NavMesh (Uses Existing BlenderAPI)

**Backend**: Reuses existing BlenderAPI microservice - NO new code needed

**Workflow**: Session-based REST API (6 steps)
1. Create session: `POST /sessions`
2. Upload GLB: `POST /sessions/{id}/upload`
3. Start navmesh: `POST /sessions/{id}/navmesh` with navmesh_params
4. Poll status: `GET /sessions/{id}/status` (every 2 seconds)
5. Download result: `GET /sessions/{id}/download/{filename}`
6. Cleanup: `DELETE /sessions/{id}`

**NavMesh Parameters**: Hard-coded Unity-standard defaults (no user configuration):
- `cell_size`: 0.3 (30cm grid resolution)
- `cell_height`: 0.2 (20cm height resolution)
- `agent_height`: 2.0 (2m tall agent - Unity default)
- `agent_radius`: 0.6 (60cm wide agent)
- `agent_max_climb`: 0.9 (90cm max step height)
- `agent_max_slope`: 45.0 (45° max slope angle)

**See**: `contracts/blenderapi-rest.md` for complete REST API documentation

#### 4. Poll NavMesh Status (BlenderAPI Session)

**Implementation**: Included in BlenderAPI REST workflow (step 4 above)

```bash
GET /sessions/{session_id}/status
Response: {
  "session_id": "...",
  "status": "PROCESSING" | "COMPLETED" | "FAILED",
  "available_files": ["navmesh_combined_scan.glb"]
}
```

**Note**: Status polling integrated into `BlenderAPIService.waitForCompletion()` method

### Phase 4: State Management

**File**: `lib/features/scanning/services/combined_scan_service.dart` (NEW)

**Key**: Reuses existing `ScanUploadService` for all upload/polling

```dart
class CombinedScanService {
  final USDZCombinerService _combiner;
  final ScanUploadService _uploadService; // EXISTING service

  Future<CombinedScan> createCombinedScan(
    String projectId,
    List<ScanData> scans,
  ) async {
    // 1. Combine USDZ files on-device → ONE file
    print('📦 Combining ${scans.length} scans into ONE USDZ...');
    final combinedPath = await _combiner.combineScans(scans);

    // 2. Create ScanData for combined file
    final combinedScanData = ScanData(
      id: Uuid().v4(),
      format: ScanFormat.usdz,
      localPath: combinedPath,
      fileSizeBytes: await File(combinedPath).length(),
      capturedAt: DateTime.now(),
      status: ScanStatus.uploading,
      projectId: projectId,
    );

    // 3. Upload using EXISTING upload service
    print('📤 Uploading combined USDZ using existing API...');
    final result = await _uploadService.uploadScan(
      scanData: combinedScanData,
      projectId: projectId,
      onProgress: (progress) => print('Upload: ${(progress * 100).toStringAsFixed(0)}%'),
    );

    // 4. Poll for GLB conversion using EXISTING polling
    print('⏳ Polling for GLB conversion...');
    await _uploadService.pollConversionStatus(
      scanId: result.scan.id,
      onStatusChange: (status) => print('Conversion: $status'),
    );

    print('✅ Combined GLB ready!');
    return CombinedScan(
      id: result.scan.id,
      projectId: projectId,
      scanIds: scans.map((s) => s.id).toList(),
      localCombinedPath: combinedPath,
      combinedGlbUrl: result.scan.glbUrl,
      status: CombinedScanStatus.glbReady,
      createdAt: DateTime.now(),
    );
  }

  Future<void> generateNavmesh(String combinedScanId) async {
    // 1. Request navmesh generation with hard-coded Unity-standard defaults
    print('🗺️ Requesting navmesh generation...');
    await _blenderAPIService.generateNavMesh(
      glbFile: combinedGlbFile,
      outputPath: navmeshOutputPath,
      // Hard-coded Unity-standard parameters (no user configuration)
      navmeshParams: {
        'cell_size': 0.3,        // 30cm grid resolution
        'cell_height': 0.2,      // 20cm height resolution
        'agent_height': 2.0,     // 2m tall agent (Unity default)
        'agent_radius': 0.6,     // 60cm wide agent
        'agent_max_climb': 0.9,  // 90cm max step height
        'agent_max_slope': 45.0, // 45° max slope angle
      },
    );

    print('✅ NavMesh ready!');
  }
}
```

**Summary**:
- ✅ Reuses `ScanUploadService.uploadScan()`
- ✅ Reuses `ScanUploadService.pollConversionStatus()`
- ✅ Only NEW code: navmesh GraphQL calls (2 mutations)
- ✅ Minimal changes, maximum reuse

### Phase 5: Local Storage

**Persistence**: SharedPreferences (like existing ScanData)

**Storage Keys**:
- `combined_scans` - JSON array of CombinedScan objects
- `combined_scan_{id}` - Individual combined scan data

## Error Handling

### Scenarios

1. **Insufficient scans**: Show error "Need at least 2 scans with positions"
2. **Combination failed**: Retry with error message
3. **Upload failed**: Retry with exponential backoff
4. **Backend processing failed**: Show error from API
5. **NavMesh generation failed**: Show error, allow retry

### User Feedback

- Toast messages for each step
- Progress indicators with percentage
- Clear error messages with retry options
- Ability to cancel at any stage

## File Organization

```
lib/features/scanning/
├── models/
│   ├── scan_data.dart (UPDATED - positions added)
│   └── combined_scan.dart (NEW)
├── services/
│   ├── usdz_combiner_service.dart (NEW)
│   ├── combined_scan_service.dart (NEW)
│   └── blenderapi_service.dart (NEW - REST API client for navmesh generation)
└── widgets/
    ├── combine_progress_dialog.dart (NEW)
    └── export_combined_dialog.dart (NEW)

ios/Runner/
├── USDZCombiner.swift (NEW - native code)
└── USDZCombinerPlugin.swift (NEW - Flutter channel)

specs/018-combined-scan-navmesh/
├── spec.md (THIS FILE)
├── api-contract.md (backend API details)
└── native-implementation.md (iOS SceneKit details)
```

## Testing Strategy

### Unit Tests
- ScanData position serialization
- Transform calculations
- API client methods

### Integration Tests
- Full combine flow (mocked backend)
- NavMesh generation flow
- Error handling scenarios

### Manual Testing
1. Create 2+ scans in project
2. Arrange on canvas, save positions
3. Tap "Combine Scans to GLB"
4. Verify progress indicators
5. Verify GLB creation
6. Generate navmesh
7. Export files
8. Import to Unity, verify positions match

## Dependencies

### New Packages
- None (uses existing: `http`, `path_provider`, `shared_preferences`)

### Native Code
- iOS: SceneKit framework (built-in)
- Minimum iOS version: 16.0 (already set for RoomPlan)

## Timeline Estimate

- **Phase 1** (Save positions): 2 hours
- **Phase 2** (USDZ combination): 8 hours (includes native code)
- **Phase 3** (API integration): 4 hours
- **Phase 4** (State management): 4 hours
- **Phase 5** (UI components): 6 hours
- **Testing & Polish**: 4 hours

**Total**: ~28 hours of development

## Success Criteria

1. ✅ User can combine 2+ scans with preserved positions
2. ✅ Combined GLB file downloads successfully
3. ✅ NavMesh generates from combined GLB
4. ✅ Export functionality works for both files
5. ✅ Position/rotation/scale match canvas arrangement exactly
6. ✅ Error handling provides clear feedback
7. ✅ Progress indicators show accurate status

## Future Enhancements

- Preview combined model before upload
- Edit positions after combining
- Multiple combined scans per project
- Direct Unity export integration
- Web viewer for combined GLB
- Custom navmesh parameter configuration for different agent types (small drones, large vehicles, etc.)

---

**Next Steps**:
1. Review and approve this specification
2. Backend team: Implement API endpoints (Phase 3)
3. Mobile team: Implement Phases 1, 2, 4, 5 in parallel with backend
