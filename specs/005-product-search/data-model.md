# Data Model: Product Search and Filtering

**Feature**: 005-product-search | **Date**: 2024-12-22 | **Phase**: Design

## Overview

This document defines the data models for product search and filtering functionality. These models manage filter state, search queries, and result presentation. All models are session-only (no persistence across app restarts).

## Core Models

### ProductFilter

**Purpose**: Encapsulates all active filter criteria for product searches. Manages filter state lifecycle and provides validation.

**Location**: `lib/features/products/models/product_filter.dart`

**Structure**:

```dart
class ProductFilter {
  final String? searchQuery;           // Search text for title matching
  final ProductStatus? selectedStatus; // Draft/Active/null (All)
  final String? selectedCategoryId;    // Category filter ID
  final List<String> selectedTags;     // Tag filters (P3 - future)

  const ProductFilter({
    this.searchQuery,
    this.selectedStatus,
    this.selectedCategoryId,
    this.selectedTags = const [],
  });
}
```

**Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `searchQuery` | `String?` | No | `null` | Search text for case-insensitive partial title matching. Null or empty means no search filter. |
| `selectedStatus` | `ProductStatus?` | No | `null` | Product status filter. Null means "All" (no status filter). Values: `ProductStatus.DRAFT`, `ProductStatus.ACTIVE` |
| `selectedCategoryId` | `String?` | No | `null` | Category ID to filter by. Null means "All Categories". Must match a valid category ID. |
| `selectedTags` | `List<String>` | No | `[]` | List of tag strings to filter by (P3 priority - deferred). Empty list means no tag filter. |

**Methods**:

```dart
// Check if any filters are active
bool get isActive {
  return searchQuery?.isNotEmpty == true ||
         selectedStatus != null ||
         selectedCategoryId != null ||
         selectedTags.isNotEmpty;
}

// Get count of active filters (for badge display)
int get activeFilterCount {
  int count = 0;
  if (searchQuery?.isNotEmpty == true) count++;
  if (selectedStatus != null) count++;
  if (selectedCategoryId != null) count++;
  if (selectedTags.isNotEmpty) count += selectedTags.length;
  return count;
}

// Clear all filters
ProductFilter clear() {
  return const ProductFilter();
}

// Create a copy with updated fields
ProductFilter copyWith({
  String? searchQuery,
  ProductStatus? selectedStatus,
  String? selectedCategoryId,
  List<String>? selectedTags,
}) {
  return ProductFilter(
    searchQuery: searchQuery ?? this.searchQuery,
    selectedStatus: selectedStatus ?? this.selectedStatus,
    selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    selectedTags: selectedTags ?? this.selectedTags,
  );
}

// Check equality (for testing and state comparison)
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  return other is ProductFilter &&
         other.searchQuery == searchQuery &&
         other.selectedStatus == selectedStatus &&
         other.selectedCategoryId == selectedCategoryId &&
         listEquals(other.selectedTags, selectedTags);
}

@override
int get hashCode {
  return Object.hash(
    searchQuery,
    selectedStatus,
    selectedCategoryId,
    Object.hashAll(selectedTags),
  );
}
```

**Validation Rules**:

- `searchQuery`: No length limit enforced (backend handles sanitization)
- `selectedStatus`: Must be null or valid ProductStatus enum value
- `selectedCategoryId`: No format validation (backend validates existence)
- `selectedTags`: Empty list allowed, duplicates should be removed

**Usage Example**:

```dart
// Initial state - no filters
ProductFilter filter = const ProductFilter();

// User types search query
filter = filter.copyWith(searchQuery: 'Steam Punk');

// User selects Draft status
filter = filter.copyWith(selectedStatus: ProductStatus.DRAFT);

// Check if filters are active
if (filter.isActive) {
  // Show "Clear all" button
  Text('Filters (${filter.activeFilterCount})');
}

// Clear all filters
filter = filter.clear();
```

---

### ProductSearchResult

**Purpose**: Wraps product search results with metadata about the query and applied filters. Provides context for empty state handling and result display.

**Location**: `lib/features/products/models/product_search_result.dart`

**Structure**:

```dart
class ProductSearchResult {
  final List<Product> products;         // Filtered product list
  final int totalCount;                 // Total matching products
  final ProductFilter appliedFilter;    // Filters used for this result
  final bool isLoading;                 // Loading state indicator
  final String? errorMessage;           // Error message if query failed

  const ProductSearchResult({
    required this.products,
    required this.totalCount,
    required this.appliedFilter,
    this.isLoading = false,
    this.errorMessage,
  });
}
```

**Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `products` | `List<Product>` | Yes | - | List of products matching the filter criteria. Empty list if no results. |
| `totalCount` | `int` | Yes | - | Total count of products matching filters (for pagination and "X of Y" display). |
| `appliedFilter` | `ProductFilter` | Yes | - | The filter criteria that produced this result. Used for empty state messaging. |
| `isLoading` | `bool` | No | `false` | Indicates if search is in progress (for loading indicator). |
| `errorMessage` | `String?` | No | `null` | Error message if search failed. Null means no error. |

**Computed Properties**:

```dart
// Check if result set is empty
bool get isEmpty => products.isEmpty;

// Check if this is an initial state (no search performed)
bool get isInitialState =>
    !appliedFilter.isActive && !isLoading && errorMessage == null;

// Check if this is a successful search with no results
bool get hasNoResults =>
    isEmpty && appliedFilter.isActive && !isLoading && errorMessage == null;

// Check if error state
bool get hasError => errorMessage != null;
```

**Factory Constructors**:

```dart
// Initial empty state (no search yet)
factory ProductSearchResult.initial() {
  return const ProductSearchResult(
    products: [],
    totalCount: 0,
    appliedFilter: ProductFilter(),
    isLoading: false,
  );
}

// Loading state (search in progress)
factory ProductSearchResult.loading(ProductFilter filter) {
  return ProductSearchResult(
    products: [],
    totalCount: 0,
    appliedFilter: filter,
    isLoading: true,
  );
}

// Error state
factory ProductSearchResult.error(ProductFilter filter, String message) {
  return ProductSearchResult(
    products: [],
    totalCount: 0,
    appliedFilter: filter,
    errorMessage: message,
  );
}

// Success state
factory ProductSearchResult.success({
  required List<Product> products,
  required int totalCount,
  required ProductFilter appliedFilter,
}) {
  return ProductSearchResult(
    products: products,
    totalCount: totalCount,
    appliedFilter: appliedFilter,
  );
}
```

**Usage Example**:

```dart
// Initial state
ProductSearchResult result = ProductSearchResult.initial();

// User types search query
ProductFilter filter = ProductFilter(searchQuery: 'Steam');
result = ProductSearchResult.loading(filter);

// API call succeeds
List<Product> matchingProducts = await productService.searchProducts('Steam');
result = ProductSearchResult.success(
  products: matchingProducts,
  totalCount: matchingProducts.length,
  appliedFilter: filter,
);

// Display results
if (result.hasNoResults) {
  return Text('No products found for "${result.appliedFilter.searchQuery}"');
} else if (result.hasError) {
  return Text('Error: ${result.errorMessage}');
} else {
  return Text('Showing ${result.products.length} of ${result.totalCount} products');
}
```

---

## Existing Models (No Changes)

### Product

**Location**: `lib/features/products/models/product.dart`

**Used For**: Representing individual products in search results

**Relevant Properties for Search**:
- `id`: Product identifier
- `title`: MultiLingualText (used for search matching)
- `status`: ProductStatus enum (DRAFT/ACTIVE)
- `categoryId`: String? (used for category filtering)
- `thumbnail`: String? (product image)
- `tracksInventory`: bool (used for inventory filter)
- `variantsCount`: int

**Notes**: No modifications needed. Product model already has all fields required for search/filter functionality.

---

### ProductStatus

**Location**: `lib/features/products/models/product.dart` (enum)

**Values**:
```dart
enum ProductStatus {
  DRAFT,
  ACTIVE,
  // Other statuses may exist but not used in filtering
}
```

**Used For**: Status filter dropdown options

---

## Model Relationships

```text
ProductsListScreen
       |
       | manages state
       v
ProductFilter ──────────────> ProductService.fetchProducts()
       |                              |
       |                              | returns
       |                              v
       └──────────────────> ProductSearchResult
                                     |
                                     | contains
                                     v
                              List<Product>
```

**Flow**:
1. User interacts with search/filter UI in ProductsListScreen
2. ProductsListScreen updates ProductFilter state
3. ProductFilter is passed to ProductService.fetchProducts()
4. ProductService returns List<Product>
5. ProductsListScreen wraps result in ProductSearchResult for display

---

## State Management

**Approach**: Simple StatefulWidget state management (no Provider)

**State Location**: `_ProductsListScreenState` in `products_list_screen.dart`

**State Variables**:

```dart
class _ProductsListScreenState extends State<ProductsListScreen> {
  // Filter state
  ProductFilter _currentFilter = const ProductFilter();

  // Search result state
  ProductSearchResult _searchResult = ProductSearchResult.initial();

  // Debouncing timer
  Timer? _debounceTimer;

  // ... existing state variables
}
```

**State Updates**:

