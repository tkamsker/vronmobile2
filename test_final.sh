#!/bin/bash
# Test using Query Signature format from ReadProjects.md (lines 58-73)
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing with Query Signature format..."
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

# Test with proper Query Signature format (pass input as object in variables)
echo "2. Testing Query Signature format..."
echo ""

# According to ReadProjects.md lines 58-73, input should be passed as a variable
QUERY='{"query":"query GetProjects($input: VRGetProjectsInput!, $lang: Language!) { getProjects(input: $input) { id slug name { text(lang: $lang) } imageUrl isLive } }","variables":{"input":{},"lang":"EN"}}'

echo "Query format: Using \$input variable as per Query Signature"
echo ""
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY" | jq .

echo ""
echo "Test complete!"
