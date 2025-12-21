#!/bin/bash

# Test script for VRon GraphQL API - Login and Fetch Projects
# Usage: ./test_getprojects.sh <email> <password>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check arguments
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: $0 <email> <password>"
    echo "Example: $0 user@example.com MyPassword123"
    exit 1
fi

EMAIL="$1"
PASSWORD="$2"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}VRon GraphQL API Test${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Login
echo -e "${YELLOW}Step 1: Logging in...${NC}"
echo "Email: $EMAIL"
echo ""

LOGIN_QUERY='{
  "query": "mutation SignIn($input: SignInInput!) { signIn(input: $input) { accessToken } }",
  "variables": {
    "input": {
      "email": "'"$EMAIL"'",
      "password": "'"$PASSWORD"'"
    }
  }
}'

echo -e "${BLUE}Login Request:${NC}"
echo "$LOGIN_QUERY" | jq .
echo ""

LOGIN_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: merchants" \
  -d "$LOGIN_QUERY")

echo -e "${BLUE}Login Response:${NC}"
echo "$LOGIN_RESPONSE" | jq .
echo ""

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken')

if [ "$ACCESS_TOKEN" == "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo -e "${RED}Error: Failed to get access token${NC}"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Login successful${NC}"
echo "Access Token (first 50 chars): ${ACCESS_TOKEN:0:50}..."
echo "Token length: ${#ACCESS_TOKEN} characters"
echo ""

# Step 2: Fetch Projects
echo -e "${YELLOW}Step 2: Fetching projects...${NC}"
echo ""

# Using exact format from ReadProjects.md with proper newlines
PROJECTS_QUERY=$(cat <<'EOF'
{
  "query": "query GetProjects($lang: Language!) {\n  getProjects(input: {}) {\n    id\n    slug\n    imageUrl\n    isLive\n    liveDate\n    name {\n      text(lang: $lang)\n    }\n    subscription {\n      isActive\n      isTrial\n      status\n      canChoosePlan\n      hasExpired\n      currency\n      price\n      renewalInterval\n      startedAt\n      expiresAt\n      renewsAt\n      prices {\n        currency\n        monthly\n        yearly\n      }\n    }\n  }\n}",
  "variables": {
    "lang": "EN"
  }
}
EOF
)

echo -e "${BLUE}Projects Query:${NC}"
echo "$PROJECTS_QUERY" | jq .
echo ""

echo -e "${BLUE}Request Headers:${NC}"
echo "  Authorization: Bearer ${ACCESS_TOKEN:0:50}..."
echo "  X-VRon-Platform: merchants"
echo "  Content-Type: application/json"
echo ""

PROJECTS_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$PROJECTS_QUERY")

echo -e "${BLUE}Projects Response:${NC}"
echo "$PROJECTS_RESPONSE" | jq .
echo ""

# Check for errors
HAS_ERRORS=$(echo "$PROJECTS_RESPONSE" | jq -r '.errors // empty')

if [ -n "$HAS_ERRORS" ]; then
    echo -e "${RED}✗ Error fetching projects${NC}"
    echo "Errors: $HAS_ERRORS"
    exit 1
fi

# Count projects
PROJECT_COUNT=$(echo "$PROJECTS_RESPONSE" | jq -r '.data.getProjects | length')

echo -e "${GREEN}✓ Projects fetched successfully${NC}"
echo "Number of projects: $PROJECT_COUNT"
echo ""

# Display project names
echo -e "${BLUE}Project Names:${NC}"
echo "$PROJECTS_RESPONSE" | jq -r '.data.getProjects[] | "  - " + .name.text'
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
