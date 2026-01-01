# BYO Project Creation - Current Status & Implementation Plan

## Summary

The BYO (Bring Your Own) project creation feature **requires backend mutations that don't exist yet**. The PRD document describes the intended implementation, but testing reveals these mutations are not available.

## What the PRD Describes (Requirements/NEW_FLUTTER_VRonCreateProjectFromOwnWorld.prd)

### Two-Step Process
1. **Create World** with GLB files
   ```graphql
   mutation createWorld($input: CreateWorldInput!) {
     createWorld(input: $input) {
       id
       slug
     }
   }
   ```

2. **Create Project** from worldId
   ```graphql
   mutation VRonCreateProject($input: VRonCreateProjectInput!) {
     VRonCreateProject(input: $input) {
       projectId
     }
   }
   ```

## What Actually Exists on Backend

### ❌ Missing Mutations
- `createWorld` - **NOT FOUND**
  - Error: Unknown type "CreateWorldInput"
  - Error: Cannot query field "createWorld" on type "Mutation"
  - Suggestion: Did you mean "createAsset"?

- `VRonCreateProjectFromOwnWorld` - **NOT FOUND** (per PRD)

### ✅ Available Mutations
- `VRonCreateProject` - **EXISTS** but requires `worldId`
  - Problem: Can't get worldId without createWorld
- `createAsset` - **EXISTS** (purpose unclear)
- `VRonUpdateProduct` - **EXISTS** (for updating projects)

## Test Results

### test_create_byo_project.sh
```bash
❌ Error: GraphQL returned errors:
[
  {
    "message": "Unknown type \"CreateWorldInput\"",
    "extensions": {
      "code": "GRAPHQL_VALIDATION_FAILED"
    }
  },
  {
    "message": "Cannot query field \"createWorld\" on type \"Mutation\"",
    "extensions": {
      "code": "GRAPHQL_VALIDATION_FAILED"
    }
  }
]
```

## Impact Assessment

### Flutter App Features Blocked

1. **"ADD Project" button** in scan_list_screen.dart (lines 97-111)
   - Status: **BLOCKED**
   - Calls: `ProjectService.createProject()`
   - Problem: No backend mutation to call

2. **`ProjectService.createProject()`** (lib/features/home/services/project_service.dart:132-190)
   - Status: **BLOCKED**
   - Mutation: `createProject` with `CreateProjectInput`
   - Problem: Mutation doesn't exist

3. **BYO Project Upload Flow**
   - Status: **BLOCKED**
   - Needs: Project ID to upload scans to
   - Problem: Can't create projects via API

### What Still Works

✅ **List existing projects** - `getProjects` query works
✅ **Update existing projects** - `VRonUpdateProduct` mutation works
✅ **View project details** - `getVRProject` query works
✅ **Upload scans to existing projects** - Works if project already exists

## Required Backend Implementation

### Option A: Implement Two Mutations (Recommended by PRD)

**1. createWorld Mutation**
```graphql
mutation createWorld($input: CreateWorldInput!) {
  createWorld(input: $input) {
    id
    slug
    worldUrl
    meshUrl
  }
}

input CreateWorldInput {
  slug: String!
  description: [I18NFieldValue!]!
  worldFile: Upload!
  meshFile: Upload!
  image: Upload!
  isFeatured: Boolean!
  isHidden: Boolean!
  spawnCoordinates: SpatialCoordinates!
  prices: WorldPrices!
  assets: [WorldAssetInput!]!
  usageRecommendation: [I18NFieldValue!]!
}
```

**2. Update VRonCreateProject** (already exists, just needs worldId)
```graphql
mutation VRonCreateProject($input: VRonCreateProjectInput!) {
  VRonCreateProject(input: $input) {
    projectId
  }
}

input VRonCreateProjectInput {
  worldId: String!
}
```

### Option B: Implement Single Combined Mutation

```graphql
mutation VRonCreateProjectFromOwnWorld($input: CreateProjectFromOwnWorldInput!) {
  VRonCreateProjectFromOwnWorld(input: $input) {
    projectId
    worldId
  }
}

input CreateProjectFromOwnWorldInput {
  slug: String!
  worldFile: Upload!
  meshFile: Upload!
  image: Upload
  description: String
}
```

This would simplify client implementation by combining both steps.

### Option C: Use Existing createAsset (If Applicable)

Investigate if `createAsset` mutation can be used for world creation:
```bash
# Test if createAsset works for GLB uploads
./test_introspect_mutations.sh | grep -i asset
```

## Recommended Immediate Actions

### For Testing GLB Upload (Today)

**Create projects manually through web UI:**
1. Go to: https://app.vron.stage.motorenflug.at/projects
2. Create a BYO project
3. Note the project ID
4. Use that ID for testing scans:
   ```bash
   ./test_getprojects.sh | jq '.data.getProjects[] | {id, slug, subscription}'
   ```

### For Flutter App (This Week)

**Option 1: Disable Feature Temporarily**
```dart
// In scan_list_screen.dart, hide ADD Project button
if (false) { // Temporarily disabled - backend not ready
  TextButton.icon(
    onPressed: _showAddProjectDialog,
    ...
  ),
}
```

**Option 2: Link to Web App**
```dart
TextButton.icon(
  onPressed: () async {
    final url = Uri.parse('https://app.vron.stage.motorenflug.at/projects/new');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  },
  icon: Icon(Icons.open_in_browser),
  label: Text('Create Project (Web)'),
),
```

### For Backend Team (This Sprint)

**Priority 1:** Implement Option B (single combined mutation)
- Simplest for clients
- Fewer round trips
- Atomic operation

**Priority 2:** If Option B isn't feasible, implement Option A
- Follows PRD specification
- Two-step process documented
- Clients can implement with multipart uploads

**Priority 3:** Document any alternative approach
- If neither mutation is planned
- How should BYO projects be created?
- Update PRD with actual implementation

## Test Scripts Status

| Script | Status | Notes |
|--------|--------|-------|
| test_getprojects.sh | ✅ Working | Lists all projects |
| test_getvrproject.sh | ✅ Working | Gets project details |
| test_update_project.sh | ✅ Working | Updates via VRonUpdateProduct |
| test_create_project.sh | ❌ Blocked | No createProject mutation |
| test_create_byo_project.sh | ❌ Blocked | No createWorld mutation |

## Next Steps

1. **Decision Required:** Which backend implementation option (A, B, or C)?
2. **Timeline:** When can the mutations be implemented?
3. **Workaround:** Should Flutter app redirect to web UI for now?
4. **Testing:** Once implemented, verify with test_create_byo_project.sh

## Questions for Product/Backend Team

1. **Is BYO project creation via API a planned feature?**
   - If yes, which option (A, B, or C)?
   - If no, document web-only creation flow

2. **What is the timeline for implementation?**
   - Blocking Flutter app feature
   - Need to plan workaround or delay

3. **Can we use createAsset mutation as alternative?**
   - What does it do?
   - Can it upload GLB files?

4. **Is there a test/staging worldId we can use?**
   - To test VRonCreateProject mutation
   - Until createWorld is implemented

## Files Created

- ✅ test_create_byo_project.sh - Ready to test once backend is implemented
- ✅ BYO_PROJECT_STATUS.md - This document
- ✅ PROJECT_CREATION_FINDINGS.md - Initial analysis
- ✅ NEW_FLUTTER_VRonCreateProjectFromOwnWorld.prd - Requirements document

All test infrastructure is ready. Just waiting for backend mutations.
