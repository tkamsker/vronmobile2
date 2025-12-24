# Research: Product Search and Filtering

**Date**: 2024-12-22
**Feature**: 005-product-search
**Purpose**: Validate technical assumptions and determine implementation approach

## 1. GraphQL Query Capabilities

### Decision
**RESOLVED**: VRonGetProducts query fully supports all required filter parameters.

### Findings
The existing `ProductService` (`lib/features/products/services/product_service.dart`) already implements comprehensive search and filtering capabilities:

**Query Structure**:
```dart
query GetProducts($input: VRonGetProductsInput!, $lang: Language!) {
  VRonGetProducts(input: $input) {
    products {
      id, title, thumbnail, status, category, tracksInventory, variantsCount
    }
    pagination {
      pageCount
    }
  }
}
```

**Supported Filter Parameters**:
- `search` (String): Case-insensitive partial match on product titles
- `status` (List[String]): Filter by ACTIVE/DRAFT
- `categoryIds` (List[String]): Filter by category IDs
- `tracksInventory` (Boolean): Filter by inventory tracking status

**Pagination Parameters**:
- `pageIndex` (int): 0-based page number
- `pageSize` (int): Items per page (default: 20)

**Existing Methods**:
1. `fetchProducts()` - Main method accepting all filter parameters
2. `searchProducts(String query)` - Convenience method for title search
3. `fetchActiveProducts()` - Pre-filtered for ACTIVE status

**Evidence**:
- GraphQL documentation: `Requirements/GraphqlProducts.md`
- Service implementation: `lib/features/products/services/product_service.dart` lines 42-157
- Test script: `test_searchproduct.sh`

### Rationale
No modifications needed to backend API or ProductService. All filtering capabilities exist and are production-ready. Implementation focuses on UI integration only.

### Alternatives Considered
- **Client-side filtering**: Rejected - would not scale to 1000+ products
- **New service methods**: Rejected - existing methods are sufficient
- **GraphQL query modifications**: Not needed - query structure is optimal

---

## 2. Debouncing Best Practices

### Decision
**RESOLVED**: Use `Timer` from `dart:async` with 400ms delay

### Findings

**Flutter Debouncing Pattern**:
```dart
Timer? _debounceTimer;

void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
    _executeSearch(query);
  });
}

@override
void dispose() {
  _debounceTimer?.cancel();
  super.dispose();
}
```

**Industry Standards**:
- **200-300ms**: Very responsive, may cause many API calls
- **400ms**: Sweet spot for search (recommended by Google Material Design)
- **500-800ms**: More conservative, may feel sluggish

**Race Condition Prevention**:
- Cancel previous timer before starting new one
- Use unique request IDs to discard stale responses (optional, not needed for our simple case)
- Cancel timer in `dispose()` to prevent memory leaks

**References**:
- Flutter documentation: Timer class
- Material Design: https://material.io/components/search
- Industry practice: 400ms is standard for search inputs

### Rationale
400ms provides optimal balance between responsiveness and API efficiency. Simple `Timer` approach avoids dependencies and follows Flutter patterns. No complex debouncing library needed (YAGNI principle).

### Alternatives Considered
- **rxdart debounce**: Rejected - adds dependency, overkill for simple case
- **Custom debounce function**: Rejected - Timer is built-in and sufficient
- **No debouncing**: Rejected - would cause excessive API calls

---

## 3. Filter UI Patterns

### Decision
**RESOLVED**: Use Material Design FilterChip for status and category, TextField with debouncing for search

### Findings

**Search Input**:
- Material `TextField` with `prefixIcon: Icon(Icons.search)`
- Clear button on suffix when text present
- Hint text: "Search products by title"
- Already implemented in ProductsListScreen (line 263-285), just needs wiring

**Status Filter**:
- `FilterChip` or `ChoiceChip` widgets
- Options: All | Draft | Active
- Single selection (radio behavior)
- Visual state: selected chip has different color/elevation

**Category Filter**:
- `DropdownButton` or bottom sheet with list
- Show category name from Product.category field
- "All Categories" as default option
- Only show if categories exist in product data

**Tags Filter** (P3 - optional):
- `Wrap` of `FilterChip` widgets
- Multi-select capability
- Scrollable if many tags
- Or: single text input for tag search

**Active Filter Indicators**:
- Badge on filter button showing count (e.g., "Filters (2)")
- `Badge` widget from Material 3
- Clear all button becomes visible when filters active

**Platform Considerations**:
- Material Design is primary (Android-first app)
- iOS users familiar with Material patterns in cross-platform apps
- No need for Cupertino alternatives (YAGNI)

### Rationale
Material Design components are well-tested, accessible, and match existing app design. FilterChip provides clear visual feedback for active filters. Simple implementation without custom widgets.

### Alternatives Considered
- **Cupertino widgets**: Rejected - Material is standard for this app
- **Custom filter panel**: Rejected - built-in widgets sufficient
- **Bottom sheet for filters**: Rejected - inline filters better for quick access
- **Tags as multi-select**: Deferred to future - P3 priority, can start without it

---

## 4. State Management Approach

