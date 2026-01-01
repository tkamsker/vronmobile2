#!/bin/bash

# This script tests creating a BYO project and uploading a GLB file
# It first authenticates, creates the project, then uploads a GLB world file.
# Requires 'jq' for JSON parsing.

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_create_project.sh [json_file] [glb_file] [email] [password]
#   - json_file: Path to JSON file containing project input (required)
#   - glb_file: Path to GLB file to upload as world (optional, default: Requirements/scan_scan-1767259992988-992988.glb)
#   - If email/password are not provided, it uses the default test credentials.
#
# --- Example JSON file (project_create.json) ---
# {
#   "name": "My Test Project",
#   "slug": "my-test-project",
#   "description": "A test project created via API"
# }

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"
DEFAULT_GLB_FILE="Requirements/scan_scan-1767259992988-992988.glb"

# Parse arguments
JSON_FILE="$1"
GLB_FILE="${2:-$DEFAULT_GLB_FILE}"
EMAIL="${3:-$DEFAULT_EMAIL}"
PASSWORD="${4:-$DEFAULT_PASSWORD}"

# Validate JSON file argument
if [ -z "$JSON_FILE" ]; then
  echo "Error: JSON file path is required as first argument."
  echo ""
  echo "Usage: ./test_create_project.sh [json_file] [glb_file] [email] [password]"
  echo ""
  echo "Example JSON file (project_create.json):"
  echo '{'
  echo '  "name": "My Test Project",'
  echo '  "slug": "my-test-project",'
  echo '  "description": "A test project created via API"'
  echo '}'
  exit 1
fi

if [ ! -f "$JSON_FILE" ]; then
  echo "Error: JSON file not found: $JSON_FILE"
  exit 1
fi

# Validate JSON file format
if ! jq empty "$JSON_FILE" 2>/dev/null; then
  echo "Error: Invalid JSON in file: $JSON_FILE"
  exit 1
fi

# Read and validate required fields
PROJECT_NAME=$(jq -r '.name // empty' "$JSON_FILE")
PROJECT_SLUG=$(jq -r '.slug // empty' "$JSON_FILE")

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: 'name' field is required in JSON file"
  exit 1
fi

if [ -z "$PROJECT_SLUG" ]; then
  echo "Error: 'slug' field is required in JSON file"
  exit 1
fi

# Validate GLB file (if provided)
if [ ! -z "$GLB_FILE" ] && [ ! -f "$GLB_FILE" ]; then
  echo "Error: GLB file not found: $GLB_FILE"
  exit 1
fi

echo "=== VRon BYO Project Creation Test ==="
echo "Project Name: $PROJECT_NAME"
echo "Project Slug: $PROJECT_SLUG"
if [ ! -z "$GLB_FILE" ]; then
  GLB_SIZE=$(du -h "$GLB_FILE" | cut -f1)
  echo "GLB File: $GLB_FILE (${GLB_SIZE})"
fi
echo ""

echo "=== Step 1: Authenticating with email: $EMAIL ==="

# 1. Construct GraphQL mutation payload for login
LOGIN_PAYLOAD=$(cat <<EOF
{
  "query": "mutation SignIn(\$input: SignInInput!) { signIn(input: \$input) { accessToken } }",
  "variables": {
    "input": {
      "email": "$EMAIL",
      "password": "$PASSWORD"
    }
  }
}
EOF
)

# 2. Send POST request to GraphQL endpoint for login
LOGIN_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$LOGIN_PAYLOAD" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed during login."
  exit 1
fi

# 3. Parse accessToken from response
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to get accessToken. Check credentials or API response."
  echo "Full response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Successfully authenticated."

# 4. Construct AUTH_CODE JSON structure
AUTH_CODE_JSON=$(cat <<EOF
{
    "MERCHANT": {
        "accessToken": "$ACCESS_TOKEN"
    },
    "activeRoles": {
        "merchants":"MERCHANT"
    }
}
EOF
)

# 5. Base64 encode the AUTH_CODE JSON
AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)

echo "Generated AUTH_CODE: ${AUTH_CODE_B64:0:50}..."
echo ""
echo "=== Step 2: Creating BYO project ==="

# Read the input data from JSON file
CREATE_INPUT=$(cat "$JSON_FILE")

