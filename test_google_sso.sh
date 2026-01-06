#!/bin/bash

# Test script for Google OAuth exchangeGoogleIdToken mutation
# Usage:
#   ./test_google_sso.sh <idToken>
#   echo "<idToken>" | ./test_google_sso.sh
#   ./test_google_sso.sh  # Will prompt for idToken

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default GraphQL endpoint (can be overridden with GRAPHQL_ENDPOINT env var)
GRAPHQL_ENDPOINT="${GRAPHQL_ENDPOINT:-https://api.vron.stage.motorenflug.at/graphql}"

echo -e "${BLUE}🔍 Google OAuth Token Exchange Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get idToken from argument, stdin, or prompt
if [ -n "$1" ]; then
    ID_TOKEN="$1"
    echo -e "${GREEN}✓${NC} Using idToken from command line argument"
elif [ ! -t 0 ]; then
    # stdin is not a terminal (piped input)
    ID_TOKEN=$(cat)
    echo -e "${GREEN}✓${NC} Using idToken from stdin"
else
    echo -e "${YELLOW}?${NC} Enter Google idToken (paste and press Enter):"
    read -r ID_TOKEN
fi

# Validate idToken is not empty
if [ -z "$ID_TOKEN" ]; then
    echo -e "${RED}✗${NC} Error: idToken cannot be empty"
    exit 1
fi

# Show idToken info
ID_TOKEN_LENGTH=${#ID_TOKEN}
ID_TOKEN_PREVIEW="${ID_TOKEN:0:50}..."
echo ""
echo -e "${BLUE}Token Info:${NC}"
echo -e "  Length: ${ID_TOKEN_LENGTH} characters"
echo -e "  Preview: ${ID_TOKEN_PREVIEW}"
echo ""

# Construct GraphQL mutation
MUTATION='mutation ExchangeGoogleIdToken($input: ExchangeGoogleIdTokenInput!) {
  exchangeGoogleIdToken(input: $input)
}'

# Construct variables
VARIABLES=$(cat <<EOF
{
  "input": {
    "idToken": "${ID_TOKEN}"
  }
}
EOF
)

# Construct full GraphQL request
REQUEST_BODY=$(cat <<EOF
{
  "query": $(echo "$MUTATION" | jq -Rs .),
  "variables": ${VARIABLES}
}
EOF
)

echo -e "${BLUE}Request Details:${NC}"
echo -e "  Endpoint: ${GRAPHQL_ENDPOINT}"
echo -e "  Mutation: exchangeGoogleIdToken"
echo -e "  Platform: merchants"
echo ""

# Show request body (with truncated idToken for readability)
echo -e "${BLUE}Request Body:${NC}"
echo "$REQUEST_BODY" | jq --arg token "${ID_TOKEN_PREVIEW}" '.variables.input.idToken = $token' || echo "$REQUEST_BODY"
echo ""

echo -e "${BLUE}Sending request...${NC}"
echo ""

# Send request with curl
HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/graphql_response.json \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-VRon-Platform: merchants" \
    -d "$REQUEST_BODY" \
    "$GRAPHQL_ENDPOINT")

# Read response
RESPONSE=$(cat /tmp/graphql_response.json)

echo -e "${BLUE}Response:${NC}"
echo -e "  HTTP Status: ${HTTP_CODE}"
echo ""

# Pretty print response
if command -v jq &> /dev/null; then
    echo -e "${BLUE}Response Body:${NC}"
    echo "$RESPONSE" | jq '.'
    echo ""

    # Check for errors
    if echo "$RESPONSE" | jq -e '.errors' > /dev/null 2>&1; then
        echo -e "${RED}✗ GraphQL Errors Found:${NC}"
        echo "$RESPONSE" | jq -r '.errors[] | "  - \(.message)"'
        echo ""
        echo -e "${YELLOW}Error Details:${NC}"
        echo "$RESPONSE" | jq '.errors'
        exit 1
    fi

    # Check for data
    if echo "$RESPONSE" | jq -e '.data.exchangeGoogleIdToken' > /dev/null 2>&1; then
        ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.exchangeGoogleIdToken')
        ACCESS_TOKEN_LENGTH=${#ACCESS_TOKEN}
        ACCESS_TOKEN_PREVIEW="${ACCESS_TOKEN:0:50}..."

        echo -e "${GREEN}✓ Success!${NC}"
        echo ""
        echo -e "${BLUE}Access Token Received:${NC}"
        echo -e "  Length: ${ACCESS_TOKEN_LENGTH} characters"
        echo -e "  Preview: ${ACCESS_TOKEN_PREVIEW}"
        echo ""
        echo -e "${GREEN}✓ Token exchange completed successfully${NC}"
        exit 0
    else
        echo -e "${RED}✗ No data in response${NC}"
        echo "$RESPONSE" | jq '.'
        exit 1
    fi
else
    # jq not available, show raw response
    echo "$RESPONSE"

    if echo "$RESPONSE" | grep -q '"errors"'; then
        echo ""
        echo -e "${RED}✗ Errors detected in response${NC}"
        exit 1
    elif echo "$RESPONSE" | grep -q '"exchangeGoogleIdToken"'; then
        echo ""
        echo -e "${GREEN}✓ Success!${NC}"
        exit 0
    else
        echo ""
        echo -e "${YELLOW}⚠ Unexpected response format${NC}"
        exit 1
    fi
fi