### Decision
**RESOLVED**: Simple StatefulWidget state in ProductsListScreen, no Provider needed

### Findings

**Current Implementation**:
- ProductsListScreen is already StatefulWidget
- Manages products list, loading state, error state
- Pattern: setState() for UI updates after async operations

**Filter State Requirements**:
```dart
// Add to _ProductsListScreenState
String? _searchQuery;
ProductStatus? _selectedStatus;  // null = All, ACTIVE, DRAFT
String? _selectedCategoryId;
Timer? _debounceTimer;
```

**Session-Only Pattern**:
- No SharedPreferences or persistence
- State lives in widget, disposed on navigation away
- Filters cleared when widget disposed
- Perfect match for existing pattern

**State Sharing**:
- No other widgets need filter state
- Search bar and filter chips are local to ProductsListScreen
- No need for Provider, Bloc, or other state management

**Lifecycle Handling**:
```dart
@override
void dispose() {
  _debounceTimer?.cancel();
  super.dispose();
}
```

### Rationale
Existing StatefulWidget pattern is sufficient. Adding Provider would violate YAGNI principle. Filter state is local to ProductsListScreen with no sharing needs. Simple setState() approach matches existing code style.

### Alternatives Considered
- **Provider**: Rejected - no state sharing needed, adds complexity
- **Bloc**: Rejected - overkill for simple filter state
- **SharedPreferences**: Rejected - spec requires session-only persistence
- **InheritedWidget**: Rejected - no child widgets need filter state

---

## 5. Empty States and Error Handling

### Decision
**RESOLVED**: Enhance existing empty state logic with filter-specific messages

### Findings

**Existing Implementation**:
ProductsListScreen already has:
- Empty state when no products (line 239-242)
- Error state with retry (line 204-226)
- Loading indicator (CircularProgressIndicator)

**New Empty State Cases**:
1. **No search results**: "No products found matching '{query}'"
   - Action: "Clear search" button

2. **No products match filters**: "No products found with selected filters"
   - Action: "Clear all filters" button
   - Show which filters are active

3. **Network error during search**: Existing error UI with retry

4. **Loading during debounce**: Show existing CircularProgressIndicator

**Error Message Patterns**:
```dart
if (products.isEmpty && _hasActiveFilters) {
  return _buildNoResultsState(
    message: 'No products found',
    action: _clearAllFilters,
  );
}
```

**User Guidance**:
- Clear messaging about why no results (search term vs filters)
- Actionable buttons to fix (clear search, clear filters)
- Maintain existing helpful tone

### Rationale
Extend existing empty/error state pattern rather than creating new widgets. Users get clear feedback about why no results and how to fix it. Maintains consistency with existing UX.

### Alternatives Considered
- **Generic empty state**: Rejected - not helpful when filters active
- **Separate widget for empty states**: Rejected - existing pattern works
- **No action buttons**: Rejected - users need clear path to fix no-results state

---

## 6. Tags Filtering Research

### Decision
**DEFERRED**: Tags are stored as comma-separated string, filtering possible but defer UI to P3 priority

### Findings

**Data Model**:
- Product model doesn't expose tags field directly
- Backend GraphQL query doesn't include tags in response
- ProductDetail model has tags (List<String>)
- VRonGetProducts filter doesn't support tags parameter

**Implementation Options**:
1. Add tags to Product model and query response
2. Add tags filter parameter to backend
3. OR: Defer tags filtering to future feature

**Current Status**:
- Tags not available in current ProductsListScreen data
- Would require ProductDetail query for each product (expensive)
- OR: Backend API changes to include tags in VRonGetProducts

### Rationale
Tags filtering requires backend changes or expensive queries. Given P3 priority and complexity, defer to future feature. Focus on P1 (search) and P2 (status) which are fully supported.

### Alternatives Considered
- **Include in MVP**: Rejected - requires backend changes, P3 priority
- **Query details for tags**: Rejected - too expensive for 20+ products
- **Implement later**: **SELECTED** - focus on higher priority features first

---

## Summary of Technical Decisions

| Decision Area | Resolution | Implementation Notes |
|---------------|------------|---------------------|
| **GraphQL Query** | ✅ Ready | Use existing ProductService methods |
| **Debouncing** | Timer (400ms) | Simple dart:async Timer pattern |
| **Search UI** | Wire existing TextField | Already in ProductsListScreen line 263-285 |
| **Filter UI** | FilterChip + DropdownButton | Material Design components |
| **State Management** | StatefulWidget setState | No Provider needed |
| **Empty States** | Enhance existing | Add filter-specific messages |
| **Tags Filtering** | Deferred to P3 | Not in initial MVP |
| **Performance** | Server-side filtering | No client-side filtering of large lists |

## Implementation Readiness

**Ready to Implement** (all research complete):
- ✅ Search by title (P1)
- ✅ Filter by status (P2)
- ✅ Filter by category (P3)
- ✅ Debouncing pattern
- ✅ State management approach
- ✅ Empty state handling

**Deferred** (future feature):
- ⏸️ Tags filtering (requires backend changes or expensive queries)

**Next Phase**: Create data-model.md and contracts/graphql-queries.md
