#!/bin/bash
# Test using EXACT query from ReadProjects.md Example 1
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "Testing with exact documentation query..."
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

# Test with EXACT query from ReadProjects.md Example 1 (lines 119-148)
echo "2. Testing with exact documentation query (Example 1)..."
EXACT_QUERY='{"query":"query GetProjects { getProjects(input: {}) { id slug imageUrl isLive liveDate name { text(lang: EN) } subscription { isActive isTrial status canChoosePlan hasExpired currency price renewalInterval startedAt expiresAt renewsAt prices { currency monthly yearly } } } }"}'

echo "Query: $EXACT_QUERY"
echo ""
echo "Response:"
curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$EXACT_QUERY" | jq .

echo ""
echo "Test complete!"