echo "Project input:"
echo "$CREATE_INPUT" | jq '.'

# 6. Construct GraphQL mutation to create project
# Note: Backend implements projects as products, so we use VRonCreateProduct
# For BYO projects, we need to provide title instead of name
PROJECT_TITLE=$(echo "$CREATE_INPUT" | jq -r '.name')
PROJECT_DESC=$(echo "$CREATE_INPUT" | jq -r '.description // ""')

CREATE_MUTATION=$(cat <<EOF
{
  "query": "mutation CreateProduct(\$input: VRonCreateProductInput!) { VRonCreateProduct(input: \$input) { __typename } }",
  "variables": {
    "input": {
      "title": "$PROJECT_TITLE",
      "slug": "$PROJECT_SLUG",
      "description": "$PROJECT_DESC",
      "status": "DRAFT"
    }
  }
}
EOF
)

# 7. Send POST request to create project
CREATE_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$CREATE_MUTATION" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed while creating project."
  exit 1
fi

# 8. Check for GraphQL errors
GRAPHQL_ERRORS=$(echo "$CREATE_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$GRAPHQL_ERRORS" ]; then
  echo "❌ Error: GraphQL returned errors:"
  echo "$CREATE_RESPONSE" | jq '.errors'
  exit 1
fi

# 9. Check if creation was successful
CREATE_RESULT=$(echo "$CREATE_RESPONSE" | jq -r '.data.VRonCreateProduct // empty')

if [ -z "$CREATE_RESULT" ]; then
  echo "Error: Create mutation did not return expected data."
  echo "Full response: $CREATE_RESPONSE"
  exit 1
fi

echo "✅ Successfully created project!"
echo "Project Slug: $PROJECT_SLUG"
echo ""
echo "=== Response ==="
echo "$CREATE_RESPONSE" | jq '.'
echo ""

# Note: VRonCreateProduct returns the slug, not the full project data
# We need to fetch the project details using the slug
echo "Fetching project details..."

# Fetch project details using getProjects query
GET_PROJECT_QUERY=$(cat <<EOF
{
  "query": "query GetProjects { getProjects(input: {}) { id slug name { text(lang: EN) } description { text(lang: EN) } imageUrl isLive subscription { status } } }"
}
EOF
)

GET_PROJECT_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$GET_PROJECT_QUERY" \
  "$GRAPHQL_ENDPOINT")

# Find the project we just created by slug
PROJECT_ID=$(echo "$GET_PROJECT_RESPONSE" | jq -r --arg slug "$PROJECT_SLUG" '.data.getProjects[] | select(.slug == $slug) | .id')

if [ -z "$PROJECT_ID" ]; then
  echo "Warning: Could not fetch project ID, but creation was successful."
  echo "Use slug '$PROJECT_SLUG' to reference the project."
else
  echo "Project ID: $PROJECT_ID"

  # Show project details
  echo ""
  echo "=== Project Details ==="
  echo "$GET_PROJECT_RESPONSE" | jq --arg slug "$PROJECT_SLUG" '.data.getProjects[] | select(.slug == $slug)'
fi

echo ""

# Skip GLB upload if no file provided
if [ -z "$GLB_FILE" ]; then
  echo "=== Test Complete (no GLB file to upload) ==="
  exit 0
fi

echo "=== Step 3: Uploading GLB World File ==="
echo "Note: The GLB upload feature requires additional backend mutations."
echo "The following steps outline the required flow:"
echo ""
echo "3.1. Request pre-signed upload URL (createWorldModelUploadUrl mutation)"
echo "3.2. Upload GLB file to pre-signed URL via PUT request"
echo "3.3. Confirm upload (confirmWorldModelUpload mutation)"
echo ""
echo "⚠️  These mutations may need to be implemented on the backend first."
echo ""

# Attempt to upload GLB using the expected pattern
# Note: These mutations may not exist yet and will need to be implemented

echo "Attempting to request upload URL..."

# Step 3.1: Request upload URL
UPLOAD_URL_MUTATION=$(cat <<EOF
{
  "query": "mutation CreateWorldModelUploadUrl(\$input: CreateWorldModelUploadUrlInput!) { createWorldModelUploadUrl(input: \$input) { uploadUrl fileUrl } }",
  "variables": {
    "input": {
      "projectId": "$PROJECT_ID",
      "mimeType": "model/gltf-binary",
      "filename": "$(basename "$GLB_FILE")"
    }
  }
}
EOF
)

