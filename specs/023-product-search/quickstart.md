# Quickstart Guide: Product Search and Filtering

**Feature**: 005-product-search | **Date**: 2024-12-22 | **Phase**: Design

## Overview

This guide provides step-by-step instructions for integrating product search and filtering into the VRon mobile app. It covers the essential code changes, testing approaches, and common integration scenarios.

**Target Audience**: Developers implementing the product search feature

**Prerequisites**:
- Familiarity with Flutter and Dart
- Understanding of StatefulWidget state management
- Basic knowledge of GraphQL and the VRon API
- Read `data-model.md` and `contracts/graphql-queries.md` first

---

## Quick Start

### 1. Create Data Models

**File**: `lib/features/products/models/product_filter.dart`

```dart
import 'package:flutter/foundation.dart';
import '../005-product-search/product.dart';

class ProductFilter {
  final String? searchQuery;
  final ProductStatus? selectedStatus;
  final String? selectedCategoryId;
  final List<String> selectedTags;

  const ProductFilter({
    this.searchQuery,
    this.selectedStatus,
    this.selectedCategoryId,
    this.selectedTags = const [],
  });

  bool get isActive =>
      searchQuery?.isNotEmpty == true ||
      selectedStatus != null ||
      selectedCategoryId != null ||
      selectedTags.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery?.isNotEmpty == true) count++;
    if (selectedStatus != null) count++;
    if (selectedCategoryId != null) count++;
    if (selectedTags.isNotEmpty) count += selectedTags.length;
    return count;
  }

  ProductFilter clear() => const ProductFilter();

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
  int get hashCode => Object.hash(
        searchQuery,
        selectedStatus,
        selectedCategoryId,
        Object.hashAll(selectedTags),
      );
}
```

**File**: `lib/features/products/models/product_search_result.dart`

```dart
import '../005-product-search/product.dart';
import '../005-product-search/product_filter.dart';

class ProductSearchResult {
  final List<Product> products;
  final int totalCount;
  final ProductFilter appliedFilter;
  final bool isLoading;
  final String? errorMessage;

  const ProductSearchResult({
    required this.products,
    required this.totalCount,
    required this.appliedFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => products.isEmpty;
  bool get isInitialState =>
      !appliedFilter.isActive && !isLoading && errorMessage == null;
  bool get hasNoResults =>
      isEmpty && appliedFilter.isActive && !isLoading && errorMessage == null;
  bool get hasError => errorMessage != null;

  factory ProductSearchResult.initial() {
    return const ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: ProductFilter(),
      isLoading: false,
    );
  }

  factory ProductSearchResult.loading(ProductFilter filter) {
    return ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: filter,
      isLoading: true,
    );
  }

  factory ProductSearchResult.error(ProductFilter filter, String message) {
    return ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: filter,
      errorMessage: message,
    );
  }

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
}
```

---

### 2. Wire Search Bar in ProductsListScreen

**File**: `lib/features/products/screens/products_list_screen.dart`

**Step 2.1**: Add state variables to `_ProductsListScreenState`:

```dart
class _ProductsListScreenState extends State<ProductsListScreen> {
  // ... existing variables

  // Search and filter state
  ProductFilter _currentFilter = const ProductFilter();
  ProductSearchResult _searchResult = ProductSearchResult.initial();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ... rest of class
}
```

**Step 2.2**: Replace the existing TODO search TextField (around line 282):

```dart
// BEFORE (line 282):
TextField(
  decoration: InputDecoration(
    hintText: 'Search products...',
    prefixIcon: const Icon(Icons.search),
  ),
  onChanged: (value) {
    // TODO: Implement search
  },
)

// AFTER:
TextField(
  decoration: InputDecoration(
    hintText: 'Search products by title',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: _currentFilter.searchQuery?.isNotEmpty == true
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          )
        : null,
  ),
  onChanged: _onSearchChanged,
)
```

**Step 2.3**: Add search handler methods:

