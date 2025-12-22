# API Contracts: Product Search and Filtering

**Feature**: 005-product-search | **Date**: 2024-12-22 | **Phase**: Design

## Overview

This document defines the GraphQL API contracts for product search and filtering. All queries use the existing `VRonGetProducts` query with filter parameters. No backend changes are required.

---

## VRonGetProducts Query

### Base Query Structure

**Location**: `lib/features/products/services/product_service.dart` (lines 42-157)

**GraphQL Schema**:

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
      categoryId
      tracksInventory
      variantsCount
    }
    pagination {
      pageCount
    }
  }
}
```

### Input Types

**VRonGetProductsInput**:

```graphql
input VRonGetProductsInput {
  filter: VRonGetProductsFilterInput
  pagination: PaginationInput
}
```

**VRonGetProductsFilterInput**:

```graphql
input VRonGetProductsFilterInput {
  search: String              # Case-insensitive partial title match
  status: [String]            # Product status: ["DRAFT"], ["ACTIVE"], or null (all)
  categoryIds: [String]       # Category IDs to filter by
  tracksInventory: Boolean    # Filter by inventory tracking status
}
```

**PaginationInput**:

```graphql
input PaginationInput {
  pageIndex: Int!    # 0-based page number
  pageSize: Int!     # Items per page
}
```

**Language** (enum):

```graphql
enum Language {
  EN
  DE
  # ... other languages
}
```

---

## Query Examples

### Example 1: No Filters (Get All Products)

**Use Case**: Initial load, show all products

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {},
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [
        {
          "id": "6752c5e3f26a1c001234abcd",
          "title": {
            "text": "Vintage Steam Punk Goggles"
          },
          "thumbnail": "https://...",
          "status": "ACTIVE",
          "categoryId": "cat123",
          "tracksInventory": true,
          "variantsCount": 3
        },
        // ... more products
      ],
      "pagination": {
        "pageCount": 5
      }
    }
  }
}
```

---

### Example 2: Search by Title

**Use Case**: User types "Steam Punk" in search field

**Dart Code**:

```dart
final result = await productService.searchProducts('Steam Punk');
// OR
final result = await productService.fetchProducts(
  search: 'Steam Punk',
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "search": "Steam Punk"
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Search Behavior**:
- Case-insensitive: "steam punk" matches "Steam Punk Goggles"
- Partial match: "Steam" matches "Steam Punk Goggles"
- Matches any position: "Punk" matches "Steam Punk Goggles"
- No regex or wildcards needed (backend handles matching)

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [
        {
          "id": "6752c5e3f26a1c001234abcd",
          "title": {
            "text": "Vintage Steam Punk Goggles"
          },
          "thumbnail": "https://...",
          "status": "ACTIVE",
          "categoryId": "cat123",
          "tracksInventory": true,
          "variantsCount": 3
        },
        {
          "id": "6752c5e3f26a1c001234abce",
          "title": {
            "text": "Steam Punk Gear Necklace"
          },
          "thumbnail": "https://...",
          "status": "DRAFT",
          "categoryId": "cat456",
          "tracksInventory": false,
          "variantsCount": 1
        }
      ],
      "pagination": {
        "pageCount": 1
      }
    }
  }
}
```

---

### Example 3: Filter by Status (Draft Only)

**Use Case**: User selects "Draft" from status filter

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  status: ['DRAFT'],
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "status": ["DRAFT"]
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [
        {
          "id": "6752c5e3f26a1c001234abce",
          "title": {
            "text": "Steam Punk Gear Necklace"
          },
          "thumbnail": "https://...",
          "status": "DRAFT",
          "categoryId": "cat456",
          "tracksInventory": false,
          "variantsCount": 1
        }
      ],
      "pagination": {
        "pageCount": 1
      }
    }
  }
}
```

**Note**: To get ACTIVE products, use `status: ['ACTIVE']`. To get all products, omit the status parameter or pass `null`.

---

### Example 4: Filter by Category

**Use Case**: User selects a category from dropdown

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  categoryIds: ['cat123'],
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "categoryIds": ["cat123"]
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [
        {
          "id": "6752c5e3f26a1c001234abcd",
          "title": {
            "text": "Vintage Steam Punk Goggles"
          },
          "thumbnail": "https://...",
          "status": "ACTIVE",
          "categoryId": "cat123",
          "tracksInventory": true,
          "variantsCount": 3
        }
      ],
      "pagination": {
        "pageCount": 1
      }
    }
  }
}
```

---

### Example 5: Combined Filters (Search + Status + Category)

