import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/products/models/product.dart';
import 'package:vronmobile2/features/products/models/product_filter.dart';
import 'package:vronmobile2/features/products/models/product_search_result.dart';
import 'package:vronmobile2/features/products/services/product_service.dart';
import 'package:vronmobile2/features/products/widgets/product_card.dart';

/// Products list screen displaying all products
class ProductsListScreen extends StatefulWidget {
  final ProductService? productService;

  const ProductsListScreen({super.key, this.productService});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  late final ProductService _productService;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search and filter state (T015)
  ProductFilter _currentFilter = const ProductFilter();
  ProductSearchResult _searchResult = ProductSearchResult.initial();

  // Debouncing timer (T016)
  Timer? _debounceTimer;

  // TextEditingController for search field (for testability)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _loadProducts();
  }

  @override
  void dispose() {
    // T017: Cancel debounce timer
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await _productService.fetchProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // T019: Implement _onSearchChanged method with 400ms debouncing
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

  // T020: Implement _clearSearch method
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentFilter = _currentFilter.copyWith(searchQuery: '');
      _executeSearch(_currentFilter);
    });
  }

  // T033: Implement _updateFilter method for filter changes
  void _updateFilter(ProductFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _searchResult = ProductSearchResult.loading(_currentFilter);
    });

    // Execute search immediately (no debouncing for filter changes)
    _executeSearch(_currentFilter);
  }

  // T043: Extract unique categories from product list
  List<String> _getUniqueCategories() {
    final categories = <String>{};
    for (final product in _products) {
      if (product.category != null && product.category!.isNotEmpty) {
        categories.add(product.category!);
      }
    }
    return categories.toList()..sort();
  }

  // T021, T058: Implement _executeSearch method with enhanced error handling
  Future<void> _executeSearch(ProductFilter filter) async {
    try {
      final products = await _productService.fetchProducts(
        search: filter.searchQuery?.isNotEmpty == true
            ? filter.searchQuery
            : null,
        status: filter.selectedStatus != null
            ? [filter.selectedStatus!.value]
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
        // T058: Enhanced error handling with specific messages
        String errorMessage = 'Failed to load products';

        final errorString = e.toString().toLowerCase();
        if (errorString.contains('socket') ||
            errorString.contains('network') ||
            errorString.contains('connection')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else if (errorString.contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (errorString.contains('unauthorized') ||
            errorString.contains('401')) {
          errorMessage = 'Authentication error. Please sign in again.';
        } else if (errorString.contains('forbidden') ||
            errorString.contains('403')) {
          errorMessage =
              'Access denied. You don\'t have permission to view these products.';
        } else if (errorString.contains('not found') ||
            errorString.contains('404')) {
          errorMessage = 'Products not found. Please try again later.';
        } else if (errorString.contains('500') ||
            errorString.contains('server')) {
          errorMessage = 'Server error. Please try again later.';
        }

        setState(() {
          _searchResult = ProductSearchResult.error(filter, errorMessage);
        });
      }
    }
  }

  // T022-T024: Build products content with state handling
  Widget _buildProductsContent() {
    // T023: Show loading state
    if (_searchResult.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // T024, T058: Show error state with enhanced error message and retry button
    if (_searchResult.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _searchResult.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _executeSearch(_currentFilter),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _currentFilter = _currentFilter.clear();
                    _loadProducts();
                  });
                },
                child: const Text('Clear filters and reload'),
              ),
            ],
          ),
        ),
      );
    }

    // T025: Show empty state when no results
    if (_searchResult.hasNoResults) {
      return _buildNoResultsState();
    }

    // Show initial empty state (no search performed, no products)
    if (_searchResult.isInitialState && _products.isEmpty) {
      return _buildEmptyState();
    }

    // T022: Show products from _searchResult
    final displayProducts = _currentFilter.isActive
        ? _searchResult.products
        : _products;

    return ListView.builder(
      itemCount: displayProducts.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final product = displayProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: product.id,
            );
          },
          onEdit: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: product.id,
            );
          },
          onDelete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete product: ${product.title}')),
            );
          },
        );
      },
    );
  }

  // T025, T037: Implement _buildNoResultsState method with active filter info
  Widget _buildNoResultsState() {
    // Build message showing which filters are active
    String message = 'No products found';
    final List<String> activeFilters = [];

    if (_currentFilter.searchQuery?.isNotEmpty == true) {
      activeFilters.add('search: "${_currentFilter.searchQuery}"');
    }
    if (_currentFilter.selectedStatus != null) {
      final statusName = _currentFilter.selectedStatus == ProductStatus.DRAFT
          ? 'Draft'
          : 'Active';
      activeFilters.add('status: $statusName');
    }
    if (_currentFilter.selectedCategoryId != null) {
      activeFilters.add('category filter');
    }

    if (activeFilters.isNotEmpty) {
      message = 'No products found with ${activeFilters.join(", ")}';
    }

    return Semantics(
      label: 'No products found',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentFilter = _currentFilter.clear();
                      _executeSearch(_currentFilter);
                    });
                  },
                  child: const Text('Clear all filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create product coming soon')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductsList();
  }

  Widget _buildLoading() {
    return Semantics(
      label: 'Loading products',
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Semantics(
      label: 'Error loading products',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Retry loading products',
                child: ElevatedButton.icon(
                  onPressed: _loadProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Semantics(
      label: 'No products yet',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                image: true,
                label: 'Products icon',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  'You have no products yet!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create your first virtual product to start\npopulating your worlds and projects.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: 'Create a product button',
                hint: 'Double tap to create your first product',
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product creation coming soon'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create a product'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Semantics(
      label: '${_products.length} products',
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Search Bar (T018: Updated with working implementation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Search products by title',
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _currentFilter.searchQuery?.isNotEmpty == true
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // T032: Status Filter UI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Filter by status',
                child: Row(
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // T035: Visual indication via selected property
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _currentFilter.selectedStatus == null,
                      onSelected: (selected) {
                        if (selected) {
                          _updateFilter(
                            _currentFilter.copyWith(selectedStatus: null),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Draft'),
                      selected:
                          _currentFilter.selectedStatus == ProductStatus.DRAFT,
                      onSelected: (selected) {
                        if (selected) {
                          _updateFilter(
                            _currentFilter.copyWith(
                              selectedStatus: ProductStatus.DRAFT,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Active'),
                      selected:
                          _currentFilter.selectedStatus == ProductStatus.ACTIVE,
                      onSelected: (selected) {
                        if (selected) {
                          _updateFilter(
                            _currentFilter.copyWith(
                              selectedStatus: ProductStatus.ACTIVE,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // T044: Category Filter UI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Filter by category',
                child: Row(
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _currentFilter.selectedCategoryId,
                        hint: const Text('All Categories'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._getUniqueCategories().map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }),
                        ],
                        onChanged: (String? value) {
                          // T045: Wire onChange to _updateFilter
                          _updateFilter(
                            _currentFilter.copyWith(selectedCategoryId: value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // T056: Clear all filters button with badge count
            if (_currentFilter.isActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _currentFilter = _currentFilter.clear();
                          _executeSearch(_currentFilter);
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: Text(
                        'Clear all filters (${_currentFilter.activeFilterCount})',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // T057: Result count display
            if (!_searchResult.isInitialState && !_searchResult.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Semantics(
                  liveRegion: true,
                  label: 'Showing ${_searchResult.products.length} products',
                  child: Text(
                    'Showing ${_searchResult.products.length} product${_searchResult.products.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Products list (T022-T024: Updated to use _searchResult with state handling)
            Expanded(child: _buildProductsContent()),
          ],
        ),
      ),
    );
  }
}
