#!/bin/bash

# This script tests fetching a single VR project detail from the vron.one GraphQL API
# It first authenticates using the login flow, then fetches project details.
# Requires 'jq' for JSON parsing.

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_getvrproject.sh [project_id] [email] [password]

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
DEFAULT_PROJECT_ID="6889cb7bc10c83ee1d423b67"
X_VRON_PLATFORM_HEADER="merchants"

# Parse arguments
PROJECT_ID="${1:-$DEFAULT_PROJECT_ID}"
EMAIL="${2:-$DEFAULT_EMAIL}"
PASSWORD="${3:-$DEFAULT_PASSWORD}"

echo "=== Step 1: Authenticating with email: $EMAIL ==="

# 1. Construct GraphQL mutation payload for login
JSON_PAYLOAD=$(cat <<EOF
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
RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$JSON_PAYLOAD" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed during login."
  exit 1
fi

# 3. Parse accessToken from response
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to get accessToken. Check credentials or API response."
  echo "Full response: $RESPONSE"
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
echo "=== Step 2: Fetching VR project $PROJECT_ID ==="

# 6. Construct GraphQL query to fetch VR project (matching actual schema)
VR_PROJECT_QUERY=$(cat <<EOF
{
  "query": "query GetVRProject(\$input: VRGetProjectInput!, \$lang: Language!) { getVRProject(input: \$input) { id slug name { text(lang: \$lang) } description { text(lang: \$lang) } liveDate isOwner isShop subscription { isTrial status canChoosePlan renewalInterval prices { currency monthly yearly } } } }",
  "variables": {
    "input": {
      "id": "$PROJECT_ID"
    },
    "lang": "EN"
  }
}
EOF
)

# 7. Send POST request to fetch VR project
VR_PROJECT_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$VR_PROJECT_QUERY" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed while fetching VR project."
  exit 1
fi

# 8. Check for GraphQL errors
GRAPHQL_ERRORS=$(echo "$VR_PROJECT_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$GRAPHQL_ERRORS" ]; then
  echo "Error: GraphQL returned errors:"
  echo "$VR_PROJECT_RESPONSE" | jq '.errors'
  exit 1
fi

# 9. Parse and display project
PROJECT_NAME=$(echo "$VR_PROJECT_RESPONSE" | jq -r '.data.getVRProject.name.text // empty')
PROJECT_DESC=$(echo "$VR_PROJECT_RESPONSE" | jq -r '.data.getVRProject.description.text // empty')

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: Failed to fetch VR project."
  echo "Full response: $VR_PROJECT_RESPONSE"
  exit 1
fi

echo "✅ Successfully fetched VR project"
echo ""
echo "=== Project Details ==="
echo "ID: $PROJECT_ID"
echo "Name (title): $PROJECT_NAME"
echo "Description: $PROJECT_DESC"
echo ""
echo "=== Full JSON Response ==="
echo "$VR_PROJECT_RESPONSE" | jq '.'

exit 0
