import 'package:flutter/material.dart';
import 'package:vronmobile2/features/products/models/product_detail.dart';
import 'package:vronmobile2/features/products/services/product_detail_service.dart';
import 'package:vronmobile2/features/products/services/product_update_service.dart';

/// Product edit screen for viewing and editing product details
/// Displays a form matching the ProductEdit.jpg design
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final ProductDetailService? productDetailService;
  final ProductUpdateService? productUpdateService;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productDetailService,
    this.productUpdateService,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductDetailService _detailService;
  late final ProductUpdateService _updateService;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  // State
  ProductDetail? _product;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _detailService = widget.productDetailService ?? ProductDetailService();
    _updateService = widget.productUpdateService ?? ProductUpdateService();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    // Listen for changes to mark form as dirty
    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);

    _loadProduct();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final product = await _detailService.getProductDetail(widget.productId);
      setState(() {
        _product = product;
        _titleController.text = product.title;
        _descriptionController.text = product.description;
        _isLoading = false;
        _isDirty = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _updateService.updateProduct(
        productId: widget.productId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      setState(() {
        _isSaving = false;
        _isDirty = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePopInvoked(bool didPop) async {
    if (didPop) return;

    if (_isDirty) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Do you want to discard them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _product == null ? 'Loading...' : 'Edit Product',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Basic details',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          actions: [
            if (_isDirty && !_isLoading)
              Semantics(
                button: true,
                label: 'Save product changes',
                child: TextButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_product != null) {
      return _buildForm();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoading() {
    return Semantics(
      label: 'Loading product',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading product...'),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Semantics(
      label: 'Error loading product',
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
                _errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Retry loading product',
                child: ElevatedButton.icon(
                  onPressed: _loadProduct,
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

  Widget _buildForm() {
    final product = _product!;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Listing basics section
            _buildSectionHeader('Listing basics'),
            const SizedBox(height: 16),

            // AI fills details button (placeholder)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    'AI fills details from photos',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title field
            _buildRequiredLabel('Title'),
            const SizedBox(height: 8),
            Semantics(
              label: 'Product title',
              textField: true,
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter listing title',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'e.g. "Modern 2BR in Berlin"',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Short text / Description field
            Text(
              'Short text',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Optional, a few key highlights',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Product description',
              textField: true,
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what makes this property special...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Let AI improve this text link (placeholder)
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'Let AI improve this text',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Photos section
            _buildRequiredLabel('Photos'),
            const SizedBox(height: 4),
            Text(
              'Add one or more pictures',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Display existing photos
            if (product.mediaFiles.isNotEmpty)
              _buildPhotosGrid(product)
            else
              _buildNoPhotos(),

            const SizedBox(height: 16),

            // Helper text
            Text(
              'Upload a few key rooms and the exterior. AI will create a clean product listing for you.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Status chip
            _buildStatusChip(product),
            const SizedBox(height: 32),

            // Save button (full width)
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: 'Save changes',
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
    );
  }

  Widget _buildRequiredLabel(String label) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        children: [
          const TextSpan(
            text: '* ',
            style: TextStyle(color: Colors.red),
          ),
          TextSpan(text: label),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid(ProductDetail product) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Main photo
        if (product.mediaFiles.isNotEmpty)
          _buildPhotoCard(
            product.mediaFiles.first,
            isMain: true,
            label: product.category ?? 'Main photo',
          ),
        // Additional photos
        ...product.mediaFiles.skip(1).map((media) => _buildPhotoCard(media)),
        // Add more photos button
        _buildAddPhotoButton(),
      ],
    );
  }

  Widget _buildPhotoCard(dynamic media, {bool isMain = false, String? label}) {
    return Container(
      width: isMain ? 200 : 120,
      height: isMain ? 140 : 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
        border: isMain ? Border.all(color: Colors.blue, width: 3) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMain ? 9 : 12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              media.url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image,
                  size: 40,
                  color: Colors.grey[400],
                );
              },
            ),
            if (isMain && label != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.blue.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue,
          width: 2,
          style: BorderStyle.solid,
        ),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Implement image picker
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image picker coming soon')),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 32, color: Colors.blue[700]),
              const SizedBox(height: 4),
              Text(
                'Add more photos',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPhotos() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No photos yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              // TODO: Implement image picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image picker coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add photos'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ProductDetail product) {
    final color = product.isActive ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            product.isActive ? Icons.check_circle : Icons.edit,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Status: ${product.statusLabel}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
