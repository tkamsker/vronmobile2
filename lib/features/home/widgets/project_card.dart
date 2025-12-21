import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Widget displaying a project card with image, title, status, description, and action button
class ProjectCard extends StatelessWidget {
  final Project project;
  final Function(String projectId)? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  String _formatUpdateTime(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 365) {
      return 'Updated ${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return 'Updated ${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return 'Updated ${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return 'Updated ${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return 'Updated ${difference.inMinutes}m ago';
    } else {
      return 'Updated just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${project.name} project, ${project.statusLabel}, ${project.shortDescription}',
      button: true,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project image
            _buildImage(),

            // Content section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (project.shortDescription.isNotEmpty)
                    Text(
                      project.shortDescription,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Metadata row (updated time + team info)
                  Text(
                    '${_formatUpdateTime(project.updatedAt)} · ${project.teamInfo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enter project button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onTap?.call(project.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Enter project'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (project.imageUrl.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: project.imageUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    // Parse color from hex string
    final colorHex = project.statusColorHex.replaceAll('#', '');
    final color = Color(int.parse('FF$colorHex', radix: 16));
    final backgroundColor = color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        project.statusLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
