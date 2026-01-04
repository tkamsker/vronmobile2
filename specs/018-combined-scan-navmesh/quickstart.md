# Quickstart Guide: Combined Scan to NavMesh Workflow

**Feature**: 018-combined-scan-navmesh
**Date**: 2026-01-04
**Audience**: Developers, QA Engineers, Product Team

## Overview

This guide provides step-by-step instructions for testing the Combined Scan to NavMesh feature, including manual test scenarios and expected outcomes.

---

## Prerequisites

### Development Environment

- iOS device with LiDAR (iPhone 12 Pro or later)
- iOS 16.0+ installed
- Xcode 26.2 or later
- Flutter 3.x environment configured
- Valid backend API credentials

### Test Data Setup

1. Create a new project in the app
2. Scan at least 2-3 rooms using the RoomPlan feature
3. Arrange the rooms on the canvas (Feature 017)
4. Save the room arrangement with positions

---

## Test Scenarios

### Scenario 1: Happy Path - Combine 3 Scans

**Objective**: Verify complete workflow from scan combination to navmesh download.

**Steps**:

1. **Arrange Scans**
   - Open a project with 3 completed scans
   - Navigate to room arrangement canvas
   - Position rooms: Living Room (0,0), Kitchen (150,0), Bedroom (300,0)
   - Rotate Kitchen 90 degrees
   - Save arrangement
   - **Expected**: Position data saved to ScanData models

2. **Start Combination**
   - Navigate to Project Detail screen
   - Verify "Combine Scans to GLB" button is enabled
   - Tap "Combine Scans to GLB" button
   - **Expected**: Progress dialog appears

3. **Monitor Combination Progress**
   - **Expected**: Dialog shows "Combining scans..." with spinner
   - **Expected**: iOS native code combines USDZ files (~5-10 seconds)
   - **Expected**: Dialog updates to "Uploading to server..." with progress bar

4. **Monitor Upload**
   - **Expected**: Progress bar shows 0-100% upload progress
   - **Expected**: Upload completes in 20-30 seconds on WiFi
   - **Expected**: Dialog updates to "Creating Combined GLB..."

5. **Monitor GLB Conversion**
   - **Expected**: Backend processes USDZ → GLB
   - **Expected**: Status polling every 2 seconds
   - **Expected**: Conversion completes in 30-60 seconds
   - **Expected**: Dialog dismisses, "Generate NavMesh" button appears

6. **Generate NavMesh**
   - Tap "Generate NavMesh" button
   - **Expected**: New progress dialog appears: "Uploading to BlenderAPI..."

7. **Monitor NavMesh Generation (BlenderAPI workflow)**
   - **Expected**: Dialog shows "Uploading GLB to BlenderAPI..." (~5 seconds)
   - **Expected**: Dialog updates to "Generating NavMesh..." with progress
   - **Expected**: Status polling every 2 seconds
   - **Expected**: Generation completes in 60-90 seconds
   - **Expected**: Dialog shows "Downloading NavMesh..."
   - **Expected**: NavMesh downloads automatically (~2-3 seconds)
   - **Expected**: BlenderAPI session cleaned up automatically

8. **Verify Completion**
   - **Expected**: Export dialog appears showing:
     - "Combined GLB (12.4 MB)"
     - "Navigation Mesh (1.2 MB)"
   - **Expected**: Both export buttons enabled

9. **Export Files**
   - Tap "Export Combined GLB"
   - **Expected**: iOS share sheet appears
   - Select "Save to Files" → Choose location → Save
   - **Expected**: File saved successfully
   - Tap "Export NavMesh"
   - **Expected**: iOS share sheet appears
   - Save navmesh file
   - **Expected**: File saved successfully

10. **Verify in Unity**
    - Import Combined GLB into Unity project
    - **Expected**: All 3 rooms visible with correct positions
    - **Expected**: Kitchen rotated 90 degrees relative to Living Room
    - Import NavMesh GLB
    - **Expected**: NavMesh data loads correctly
    - **Expected**: AI agents can navigate the combined floor plan

