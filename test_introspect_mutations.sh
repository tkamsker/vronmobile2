#!/bin/bash

# Script to introspect available mutations related to projects

GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"

EMAIL="${1:-$DEFAULT_EMAIL}"
PASSWORD="${2:-$DEFAULT_PASSWORD}"

echo "=== Authenticating ==="

LOGIN_PAYLOAD=$(cat <<EOF
{
  "query": "mutation SignIn(\$input: SignInInput!) { signIn(input: \$input) { accessToken } }",
  "variables": {
    "input": {
      "email": "$EMAIL",
      "password": "$PASSWORD"
    }
  }
}
EOF
)

LOGIN_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$LOGIN_PAYLOAD" \
  "$GRAPHQL_ENDPOINT")

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to authenticate"
  exit 1
fi

echo "✅ Authenticated"

AUTH_CODE_JSON=$(cat <<EOF
{
    "MERCHANT": {
        "accessToken": "$ACCESS_TOKEN"
    },
    "activeRoles": {
        "merchants":"MERCHANT"
    }
}
EOF
)

AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)

echo ""
echo "=== Introspecting Project/World Related Mutations ==="

INTROSPECTION_QUERY=$(cat <<EOF
{
  "query": "{ __schema { mutationType { fields { name description args { name type { name kind ofType { name kind } } } type { name kind ofType { name kind } } } } } }"
}
EOF
)

INTROSPECTION_RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  -H "Authorization: Bearer $AUTH_CODE_B64" \
  --data "$INTROSPECTION_QUERY" \
  "$GRAPHQL_ENDPOINT")

echo "All mutations containing 'Project' or 'World':"
echo "$INTROSPECTION_RESPONSE" | jq '.data.__schema.mutationType.fields[] | select(.name | test("Project|World"; "i")) | {name, description, args: [.args[] | {name, type: .type.name}], returnType: .type.name}'

echo ""
echo "=== VRonCreateProject Details ==="
echo "$INTROSPECTION_RESPONSE" | jq '.data.__schema.mutationType.fields[] | select(.name == "VRonCreateProject")'
