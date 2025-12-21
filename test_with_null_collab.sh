#!/bin/bash
# Test with explicit collaborationId: null
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing with explicit null collaborationId..."
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

# Test with explicit null
echo "2. Test with collaborationId: null..."
QUERY1='{"query":"query GetProjects($input: VRGetProjectsInput!, $lang: Language!) { getProjects(input: $input) { id slug } }","variables":{"input":{"collaborationId":null},"lang":"EN"}}'

echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY1" | jq .

echo ""

# Test WITHOUT lang variable (just input)
echo "3. Test without lang variable (simpler)..."
QUERY2='{"query":"query GetProjects($input: VRGetProjectsInput!) { getProjects(input: $input) { id slug } }","variables":{"input":{}}}'

echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY2" | jq .

echo ""
echo "Tests complete!"
