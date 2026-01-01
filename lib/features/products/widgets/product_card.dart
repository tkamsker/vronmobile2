import 'package:flutter/material.dart';
import 'package:vronmobile2/features/products/models/product.dart';

/// Card widget displaying product information in a list
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Product: ${product.title}, ${product.statusLabel}',
      button: onTap != null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                _buildThumbnail(context),
                const SizedBox(width: 12),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Semantics(
                        header: true,
                        child: Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Category
                      if (product.category != null &&
                          product.category!.isNotEmpty)
                        Semantics(
                          label: 'Category: ${product.category}',
                          child: Text(
                            product.category!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Status and metadata
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatusChip(context),
                          if (product.variantsCount > 0)
                            _buildInfoChip(
                              context,
                              Icons.style_outlined,
                              '${product.variantsCount} variant${product.variantsCount != 1 ? 's' : ''}',
                            ),
                          if (product.tracksInventory)
                            _buildInfoChip(
                              context,
                              Icons.inventory_2_outlined,
                              'Tracks inventory',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Created date and action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Created\n${_formatDate(DateTime.now())}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                            ),
                          ),
                          // Edit button
                          if (onEdit != null)
                            Semantics(
                              button: true,
                              label: 'Edit ${product.title}',
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: onEdit,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Delete button
                          if (onDelete != null)
                            Semantics(
                              button: true,
                              label: 'Delete ${product.title}',
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: onDelete,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildThumbnail(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Product thumbnail for ${product.title}',
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: product.thumbnail != null && product.thumbnail!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholderIcon();
                  },
                ),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey[400]);
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = product.isActive ? Colors.green : Colors.orange;
    return Semantics(
      label: 'Status: ${product.statusLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              product.statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
