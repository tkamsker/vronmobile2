# Combined Scan to NavMesh Workflow

## Overview

The Combined Scan to NavMesh workflow allows you to merge multiple LiDAR room scans into a single 3D model with navigation mesh, ready for Unity integration.

## Features

- **Multi-Room Combination**: Combine 2+ positioned room scans into single GLB file
- **Automatic NavMesh Generation**: Generate Unity-compatible navigation mesh
- **Dual Export**: Export both combined model and navmesh separately or as ZIP
- **Real-time Progress**: Monitor all workflow stages with live updates
- **Cancellation Support**: Cancel operations at any stage with automatic cleanup

## Prerequisites

- **iOS Device**: iPhone or iPad with LiDAR sensor (iOS 16.0+)
- **Scans**: Minimum 2 completed room scans
- **Positioning**: Scans must be arranged on canvas with position data

## Workflow Steps

### 1. Arrange Your Scans

Before combining, arrange your room scans on the canvas:

1. Navigate to project detail screen
2. View your captured room scans
3. Tap and drag scans to position them relative to each other
4. Rotate and scale as needed
5. Ensure all scans have position coordinates (shown in scan details)

### 2. Combine Scans to GLB

Once positioned:

1. Tap the **"Combine X Scans to GLB"** button
2. Monitor progress through 3 stages:
   - **Combining scans**: iOS native USDZ combination
   - **Uploading to server**: Transfer to backend
   - **Creating Combined GLB**: Server-side conversion

3. Wait for completion (typically 30-90 seconds depending on scan count)

**File Size Guidelines:**
- ⚠️ Warning at 50MB total: May take longer
- ❌ Error at 250MB total: Reduce scan count or quality

### 3. Generate NavMesh

After GLB creation:

1. Tap the **"Generate NavMesh"** button
2. Monitor progress through 4 stages:
   - **Uploading GLB to BlenderAPI**: Transfer to processing service
   - **Generating NavMesh**: Unity-standard parameters applied
   - **Downloading NavMesh**: Retrieve generated file
   - **Cleanup**: Automatic session cleanup

3. Wait for completion (typically 60-180 seconds depending on geometry complexity)

**NavMesh Parameters (Unity-Standard):**
- Cell Size: 0.3m (30cm grid resolution)
- Cell Height: 0.2m (20cm height resolution)
- Agent Height: 2.0m (default humanoid)
- Agent Radius: 0.6m (60cm wide agent)
- Max Climb: 0.9m (90cm step height)
- Max Slope: 45° (maximum walkable angle)

### 4. Export Files

When both files are ready:

1. The **Export Dialog** appears automatically
2. Choose export option:
   - **Export Combined GLB**: Share GLB model only
   - **Export NavMesh**: Share navmesh only
   - **Export Both as ZIP**: Share both files in single archive

3. Use iOS share sheet to:
   - AirDrop to Mac
   - Save to Files app
   - Email to team members
   - Share to cloud storage

## Unity Integration

### Importing Combined GLB

```csharp
// 1. Import GLB file into Unity Assets folder
// 2. Reference in scene
public GameObject combinedModel;

void Start() {
    // Model is ready to use with materials and textures
    combinedModel.SetActive(true);
}
```

### Importing NavMesh

```csharp
// 1. Import navmesh GLB into Unity Assets folder
// 2. Bake as Navigation Mesh
using UnityEngine.AI;

public class NavMeshSetup : MonoBehaviour {
    void Start() {
        // NavMesh is automatically detected by NavMeshAgent
        // Configure your agents with matching parameters:
        NavMeshAgent agent = GetComponent<NavMeshAgent>();
        agent.height = 2.0f;
        agent.radius = 0.6f;
        agent.agentTypeID = 0; // Humanoid
    }
}
```

## Troubleshooting

### "Need at least 2 scans to combine"
- **Cause**: Less than 2 scans in project
- **Solution**: Capture more room scans before combining

### "Scans must have position data"
- **Cause**: Scans not arranged on canvas
- **Solution**: Drag scans on canvas to assign positions

### "File size exceeds 250MB limit"
- **Cause**: Total scan size too large
- **Solution**:
  - Reduce number of scans
  - Capture at lower quality settings
  - Split into multiple combinations

### "Failed to combine USDZ files"
- **Cause**: Invalid or corrupted scan files
- **Solution**:
  - Retry the failed scan
  - Check device storage space
  - Restart app and retry

### "NavMesh generation failed"
- **Cause**: Invalid geometry or processing timeout
- **Solution**:
  - Simplify combined model geometry
  - Check for overlapping rooms
  - Retry operation

### Progress Stuck at X%
- **Cause**: Network issues or server load
- **Solution**:
  - Check internet connection
  - Wait for timeout (operations auto-fail after 15 minutes)
  - Cancel and retry

## Tips for Best Results

### Scan Quality
- **Overlap**: Ensure 20-30% overlap between adjacent rooms
- **Lighting**: Scan in consistent lighting conditions
- **Movement**: Scan slowly and steadily for best detail
- **Coverage**: Capture all walls, floors, and major features

### Positioning
- **Alignment**: Align doorways and shared walls between rooms
- **Scale**: Use consistent scale (1.0) unless intentional resize needed
- **Rotation**: Match room orientations to real-world layout
- **Origin**: Place first scan at (0, 0) as reference point

### Performance
- **Scan Count**: 3-7 rooms is optimal for most projects
- **File Size**: Keep individual scans under 20MB each
- **Device**: Close other apps during combination for best performance
- **Storage**: Ensure 1GB+ free space for temporary files

## Technical Details

### Workflow Architecture

```
iOS LiDAR Scans (USDZ)
    ↓
[iOS Native] SceneKit USDZ Combination
    ↓
Combined USDZ File (Local)
    ↓
[GraphQL API] Upload & GLB Conversion
    ↓
Combined GLB File (Downloaded)
    ↓
[BlenderAPI] NavMesh Generation
    ↓
NavMesh GLB File (Downloaded)
    ↓
Export Dialog → Unity Integration
```

### File Formats

- **Input**: USDZ (Universal Scene Description)
- **Intermediate**: USDZ (combined)
- **Output**: GLB (GL Transmission Format Binary)
- **NavMesh**: GLB with mesh geometry

### Status Lifecycle

1. `combining` - iOS native combining scans
2. `uploadingUsdz` - Uploading to GraphQL backend
3. `processingGlb` - Backend creating GLB
4. `glbReady` - GLB downloaded, ready for navmesh
5. `uploadingToBlender` - Uploading to BlenderAPI
6. `generatingNavmesh` - NavMesh being generated
7. `downloadingNavmesh` - NavMesh being downloaded
8. `completed` - Both files ready
9. `failed` - Operation failed (see error message)

## Support

For issues or questions:
- Check device logs for detailed error messages
- Verify iOS version (16.0+ required)
- Confirm LiDAR sensor availability
- Contact support with workflow stage where failure occurred

## Version History

- **v1.0.0** (Feature 018): Initial release
  - Multi-room USDZ combination
  - Unity-standard NavMesh generation
  - Dual export (GLB + NavMesh)
  - Cancellation support
  - Real-time progress tracking