**Use Case**: User types "Steam" AND selects "Active" status AND selects category "cat123"

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  search: 'Steam',
  status: ['ACTIVE'],
  categoryIds: ['cat123'],
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "search": "Steam",
      "status": ["ACTIVE"],
      "categoryIds": ["cat123"]
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Filter Logic**: AND (all conditions must match)
- Title contains "Steam" (case-insensitive)
- AND status is "ACTIVE"
- AND categoryId is "cat123"

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [
        {
          "id": "6752c5e3f26a1c001234abcd",
          "title": {
            "text": "Vintage Steam Punk Goggles"
          },
          "thumbnail": "https://...",
          "status": "ACTIVE",
          "categoryId": "cat123",
          "tracksInventory": true,
          "variantsCount": 3
        }
      ],
      "pagination": {
        "pageCount": 1
      }
    }
  }
}
```

---

### Example 6: No Results

**Use Case**: Search query or filter combination has no matches

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  search: 'NonexistentProduct',
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "search": "NonexistentProduct"
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Expected Response**:

```json
{
  "data": {
    "VRonGetProducts": {
      "products": [],
      "pagination": {
        "pageCount": 0
      }
    }
  }
}
```

**UI Handling**: Show empty state message with "Clear search" button

---

### Example 7: Filter by Inventory Tracking

**Use Case**: User wants to see only products that track inventory (optional filter)

**Dart Code**:

```dart
final result = await productService.fetchProducts(
  tracksInventory: true,
  pageIndex: 0,
  pageSize: 20,
);
```

**GraphQL Variables**:

```json
{
  "input": {
    "filter": {
      "tracksInventory": true
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Note**: This filter is not in the initial UI spec but is supported by the backend. Can be added in future iterations.

---

## Error Responses

### Network Error

**Scenario**: No internet connection or server unreachable

**Dart Exception**:

```dart
try {
  final result = await productService.searchProducts('Steam');
} on SocketException catch (e) {
  // Handle network error
  print('Network error: ${e.message}');
}
```

**UI Handling**: Show error state with retry button

**Error Message Example**: "Network error. Please check your connection."

---

### GraphQL Error

**Scenario**: Invalid query structure or server error

**Response**:

```json
{
  "errors": [
    {
      "message": "Invalid filter parameter",
      "locations": [{"line": 1, "column": 20}],
      "path": ["VRonGetProducts"]
    }
  ]
}
```

**Dart Exception**:

```dart
try {
  final result = await productService.searchProducts('Steam');
} on GraphQLException catch (e) {
  // Handle GraphQL error
  print('GraphQL error: ${e.message}');
}
```

**UI Handling**: Show error state with generic message

**Error Message Example**: "Failed to load products. Please try again."

---

### Authentication Error

**Scenario**: Invalid or expired access token

**Response**:

```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "extensions": {
        "code": "UNAUTHENTICATED"
      }
    }
  ]
}
```

**Dart Handling**:

```dart
try {
  final result = await productService.searchProducts('Steam');
} on GraphQLException catch (e) {
  if (e.message.contains('Unauthorized')) {
    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }
}
```

---

## Response Time and Performance

**Expected Response Times**:
- No filters: 200-500ms (depends on total product count)
- Search query: 300-600ms (backend performs database search)
- Multiple filters: 300-600ms (AND logic, efficient indexing)

**Pagination**:
- Default page size: 20 items
- Recommended range: 10-50 items per page
- Large page sizes (100+) may increase response time

**Caching**:
- No client-side caching implemented (session-only state)
- Backend may cache results (implementation detail)
- Each search triggers new API call (with debouncing)

---

## Testing Queries

### Test Script

**Location**: `test_searchproduct.sh`

**Usage**:

```bash
# Test basic query (all products)
./test_searchproduct.sh

# Test search query
# Modify script to include search parameter:
"filter": {"search": "Steam"}
```

**Expected Behavior**:
- Login succeeds (accessToken returned)
- Authorization header created (Base64 encoded)
- VRonGetProducts query returns product list
- Products have all required fields (id, title, status, etc.)

---

## Integration with ProductService

### Existing Methods

**ProductService** (`lib/features/products/services/product_service.dart`):

```dart
// Main method - supports all filter parameters
Future<List<Product>> fetchProducts({
  List<String>? categoryIds,
  String? search,
  List<String>? status,
  bool? tracksInventory,
  int pageIndex = 0,
  int pageSize = 20,
})

// Convenience method - search by title
Future<List<Product>> searchProducts(String query)

// Convenience method - get active products only
Future<List<Product>> fetchActiveProducts()
```

### Method Selection Guide

**Use `fetchProducts()`** when:
- Applying multiple filters (search + status + category)
- Need pagination control
- Need access to all filter parameters

**Use `searchProducts()`** when:
- Only searching by title (no other filters)
- Quick search implementation
- Default pagination is acceptable

**Use `fetchActiveProducts()`** when:
- Only need active products (no search, no other filters)
- Product selection screens

---

## Data Mapping

### GraphQL Response → Dart Model

**GraphQL Product**:
```json
{
  "id": "6752c5e3f26a1c001234abcd",
  "title": { "text": "Steam Punk Goggles" },
  "thumbnail": "https://...",
  "status": "ACTIVE",
  "categoryId": "cat123",
  "tracksInventory": true,
  "variantsCount": 3
}
```

**Dart Product Model**:
```dart
Product(
  id: "6752c5e3f26a1c001234abcd",
  title: MultiLingualText(translations: {"EN": "Steam Punk Goggles"}),
  thumbnail: "https://...",
  status: ProductStatus.ACTIVE,
  categoryId: "cat123",
  tracksInventory: true,
  variantsCount: 3,
)
```

**Mapping Code**: Handled by ProductService (lines 115-150)

---

## Future Enhancements (Not Implemented)

### Tags Filtering (Deferred - P3)

**Why Deferred**: Product model doesn't expose tags in VRonGetProducts response. Would require:
- Backend changes to include tags field
- OR: Expensive ProductDetail query for each product

**Potential Future Query**:

```json
{
  "input": {
    "filter": {
      "tags": ["vintage", "steampunk"]
    },
    "pagination": {
      "pageIndex": 0,
      "pageSize": 20
    }
  },
  "lang": "EN"
}
```

**Decision**: Focus on P1 (search) and P2 (status) which are fully supported. Tags can be added in future iteration after backend support.

---

## References

- **ProductService Implementation**: `lib/features/products/services/product_service.dart` (lines 42-157)
- **GraphQL Documentation**: `Requirements/GraphqlProducts.md`
- **Test Script**: `test_searchproduct.sh`
- **Research Findings**: `specs/005-product-search/research.md` (Section 1: GraphQL Query Capabilities)
- **Data Models**: `specs/005-product-search/data-model.md`
