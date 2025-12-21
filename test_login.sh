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
DEFAULT_EMAIL="rusuandreicristian+10@gmail.com"
DEFAULT_PASSWORD="QuackQuackIAmADuck"
X_VRON_PLATFORM_HEADER="merchants"

# Use provided credentials or defaults
EMAIL="${1:-$DEFAULT_EMAIL}"
PASSWORD="${2:-$DEFAULT_PASSWORD}"

echo "Attempting to sign in with email: $EMAIL"

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
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$JSON_PAYLOAD" \
  "$GRAPHQL_ENDPOINT")

# Check for cURL errors
if [ $? -ne 0 ]; then
  echo "Error: cURL command failed."
  exit 1
fi

# 3. Parse accessToken from response
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to get accessToken. Check credentials or API response."
  echo "Full response: $RESPONSE"
  exit 1
fi

echo "Successfully received accessToken."
echo "AccessToken: $ACCESS_TOKEN"

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

echo "Generated AUTH_CODE (Base64 encoded): $AUTH_CODE_B64"
echo "---"
echo "You can use this AUTH_CODE in your Authorization header for subsequent requests:"
echo "Authorization: Bearer $AUTH_CODE_B64"

exit 0
