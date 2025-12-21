#!/bin/bash
# Clean test for getProjects - macOS compatible
# No special characters, simple JSON format
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing getProjects with clean formatting..."
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

# Test 1: Without input parameter
echo "2. Test WITHOUT input parameter..."
QUERY1='{"query":"query { getProjects { id slug } }"}'
echo "Query: $QUERY1"
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY1" | jq .
echo ""

# Test 2: With empty input
echo "3. Test WITH input: {}"
QUERY2='{"query":"query { getProjects(input: {}) { id slug } }"}'
echo "Query: $QUERY2"
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY2" | jq .
echo ""

# Test 3: With input: null
echo "4. Test WITH input: null"
QUERY3='{"query":"query { getProjects(input: null) { id slug } }"}'
echo "Query: $QUERY3"
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY3" | jq .
echo ""

# Test 4: With language variable
echo "5. Test WITH language variable"
QUERY4='{"query":"query GetProjects($lang: Language!) { getProjects(input: {}) { id slug name { text(lang: $lang) } } }","variables":{"lang":"EN"}}'
echo "Query: $QUERY4"
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY4" | jq .

echo ""
echo "Tests complete!"
