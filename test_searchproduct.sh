#!/bin/bash

# This script tests the product search/detail functionality of the vron.one GraphQL API
# It first logs in to get an access token, then queries for products

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# RECOMMENDED: Run test_login.sh first to save authentication token:
#   ./test_login.sh
#   ./test_searchproduct.sh [product_id]
#
# Alternative: This script can login on its own:
#   ./test_searchproduct.sh [product_id]
#   - If product_id is not provided, it will list all products first
#   - If product_id is provided, it will fetch that specific product's details
#
# The script will automatically use saved token from test_login.sh if available and recent

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"
LANGUAGE="EN"
CURL_TIMEOUT=30

# Parse command line arguments
EMAIL="${1:-$DEFAULT_EMAIL}"
PASSWORD="${2:-$DEFAULT_PASSWORD}"

# If first arg looks like a product ID (hex string), use it as product ID
if [[ "$1" =~ ^[0-9a-f]{24}$ ]]; then
  PRODUCT_ID="$1"
  EMAIL="$DEFAULT_EMAIL"
  PASSWORD="$DEFAULT_PASSWORD"
elif [ -n "$3" ]; then
  # If 3 args provided: email password product_id
  PRODUCT_ID="$3"
else
  PRODUCT_ID=""
fi

echo "=== VRon Product Query Test ==="
echo ""

# Check for saved token from test_login.sh
TOKEN_FILE=".auth_token"
AUTH_CODE_B64=""

if [ -f "$TOKEN_FILE" ]; then
  # Check if token file is less than 1 hour old
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    TOKEN_AGE=$(($(date +%s) - $(stat -f %m "$TOKEN_FILE")))
  else
    # Linux
    TOKEN_AGE=$(($(date +%s) - $(stat -c %Y "$TOKEN_FILE")))
  fi

  if [ $TOKEN_AGE -lt 3600 ]; then
    AUTH_CODE_B64=$(cat "$TOKEN_FILE")
    echo "✅ Using saved authentication token from test_login.sh (${TOKEN_AGE}s old)"
    echo ""
  else
    echo "⚠️ Saved token is too old (${TOKEN_AGE}s), logging in again..."
    echo ""
  fi
fi

# Step 1: Login to get access token (if needed)
if [ -z "$AUTH_CODE_B64" ]; then
  echo "Step 1: Logging in as $EMAIL..."
  LOGIN_PAYLOAD=$(cat <<EOF
{
  "query": "mutation SignIn(\\$input: SignInInput!) { signIn(input: \\$input) { accessToken } }",
  "variables": {
    "input": {
      "email": "$EMAIL",
      "password": "$PASSWORD"
    }
  }
}
EOF
)

echo "  Sending request to $GRAPHQL_ENDPOINT..."
LOGIN_RESPONSE=$(curl -s \
  --max-time $CURL_TIMEOUT \
  -X POST \
  -H "Content-Type: application/json" \
  -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
  --data "$LOGIN_PAYLOAD" \
  "$GRAPHQL_ENDPOINT" 2>&1)

CURL_EXIT_CODE=$?
if [ $CURL_EXIT_CODE -ne 0 ]; then
  echo "❌ Error: curl command failed with code $CURL_EXIT_CODE"
  echo "This might indicate a network issue or timeout."
  exit 1
fi

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.data.signIn.accessToken // empty')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Error: Failed to get accessToken"
  echo "Response: $LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Successfully logged in"
echo ""

  # Step 2: Create Authorization header
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

  # Base64 encode (handle macOS vs Linux differences)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)
  else
    # Linux
    AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64 -w 0)
  fi
fi

# Step 3: Query products
if [ -z "$PRODUCT_ID" ]; then
  # List all products
  echo "Step 2: Fetching all products..."
  QUERY_PAYLOAD=$(cat <<'EOF'
{
  "query": "query GetProducts($input: VRonGetProductsInput!, $lang: Language!) { VRonGetProducts(input: $input) { products { id title { text(lang: $lang) } thumbnail status categoryId tracksInventory variantsCount } pagination { pageCount } } }",
  "variables": {
    "input": {
      "filter": {},
      "pagination": {
        "pageIndex": 0,
        "pageSize": 20
      }
    },
    "lang": "EN"
  }
}
EOF
)

  echo "  Fetching products..."
  PRODUCTS_RESPONSE=$(curl -s \
    --max-time $CURL_TIMEOUT \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
    -H "Authorization: Bearer $AUTH_CODE_B64" \
    --data "$QUERY_PAYLOAD" \
    "$GRAPHQL_ENDPOINT")

  # Check for errors
  ERRORS=$(echo "$PRODUCTS_RESPONSE" | jq -r '.errors // empty')
  if [ ! -z "$ERRORS" ]; then
    echo "❌ GraphQL Errors:"
    echo "$PRODUCTS_RESPONSE" | jq '.errors'
    exit 1
  fi

  echo "✅ Products fetched successfully"
  echo ""
  echo "Products List:"
  echo "$PRODUCTS_RESPONSE" | jq -r '.data.VRonGetProducts.products[] | "  - \(.title.text) (\(.id)) - \(.status)"'
  echo ""
  echo "Total products: $(echo "$PRODUCTS_RESPONSE" | jq '.data.VRonGetProducts.products | length')"
  echo ""
  echo "💡 Tip: Run './test_searchproduct.sh <product_id>' to get details for a specific product"

else
  # Get specific product details
  echo "Step 2: Fetching product details for ID: $PRODUCT_ID..."
  QUERY_PAYLOAD=$(cat <<EOF
{
  "query": "query GetProduct(\\\$input: VRonGetProductInput!, \\\$lang: Language!) { VRonGetProduct(input: \\\$input) { title { text(lang: \\\$lang) } description { text(lang: \\\$lang) } status tags mediaFiles { id url filename } variants { id sku price } } }",
  "variables": {
    "input": {
      "id": "$PRODUCT_ID"
    },
    "lang": "$LANGUAGE"
  }
}
EOF
)

  echo "  Fetching product details..."
  PRODUCT_RESPONSE=$(curl -s \
    --max-time $CURL_TIMEOUT \
    -X POST \
    -H "Content-Type: application/json" \
    -H "X-VRon-Platform: $X_VRON_PLATFORM_HEADER" \
    -H "Authorization: Bearer $AUTH_CODE_B64" \
    --data "$QUERY_PAYLOAD" \
    "$GRAPHQL_ENDPOINT")

  # Check for errors
  ERRORS=$(echo "$PRODUCT_RESPONSE" | jq -r '.errors // empty')
  if [ ! -z "$ERRORS" ]; then
    echo "❌ GraphQL Errors:"
    echo "$PRODUCT_RESPONSE" | jq '.errors'
    echo ""
    echo "Full response:"
    echo "$PRODUCT_RESPONSE" | jq '.'
    exit 1
  fi

  # Check if product exists
  PRODUCT_DATA=$(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct // empty')
  if [ -z "$PRODUCT_DATA" ]; then
    echo "❌ Error: Product not found or no data returned"
    echo "Full response:"
    echo "$PRODUCT_RESPONSE" | jq '.'
    exit 1
  fi

  echo "✅ Product fetched successfully"
  echo ""
  echo "=== Product Details ==="
  echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct'
  echo ""
  echo "=== Summary ==="
  echo "Title: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.title.text')"
  echo "Status: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.status')"
  echo "Tags: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.tags | join(", ")')"
  echo "Media Files: $(echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct.mediaFiles | length')"
  echo "Variants: $(echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct.variants | length')"
fi

echo ""
echo "=== Test Complete ==="
exit 0
