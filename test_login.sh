#!/bin/bash

# This script tests the login functionality of the vron.one GraphQL API
# using curl. It requires 'jq' for JSON parsing.

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_login.sh [email] [password]
#   - If email/password are not provided, it uses the default test credentials.

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"
CURL_TIMEOUT=30

# Use provided credentials or defaults
EMAIL="${1:-$DEFAULT_EMAIL}"
PASSWORD="${2:-$DEFAULT_PASSWORD}"

echo "=== VRon Login Test ==="
echo "Attempting to sign in with email: $EMAIL"
echo "Sending request to $GRAPHQL_ENDPOINT..."
echo ""

# 1. Construct GraphQL mutation payload
JSON_PAYLOAD=$(cat <<EOF
{
  "query": "mutation SignIn(\\$input: SignInInput!) { signIn(input: \\$input) { accessToken } }",
  "variables": {
    "input": {
      "email": "$EMAIL",
      "password": "$PASSWORD"
    }
  }
}
EOF
)

# 2. Send POST request to GraphQL endpoint
RESPONSE=$(curl -s \
  --max-time $CURL_TIMEOUT \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$JSON_PAYLOAD" \
  "$GRAPHQL_ENDPOINT" 2>&1)

# Check for cURL errors
CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0 ]; then
  echo "❌ Error: curl command failed with code $CURL_EXIT_CODE"
  if [ $CURL_EXIT_CODE -eq 28 ]; then
    echo "   This indicates a connection timeout after ${CURL_TIMEOUT} seconds."
    echo "   Possible causes:"
    echo "   - API server is not reachable from your network"
    echo "   - You may need VPN access"
    echo "   - API server may be down"
    echo "   - Firewall blocking the connection"
  fi
  exit 1
fi

# 3. Parse accessToken from response
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Error: Failed to get accessToken. Check credentials or API response."
  echo "Full response: $RESPONSE"
  exit 1
fi

echo "✅ Successfully received accessToken."
echo "   AccessToken: ${ACCESS_TOKEN:0:20}...${ACCESS_TOKEN: -10}"
echo ""

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
# Handle macOS vs Linux differences
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)
else
  # Linux
  AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64 -w 0)
fi

# 6. Save token to file for reuse by other scripts
TOKEN_FILE=".auth_token"
echo "$AUTH_CODE_B64" > "$TOKEN_FILE"

echo "✅ Token saved to $TOKEN_FILE for reuse by other test scripts"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "You can now run other test scripts without authentication:"
echo "  ./test_searchproduct.sh"
echo "  ./test_getprojects.sh"
echo "  ./test_getvrproject.sh <project_id>"
echo "  ./test_update_project.sh <project_id>"
echo ""
echo "Authorization header for manual use:"
echo "  Authorization: Bearer $AUTH_CODE_B64"
echo "═══════════════════════════════════════════════════════════"

exit 0
