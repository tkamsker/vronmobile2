#!/bin/bash

# This script tests creating a BYO project using the combined mutation:
# VRonCreateProjectFromOwnWorld - Single mutation that creates both world and project
#
# This is the recommended approach (Option B) from the PRD

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"
DEFAULT_GLB_FILE="Requirements/scan_scan-1767259992988-992988.glb"

# Parse arguments
GLB_FILE="${1:-$DEFAULT_GLB_FILE}"
WORLD_SLUG="${2:-test-byo-world-$(date +%s)}"
PROJECT_NAME="${3:-Test BYO Project}"
EMAIL="${4:-$DEFAULT_EMAIL}"
PASSWORD="${5:-$DEFAULT_PASSWORD}"

# Use same GLB file for both world and mesh if not specified
MESH_FILE="${GLB_FILE}"

# Generate a simple placeholder image
IMAGE_FILE="/tmp/placeholder_world_image.png"

# Validate GLB file
if [ ! -f "$GLB_FILE" ]; then
  echo "Error: GLB file not found: $GLB_FILE"
  echo ""
  echo "Usage: ./test_create_byo_project_combined.sh [glb_file] [world_slug] [project_name] [email] [password]"
  echo ""
  echo "Example:"
  echo "  ./test_create_byo_project_combined.sh Requirements/scan_scan-1767259992988-992988.glb"
  exit 1
fi

GLB_SIZE=$(du -h "$GLB_FILE" | cut -f1)

echo "=== VRon BYO Project Creation (Combined Mutation) ==="
echo "Project Name: $PROJECT_NAME"
echo "World Slug: $WORLD_SLUG"
echo "GLB File: $GLB_FILE (${GLB_SIZE})"
echo "Mesh File: $MESH_FILE"
echo ""

# Create placeholder image if it doesn't exist
if [ ! -f "$IMAGE_FILE" ]; then
  echo "Creating placeholder image..."
  # Create a simple 1x1 PNG
  printf '\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x0a\x49\x44\x41\x54\x78\x9c\x63\x00\x01\x00\x00\x05\x00\x01\x0d\x0a\x2d\xb4\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82' > "$IMAGE_FILE"
fi

echo "=== Step 1: Authenticating ==="

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

LOGIN_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$LOGIN_PAYLOAD" \
  "$GRAPHQL_ENDPOINT")

if [ $? -ne 0 ]; then
  echo "Error: cURL command failed during login."
  exit 1
fi

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to get accessToken. Check credentials or API response."
  echo "Full response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Successfully authenticated."

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

AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)

echo ""
echo "=== Step 2: Creating BYO Project (Single Combined Mutation) ==="

# GraphQL mutation for VRonCreateProjectFromOwnWorld
MUTATION='mutation VRonCreateProjectFromOwnWorld($input: CreateProjectFromOwnWorldInput!) { VRonCreateProjectFromOwnWorld(input: $input) { projectId worldId } }'

# Prepare the operations field (GraphQL query + variables)
OPERATIONS=$(cat <<EOF
{
  "query": "$MUTATION",
  "variables": {
    "input": {
      "slug": "$WORLD_SLUG",
      "name": "$PROJECT_NAME",
      "description": "BYO Project from LiDAR scan",
      "worldFile": null,
      "meshFile": null,
      "image": null
    }
  }
}
EOF
)

# Prepare the map field (maps files to variables)
MAP=$(cat <<EOF
{
  "worldFile": ["variables.input.worldFile"],
  "meshFile": ["variables.input.meshFile"],
  "image": ["variables.input.image"]
}
EOF
)

echo "Uploading files and creating project..."
echo "  World file: $(basename "$GLB_FILE")"
echo "  Mesh file: $(basename "$MESH_FILE")"
echo "  Image file: $(basename "$IMAGE_FILE")"

# Make multipart request with file uploads
# Note: apollo-require-preflight header is needed for CSRF protection
CREATE_RESPONSE=$(curl -s \
  -X POST \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "apollo-require-preflight: true" \
  -F "operations=$OPERATIONS" \
  -F "map=$MAP" \
  -F "worldFile=@$GLB_FILE;type=model/gltf-binary" \
  -F "meshFile=@$MESH_FILE;type=model/gltf-binary" \
  -F "image=@$IMAGE_FILE;type=image/png" \
  "$GRAPHQL_ENDPOINT")

