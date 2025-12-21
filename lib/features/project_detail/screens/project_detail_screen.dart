import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_action_buttons.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_header.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_info_section.dart';

/// Project detail screen displaying comprehensive project information
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<Project> _projectFuture;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _loadProject() {
    setState(() {
      _projectFuture = _projectService.fetchProjectDetail(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('projectDetail.title'.tr()),
        leading: const BackButton(),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProject();
          await _projectFuture;
        },
        child: FutureBuilder<Project>(
          future: _projectFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            } else if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            } else if (snapshot.hasData) {
              return _buildSuccessState(snapshot.data!);
            } else {
              return _buildErrorState('projectDetail.error'.tr());
            }
          },
        ),
      ),
    );
  }

  /// Build loading state with circular progress indicator
  Widget _buildLoadingState() {
    return Center(
      child: Semantics(
        label: 'projectDetail.loading'.tr(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'projectDetail.loading'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state with error message and retry button
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'projectDetail.error'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'projectDetail.retry'.tr(),
              child: ElevatedButton.icon(
                onPressed: _loadProject,
                icon: const Icon(Icons.refresh),
                label: Text('projectDetail.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build success state with project data display
  Widget _buildSuccessState(Project project) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header (image, name, status)
          ProjectHeader(
            imageUrl: project.imageUrl,
            name: project.name,
            isLive: project.isLive,
          ),

          const SizedBox(height: 24),

          // Project Info (description, subscription, dates)
          ProjectInfoSection(project: project),

          const SizedBox(height: 32),

          // Action Buttons (Project Data, Products)
          ProjectActionButtons(
            onProjectDataTap: () => _handleProjectDataTap(project),
            onProductsTap: () => _handleProductsTap(project),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _handleProjectDataTap(Project project) async {
    // Navigate to project data edit screen
    final result = await Navigator.pushNamed(
      context,
      '/project-data',
      arguments: {
        'projectId': project.id,
        'initialName': project.name,
        'initialDescription': project.description,
      },
    );

    // If changes were saved, refresh the project data
    if (result == true) {
      _loadProject();
    }
  }

  void _handleProductsTap(Project project) {
    // TODO: Navigate to products list screen (future feature)
    // For now, show placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to Products for ${project.name}')),
    );
  }
}
