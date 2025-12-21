import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Products tab widget
/// Provides navigation to the products list for this project
class ProjectProductsTab extends StatelessWidget {
  final Project project;
  final VoidCallback? onNavigateToProducts;

  const ProjectProductsTab({
    super.key,
    required this.project,
    this.onNavigateToProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Products section for ${project.name}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Products icon',
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  'Products for ${project.name}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'View and manage all products associated with this project',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: 'View Products button. Navigate to products list for ${project.name}',
                hint: 'Double tap to view all products',
                child: ElevatedButton(
                  onPressed: onNavigateToProducts ?? () {
                    // TODO: Navigate to products list screen (UC12)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Products feature coming soon (UC12)'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'View Products',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
