#!/bin/bash

# This script tests the product search/detail functionality of the vron.one GraphQL API
# It first logs in to get an access token, then queries for products

# --- Prerequisites ---
# Ensure 'jq' is installed:
#   brew install jq
#
# --- Usage ---
# ./test_searchproduct.sh [product_id]
#   - If product_id is not provided, it will list all products first
#   - If product_id is provided, it will fetch that specific product's details

# --- Configuration ---
GRAPHQL_ENDPOINT="https://api.vron.stage.motorenflug.at/graphql"
DEFAULT_EMAIL="tkamsker@gmail.com"
DEFAULT_PASSWORD="Test123!"
X_VRON_PLATFORM_HEADER="merchants"
LANGUAGE="EN"

# Get product ID from command line or use empty for listing all
PRODUCT_ID="$1"

echo "=== VRon Product Query Test ==="
echo ""

# Step 1: Login to get access token
echo "Step 1: Logging in..."
LOGIN_PAYLOAD=$(cat <<EOF
{
  "query": "mutation SignIn(\\$input: SignInInput!) { signIn(input: \\$input) { accessToken } }",
  "variables": {
    "input": {
      "email": "$DEFAULT_EMAIL",
      "password": "$DEFAULT_PASSWORD"
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

AUTH_CODE_B64=$(echo -n "$AUTH_CODE_JSON" | base64)

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

  PRODUCTS_RESPONSE=$(curl -s \
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
  "query": "query GetProduct(\\\$input: VRonGetProductInput!, \\\$lang: Language!) { VRonGetProduct(input: \\\$input) { product { id title { text(lang: \\\$lang) } description { text(lang: \\\$lang) } thumbnail status categoryId tags tracksInventory mediaFiles { id url filename mime size } variants { id sku price compareAtPrice inventoryPolicy inventoryQuantity weight weightUnit } createdAt updatedAt } } }",
  "variables": {
    "input": {
      "id": "$PRODUCT_ID"
    },
    "lang": "$LANGUAGE"
  }
}
EOF
)

  PRODUCT_RESPONSE=$(curl -s \
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
  PRODUCT_DATA=$(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.product // empty')
  if [ -z "$PRODUCT_DATA" ]; then
    echo "❌ Error: Product not found or no data returned"
    echo "Full response:"
    echo "$PRODUCT_RESPONSE" | jq '.'
    exit 1
  fi

  echo "✅ Product fetched successfully"
  echo ""
  echo "=== Product Details ==="
  echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct.product'
  echo ""
  echo "=== Summary ==="
  echo "ID: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.product.id')"
  echo "Title: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.product.title.text')"
  echo "Status: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.product.status')"
  echo "Category ID: $(echo "$PRODUCT_RESPONSE" | jq -r '.data.VRonGetProduct.product.categoryId // "none"')"
  echo "Media Files: $(echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct.product.mediaFiles | length')"
  echo "Variants: $(echo "$PRODUCT_RESPONSE" | jq '.data.VRonGetProduct.product.variants | length')"
fi

echo ""
echo "=== Test Complete ==="
exit 0
