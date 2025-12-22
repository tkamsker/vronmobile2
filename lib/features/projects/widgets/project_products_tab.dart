import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/products/models/product.dart';
import 'package:vronmobile2/features/products/services/product_service.dart';
import 'package:vronmobile2/features/products/widgets/product_card.dart';

/// Products tab widget
/// Displays list of products associated with the project
class ProjectProductsTab extends StatefulWidget {
  final Project project;
  final VoidCallback? onNavigateToProducts;

  const ProjectProductsTab({
    super.key,
    required this.project,
    this.onNavigateToProducts,
  });

  @override
  State<ProjectProductsTab> createState() => _ProjectProductsTabState();
}

class _ProjectProductsTabState extends State<ProjectProductsTab> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  @override
  Widget build(BuildContext context) {
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
      child: const Center(
        child: CircularProgressIndicator(),
      ),
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load products',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
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
                  child: Icon(
                    Icons.apps,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: 'Create a product button',
                hint: 'Double tap to create your first product',
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to product creation (UC13)
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
              const SizedBox(height: 16),
              Text(
                'Set up materials, lighting, and interactions –\neverything in one place.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
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
      label: '${_products.length} products for ${widget.project.name}',
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        '${_products.length} Product${_products.length != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Create new product',
                    child: IconButton(
                      onPressed: () {
                        // TODO: Navigate to product creation
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product creation coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Create product',
                    ),
                  ),
                ],
              ),
            ),

            // Products list
            Expanded(
              child: ListView.builder(
                itemCount: _products.length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      // TODO: Navigate to product detail (UC14)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('View product: ${product.title}'),
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
