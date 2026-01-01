# Project Creation API Findings

## Summary

Testing reveals a mismatch between the Flutter app's `ProjectService` and the actual backend GraphQL API for creating BYO (Bring Your Own) projects.

## What We Discovered

### 1. Flutter App Expects
```graphql
mutation CreateProject($data: CreateProjectInput!) {
  createProject(data: $data) {
    id
    name
    slug
    ...
  }
}
```

**Input:**
- `name` (String!)
- `slug` (String!)
- `description` (String, optional)

### 2. Backend Actually Has
```graphql
# Option A: VRonCreateProject (for purchasing worlds)
mutation VRonCreateProject($input: VRonCreateProjectInput!) {
  VRonCreateProject(input: $input) {
    projectId
  }
}
```

**Input:**
- `worldId` (String!) - Requires purchasing a world template

```graphql
# Option B: VRonCreateProduct (for e-commerce products, NOT projects)
mutation VRonCreateProduct($input: VRonCreateProductInput!) {
  VRonCreateProduct(input: $input) {
    ...
  }
}
```

**Input:** Requires many product-specific fields:
- `title` (String!)
- `tracksInventory` (Boolean!)
- `mediaFiles` ([MediaFileInput!]!)
- `mediaLinks` ([MediaLinkInput!]!)
- `variants` ([VRonProductVariantInputWithOptions!]!)
- `variantOptionsIds` ([String!]!)
- NO `slug` field!

## The Problem

**For BYO Projects (MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER):**

The backend doesn't appear to have a mutation that:
1. Creates a project without purchasing a world
2. Accepts simple inputs (name, slug, description)
3. Returns MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER subscription status

## Possible Solutions

### Solution 1: Backend Needs to Implement createProject Mutation

Add a new mutation matching Flutter's expectations:

```graphql
mutation CreateProject($data: CreateProjectInput!) {
  createProject(data: $data) {
    id
    slug
    name { text(lang: EN) }
    description { text(lang: EN) }
    subscription { status }
  }
}

input CreateProjectInput {
  name: String!
  slug: String!
  description: String
}
```

This mutation should:
- Create a project with MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER subscription
- NOT require worldId
- NOT require product-specific fields

### Solution 2: Use VRonCreateProject with BYO World Template

If there's a special "BYO World Template" with a known ID:

```bash
# Find BYO world template
QUERY='{ getWorlds { id slug description { text(lang: EN) } } }'

# Use that worldId for all BYO projects
mutation VRonCreateProject($input: VRonCreateProjectInput!) {
  VRonCreateProject(input: { worldId: "BYO_TEMPLATE_ID" })
}
```

### Solution 3: Projects Created Through Web UI Only

BYO projects might be intended to be created only through the merchants web application, not via API.

## Current Workaround

### For Testing

1. Create projects manually through the web UI at:
   ```
   https://app.vron.stage.motorenflug.at/projects
   ```

2. Get the project list to find IDs:
   ```bash
   ./test_getprojects.sh
   ```

3. Use those project IDs for uploading scans

### For Flutter App

The Flutter app's "ADD Project" feature will fail until one of the solutions above is implemented. Options:

1. **Disable the feature**: Remove "ADD Project" button until backend is ready
2. **Open web UI**: Navigate to web app for project creation
3. **Mock it**: Show local-only projects until synced

## Impact on Flutter Implementation

### Current Status
- ❌ `ProjectService.createProject()` - **NOT WORKING** (mutation doesn't exist)
- ✅ `ProjectService.fetchProjects()` - **Working**
- ✅ `ProjectService.updateProject()` - **Working** (uses VRonUpdateProduct)
- ✅ `ProjectService.getProjectDetail()` - **Working**

### What Needs Fixing

**File:** `lib/features/home/services/project_service.dart`

**Line 132-190:** `createProject()` method uses non-existent mutation

**Options:**
1. Wait for backend to implement `createProject` mutation
2. Update to use `VRonCreateProject` with BYO world template ID
3. Remove create functionality and redirect to web app

**File:** `lib/features/scanning/screens/scan_list_screen.dart`

**Line 414-708:** `_createNewProject()` calls `ProjectService.createProject()`

**Action Required:**
- Add error handling for mutation not found
- Show user-friendly message: "Create projects through the web app"
- Provide link/button to open web app

## Recommendations

### Immediate (for testing GLB upload)

1. **Create test project manually** through web UI
2. **Get project ID** using `./test_getprojects.sh`
3. **Modify test_create_project.sh** to:
   - Skip project creation
   - Accept project ID as input
   - Focus on GLB upload testing

### Short-term (for Flutter app)

1. **Disable ADD Project button** temporarily
2. **Add explanatory message**: "Create projects at app.vron.stage.motorenflug.at"
3. **Add "Open Web App" button** that launches browser

### Long-term (backend implementation)

1. **Implement `createProject` mutation** as specified above
2. **Document BYO world template** if using VRonCreateProject approach
3. **Update API documentation** with working examples
4. **Add integration tests** to prevent future mismatches

## Test Files Status

- ✅ `test_getprojects.sh` - **Working**
- ✅ `test_getvrproject.sh` - **Working**
- ✅ `test_update_project.sh` - **Working**
- ❌ `test_create_project.sh` - **Blocked** (needs backend fix)

## Next Steps

**Question for Backend Team:**

> How should BYO (MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER) projects be created via API?
>
> Options:
> A) Implement new `createProject` mutation
> B) Provide BYO world template ID for `VRonCreateProject`
> C) Projects only created through web UI (no API support)

**For Now:**

I recommend creating a simplified test script that:
1. Assumes a project already exists
2. Takes project ID as input
3. Only tests GLB upload functionality

Would you like me to create that version?
