import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';

/// Action buttons for navigating to Project Data and Products
class ProjectActionButtons extends StatelessWidget {
  final VoidCallback onProjectDataTap;
  final VoidCallback onProductsTap;

  const ProjectActionButtons({
    super.key,
    required this.onProjectDataTap,
    required this.onProductsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Project Data Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onProjectDataTap,
            icon: const Icon(Icons.edit),
            label: Text('projectDetail.projectData'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Products Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onProductsTap,
            icon: const Icon(Icons.inventory),
            label: Text('projectDetail.products'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
