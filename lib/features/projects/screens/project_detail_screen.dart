import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/projects/widgets/project_detail_header.dart';
import 'package:vronmobile2/features/projects/widgets/project_viewer_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_data_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_products_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_tab_navigation.dart';

/// Project Detail Screen (UC10)
/// Displays comprehensive project information with tabs:
/// - Viewer: 3D/VR viewer placeholder
/// - Project data: Edit form for name and description
/// - Products: Navigation to products list
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final ProjectService? projectService;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectService,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectService _projectService;
  Project? _project;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? ProjectService();
    _loadProjectDetail();
  }

  Future<void> _loadProjectDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = await _projectService.getProjectDetail(widget.projectId);
      setState(() {
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSaveProjectData(String name, String description) async {
    if (_project == null) return;

    try {
      // Call updateProject mutation
      await _projectService.updateProject(
        projectId: _project!.id,
        name: name,
        slug: _project!.slug,
        description: description,
      );

      // Automatic refresh after successful save (per clarification #1: last-write-wins)
      // Reload project to show any server-side changes or concurrent modifications
      await _loadProjectDetail();
    } catch (e) {
      // Error is already handled by ProjectDataTab
      // Just rethrow so the tab can display the error
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProjectDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_project == null) {
      return const Center(
        child: Text('Project not found'),
      );
    }

    return Column(
      children: [
        ProjectDetailHeader(project: _project!),
        Expanded(
          child: ProjectTabNavigation(
            tabViews: [
              ProjectViewerTab(project: _project!),
              ProjectDataTab(
                project: _project!,
                onSave: _handleSaveProjectData,
              ),
              ProjectProductsTab(project: _project!),
            ],
          ),
        ),
      ],
    );
  }
}
