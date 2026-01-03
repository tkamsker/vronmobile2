# GraphQL API for Products

This document outlines the GraphQL API endpoints for managing products, including listing, searching, creating, editing, and adding media.

**Authentication:** All requests must include an `Authorization` header with a valid bearer token.

```shell
TOKEN="your_auth_token_here"
API_URL="your_graphql_api_url_here"
```

---

## 1. List/Search Products

Use the `VRonGetProducts` query to list and search for products.

**Query:**
```graphql
query GetProducts($input: VRonGetProductsInput!, $lang: Language!) {
  VRonGetProducts(input: $input) {
    products {
      id
      title {
        text(lang: $lang)
      }
      thumbnail
      status
      category {
        text(lang: $lang)
      }
      tracksInventory
      variantsCount
    }
    pagination {
      pageCount
    }
  }
}
```

**Input (`VRonGetProductsInput`):**
*   `filter` (`VRonGetProductsFilterInput`):
    *   `categoryIds` (`[String]`): Filter by category IDs.
    *   `search` (`String`): Search term for product titles, etc.
    *   `status` (`[ProductStatus]`): `ACTIVE` or `DRAFT`.
    *   `tracksInventory` (`Boolean`): Filter by inventory tracking status.
*   `pagination` (`PaginationInput`):
    *   `pageIndex` (`Float`): The page number to retrieve.
    *   `pageSize` (`Float`): The number of items per page.

### Example: List all active products

```shell
curl -X POST -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d 
'{ 
  "query": "query GetProducts($input: VRonGetProductsInput!, $lang: Language!) { VRonGetProducts(input: $input) { products { id title { text(lang: $lang) } } } }",
  "variables": {
    "input": {
      "filter": {
        "status": ["ACTIVE"]
      },
      "pagination": {
        "pageIndex": 0,
        "pageSize": 10
      }
    },
    "lang": "EN"
  }
}' $API_URL
```

### Example: Search for products

```shell
curl -X POST -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d 
'{ 
  "query": "query GetProducts($input: VRonGetProductsInput!, $lang: Language!) { VRonGetProducts(input: $input) { products { id title { text(lang: $lang) } } } }",
  "variables": {
    "input": {
      "filter": {
        "search": "My Product"
      },
      "pagination": {
        "pageIndex": 0,
        "pageSize": 10
      }
    },
    "lang": "EN"
  }
}' $API_URL
```

---

## 2. Get a Single Product

Use the `VRonGetProduct` query to retrieve a single product by its ID.

**Query:**
```graphql
query GetProduct($input: VRonGetProductInput!, $lang: Language!) {
  VRonGetProduct(input: $input) {
    title { text(lang: $lang) }
    description { text(lang: $lang) }
    status
    tags
    mediaFiles { id, url, filename }
    variants { id, sku, price }
  }
}
```

**Input (`VRonGetProductInput`):**
*   `id` (`String`): The ID of the product to retrieve.

### Example: Get a product by ID

```shell
curl -X POST -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d 
'{ 
  "query": "query GetProduct($input: VRonGetProductInput!, $lang: Language!) { VRonGetProduct(input: $input) { title { text(lang: $lang) } } }",
  "variables": {
    "input": {
      "id": "your_product_id"
    },
    "lang": "EN"
  }
}' $API_URL
```

---

## 3. Create a Product

Use the `VRonCreateProduct` mutation to create a new product.

**Mutation:**
```graphql
mutation CreateProduct($input: VRonCreateProductInput!) {
  VRonCreateProduct(input: $input) {
    productId
  }
}
```

**Input (`VRonCreateProductInput`):**
*   `title` (`String`): Product title.
*   `description` (`String`): Product description.
*   `status` (`ProductStatus`): `ACTIVE` or `DRAFT`.
*   `tracksInventory` (`Boolean`): Whether to track inventory.
*   `variants` (`[VRonProductVariantInputWithOptions]`): List of product variants.
*   And other optional fields like `categoryId`, `tags`, `mediaFiles`, etc.

### Example: Create a new product

```shell
curl -X POST -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d 
'{ 
  "query": "mutation CreateProduct($input: VRonCreateProductInput!) { VRonCreateProduct(input: $input) { productId } }",
  "variables": {
    "input": {
      "title": "New Flutter Product",
      "description": "A product created for Flutter.",
      "status": "DRAFT",
      "tracksInventory": true,
      "variants": [
        {
          "price": 99.99,
          "sku": "FLUTTER-001",
          "inventoryPolicy": "DENY",
          "inventoryQuantity": 100
        }
      ]
    }
  }
}' $API_URL
```

---

## 4. Edit a Product

Use the `VRonUpdateProduct` mutation to update an existing product.

**Mutation:**
```graphql
mutation UpdateProduct($input: VRonUpdateProductInput!) {
  VRonUpdateProduct(input: $input)
}
```

**Input (`VRonUpdateProductInput`):**
*   `id` (`String!`): The ID of the product to update.
*   `title` (`String`): New product title.
*   Other fields from `VRonCreateProductInput` are also applicable.

### Example: Update a product's title

```shell
curl -X POST -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-d 
'{ 
  "query": "mutation UpdateProduct($input: VRonUpdateProductInput!) { VRonUpdateProduct(input: $input) }",
  "variables": {
    "input": {
      "id": "your_product_id",
      "title": "Updated Flutter Product Title"
    }
  }
}' $API_URL
```

---

## 5. Add Media to a Product

Adding media is a two-step process:
1.  Create the product (you can include media links).
2.  Upload media files using the `VRonUploadMediaFiles` mutation. This requires a multipart/form-data request.

**Mutation for Media Upload:**
```graphql
mutation UploadMediaFiles($input: VRonUploadMediaFilesInput!) {
  VRonUploadMediaFiles(input: $input)
}
```

**Input (`VRonUploadMediaFilesInput`):**
*   `productId` (`String!`): The ID of the product.
*   `files` (`[Upload!]!`): The files to upload.

### Example: Upload a media file

This example uses a `curl` command to simulate a multipart/form-data request.

```shell
curl -X POST $API_URL \
  -H "Authorization: Bearer $TOKEN" \
  -F operations='{ "query": "mutation UploadMediaFiles($input: VRonUploadMediaFilesInput!) { VRonUploadMediaFiles(input: $input) }", "variables": { "input": { "productId": "your_product_id", "files": [null] } } }' \
  -F map='{ "0": ["variables.input.files.0"] }' \
  -F 0=@/path/to/your/image.jpg
```

This is a standard GraphQL multipart request. The `operations` field contains the GraphQL query, and `map` links the file (`0`) to the `files` array in the variables.

```