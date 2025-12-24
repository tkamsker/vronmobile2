import 'package:flutter/material.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/products/models/product.dart';
import 'package:vronmobile2/features/products/services/product_service.dart';
import 'package:vronmobile2/features/products/widgets/product_card.dart';

/// Products tab widget
/// Displays list of products associated with the project
class ProjectProductsTab extends StatefulWidget {
  final Project project;
  final VoidCallback? onNavigateToProducts;
  final void Function(String projectId)? onCreateProduct;
  final ProductService? productService;

  const ProjectProductsTab({
    super.key,
    required this.project,
    this.onNavigateToProducts,
    this.onCreateProduct,
    this.productService,
  });

  @override
  State<ProjectProductsTab> createState() => _ProjectProductsTabState();
}

class _ProjectProductsTabState extends State<ProjectProductsTab> {
  late final ProductService _productService;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
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

  /// Handle search query changes
  /// T045: Filter products list based on search query
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  /// Clear search query
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  /// Get filtered products based on search query
  /// T046: Filter by product title
  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      return product.title.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  /// Navigate to product creation screen with project context
  /// T037: Pass projectId and projectName as navigation arguments
  Future<void> _navigateToCreateProduct() async {
    // Call the callback if provided (for testing and custom navigation)
    if (widget.onCreateProduct != null) {
      widget.onCreateProduct!(widget.project.id);
      return;
    }

    // TODO: Replace with actual navigation when CreateProductScreen is implemented
    // For now, navigate to products list as placeholder
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.products,
      arguments: {
        'projectId': widget.project.id,
        'projectName': widget.project.name,
      },
    );

    // T039: Refresh product list if creation succeeded
    if (result == true && mounted) {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = _buildLoading();
    } else if (_errorMessage != null) {
      content = _buildError();
    } else if (_products.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = _buildProductsList();
    }

    // Wrap content with Stack to add FAB
    return Stack(
      children: [
        content,
        // FAB for creating products
        Positioned(
          right: 16,
          bottom: 16,
          child: Semantics(
            button: true,
            label: 'Create product for ${widget.project.name}',
            child: FloatingActionButton(
              onPressed: _navigateToCreateProduct,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
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
      label: 'No products yet for ${widget.project.name}',
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
                  child: Icon(Icons.apps, size: 60, color: Colors.grey[400]),
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
                  onPressed: _navigateToCreateProduct,
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
              const SizedBox(height: 16),
              Text(
                'Set up materials, lighting, and interactions –\neverything in one place.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Semantics(
      label: _searchQuery.isNotEmpty
          ? '${_filteredProducts.length} of ${_products.length} products for ${widget.project.name}'
          : '${_products.length} products for ${widget.project.name}',
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            // Create Product Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Create a product',
                      child: ElevatedButton(
                        onPressed: _navigateToCreateProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create a product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'More options',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: More options
                        },
                        icon: const Icon(Icons.add),
                        iconSize: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar (T044: Updated with working implementation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                label: 'Search products by title',
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                            tooltip: 'Clear search',
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
                ),
              ),
            ),

            const SizedBox(height: 16),

            // T047: Search results count
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_filteredProducts.length} ${_filteredProducts.length == 1 ? "product" : "products"} found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (_searchQuery.isNotEmpty) const SizedBox(height: 8),

            // Products list (T046: Using filtered products)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Edit product: ${product.title}'),
                        ),
                      );
                    },
                    onDelete: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delete product: ${product.title}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
