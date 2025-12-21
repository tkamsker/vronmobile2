#!/bin/bash
# GraphQL Schema Introspection for getProjects query
# Compatible with macOS
set -e

EMAIL="${1:-tkamsker@gmail.com}"
PASSWORD="${2:-Test123!}"
API_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"

echo "==================================="
echo "GraphQL Schema Introspection"
echo "==================================="
echo ""

# Step 1: Login
echo "Step 1: Logging in..."
LOGIN_QUERY='{"query":"mutation SignIn($input: SignInInput!) { signIn(input: $input) { accessToken } }","variables":{"input":{"email":"'$EMAIL'","password":"'$PASSWORD'"}}}'

LOGIN_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: merchants" \
  -d "$LOGIN_QUERY")

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Login failed"
    echo "$LOGIN_RESPONSE" | jq .
    exit 1
fi

echo "✅ Login successful"
echo "Token: ${ACCESS_TOKEN:0:50}..."
echo ""

# Step 2: Query schema for getProjects
echo "Step 2: Querying schema for getProjects..."
echo ""

SCHEMA_QUERY='{"query":"query IntrospectionQuery { __type(name: \"Query\") { name fields { name description type { name kind ofType { name kind ofType { name kind } } } args { name description type { name kind ofType { name } } } } } }"}'

echo "Fetching Query type schema..."
SCHEMA_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$SCHEMA_QUERY")

echo ""
echo "=== Available Query Fields ==="
echo "$SCHEMA_RESPONSE" | jq -r '.data.__type.fields[] | select(.name | contains("project") or contains("Project")) | "\(.name): \(.type.name // .type.kind) - \(.description // "No description")"'

echo ""
echo "=== Full getProjects Field Details ==="
echo "$SCHEMA_RESPONSE" | jq '.data.__type.fields[] | select(.name == "getProjects")'

# Step 3: Query schema for Project type
echo ""
echo "Step 3: Querying Project type fields..."
echo ""

PROJECT_TYPE_QUERY='{"query":"query { __type(name: \"Project\") { name fields { name type { name kind ofType { name kind } } } } }"}'

PROJECT_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$PROJECT_TYPE_QUERY")

echo "=== Project Type Fields ==="
echo "$PROJECT_RESPONSE" | jq -r '.data.__type.fields[]? | "  - \(.name): \(.type.name // .type.kind)"'

# Step 4: Query VrGetProjectsInput type
echo ""
echo "Step 4: Querying VrGetProjectsInput type..."
echo ""

INPUT_TYPE_QUERY='{"query":"query { __type(name: \"VrGetProjectsInput\") { name inputFields { name description type { name kind ofType { name } } defaultValue } } }"}'

INPUT_RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-VRon-Platform: merchants" \
  -d "$INPUT_TYPE_QUERY")

echo "=== VrGetProjectsInput Fields ==="
echo "$INPUT_RESPONSE" | jq '.data.__type'

echo ""
echo "==================================="
echo "Schema introspection complete!"
echo "==================================="
