import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';

/// Export dialog for completed combined scan with navmesh
/// Feature 018: Combined Scan to NavMesh Workflow
/// Shows file sizes and export options
class ExportCombinedDialog extends StatelessWidget {
  final CombinedScan combinedScan;
  final VoidCallback? onExportGlb;
  final VoidCallback? onExportNavmesh;
  final VoidCallback? onExportBoth;
  final VoidCallback? onClose;

  const ExportCombinedDialog({
    Key? key,
    required this.combinedScan,
    this.onExportGlb,
    this.onExportNavmesh,
    this.onExportBoth,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Combined Scan Ready',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // File list
            _buildFileItem(
              context: context,
              icon: Icons.view_in_ar,
              title: 'Combined GLB',
              subtitle: _getGlbFileSize(),
            ),
            const SizedBox(height: 16),
            _buildFileItem(
              context: context,
              icon: Icons.map,
              title: 'Navigation Mesh',
              subtitle: _getNavmeshFileSize(),
            ),

            const SizedBox(height: 32),

            // Export buttons
            ElevatedButton.icon(
              onPressed: onExportGlb,
              icon: const Icon(Icons.ios_share),
              label: const Text('Export Combined GLB'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onExportNavmesh,
              icon: const Icon(Icons.ios_share),
              label: const Text('Export NavMesh'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onExportBoth,
              icon: const Icon(Icons.folder_zip),
              label: const Text('Export Both as ZIP'),
            ),

            const SizedBox(height: 24),

            // Close button
            TextButton(
              onPressed: onClose,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGlbFileSize() {
    if (combinedScan.combinedGlbLocalPath == null) {
      return 'Unknown size';
    }

    try {
      final file = File(combinedScan.combinedGlbLocalPath!);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        return _formatFileSize(bytes);
      }
    } catch (e) {
      // File access error
    }

    return 'Unknown size';
  }

  String _getNavmeshFileSize() {
    if (combinedScan.localNavmeshPath == null) {
      return 'Unknown size';
    }

    try {
      final file = File(combinedScan.localNavmeshPath!);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        return _formatFileSize(bytes);
      }
    } catch (e) {
      // File access error
    }

    return 'Unknown size';
  }

  String _formatFileSize(int bytes) {
    const int mb = 1024 * 1024;
    const int kb = 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(2)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
}