if [ $? -ne 0 ]; then
  echo "❌ Error: cURL command failed while creating project."
  exit 1
fi

# Check for GraphQL errors
GRAPHQL_ERRORS=$(echo "$CREATE_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$GRAPHQL_ERRORS" ]; then
  echo "❌ Error: GraphQL returned errors:"
  echo "$CREATE_RESPONSE" | jq '.errors'

  # Check if mutation doesn't exist
  ERROR_MSG=$(echo "$CREATE_RESPONSE" | jq -r '.errors[0].message // empty')
  if [[ "$ERROR_MSG" == *"Cannot query field"* ]] || [[ "$ERROR_MSG" == *"Unknown type"* ]]; then
    echo ""
    echo "⚠️  The VRonCreateProjectFromOwnWorld mutation is not yet implemented on the backend."
    echo ""
    echo "Backend team needs to implement this mutation with the following signature:"
    echo ""
    echo "mutation VRonCreateProjectFromOwnWorld(\$input: CreateProjectFromOwnWorldInput!) {"
    echo "  VRonCreateProjectFromOwnWorld(input: \$input) {"
    echo "    projectId"
    echo "    worldId"
    echo "  }"
    echo "}"
    echo ""
    echo "input CreateProjectFromOwnWorldInput {"
    echo "  slug: String!"
    echo "  name: String!"
    echo "  description: String"
    echo "  worldFile: Upload!"
    echo "  meshFile: Upload!"
    echo "  image: Upload"
    echo "}"
    echo ""
    echo "See BYO_PROJECT_STATUS.md for full implementation details."
  fi

  exit 1
fi

# Extract project ID and world ID
PROJECT_ID=$(echo "$CREATE_RESPONSE" | jq -r '.data.VRonCreateProjectFromOwnWorld.projectId // empty')
WORLD_ID=$(echo "$CREATE_RESPONSE" | jq -r '.data.VRonCreateProjectFromOwnWorld.worldId // empty')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Error: Mutation did not return project ID."
  echo "Full response: $CREATE_RESPONSE"
  exit 1
fi

echo "✅ Successfully created BYO project!"
echo "Project ID: $PROJECT_ID"
echo "World ID: $WORLD_ID"
echo ""

# Fetch full project details
echo "=== Fetching Project Details ==="

GET_PROJECT_QUERY=$(cat <<EOF
{
  "query": "query GetProjects { getProjects(input: {}) { id slug name { text(lang: EN) } description { text(lang: EN) } imageUrl isLive worldUrl meshUrl subscription { status isActive isTrial } } }"
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

# Find the project we just created
PROJECT_DETAILS=$(echo "$GET_PROJECT_RESPONSE" | jq --arg id "$PROJECT_ID" '.data.getProjects[] | select(.id == $id)')

if [ ! -z "$PROJECT_DETAILS" ]; then
  echo "$PROJECT_DETAILS" | jq '.'

  # Extract key information
  SUBSCRIPTION_STATUS=$(echo "$PROJECT_DETAILS" | jq -r '.subscription.status // empty')
  WORLD_URL=$(echo "$PROJECT_DETAILS" | jq -r '.worldUrl // empty')
  MESH_URL=$(echo "$PROJECT_DETAILS" | jq -r '.meshUrl // empty')

  echo ""
  echo "=== Verification ==="
  echo "Subscription Status: $SUBSCRIPTION_STATUS"
  if [ "$SUBSCRIPTION_STATUS" == "MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER" ]; then
    echo "✅ Correct subscription status for BYO project"
  fi

  if [ ! -z "$WORLD_URL" ]; then
    echo "✅ World GLB uploaded: $WORLD_URL"
  fi

  if [ ! -z "$MESH_URL" ]; then
    echo "✅ Mesh GLB uploaded: $MESH_URL"
  fi
else
  echo "Warning: Could not fetch full project details."
fi

echo ""
echo "=== Test Complete ==="
echo "✅ BYO Project created successfully!"
echo "✅ Project ID: $PROJECT_ID"
echo "✅ World ID: $WORLD_ID"
echo ""
echo "Project is now ready for uploading additional scans!"

exit 0
