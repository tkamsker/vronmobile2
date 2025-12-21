#!/bin/bash

# Simple test without variables
set -e

EMAIL="$1"
PASSWORD="$2"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "=== Step 1: Login ==="
LOGIN_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: merchants" \
  -d '{
    "query": "mutation SignIn($input: SignInInput!) { signIn(input: $input) { accessToken } }",
    "variables": {"input": {"email": "'"$EMAIL"'", "password": "'"$PASSWORD"'"}}
  }')

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken')
echo "Access Token: ${ACCESS_TOKEN:0:50}..."
echo ""

echo "=== Step 2: Test Simple Query (no variables) ==="
# Hardcoded language, no variables
curl -v -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d '{
    "query": "query GetProjects { getProjects(input: {}) { id slug name { text(lang: EN) } } }"
  }' | jq .
