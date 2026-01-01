import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/scan_data.dart';
import '../services/scan_session_manager.dart';
import '../../home/models/project.dart';
import '../../home/services/project_service.dart';
import '../../home/services/byo_project_service.dart';
import 'scanning_screen.dart';
import 'usdz_preview_screen.dart';

/// Screen showing list of scans for current session
/// Matches design from Requirements/ScanList2.jpg
class ScanListScreen extends StatefulWidget {
  final String? projectName;

  const ScanListScreen({
    super.key,
    this.projectName,
  });

  @override
  State<ScanListScreen> createState() => _ScanListScreenState();
}

class _ScanListScreenState extends State<ScanListScreen> {
  final ScanSessionManager _sessionManager = ScanSessionManager();
  final ProjectService _projectService = ProjectService();
  final BYOProjectService _byoProjectService = BYOProjectService();

  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final projects = await _projectService.fetchProjectsBySubscriptionStatus(
        'MANAGED_BY_BRING_YOUR_OWN_WORLDS_TIER',
      );
      setState(() {
        _projects = projects;
        _selectedProject = projects.isNotEmpty ? projects.first : null;
        _isLoadingProjects = false;
      });
    } catch (e) {
      print('❌ [SCAN_LIST] Error loading projects: $e');
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scans = _sessionManager.scans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Scans', style: TextStyle(fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Current Project section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Project header with ADD Project link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Project',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddProjectDialog,
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        label: Text(
                          'ADD Project',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Project picker dropdown
                  InkWell(
                    onTap: _isLoadingProjects ? null : _showProjectPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isLoadingProjects
                                  ? 'Loading projects...'
                                  : (_selectedProject?.name ?? 'No project selected'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Helper text
                  Text(
                    'Selecting a project filters the scan list below.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // Recent Scans header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // View all scans
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scan list
            Expanded(
              child: scans.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: scans.length,
                      itemBuilder: (context, index) {
                        final scan = scans[index];
                        return _buildScanCard(scan, index + 1);
                      },
                    ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Scan another room button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _scanAnotherRoom(),
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: const Text(
                        'Scan another room',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room stitching button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: scans.length >= 2 ? () => _roomStitching() : null,
                      icon: Icon(
                        Icons.folder_open,
                        size: 24,
                        color: scans.length >= 2
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      label: Text(
                        'Room stitching',
                        style: TextStyle(
                          fontSize: 18,
                          color: scans.length >= 2
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: scans.length >= 2
                            ? Colors.grey.shade800
                            : Colors.grey.shade900,
                        side: BorderSide(
                          color: scans.length >= 2
                              ? Colors.grey.shade700
                              : Colors.grey.shade800,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
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

  Widget _buildScanCard(ScanData scan, int scanNumber) {
    // Determine room name - use metadata room name or default to "Scan N"
    final roomName = scan.metadata?['roomName'] as String? ?? 'Scan $scanNumber';

    // Get project name from metadata or use default
    final projectName = scan.metadata?['projectName'] as String? ?? 'Current Project';

    // Get square footage from metadata if available
    final sqFt = scan.metadata?['squareFootage'] as double?;
    final sqFtText = sqFt != null ? ' • ${sqFt.toStringAsFixed(0)} sq ft' : '';

    // Status badge - for now all scans are "DONE" (green)
    // In future, drafts or incomplete scans can use "DRAFT" (orange)
    final isDraft = scan.metadata?['isDraft'] as bool? ?? false;
    final statusText = isDraft ? 'DRAFT' : 'DONE';
    final statusColor = isDraft ? Colors.orange : Colors.green;

    return InkWell(
      onTap: () => _viewUsdzPreview(scan),
      onLongPress: () => _showScanOptions(scan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade800, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail with status badge overlay
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.threed_rotation,
                      color: Colors.grey.shade600,
                      size: 48,
                    ),
                  ),
                ),
                // Status badge (bottom-left corner)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Scan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room name
                  Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Project name with folder icon
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 16,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        projectName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Timestamp and square footage
                  Text(
                    '${_formatRelativeDate(scan.capturedAt)}$sqFtText',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade600,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    File? worldFile;
    File? meshFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.blue.shade400),
              const SizedBox(width: 12),
              const Text('Create BYO Project', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text about auto-generation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade700.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Project name will be auto-generated from your uploaded GLB files.',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // World File Picker
                Text(
                  'World File (GLB) *',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['glb'],
                      withData: false,
                      withReadStream: true,
                    );

                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        worldFile = File(result.files.single.path!);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: worldFile != null
                          ? Colors.green.shade600
                          : Colors.grey.shade700,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          worldFile != null ? Icons.check_circle : Icons.upload_file,
                          color: worldFile != null
                            ? Colors.green.shade400
                            : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            worldFile != null
                              ? worldFile!.path.split('/').last
                              : 'Select world GLB file',
                            style: TextStyle(
                              color: worldFile != null
                                ? Colors.white
                                : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mesh File Picker
                Text(
                  'Mesh File (GLB) *',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['glb'],
                      withData: false,
                      withReadStream: true,
                    );

                    if (result != null && result.files.single.path != null) {
                      setDialogState(() {
                        meshFile = File(result.files.single.path!);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: meshFile != null
                          ? Colors.green.shade600
                          : Colors.grey.shade700,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          meshFile != null ? Icons.check_circle : Icons.upload_file,
                          color: meshFile != null
                            ? Colors.green.shade400
                            : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            meshFile != null
                              ? meshFile!.path.split('/').last
                              : 'Select mesh GLB file',
                            style: TextStyle(
                              color: meshFile != null
                                ? Colors.white
                                : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade700.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade400, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This will create a BYO (Bring Your Own) project with your GLB files.',
                          style: TextStyle(
                            color: Colors.blue.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (worldFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a world GLB file'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (meshFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a mesh GLB file'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                await _createNewProject(worldFile!, meshFile!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _createNewProject(
    File worldFile,
    File meshFile,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Creating BYO project...',
                  style: TextStyle(color: Colors.grey.shade300),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading GLB files',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );

      if (kDebugMode) {
        print('📦 [SCAN_LIST] Creating new BYO project');
        print('📦 [SCAN_LIST] World file: ${worldFile.path}');
        print('📦 [SCAN_LIST] Mesh file: ${meshFile.path}');
      }

      // Create the project using BYOProjectService
      final result = await _byoProjectService.createProjectFromOwnWorld(
        worldFile: worldFile,
        meshFile: meshFile,
      );

      if (kDebugMode) {
        print('✅ [SCAN_LIST] BYO Project created: ${result.projectId}');
        print('✅ [SCAN_LIST] World ID: ${result.worldId}');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Refresh project list to get the newly created project
      await _loadProjects();

      // Find and select the newly created project
      if (mounted) {
        final newProject = _projects.firstWhere(
          (p) => p.id == result.projectId,
          orElse: () => _projects.first,
        );

        setState(() {
          _selectedProject = newProject;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('BYO project created successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCAN_LIST] Error creating BYO project: $e');
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        final errorMessage = e.toString();
        String displayMessage = 'Failed to create BYO project';
        String? actionMessage;

        // Check if mutation doesn't exist on backend
        if (errorMessage.contains('VRonCreateProjectFromOwnWorld mutation not implemented')) {
          displayMessage = 'Backend not ready for BYO project creation';
          actionMessage = 'Please create projects via the web UI for now';
        } else if (errorMessage.contains('already exists') ||
                   errorMessage.contains('DUPLICATE_SLUG') ||
                   errorMessage.contains('duplicate')) {
          displayMessage = 'A project with this slug already exists';
          actionMessage = 'Please choose a different name';
        } else if (errorMessage.contains('Not authenticated') ||
                   errorMessage.contains('401')) {
          displayMessage = 'Authentication failed';
          actionMessage = 'Please log in again';
        } else {
          displayMessage = 'Failed to create project: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + '...' : errorMessage}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400),
                    const SizedBox(width: 12),
                    Expanded(child: Text(displayMessage)),
                  ],
                ),
                if (actionMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    actionMessage,
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _showProjectPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(color: Colors.grey.shade800, height: 1),
            ..._projects.map((project) => ListTile(
              leading: Icon(
                Icons.folder,
                color: Colors.blue.shade400,
              ),
              title: Text(
                project.name,
                style: const TextStyle(color: Colors.white),
              ),
              trailing: _selectedProject?.id == project.id
                  ? Icon(Icons.check, color: Colors.blue.shade400)
                  : null,
              onTap: () {
                setState(() {
                  _selectedProject = project;
                });
                Navigator.pop(context);
              },
            )),
            if (_projects.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No projects available',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showScanOptions(ScanData scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text('View USDZ', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _viewUsdzPreview(scan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_in_ar, color: Colors.white),
              title: const Text('View GLB', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _viewGlbPreview(scan);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteScan(scan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.threed_rotation,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to create your first 3D room',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return _formatRelativeDate(date);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _scanAnotherRoom() async {
    final result = await Navigator.of(context).push<ScanData>(
      MaterialPageRoute(
        builder: (context) => const ScanningScreen(),
      ),
    );

    if (result != null) {
      // Scan was already added to session in ScanningScreen
      // Just refresh the UI to show the updated list
      setState(() {});
    }
  }

  void _roomStitching() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room stitching feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _viewUsdzPreview(ScanData scan) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UsdzPreviewScreen(scanData: scan),
      ),
    );

    // Handle result if user chose to save from preview
    if (result != null && result is Map && result['action'] == 'save') {
      // User clicked "Ready to save" - could navigate to upload here
      print('📤 [SCAN_LIST] User wants to save scan: ${scan.id}');
    }
  }

  Future<void> _viewGlbPreview(ScanData scan) async {
    // Phase 1: Show USDZ preview (same as USDZ button)
    // GLB conversion will be implemented via server-side in Phase 2
    print('📱 [SCAN_LIST] GLBView: Showing USDZ in QuickLook (Phase 1)');

    await _viewUsdzPreview(scan);
  }

  void _confirmDeleteScan(ScanData scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: Text('Are you sure you want to delete this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteScan(scan);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteScan(ScanData scan) {
    // Remove scan immediately
    _sessionManager.removeScan(scan.id);
    setState(() {});

    // Hide any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show new snackbar with Undo and Close buttons
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Expanded(
            child: Text('Scan deleted'),
          ),
          TextButton(
            onPressed: () {
              // Restore scan
              _sessionManager.addScan(scan);
              setState(() {});
              // Hide snackbar immediately after undo
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text(
              'Undo',
              style: TextStyle(
                color: Colors.blue.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: Colors.white,
            onPressed: () {
              // Close snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.grey.shade800,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      // Ensure snackbar is fully dismissed
      if (mounted) {
        print('🔔 [SCAN_LIST] Snackbar closed: $reason');
      }
    });
  }
}
