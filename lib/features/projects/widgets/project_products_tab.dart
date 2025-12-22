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
    final activeCount = _products.where((p) => p.status == 'ACTIVE').length;
    final draftCount = _products.where((p) => p.status == 'DRAFT').length;

    return Semantics(
      label: '${_products.length} products for ${widget.project.name}',
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            // Stats Header Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      'Your products',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage all ${_products.length} products in one place',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Stats chips
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildStatChip('Active', activeCount, Colors.blue),
                      _buildStatChip('Drafts', draftCount, Colors.orange),
                      _buildStatChip('Last updated', 'Just now', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

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
                        onPressed: () {
                          // TODO: Navigate to product creation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product creation coming soon'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create a product',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
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
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
            ),

            const SizedBox(height: 16),

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
                      // TODO: Navigate to product detail (Phase 2)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('View product: ${product.title}'),
                        ),
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

  Widget _buildStatChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label · ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
