#!/bin/bash

# This script tests updating a project via VRonUpdateProduct mutation
# It first authenticates, then sends the update mutation with data from a JSON file.
# Requires 'jq' for JSON parsing.

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_update_project.sh [json_file] [email] [password]
#   - json_file: Path to JSON file containing update input (required)
#   - If email/password are not provided, it uses the default test credentials.
#
# --- Example JSON file (project_update.json) ---
# {
#   "id": "6889cb75c10c83ee1d423b53",
#   "title": "Updated Project Name",
#   "description": "Updated description"
# }
#
# Or with all fields:
# {
#   "id": "6889cb75c10c83ee1d423b53",
#   "title": "Updated Project Name",
#   "description": "Updated description",
#   "status": "DRAFT",
#   "tracksInventory": false,
#   "categoryId": "some-category-id",
#   "tags": ["tag1", "tag2"]
# }

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"

# Parse arguments
JSON_FILE="$1"
EMAIL="${2:-$DEFAULT_EMAIL}"
PASSWORD="${3:-$DEFAULT_PASSWORD}"

# Validate JSON file argument
if [ -z "$JSON_FILE" ]; then
  echo "Error: JSON file path is required as first argument."
  echo ""
  echo "Usage: ./test_update_project.sh [json_file] [email] [password]"
  echo ""
  echo "Example JSON file (project_update.json):"
  echo '{'
  echo '  "id": "6889cb75c10c83ee1d423b53",'
  echo '  "title": "Updated Project Name",'
  echo '  "description": "Updated description"'
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
PROJECT_ID=$(jq -r '.id // empty' "$JSON_FILE")
if [ -z "$PROJECT_ID" ]; then
  echo "Error: 'id' field is required in JSON file"
  exit 1
fi

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
echo "=== Step 2: Updating project $PROJECT_ID ==="

# Read the input data from JSON file
UPDATE_INPUT=$(cat "$JSON_FILE")

echo "Update input:"
echo "$UPDATE_INPUT" | jq '.'

# 6. Construct GraphQL mutation to update project
UPDATE_MUTATION=$(cat <<EOF
{
  "query": "mutation UpdateProduct(\$input: VRonUpdateProductInput!) { VRonUpdateProduct(input: \$input) }",
  "variables": {
    "input": $UPDATE_INPUT
  }
}
EOF
)

# 7. Send POST request to update project
UPDATE_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$UPDATE_MUTATION" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed while updating project."
  exit 1
fi

# 8. Check for GraphQL errors
GRAPHQL_ERRORS=$(echo "$UPDATE_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$GRAPHQL_ERRORS" ]; then
  echo "❌ Error: GraphQL returned errors:"
  echo "$UPDATE_RESPONSE" | jq '.errors'
  exit 1
fi

# 9. Check for successful response
UPDATE_RESULT=$(echo "$UPDATE_RESPONSE" | jq -r '.data.VRonUpdateProduct // empty')

if [ -z "$UPDATE_RESULT" ]; then
  echo "Error: Update mutation did not return expected data."
  echo "Full response: $UPDATE_RESPONSE"
  exit 1
fi

echo "✅ Successfully updated project!"
echo ""
echo "=== Full JSON Response ==="
echo "$UPDATE_RESPONSE" | jq '.'

exit 0
