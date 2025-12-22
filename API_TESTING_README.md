# GraphQL API Testing Scripts

Shell scripts for testing the VRon GraphQL API directly without running the Flutter app.

## Prerequisites

Install `jq` for JSON parsing:
```bash
brew install jq
```

## Scripts

### 1. test_getprojects.sh

Fetches all projects for authenticated user.

**Usage:**
```bash
./test_getprojects.sh [email] [password]
```

**Example:**
```bash
./test_getprojects.sh tkamsker@gmail.com "Test123!"
```

**Output:**
- Lists all projects with ID, name, and live status
- Full JSON response with all project data

---

### 2. test_update_project.sh

Updates a project via VRonUpdateProduct mutation.

**Usage:**
```bash
./test_update_project.sh [json_file] [email] [password]
```

**Example:**
```bash
./test_update_project.sh project_update_full.json tkamsker@gmail.com "Test123!"
```

---

## JSON File Format

### Minimal (doesn't work - missing required fields):
```json
{
  "id": "6889cb75c10c83ee1d423b53",
  "title": "Updated Title",
  "description": "Updated description"
}
```

### Full (required fields):
```json
{
  "id": "6889cb75c10c83ee1d423b53",
  "title": "Updated Title",
  "description": "Updated description",
  "status": "DRAFT",
  "tracksInventory": false,
  "tags": ""
}
```

---

## API Discoveries

### VRonUpdateProduct Mutation

**Schema:**
```graphql
mutation UpdateProduct($input: VRonUpdateProductInput!) {
  VRonUpdateProduct(input: $input)
}
```

**Required Fields:**
- `id: String!` - Project/Product ID
- `title: String!` - Project name (maps from "name" in frontend)
- `description: String` - Project description
- `status: ProductStatus!` - Product status enum
- `tracksInventory: Boolean!` - Whether inventory is tracked

**Optional Fields:**
- `categoryId: String` - Product category ID
- `tags: String` - Tags as comma-separated string (NOT array!)

**Return Type:** `Boolean` (true/false for success)

### Key Findings

1. **Projects = Products in Backend**
   - Projects are implemented as Products in the backend
   - Use VRonUpdateProduct mutation to update projects

2. **Field Type Corrections:**
   - `tags` is `String`, not array
   - Empty tags should be: `"tags": ""` not `"tags": []`

3. **ProductStatus Enum Values:**
   - Unknown valid values yet
   - `"PUBLISHED"` is NOT valid (error: "does not exist in ProductStatus enum")
   - `"DRAFT"` may be valid but returns false
   - Need to discover valid enum values

4. **No Product Query Available:**
   - Backend has NO `product(id: ID!)` query
   - Backend has NO `getProduct(id: ID!)` query
   - Cannot fetch Product fields before updating
   - Must provide all required fields in mutation

### Questions to Resolve

1. What are the valid `ProductStatus` enum values?
2. Why does the mutation return `false` with status="DRAFT"?
3. Is there a way to query existing Product fields?
4. What is the correct status value to preserve existing project status?

---

## Next Steps for Flutter Implementation

Since we cannot query Product fields before updating, we have two options:

**Option A: Use Hardcoded Defaults**
```dart
final result = await _graphqlService.query(
  _updateProjectMutation,
  variables: {
    'input': {
      'id': projectId,
      'title': name,
      'description': description,
      'status': 'ACTIVE', // Or whatever the correct value is
      'tracksInventory': false,
      'tags': '',
    },
  },
);
```

**Option B: Add Product Fields to Project Model**
- Add status, tracksInventory, tags to getProjects query
- Store them in Project model
- Pass them back when updating

**Recommendation:** First discover the correct `ProductStatus` enum values by testing different values with these scripts, then implement Option A or B accordingly.

---

## Testing Different Status Values

Create test JSON files with different status values:

```bash
# Test ACTIVE
echo '{
  "id": "6889cb75c10c83ee1d423b53",
  "title": "Test Title",
  "description": "Test desc",
  "status": "ACTIVE",
  "tracksInventory": false,
  "tags": ""
}' > test_active.json

./test_update_project.sh test_active.json

# Test PUBLISHED
echo '{
  "id": "6889cb75c10c83ee1d423b53",
  "title": "Test Title",
  "description": "Test desc",
  "status": "PUBLISHED",
  "tracksInventory": false,
  "tags": ""
}' > test_published.json

./test_update_project.sh test_published.json
```

---

## API Endpoint

```
https://api.vron.stage.motorenflug.at/graphql
```

**Required Headers:**
- `Content-Type: application/json`
- `X-VRon-Platform: merchants`
- `Authorization: Bearer <AUTH_CODE>` (for authenticated requests)