**Success Criteria**:
- ✅ All rooms combined correctly
- ✅ Positions match canvas arrangement
- ✅ Both files exported successfully
- ✅ Unity imports work without errors

---

### Scenario 2: Cancel During Upload

**Objective**: Verify cancellation handling during upload phase.

**Steps**:

1. Follow Scenario 1 steps 1-3
2. During upload (50% progress):
   - Tap "Cancel" button in progress dialog
   - **Expected**: Upload cancels immediately
   - **Expected**: Dialog dismisses
   - **Expected**: Partial files cleaned up

3. Verify cleanup:
   - Check local storage
   - **Expected**: Combined USDZ file deleted
   - Check SharedPreferences
   - **Expected**: CombinedScan record removed or marked failed

4. Retry:
   - Tap "Combine Scans to GLB" again
   - **Expected**: Fresh attempt starts from beginning
   - Let it complete
   - **Expected**: Works normally

**Success Criteria**:
- ✅ Cancel works immediately
- ✅ No orphaned files left
- ✅ Retry works after cancellation

---

### Scenario 3: Network Failure During Upload

**Objective**: Verify error handling when network drops during upload.

**Steps**:

1. Follow Scenario 1 steps 1-3
2. During upload (30% progress):
   - Disable WiFi on device
   - **Expected**: Upload fails after timeout (~10 seconds)
   - **Expected**: Error dialog appears: "Upload failed. Check your connection and try again."

3. Re-enable network:
   - Turn WiFi back on
   - Tap "Retry" button
   - **Expected**: Upload resumes from beginning
   - **Expected**: Completes successfully

**Success Criteria**:
- ✅ Error detected and reported clearly
- ✅ Retry mechanism works
- ✅ No data corruption

---

### Scenario 4: Backend GLB Conversion Failure

**Objective**: Verify handling when backend fails to convert USDZ → GLB.

**Steps**:

1. Follow Scenario 1 steps 1-4
2. Simulate backend failure (coordinate with backend team):
   - Backend returns conversion error
3. **Expected**: Error dialog appears: "GLB conversion failed: [error message]"
4. **Expected**: User can tap "Close" to dismiss
5. **Expected**: "Combine Scans to GLB" button still available for retry

**Success Criteria**:
- ✅ Backend errors propagated to UI
- ✅ Clear error message shown
- ✅ User can retry

---

### Scenario 5: NavMesh Generation Failure

**Objective**: Verify handling when navmesh generation fails (e.g., invalid geometry).

**Steps**:

1. Follow Scenario 1 steps 1-6
2. Simulate invalid geometry (test with invalid GLB file or coordinate with backend):
   - BlenderAPI returns `INVALID_GEOMETRY` error during processing
3. **Expected**: Error dialog appears: "NavMesh generation failed: Invalid geometry - non-manifold edges detected"
4. **Expected**: Suggested action: "Try re-scanning the rooms and combining again"
5. **Expected**: BlenderAPI session automatically cleaned up (deleted)
6. Verify state:
   - Combined GLB is still available locally
   - **Expected**: Can still export Combined GLB
   - **Expected**: "Generate NavMesh" button still available for retry

**Success Criteria**:
- ✅ Clear error message with actionable advice
- ✅ Combined GLB not lost on navmesh failure
- ✅ Can retry navmesh generation

---

### Scenario 6: Insufficient Scans

**Objective**: Verify validation when project has < 2 scans.

**Steps**:

1. Create new project with only 1 scan
2. Navigate to Project Detail screen
3. **Expected**: "Combine Scans to GLB" button is disabled (greyed out)
4. **Expected**: Tooltip or message: "Need at least 2 scans to combine"

**Success Criteria**:
- ✅ Button disabled for insufficient scans
- ✅ Clear message explaining why

---

### Scenario 7: Scans Without Position Data