```dart
void _onSearchChanged(String query) {
  // Cancel previous timer
  _debounceTimer?.cancel();

  // Update filter with new search query
  final newFilter = _currentFilter.copyWith(searchQuery: query);

  // Set loading state immediately
  setState(() {
    _currentFilter = newFilter;
    _searchResult = ProductSearchResult.loading(newFilter);
  });

  // Debounce: wait 400ms before executing search
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    _executeSearch(newFilter);
  });
}

void _clearSearch() {
  setState(() {
    _currentFilter = _currentFilter.copyWith(searchQuery: '');
    _executeSearch(_currentFilter);
  });
}

Future<void> _executeSearch(ProductFilter filter) async {
  try {
    final products = await _productService.fetchProducts(
      search: filter.searchQuery?.isNotEmpty == true
          ? filter.searchQuery
          : null,
      status: filter.selectedStatus != null
          ? [filter.selectedStatus!.name]
          : null,
      categoryIds: filter.selectedCategoryId != null
          ? [filter.selectedCategoryId!]
          : null,
    );

    if (mounted) {
      setState(() {
        _searchResult = ProductSearchResult.success(
          products: products,
          totalCount: products.length,
          appliedFilter: filter,
        );
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _searchResult = ProductSearchResult.error(
          filter,
          'Failed to load products: ${e.toString()}',
        );
      });
    }
  }
}
```

**Step 2.4**: Update product list display to use `_searchResult.products`:

```dart
// BEFORE:
ListView.builder(
  itemCount: _products.length,
  itemBuilder: (context, index) {
    final product = _products[index];
    return ProductCard(product: product);
  },
)

// AFTER:
if (_searchResult.isLoading)
  const Center(child: CircularProgressIndicator())
else if (_searchResult.hasError)
  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_searchResult.errorMessage!),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _executeSearch(_currentFilter),
          child: const Text('Retry'),
        ),
      ],
    ),
  )
else if (_searchResult.hasNoResults)
  _buildNoResultsState()
else
  ListView.builder(
    itemCount: _searchResult.products.length,
    itemBuilder: (context, index) {
      final product = _searchResult.products[index];
      return ProductCard(product: product);
    },
  )
```

**Step 2.5**: Add empty state widget:

```dart
Widget _buildNoResultsState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          _currentFilter.searchQuery?.isNotEmpty == true
              ? 'No products found for "${_currentFilter.searchQuery}"'
              : 'No products found with selected filters',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your search or filters',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _currentFilter = _currentFilter.clear();
              _executeSearch(_currentFilter);
            });
          },
          child: const Text('Clear all filters'),
        ),
      ],
    ),
  );
}
```

---

### 3. Add Status Filter (Optional)

**Step 3.1**: Add filter UI above the product list:

```dart
Row(
  children: [
    const Text('Status:'),
    const SizedBox(width: 8),
    ChoiceChip(
      label: const Text('All'),
      selected: _currentFilter.selectedStatus == null,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(_currentFilter.copyWith(selectedStatus: null));
        }
      },
    ),
    const SizedBox(width: 8),
    ChoiceChip(
      label: const Text('Draft'),
      selected: _currentFilter.selectedStatus == ProductStatus.DRAFT,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(
            _currentFilter.copyWith(selectedStatus: ProductStatus.DRAFT),
          );
        }
      },
    ),
    const SizedBox(width: 8),
    ChoiceChip(
      label: const Text('Active'),
      selected: _currentFilter.selectedStatus == ProductStatus.ACTIVE,
      onSelected: (selected) {
        if (selected) {
          _updateFilter(
            _currentFilter.copyWith(selectedStatus: ProductStatus.ACTIVE),
          );
        }
      },
    ),
  ],
)
```

**Step 3.2**: Add filter update method:

```dart
void _updateFilter(ProductFilter newFilter) {
  setState(() {
    _currentFilter = newFilter;
    _searchResult = ProductSearchResult.loading(_currentFilter);
  });

  // Execute search immediately (no debouncing for filter changes)
  _executeSearch(_currentFilter);
}
```

---

## Testing

### Unit Tests

