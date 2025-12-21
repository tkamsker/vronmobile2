import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Header widget for project detail screen
/// Displays project name, status badge, back button, and menu
class ProjectDetailHeader extends StatelessWidget {
  final Project project;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;

  const ProjectDetailHeader({
    super.key,
    required this.project,
    this.onBackPressed,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Back button, Menu button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMenuPressed ?? () {},
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Project name
            Text(
              project.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                project.statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get status color based on project status
  Color _getStatusColor() {
    final colorHex = project.statusColorHex;
    // Remove '#' and parse hex color
    final hexColor = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
