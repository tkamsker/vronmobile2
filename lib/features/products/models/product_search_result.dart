import 'product.dart';
import 'product_filter.dart';

/// Wraps product search results with metadata about the query and applied filters.
/// Provides context for empty state handling and result display.
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

  /// Check if result set is empty
  bool get isEmpty => products.isEmpty;

  /// Check if this is an initial state (no search performed)
  bool get isInitialState =>
      !appliedFilter.isActive && !isLoading && errorMessage == null;

  /// Check if this is a successful search with no results
  bool get hasNoResults =>
      isEmpty && appliedFilter.isActive && !isLoading && errorMessage == null;

  /// Check if error state
  bool get hasError => errorMessage != null;

  /// Initial empty state (no search yet)
  factory ProductSearchResult.initial() {
    return const ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: ProductFilter(),
      isLoading: false,
    );
  }

  /// Loading state (search in progress)
  factory ProductSearchResult.loading(ProductFilter filter) {
    return ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: filter,
      isLoading: true,
    );
  }

  /// Error state
  factory ProductSearchResult.error(ProductFilter filter, String message) {
    return ProductSearchResult(
      products: [],
      totalCount: 0,
      appliedFilter: filter,
      errorMessage: message,
    );
  }

  /// Success state
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