**File**: `test/features/products/models/product_filter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_filter.dart';
import 'package:vronmobile2/features/products/models/product.dart';

void main() {
  group('ProductFilter', () {
    test('initial state has no active filters', () {
      const filter = ProductFilter();
      expect(filter.isActive, false);
      expect(filter.activeFilterCount, 0);
    });

    test('isActive returns true when search query is set', () {
      const filter = ProductFilter(searchQuery: 'test');
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 1);
    });

    test('isActive returns true when status is set', () {
      const filter = ProductFilter(selectedStatus: ProductStatus.DRAFT);
      expect(filter.isActive, true);
      expect(filter.activeFilterCount, 1);
    });

    test('activeFilterCount returns correct count with multiple filters', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.DRAFT,
        selectedCategoryId: 'cat123',
      );
      expect(filter.activeFilterCount, 3);
    });

    test('clear returns empty filter', () {
      const filter = ProductFilter(
        searchQuery: 'test',
        selectedStatus: ProductStatus.ACTIVE,
      );
      final cleared = filter.clear();
      expect(cleared.isActive, false);
      expect(cleared.searchQuery, null);
      expect(cleared.selectedStatus, null);
    });

    test('copyWith updates only specified fields', () {
      const filter = ProductFilter(searchQuery: 'test');
      final updated = filter.copyWith(selectedStatus: ProductStatus.ACTIVE);
      expect(updated.searchQuery, 'test');
      expect(updated.selectedStatus, ProductStatus.ACTIVE);
    });

    test('equality works correctly', () {
      const filter1 = ProductFilter(searchQuery: 'test');
      const filter2 = ProductFilter(searchQuery: 'test');
      const filter3 = ProductFilter(searchQuery: 'other');
      expect(filter1, filter2);
      expect(filter1 == filter3, false);
    });
  });
}
```

**File**: `test/features/products/models/product_search_result_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/products/models/product_search_result.dart';
import 'package:vronmobile2/features/products/models/product_filter.dart';
import 'package:vronmobile2/features/products/models/product.dart';

void main() {
  group('ProductSearchResult', () {
    test('initial factory creates correct state', () {
      final result = ProductSearchResult.initial();
      expect(result.isEmpty, true);
      expect(result.isInitialState, true);
      expect(result.isLoading, false);
      expect(result.hasError, false);
    });

    test('loading factory creates loading state', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.loading(filter);
      expect(result.isLoading, true);
      expect(result.products, isEmpty);
      expect(result.appliedFilter, filter);
    });

    test('error factory creates error state', () {
      const filter = ProductFilter(searchQuery: 'test');
      final result = ProductSearchResult.error(filter, 'Network error');
      expect(result.hasError, true);
      expect(result.errorMessage, 'Network error');
      expect(result.appliedFilter, filter);
    });

    test('hasNoResults returns true for active filter with no results', () {
      const filter = ProductFilter(searchQuery: 'nonexistent');
      final result = ProductSearchResult.success(
        products: [],
        totalCount: 0,
        appliedFilter: filter,
      );
      expect(result.hasNoResults, true);
      expect(result.isEmpty, true);
    });

    test('success factory creates correct state with products', () {
      const filter = ProductFilter(searchQuery: 'test');
      final products = [
        // Mock products here
      ];
      final result = ProductSearchResult.success(
        products: products,
        totalCount: products.length,
        appliedFilter: filter,
      );
      expect(result.products, products);
      expect(result.totalCount, products.length);
      expect(result.isLoading, false);
      expect(result.hasError, false);
    });
  });
}
```

### Widget Tests

**File**: `test/features/products/screens/products_list_screen_search_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/products/screens/products_list_screen.dart';

void main() {
  group('ProductsListScreen Search', () {
    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products by title'), findsOneWidget);
    });

    testWidgets('typing in search field updates query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Steam Punk');
      await tester.pump();

      expect(find.text('Steam Punk'), findsOneWidget);
    });

    testWidgets('shows loading indicator during search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Steam');

      // Wait for debounce (400ms)
      await tester.pump(const Duration(milliseconds: 400));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no results', (tester) async {
      // Mock service to return empty results
      await tester.pumpWidget(
        MaterialApp(
          home: ProductsListScreen(),
        ),
      );

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'NonexistentProduct');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('No products found'), findsOneWidget);
      expect(find.text('Clear all filters'), findsOneWidget);
    });
  });
}
```

---

## Common Integration Scenarios

### Scenario 1: Add Search to Existing Screen

**Goal**: Wire search functionality to existing ProductsListScreen

**Steps**:
1. Add ProductFilter and ProductSearchResult state variables
2. Replace TODO search TextField with working implementation
3. Add debouncing with Timer (400ms)
4. Update product list to use _searchResult.products
5. Add empty state handling

**Files Modified**: `products_list_screen.dart`

**Estimated Effort**: 1-2 hours

---

### Scenario 2: Add Status Filter

**Goal**: Add Draft/Active/All filter chips

**Steps**:
1. Add Row of ChoiceChip widgets above product list
2. Wire onSelected to _updateFilter method
3. Update _executeSearch to pass status parameter
4. Add visual indication of selected status

