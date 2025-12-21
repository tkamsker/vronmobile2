#!/bin/bash
# Test single project query to see if the issue is specific to getProjects
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
PROJECT_ID="${3:-}" # Will be provided if known
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing alternative queries..."
echo ""

# Login
echo "1. Logging in..."
LOGIN_JSON='{"query":"mutation SignIn($input: SignInInput!) { signIn(input: $input) { accessToken } }","variables":{"input":{"email":"'$EMAIL'","password":"'$PASSWORD'"}}}'

TOKEN=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: merchants" \
  -d "$LOGIN_JSON" | jq -r '.data.signIn.accessToken')

if [ "$TOKEN" = "null" ]; then
  echo "❌ Login failed"
  exit 1
fi

echo "✅ Token: ${TOKEN:0:50}..."
echo ""

# Test __typename query (should always work)
echo "2. Testing GraphQL introspection - checking if getProjects field exists..."
INTRO_QUERY='{"query":"{ __schema { queryType { name fields { name } } } }"}'

echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$INTRO_QUERY" | jq '.data.__schema.queryType.fields[] | select(.name | contains("project") or contains("Project"))'

echo ""
echo "Test complete!"