```dart
// Update filter and trigger search
void _updateFilter(ProductFilter newFilter) {
  setState(() {
    _currentFilter = newFilter;
    _searchResult = ProductSearchResult.loading(_currentFilter);
  });

  // Debounce search execution
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    _executeSearch(_currentFilter);
  });
}

// Execute search with current filter
Future<void> _executeSearch(ProductFilter filter) async {
  try {
    final products = await _productService.fetchProducts(
      search: filter.searchQuery,
      status: filter.selectedStatus != null
          ? [filter.selectedStatus!.name]
          : null,
      categoryIds: filter.selectedCategoryId != null
          ? [filter.selectedCategoryId!]
          : null,
    );

    setState(() {
      _searchResult = ProductSearchResult.success(
        products: products,
        totalCount: products.length,
        appliedFilter: filter,
      );
    });
  } catch (e) {
    setState(() {
      _searchResult = ProductSearchResult.error(
        filter,
        'Failed to load products: ${e.toString()}',
      );
    });
  }
}
```

---

## Validation and Error Handling

### Input Validation

**Search Query**:
- No client-side length limit (backend handles sanitization)
- Special characters allowed (backend handles escaping)
- Empty/null treated as "no search filter"

**Status Filter**:
- Must be null or valid ProductStatus enum value
- Invalid values rejected at compile time (type safety)

**Category Filter**:
- No client-side validation (backend validates category existence)
- Non-existent categories return empty results (not an error)

### Error States

**Network Errors**:
```dart
ProductSearchResult.error(
  filter,
  'Network error. Please check your connection.',
)
```

**Empty Results**:
```dart
if (result.hasNoResults) {
  // Not an error - show helpful empty state
  return EmptyStateWidget(
    message: 'No products found',
    action: () => _updateFilter(ProductFilter()),
  );
}
```

**Invalid Filter Combinations**:
- All filter combinations are valid (AND logic)
- Empty results are not errors, just empty state

---

## Testing Considerations

### Unit Tests (product_filter_test.dart)

```dart
test('isActive returns true when search query is set', () {
  final filter = ProductFilter(searchQuery: 'test');
  expect(filter.isActive, true);
});

test('activeFilterCount returns correct count', () {
  final filter = ProductFilter(
    searchQuery: 'test',
    selectedStatus: ProductStatus.DRAFT,
  );
  expect(filter.activeFilterCount, 2);
});

test('clear returns empty filter', () {
  final filter = ProductFilter(searchQuery: 'test');
  final cleared = filter.clear();
  expect(cleared.isActive, false);
});

test('copyWith updates only specified fields', () {
  final filter = ProductFilter(searchQuery: 'test');
  final updated = filter.copyWith(selectedStatus: ProductStatus.ACTIVE);
  expect(updated.searchQuery, 'test');
  expect(updated.selectedStatus, ProductStatus.ACTIVE);
});
```

### Unit Tests (product_search_result_test.dart)

```dart
test('isEmpty returns true when products list is empty', () {
  final result = ProductSearchResult.initial();
  expect(result.isEmpty, true);
});

test('hasNoResults returns true for active filter with no results', () {
  final filter = ProductFilter(searchQuery: 'nonexistent');
  final result = ProductSearchResult.success(
    products: [],
    totalCount: 0,
    appliedFilter: filter,
  );
  expect(result.hasNoResults, true);
});

test('loading factory creates loading state', () {
  final filter = ProductFilter(searchQuery: 'test');
  final result = ProductSearchResult.loading(filter);
  expect(result.isLoading, true);
  expect(result.products, isEmpty);
});
```

---

## Performance Considerations

**Memory**:
- ProductFilter is lightweight (4 nullable/small fields)
- ProductSearchResult holds List<Product> reference (not copy)
- No caching of previous results (session-only state)

**Rebuild Optimization**:
- ProductFilter implements equality operators for widget rebuild optimization
- Use `const` constructors where possible
- Debouncing prevents excessive state updates

**Search Performance**:
- All filtering done server-side (no client-side processing)
- Results are paginated (20 items default, from ProductService)
- No local caching (simplifies state management)

---

## Future Enhancements (Out of Scope)

- **Tags Filtering**: Requires backend changes to include tags in VRonGetProducts response
- **Search History**: Would require SharedPreferences persistence
- **Saved Filters**: Would require backend storage and retrieval
- **Advanced Filters**: Price range, inventory levels, etc.
- **Sort Options**: Sort by name, date, price (separate feature)

---

## References

- **Existing Models**: `lib/features/products/models/product.dart`
- **Service Layer**: `lib/features/products/services/product_service.dart`
- **GraphQL Query**: VRonGetProducts (see `contracts/graphql-queries.md`)
- **Research**: `specs/005-product-search/research.md` (State Management section)