**Files Modified**: `products_list_screen.dart`

**Estimated Effort**: 30-60 minutes

---

### Scenario 3: Add Category Filter

**Goal**: Add category dropdown filter

**Steps**:
1. Fetch available categories (from product list or separate query)
2. Add DropdownButton widget with category options
3. Wire onChange to _updateFilter method
4. Update _executeSearch to pass categoryIds parameter

**Files Modified**: `products_list_screen.dart`

**Complexity**: Requires category data source (P3 priority)

---

### Scenario 4: Show Active Filter Count

**Goal**: Display badge showing number of active filters

**Steps**:
1. Add Badge widget to filter button
2. Use _currentFilter.activeFilterCount for badge text
3. Show/hide badge based on _currentFilter.isActive

**Example**:

```dart
Badge(
  label: Text('${_currentFilter.activeFilterCount}'),
  isLabelVisible: _currentFilter.isActive,
  child: IconButton(
    icon: const Icon(Icons.filter_list),
    onPressed: _showFilterPanel,
  ),
)
```

**Files Modified**: `products_list_screen.dart`

**Estimated Effort**: 15-30 minutes

---

## Troubleshooting

### Issue 1: Search Results Not Updating

**Symptoms**: Typing in search field doesn't trigger search

**Possible Causes**:
- Timer not canceling previous searches
- Missing setState() call
- ProductService not called

**Solution**:
```dart
void _onSearchChanged(String query) {
  _debounceTimer?.cancel(); // ✅ Always cancel first
  setState(() { /* ... */ }); // ✅ Update UI immediately
  _debounceTimer = Timer(...); // ✅ Start new timer
}
```

---

### Issue 2: Memory Leak Warning

**Symptoms**: "setState() called after dispose()" warning

**Possible Cause**: Timer fires after widget disposed

**Solution**:
```dart
@override
void dispose() {
  _debounceTimer?.cancel(); // ✅ Cancel timer in dispose
  super.dispose();
}

Future<void> _executeSearch(ProductFilter filter) async {
  // ...
  if (mounted) { // ✅ Check mounted before setState
    setState(() { /* ... */ });
  }
}
```

---

### Issue 3: Stale Search Results

**Symptoms**: Old results displayed after new search

**Possible Cause**: Race condition (fast typing causes out-of-order responses)

**Solution**: Debouncing prevents this (timer cancels previous searches)

---

### Issue 4: Empty State Shows Too Quickly

**Symptoms**: Empty state flashes before results load

**Possible Cause**: Not showing loading state during debounce

**Solution**:
```dart
void _onSearchChanged(String query) {
  setState(() {
    _searchResult = ProductSearchResult.loading(_currentFilter); // ✅
  });
  // ... rest of method
}
```

---

## Performance Tips

1. **Debouncing**: 400ms is optimal (Material Design recommendation)
   - Too short (< 300ms): excessive API calls
   - Too long (> 500ms): feels sluggish

2. **Loading States**: Always show loading indicator during search
   - Prevents users from thinking nothing is happening

3. **Empty States**: Provide clear guidance when no results
   - Tell users why (search term vs filters)
   - Provide action to fix ("Clear filters" button)

4. **State Management**: Keep it simple (StatefulWidget)
   - No Provider needed (state is local to screen)
   - Session-only (no persistence)

5. **Error Handling**: Always handle network errors
   - Show user-friendly messages
   - Provide retry button

---

## Next Steps

After completing basic search integration:

1. **Add Tests**: Write unit tests for ProductFilter and ProductSearchResult
2. **Add Widget Tests**: Test search field and empty states
3. **Add Accessibility**: Semantic labels for screen readers
4. **Add Status Filter**: Implement P2 priority feature
5. **Add Category Filter**: Implement P3 priority feature (if categories available)
6. **Performance Testing**: Test with 1000+ products

---

## References

- **Data Models**: `specs/005-product-search/data-model.md`
- **API Contracts**: `specs/005-product-search/contracts/graphql-queries.md`
- **Research**: `specs/005-product-search/research.md`
- **Spec**: `specs/005-product-search/spec.md`
- **Plan**: `specs/005-product-search/plan.md`

---

## Support

For questions or issues:
- Review research.md for technical decisions
- Check contracts/graphql-queries.md for API examples
- Consult data-model.md for model details
- See existing ProductService implementation for patterns
