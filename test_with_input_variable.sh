#!/bin/bash
# Test getProjects using input as a variable (proper GraphQL approach)
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing getProjects with input as variable..."
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

# Test 1: Use input as variable with empty object (FIXED: VRGetProjectsInput not VrGetProjectsInput)
echo "2. Test with input variable (empty object)..."
QUERY1='{"query":"query GetProjects($input: VRGetProjectsInput!) { getProjects(input: $input) { id slug } }","variables":{"input":{}}}'
echo "Query: $QUERY1"
echo ""
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY1" | jq .

echo ""

# Test 2: With language parameter (FIXED: VRGetProjectsInput not VrGetProjectsInput)
echo "3. Test with input variable and language..."
QUERY2='{"query":"query GetProjects($input: VRGetProjectsInput!, $lang: Language!) { getProjects(input: $input) { id slug name { text(lang: $lang) } } }","variables":{"input":{},"lang":"EN"}}'
echo "Query: $QUERY2"
echo ""
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$QUERY2" | jq .

echo ""
echo "Tests complete!"
