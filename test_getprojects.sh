#!/bin/bash

# This script tests fetching projects from the vron.one GraphQL API
# It first authenticates using the login flow, then fetches projects.
# Requires 'jq' for JSON parsing.

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_getprojects.sh [email] [password]
#   - If email/password are not provided, it uses the default test credentials.

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"

# Use provided credentials or defaults
EMAIL="${1:-$DEFAULT_EMAIL}"
PASSWORD="${2:-$DEFAULT_PASSWORD}"

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
echo "=== Step 2: Fetching projects ==="

# 6. Construct GraphQL query to fetch projects
PROJECTS_QUERY=$(cat <<'EOF'
{
  "query": "query GetProjects($lang: Language!) { getProjects(input: {}) { id slug imageUrl isLive liveDate name { text(lang: $lang) } subscription { isActive isTrial status canChoosePlan hasExpired currency price renewalInterval startedAt expiresAt renewsAt prices { currency monthly yearly } } } }",
  "variables": {
    "lang": "EN"
  }
}
EOF
)

# 7. Send POST request to fetch projects
PROJECTS_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$PROJECTS_QUERY" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed while fetching projects."
  exit 1
fi

# 8. Check for GraphQL errors
GRAPHQL_ERRORS=$(echo "$PROJECTS_RESPONSE" | jq -r '.errors // empty')

if [ ! -z "$GRAPHQL_ERRORS" ]; then
  echo "Error: GraphQL returned errors:"
  echo "$PROJECTS_RESPONSE" | jq '.errors'
  exit 1
fi

# 9. Parse and display projects
PROJECT_COUNT=$(echo "$PROJECTS_RESPONSE" | jq '.data.getProjects | length')

if [ -z "$PROJECT_COUNT" ] || [ "$PROJECT_COUNT" == "null" ]; then
  echo "Error: Failed to fetch projects."
  echo "Full response: $PROJECTS_RESPONSE"
  exit 1
fi

echo "✅ Successfully fetched $PROJECT_COUNT projects"
echo ""
echo "=== Projects List ==="
echo "$PROJECTS_RESPONSE" | jq -r '.data.getProjects[] | "\(.id) - \(.name.text) - Live: \(.isLive)"'

echo ""
echo "=== Full JSON Response ==="
echo "$PROJECTS_RESPONSE" | jq '.'

exit 0