UPLOAD_URL_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$UPLOAD_URL_MUTATION" \
  "$GRAPHQL_ENDPOINT")

# Check if mutation exists
UPLOAD_URL_ERRORS=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$UPLOAD_URL_ERRORS" ]; then
  ERROR_MESSAGE=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.errors[0].message // empty')

  if [[ "$ERROR_MESSAGE" == *"Cannot query field"* ]] || [[ "$ERROR_MESSAGE" == *"Unknown type"* ]]; then
    echo "⚠️  GLB upload mutations not yet implemented on backend."
    echo "Error: $ERROR_MESSAGE"
    echo ""
    echo "To implement GLB upload, the backend needs to add:"
    echo "  - createWorldModelUploadUrl mutation"
    echo "  - confirmWorldModelUpload mutation"
    echo ""
    echo "See Requirements/CreateNewWorld_Flutter_PRD.md for implementation details."
    echo ""
    echo "=== Test Complete (project created, GLB upload pending backend support) ==="
    exit 0
  else
    echo "❌ Error requesting upload URL:"
    echo "$UPLOAD_URL_RESPONSE" | jq '.errors'
    exit 1
  fi
fi

# Extract upload URL
UPLOAD_URL=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.data.createWorldModelUploadUrl.uploadUrl // empty')
FILE_URL=$(echo "$UPLOAD_URL_RESPONSE" | jq -r '.data.createWorldModelUploadUrl.fileUrl // empty')

if [ -z "$UPLOAD_URL" ] || [ -z "$FILE_URL" ]; then
  echo "Error: Failed to get upload URL."
  echo "Response: $UPLOAD_URL_RESPONSE"
  exit 1
fi

echo "✅ Received upload URL"
echo "Upload URL: ${UPLOAD_URL:0:80}..."
echo "File URL: $FILE_URL"
echo ""

# Step 3.2: Upload GLB file to pre-signed URL
echo "Uploading GLB file..."

UPLOAD_STATUS=$(curl -s -w "%{http_code}" -o /dev/null \
  -X PUT \
  -H "Content-Type: model/gltf-binary" \
  --data-binary "@$GLB_FILE" \
  "$UPLOAD_URL")

if [ "$UPLOAD_STATUS" != "200" ]; then
  echo "❌ Error: GLB upload failed with status $UPLOAD_STATUS"
  exit 1
fi

echo "✅ GLB file uploaded successfully"
echo ""

# Step 3.3: Confirm upload
echo "Confirming upload..."

CONFIRM_MUTATION=$(cat <<EOF
{
  "query": "mutation ConfirmWorldModelUpload(\$input: ConfirmWorldModelUploadInput!) { confirmWorldModelUpload(input: \$input) { success worldUrl } }",
  "variables": {
    "input": {
      "projectId": "$PROJECT_ID",
      "fileUrl": "$FILE_URL"
    }
  }
}
EOF
)

CONFIRM_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$CONFIRM_MUTATION" \
  "$GRAPHQL_ENDPOINT")

# Check for errors
CONFIRM_ERRORS=$(echo "$CONFIRM_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$CONFIRM_ERRORS" ]; then
  echo "❌ Error confirming upload:"
  echo "$CONFIRM_RESPONSE" | jq '.errors'
  exit 1
fi

# Check success
UPLOAD_SUCCESS=$(echo "$CONFIRM_RESPONSE" | jq -r '.data.confirmWorldModelUpload.success // empty')
WORLD_URL=$(echo "$CONFIRM_RESPONSE" | jq -r '.data.confirmWorldModelUpload.worldUrl // empty')

if [ "$UPLOAD_SUCCESS" != "true" ]; then
  echo "❌ Error: Upload confirmation failed"
  echo "Response: $CONFIRM_RESPONSE"
  exit 1
fi

echo "✅ Upload confirmed!"
echo "World URL: $WORLD_URL"
echo ""

echo "=== Test Complete ==="
echo "✅ Project created successfully: $PROJECT_ID"
echo "✅ GLB world file uploaded: $WORLD_URL"
echo ""
echo "You can now view the project in the merchants app or use it for scanning."

exit 0
