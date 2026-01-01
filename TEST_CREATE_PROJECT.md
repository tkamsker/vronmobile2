# Test Create Project Script

This document explains how to use the `test_create_project.sh` script to test creating BYO (Bring Your Own) projects and uploading GLB files.

## Prerequisites

1. **Install jq** (JSON parser):
   ```bash
   brew install jq
   ```

2. **Ensure you have valid credentials** for the VRon staging environment

3. **GLB file** (default: `Requirements/scan_scan-1767259992988-992988.glb`)

## Usage

### Basic Usage (with default GLB file)

```bash
./test_create_project.sh project_create.json
```

### With Custom GLB File

```bash
./test_create_project.sh project_create.json path/to/your/world.glb
```

### With Custom Credentials

```bash
./test_create_project.sh project_create.json path/to/world.glb your@email.com YourPassword
```

## JSON Input File Format

Create a JSON file (e.g., `project_create.json`) with the following structure:

```json
{
  "name": "My Test Project",
  "slug": "my-test-project",
  "description": "A test project created via API"
}
```

### Required Fields

- **name** (string): The project name
- **slug** (string): URL-friendly identifier (must be unique)

### Optional Fields

- **description** (string): Project description

## Example Test Files

### Example 1: Minimal Project

`minimal_project.json`:
```json
{
  "name": "Minimal Test",
  "slug": "minimal-test"
}
```

### Example 2: Full Project

`full_project.json`:
```json
{
  "name": "My Virtual Showroom",
  "slug": "my-virtual-showroom",
  "description": "A virtual showroom for product demonstrations created from LiDAR scan"
}
```

## What the Script Does

### Step 1: Authentication
- Authenticates with the GraphQL API using email/password
- Receives and encodes an access token

### Step 2: Project Creation
- Creates a new BYO project using the `createProject` mutation
- Returns project details including:
  - Project ID
  - Subscription status (MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER)
  - Project metadata

### Step 3: GLB Upload (if backend supports)
The script attempts to upload a GLB world file through the following steps:

1. **Request Upload URL**: Calls `createWorldModelUploadUrl` mutation
2. **Upload GLB**: Uses pre-signed URL to PUT the GLB file
3. **Confirm Upload**: Calls `confirmWorldModelUpload` to finalize

**Note**: The GLB upload mutations may need to be implemented on the backend. If not available, the script will gracefully handle this and complete after project creation.

## Expected Output

### Successful Project Creation

```
=== VRon BYO Project Creation Test ===
Project Name: Test BYO Project
Project Slug: test-byo-project
GLB File: Requirements/scan_scan-1767259992988-992988.glb (39K)

=== Step 1: Authenticating with email: tkamsker@gmail.com ===
✅ Successfully authenticated.
Generated AUTH_CODE: eyJNRVJDSEFOVCI6eyJhY2Nlc3NUb2tlbiI6ImV5SmhiR...

=== Step 2: Creating BYO project ===
Project input:
{
  "name": "Test BYO Project",
  "slug": "test-byo-project",
  "description": "A test BYO project created via API with LiDAR scan upload"
}
✅ Successfully created project!
Project ID: 67764f2a8c9e4a001d2b3c4d

=== Project Details ===
{
  "id": "67764f2a8c9e4a001d2b3c4d",
  "slug": "test-byo-project",
  "name": {
    "text": "Test BYO Project"
  },
  "description": {
    "text": "A test BYO project created via API with LiDAR scan upload"
  },
  "imageUrl": "",
  "isLive": false,
  "liveDate": null,
  "subscription": {
    "isActive": true,
    "isTrial": false,
    "status": "MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER",
    ...
  }
}

=== Step 3: Uploading GLB World File ===
✅ Received upload URL
✅ GLB file uploaded successfully
✅ Upload confirmed!
World URL: https://storage.vron.stage.motorenflug.at/worlds/test-byo-project.glb

=== Test Complete ===
✅ Project created successfully: 67764f2a8c9e4a001d2b3c4d
✅ GLB world file uploaded: https://storage.vron.stage.motorenflug.at/worlds/test-byo-project.glb
```

### If GLB Upload Not Implemented

```
=== Step 3: Uploading GLB World File ===
Attempting to request upload URL...
⚠️  GLB upload mutations not yet implemented on backend.
Error: Cannot query field "createWorldModelUploadUrl" on type "Mutation".

To implement GLB upload, the backend needs to add:
  - createWorldModelUploadUrl mutation
  - confirmWorldModelUpload mutation

See Requirements/CreateNewWorld_Flutter_PRD.md for implementation details.

=== Test Complete (project created, GLB upload pending backend support) ===
```

## Common Errors

### Authentication Failed

```
Error: Failed to get accessToken. Check credentials or API response.
```

**Solution**: Verify your email and password are correct.

### Duplicate Slug

```
❌ Error: GraphQL returned errors:
[
  {
    "message": "A project with this slug already exists",
    "extensions": {
      "code": "DUPLICATE_SLUG"
    }
  }
]
```

**Solution**: Use a different slug in your JSON file.

### GLB File Not Found

```
Error: GLB file not found: path/to/file.glb
```

**Solution**: Verify the GLB file path is correct.

## Environment

- **API Endpoint**: `https://api.vron.stage.motorenflug.at/graphql`
- **Platform**: `merchants`
- **Default Credentials**: `tkamsker@gmail.com` / `Test123!`

## Testing Multiple Projects

You can create multiple test files and run them sequentially:

```bash
./test_create_project.sh project1.json
./test_create_project.sh project2.json
./test_create_project.sh project3.json
```

## Cleanup

After testing, you may want to delete test projects through:
- The VRon merchants app UI
- Direct API calls (if delete mutation is available)

## Related Files

- `test_update_project.sh` - Script to update existing projects
- `test_getprojects.sh` - Script to list all projects
- `test_getvrproject.sh` - Script to get project details
- `project_create.json` - Example project creation input

## Backend Implementation Reference

For implementing the GLB upload mutations on the backend, refer to:
- `Requirements/CreateNewWorld_Flutter_PRD.md` - Complete implementation guide
- Section "Uploading GLB Files to Projects" - Pre-signed URL pattern

## Notes

- The script creates projects with `MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER` subscription status
- Projects are created without world purchase (BYO = Bring Your Own)
- GLB files should be in `.glb` format (GLTF Binary)
- The default GLB file is approximately 39KB