**Objective**: Verify handling when scans don't have position data saved.

**Steps**:

1. Create project with 2 scans
2. **Skip** canvas arrangement step (don't save positions)
3. Navigate to Project Detail screen
4. **Expected**: "Combine Scans to GLB" button is disabled
5. **Expected**: Message: "Arrange scans on canvas first"

**Success Criteria**:
- ✅ Button disabled for non-positioned scans
- ✅ Clear guidance to arrange scans first

---

### Scenario 8: Large Combined File (10 Rooms)

**Objective**: Verify performance with maximum expected room count.

**Steps**:

1. Create project with 10 scans (~5MB each = 50MB combined)
2. Arrange all 10 rooms on canvas
3. Save arrangement
4. Tap "Combine Scans to GLB"
5. Monitor performance:
   - **Expected**: Combination takes 15-20 seconds (acceptable)
   - **Expected**: Upload takes 60-90 seconds on WiFi
   - **Expected**: GLB conversion takes 90-120 seconds
   - **Expected**: NavMesh generation takes 120-180 seconds

6. **Expected**: All operations complete successfully
7. **Expected**: UI remains responsive throughout
8. **Expected**: Memory usage stays reasonable (<500MB)

**Success Criteria**:
- ✅ Large files handled without crashes
- ✅ Progress reporting accurate
- ✅ Reasonable timeouts (no premature failures)

---

### Scenario 9: Export to External Apps

**Objective**: Verify export integration with iOS share sheet and external apps.

**Steps**:

1. Complete Scenario 1 through step 9 (files ready)
2. Test various export destinations:

   **2a. Save to Files**
   - Tap "Export Combined GLB"
   - Select "Save to Files" → iCloud Drive
   - **Expected**: File appears in Files app

   **2b. Share via AirDrop**
   - Tap "Export NavMesh"
   - Select AirDrop → Nearby Mac
   - **Expected**: File transfers successfully

   **2c. Email attachment**
   - Tap "Export Both as ZIP"
   - Select Mail app
   - **Expected**: ZIP file (13.6 MB) attached to email

   **2d. Import to Unity Editor (Mac)**
   - AirDrop combined GLB to Mac
   - Drag into Unity project Assets folder
   - **Expected**: Unity imports model successfully

**Success Criteria**:
- ✅ iOS share sheet works correctly
- ✅ Files valid and usable in external apps
- ✅ ZIP export contains both files

---

### Scenario 10: Offline Mode

**Objective**: Verify behavior when device is offline throughout.

**Steps**:

1. Create project with 3 positioned scans
2. Disable WiFi and cellular data
3. Tap "Combine Scans to GLB"
4. **Expected**: Combination completes (on-device operation)
5. **Expected**: Upload fails immediately with offline error
6. **Expected**: Error message: "No internet connection. Combined USDZ saved locally. Upload will retry when online."

7. Re-enable network:
   - **Expected**: App detects connectivity
   - **Expected**: Upload resumes automatically OR button shows "Retry Upload"

**Success Criteria**:
- ✅ On-device combination works offline
- ✅ Clear offline error messaging
- ✅ Seamless resume when online

---

## Quick Smoke Test (5 Minutes)

**Purpose**: Rapid validation that feature is working after deployment.

**Steps**:

1. Open app → Navigate to project with 3 scans
2. Verify canvas shows rooms with positions
3. Tap "Combine Scans to GLB" → Wait for completion (~2 minutes)
4. Verify "Generate NavMesh" button appears
5. Tap "Generate NavMesh" → Wait for completion (~1 minute)
6. Verify export dialog shows both files
7. Tap "Export Combined GLB" → Save to Files
8. **Expected**: ✅ All steps complete without errors

---

## Performance Benchmarks

| Operation | Expected Time | Acceptable Range |
|-----------|---------------|------------------|
| Combine 3 scans (USDZ) | 7 seconds | 5-10 seconds |
| Upload USDZ (WiFi, 15MB) | 25 seconds | 20-35 seconds |
| GLB conversion (backend) | 45 seconds | 30-60 seconds |
| Download GLB (WiFi, 12MB) | 5 seconds | 3-8 seconds |
| Upload GLB to BlenderAPI | 8 seconds | 5-12 seconds |
| NavMesh generation (BlenderAPI) | 75 seconds | 60-120 seconds |
| NavMesh download (1-2MB) | 3 seconds | 2-5 seconds |
| **Total end-to-end** | **~2.8 minutes** | **2-4 minutes** |

**Note**: BlenderAPI session-based workflow adds ~10-15 seconds for upload/download but eliminates need for new GraphQL mutations.

---

## Troubleshooting

### Issue: "Combine Scans to GLB" button disabled

**Check**:
- Project has ≥ 2 scans?
- All scans have position data (canvas arranged)?
- All scans status == completed?

**Fix**: Arrange scans on canvas and save

---

### Issue: Combination takes too long (>30 seconds)

**Check**:
- How many scans? (10+ may be slow)
- File sizes? (Large scans take longer)
- Device model? (Older devices slower)

**Fix**: Acceptable if <10 rooms. If >10, may need optimization.

---

### Issue: Upload fails repeatedly

**Check**:
- Internet connection stable?
- Backend API reachable?
- File size reasonable (<100MB)?
- Valid auth token?

**Fix**: Check network, re-login if token expired

---

### Issue: NavMesh generation fails with "INVALID_GEOMETRY"

**Root Cause**: Combined GLB has non-manifold geometry or overlapping meshes (BlenderAPI error)

**Fix**:
1. Check if rooms overlap in canvas arrangement
2. Re-scan problematic room(s)
3. Retry combination

---

### Issue: BlenderAPI session creation fails

**Root Cause**: BlenderAPI service unavailable or authentication issue

**Check**:
- Network connection stable?
- BlenderAPI service health: `https://blenderapi.stage.motorenflug.at/health`
- Valid API key configured?

**Fix**: Check service status, verify API key, retry

---

### Issue: BlenderAPI upload fails with 413 Payload Too Large

**Root Cause**: Combined GLB exceeds BlenderAPI size limit (typically 100MB)

**Fix**:
1. Reduce number of rooms in combination (max 5-7 rooms)
2. Check individual scan file sizes before combining
3. Consider re-scanning with lower quality settings if needed

---

### Issue: Export fails ("Share sheet doesn't appear")

**Check**:
- Files still exist locally?
- Sufficient storage space?
- iOS share sheet permissions?

**Fix**: Verify files exist, free up space if needed

---

## Automated Test Commands

### Unit Tests

```bash
# Run all combined scan feature tests
flutter test test/features/scanning/services/combined_scan_service_test.dart

# Run widget tests
flutter test test/features/scanning/widgets/

# Run iOS native tests
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
```

### Integration Tests

```bash
# Run full E2E test
flutter test integration_test/combine_scan_flow_test.dart

# Run with device
flutter test integration_test/ -d <device-id>
```

---

## Mock Data for Testing

### Mock Backend Responses

```json
// uploadProjectScan response
{
  "scan": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "conversionStatus": "processing"
  }
}

// generateNavMesh response
{
  "generateNavMesh": {
    "navmesh": {
      "id": "a1b2c3d4-e5f6-4789-a012-3456789abcde",
      "status": "PROCESSING"
    },
    "success": true
  }
}

// Completed navmesh
{
  "scan": {
    "navmesh": {
      "status": "COMPLETED",
      "meshUrl": "https://s3.example.com/navmesh.glb"
    }
  }
}
```

---

## References

- Feature Specification: `specs/018-combined-scan-navmesh/spec.md`
- API Contracts: `specs/018-combined-scan-navmesh/contracts/navmesh-graphql.md`
- Data Model: `specs/018-combined-scan-navmesh/data-model.md`
