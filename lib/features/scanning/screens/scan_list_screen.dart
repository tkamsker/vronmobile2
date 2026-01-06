import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_data.dart';
import '../models/combined_scan.dart';
import '../services/scan_session_manager.dart';
import '../services/blender_api_service.dart';
import '../services/combined_scan_service.dart';
import '../widgets/combine_progress_dialog.dart';
import '../../home/models/project.dart';
import '../../home/services/project_service.dart';
import '../../home/services/byo_project_service.dart';
import 'scanning_screen.dart';
import 'usdz_preview_screen.dart';
import 'room_stitching_screen.dart';
import 'room_layout_canvas_screen.dart';
import '../services/room_stitching_service.dart';
import '../services/retry_policy_service.dart';
import '../../../core/services/graphql_service.dart';
import '../models/room_layout.dart';

/// Screen showing list of scans for current session
/// Matches design from Requirements/ScanList2.jpg
class ScanListScreen extends StatefulWidget {
  final String? projectName;

  const ScanListScreen({super.key, this.projectName});

  @override
  State<ScanListScreen> createState() => _ScanListScreenState();
}

class _ScanListScreenState extends State<ScanListScreen> {
  final ScanSessionManager _sessionManager = ScanSessionManager();
  final ProjectService _projectService = ProjectService();
  final BYOProjectService _byoProjectService = BYOProjectService();
  final BlenderApiService _blenderApiService = BlenderApiService();
  final CombinedScanService _combinedScanService = CombinedScanService();

  List<Project> _projects = [];
  Project? _selectedProject;
  bool _isLoadingProjects = false;

  // Feature 018: Combined scan state
  CombinedScan? _combinedScan;
  bool _isCombining = false;
  double _uploadProgress = 0.0;

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'create_glb') {
                _handleCombineScans();
              } else if (value == 'generate_navmesh') {
                _handleGenerateNavmesh();
              }
            },
            itemBuilder: (BuildContext context) {
              final scans = _sessionManager.scans;
              // Create GLB: enabled when 2+ scans exist
              final canCombine = scans.length >= 2 && !_isCombining;
              // Generate NavMesh: enabled when combined GLB exists
              final hasGlbReady = _combinedScan?.status == CombinedScanStatus.glbReady;
              final canGenerateNavmesh = hasGlbReady && !_isCombining;

              return [
                PopupMenuItem<String>(
                  value: 'create_glb',
                  enabled: canCombine,
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        color: canCombine ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Create GLB',
                        style: TextStyle(
                          color: canCombine ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'generate_navmesh',
                  enabled: canGenerateNavmesh,
                  child: Row(
                    children: [
                      Icon(
                        Icons.map,
                        color: canGenerateNavmesh ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generate NavMesh',
                        style: TextStyle(
                          color: canGenerateNavmesh ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
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
                                  : (_selectedProject?.name ??
                                        'No project selected'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(Icons.expand_more, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Helper text
                  Text(
                    'Selecting a project filters the scan list below.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Recent Scans header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      onPressed: scans.length >= 2
                          ? () => _roomStitching()
                          : null,
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
    final roomName =
        scan.metadata?['roomName'] as String? ?? 'Scan $scanNumber';

    // Get project name from metadata or use default
    final projectName =
        scan.metadata?['projectName'] as String? ?? 'Current Project';

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                      Icon(Icons.folder, size: 16, color: Colors.blue.shade400),
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Chevron icon
            Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 28),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog() {
    // Check if we have combined GLB files available
    File? worldFile;
    File? meshFile;

    // If combined scan is complete, use those files as defaults
    if (_combinedScan?.status == CombinedScanStatus.completed) {
      if (_combinedScan!.combinedGlbLocalPath != null) {
        final glbFile = File(_combinedScan!.combinedGlbLocalPath!);
        if (glbFile.existsSync()) {
          worldFile = glbFile;
        }
      }
      if (_combinedScan!.localNavmeshPath != null) {
        final navmeshFile = File(_combinedScan!.localNavmeshPath!);
        if (navmeshFile.existsSync()) {
          meshFile = navmeshFile;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.add_circle, color: Colors.blue.shade400),
              const SizedBox(width: 12),
              const Text(
                'Create BYO Project',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info text about combined files or auto-generation
                if (worldFile != null && meshFile != null)
                  // Show success message when files are auto-populated
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Using combined GLB and NavMesh from your scans. You can change files if needed.',
                            style: TextStyle(
                              color: Colors.green.shade200,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Show info about auto-generation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade400,
                          size: 20,
                        ),
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
                          worldFile != null
                              ? Icons.check_circle
                              : Icons.upload_file,
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
                // Show info if using combined scan file
                if (worldFile != null &&
                    _combinedScan?.combinedGlbLocalPath == worldFile!.path) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Using combined GLB from scans',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                          meshFile != null
                              ? Icons.check_circle
                              : Icons.upload_file,
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
                // Show info if using navmesh file
                if (meshFile != null &&
                    _combinedScan?.localNavmeshPath == meshFile!.path) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Using navmesh from scans',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade700.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade400),
              ),
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

  Future<void> _createNewProject(File worldFile, File meshFile) async {
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
                Expanded(child: Text('BYO project created successfully!')),
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
        if (errorMessage.contains(
          'VRonCreateProjectFromOwnWorld mutation not implemented',
        )) {
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
          displayMessage =
              'Failed to create project: ${errorMessage.length > 100 ? '${errorMessage.substring(0, 100)}...' : errorMessage}';
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
                    style: TextStyle(color: Colors.red.shade200, fontSize: 12),
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

  /// Create a new project from a USDZ scan
  ///
  /// This method:
  /// 1. Checks if GLB already exists for this scan
  /// 2. If not, converts USDZ to GLB using Blender API
  /// 3. Creates a BYO project with both USDZ (world) and GLB (mesh)
  Future<void> _createProjectFromScan(ScanData scan) async {
    final usdzFile = File(scan.localPath);

    if (!await usdzFile.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('USDZ file not found.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('📦 [SCAN_LIST] Creating project from USDZ scan');
      print('📦 [SCAN_LIST] USDZ file: ${usdzFile.path}');
    }

    // Check if GLB already exists
    File? glbFile;
    if (scan.glbLocalPath != null) {
      glbFile = File(scan.glbLocalPath!);
      if (await glbFile.exists()) {
        if (kDebugMode) {
          print('✅ [SCAN_LIST] GLB already exists: ${scan.glbLocalPath}');
        }
        // GLB exists, proceed to create project
        await _createNewProject(usdzFile, glbFile);
        return;
      }
    }

    // GLB doesn't exist, need to convert first
    if (kDebugMode) {
      print('🔄 [SCAN_LIST] GLB not found, converting USDZ to GLB...');
    }

    // Show conversion dialog with progress
    await _showConversionDialog(scan, usdzFile);
  }

  /// Show conversion progress dialog and create project after completion
  Future<void> _showConversionDialog(ScanData scan, File usdzFile) async {
    // State for the dialog
    final dialogState = _ConversionDialogState();

    // Capture the setState callback for use in async operations
    void Function(VoidCallback)? updateDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Capture setDialogState for use in async callbacks
          updateDialog = setDialogState;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Row(
              children: [
                Icon(
                  dialogState.isConverting
                      ? Icons.sync
                      : (dialogState.errorMessage != null
                            ? Icons.error
                            : Icons.check_circle),
                  color: dialogState.isConverting
                      ? Colors.blue.shade400
                      : (dialogState.errorMessage != null
                            ? Colors.red.shade400
                            : Colors.green.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dialogState.isConverting
                        ? 'Converting to GLB'
                        : (dialogState.errorMessage != null
                              ? 'Conversion Failed'
                              : 'Conversion Complete'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dialogState.isConverting) ...[
                  LinearProgressIndicator(
                    value: dialogState.progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(dialogState.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dialogState.statusText,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
                  ),
                ] else if (dialogState.errorMessage != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dialogState.errorMessage!,
                    style: TextStyle(color: Colors.grey.shade300),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Creating project...',
                    style: TextStyle(color: Colors.grey.shade300),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            actions: dialogState.errorMessage != null
                ? [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ]
                : [],
          );
        },
      ),
    );

    try {
      // Start conversion
      final glbPath = await _blenderApiService.convertUsdzToGlb(
        usdzPath: usdzFile.path,
        onProgress: (p, status) {
          updateDialog?.call(() {
            dialogState.progress = p;
            dialogState.statusText = status;
          });
        },
      );

      if (kDebugMode) {
        print('✅ [SCAN_LIST] Conversion complete: $glbPath');
      }

      // Update scan data with GLB path
      final updatedScan = scan.copyWith(glbLocalPath: glbPath);
      _sessionManager.updateScan(updatedScan);

      // Update dialog state to show completion
      updateDialog?.call(() {
        dialogState.isConverting = false;
        dialogState.progress = 1.0;
      });

      // Small delay to show completion state
      await Future.delayed(const Duration(milliseconds: 500));

      // Create project with both files
      final glbFile = File(glbPath);
      await _createNewProject(usdzFile, glbFile);

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SCAN_LIST] Conversion failed: $e');
      }

      // Update dialog to show error
      updateDialog?.call(() {
        dialogState.isConverting = false;
        dialogState.errorMessage = e.toString();
      });
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
            ..._projects.map(
              (project) => ListTile(
                leading: Icon(Icons.folder, color: Colors.blue.shade400),
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
              ),
            ),
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
            // Create Project from Scan option (always available for USDZ scans)
            ListTile(
              leading: Icon(Icons.add_circle, color: Colors.green.shade400),
              title: Text(
                'Create Project from Scan',
                style: TextStyle(
                  color: Colors.green.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Backend will convert USDZ → GLB automatically',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _createProjectFromScan(scan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text(
                'View USDZ',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _viewUsdzPreview(scan);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text(
                'Delete',
                style: TextStyle(color: Colors.red.shade400),
              ),
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
          Icon(Icons.threed_rotation, size: 80, color: Colors.grey.shade300),
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
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
      MaterialPageRoute(builder: (context) => const ScanningScreen()),
    );

    if (result != null) {
      // Scan was already added to session in ScanningScreen
      // Just refresh the UI to show the updated list
      setState(() {});
    }
  }

  Future<void> _roomStitching() async {
    final scans = _sessionManager.scans;

    // Get projectId from scan metadata or use temporary session-based ID
    final projectId = scans.isNotEmpty
        ? (scans.first.metadata?['projectId'] as String? ??
              'temp-session-${DateTime.now().millisecondsSinceEpoch}')
        : 'temp-session-${DateTime.now().millisecondsSinceEpoch}';

    // Step 1: Show canvas layout screen for room arrangement
    final RoomLayout? layout = await Navigator.of(context).push<RoomLayout>(
      MaterialPageRoute(
        builder: (context) =>
            RoomLayoutCanvasScreen(scans: scans, projectId: projectId),
      ),
    );

    // If user canceled or went back, don't proceed to stitching
    if (layout == null || !mounted) {
      setState(() {});
      return;
    }

    // Step 2: Proceed to stitching with layout configuration
    final graphQLService = GraphQLService();
    final retryPolicyService = RetryPolicyService();
    final stitchingService = RoomStitchingService(
      graphQLService: graphQLService,
      retryPolicyService: retryPolicyService,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoomStitchingScreen(
          scans: scans,
          stitchingService: stitchingService,
          projectId: projectId,
          isGuestMode: false, // TODO: Check actual auth status
          roomLayout: layout, // Pass layout configuration
        ),
      ),
    );

    // Refresh the UI after returning from stitching screen
    setState(() {});
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
          const Expanded(child: Text('Scan deleted')),
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

  /// Feature 018: Start combined scan workflow
  Future<void> _handleCombineScans() async {
    final scans = _sessionManager.scans;

    if (scans.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 2 scans to combine'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final documentsDirectory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      _isCombining = true;
    });

    try {
      // Show progress dialog
      if (!mounted) return;
      _showCombineProgressDialog();

      // Ensure all scans have position data - assign default positions if missing
      final scansWithPositions = scans.map((scan) {
        if (scan.positionX == null && scan.positionY == null) {
          // Assign default positions in a simple grid layout
          final index = scans.indexOf(scan);
          return scan.copyWith(
            positionX: (index % 3) * 100.0, // Simple grid: 3 columns
            positionY: (index ~/ 3) * 100.0, // Simple grid: rows
            rotationDegrees: 0.0,
            scaleFactor: 1.0,
          );
        }
        return scan;
      }).toList();

      // Start combination
      final combinedScan = await _combinedScanService.createCombinedScan(
        projectId: _selectedProject!.id,
        scans: scansWithPositions,
        documentsDirectory: documentsDirectory,
        onStatusChange: (status) {
          setState(() {
            _combinedScan = _combinedScan?.copyWith(status: status) ??
                CombinedScan(
                  id: 'temp',
                  projectId: _selectedProject!.id,
                  scanIds: scans.map((s) => s.id).toList(),
                  localCombinedPath: '',
                  status: status,
                  createdAt: DateTime.now(),
                );
          });
        },
      );

      print('✅ Combined USDZ created: ${combinedScan.id}');
      print('🔄 Starting GLB conversion via BlenderAPI...');

      // Update status to uploading
      setState(() {
        _combinedScan = combinedScan.copyWith(
          status: CombinedScanStatus.uploadingUsdz,
        );
      });

      // Convert combined USDZ to GLB using BlenderAPI
      final glbPath = await _blenderApiService.convertUsdzToGlb(
        usdzPath: combinedScan.localCombinedPath,
        onProgress: (progress, statusText) {
          // Update progress and status based on stage
          setState(() {
            _uploadProgress = progress;
            // Switch to processingGlb status when upload is complete
            if (progress > 0.5 && _combinedScan?.status == CombinedScanStatus.uploadingUsdz) {
              _combinedScan = _combinedScan?.copyWith(
                status: CombinedScanStatus.processingGlb,
              );
            }
          });
          print('📊 Conversion progress: ${(progress * 100).toInt()}% - $statusText');
        },
      );

      print('✅ GLB conversion complete: $glbPath');

      // Update combined scan with GLB path and mark as ready
      setState(() {
        _combinedScan = combinedScan.copyWith(
          combinedGlbLocalPath: glbPath,
          status: CombinedScanStatus.glbReady,
        );
        _isCombining = false;
      });

      print('✅ Combined scan ready for NavMesh generation!');
    } catch (e) {
      print('❌ Failed to combine scans: $e');

      setState(() {
        _isCombining = false;
        _combinedScan = _combinedScan?.copyWith(
          status: CombinedScanStatus.failed,
          errorMessage: _formatCombineError(e),
        );
      });
    }
  }

  /// Format error messages for better user experience
  String _formatCombineError(dynamic error) {
    final errorStr = error.toString();

    // Position validation errors
    if (errorStr.contains('position data')) {
      return 'Scans need to be arranged on canvas first. Use "Room stitching" to position scans.';
    }

    // File system errors
    if (errorStr.contains('FileSystemException') ||
        errorStr.contains('No such file or directory')) {
      return 'File access error. One or more scan files could not be read.';
    }

    // Platform errors (iOS native)
    if (errorStr.contains('PlatformException')) {
      if (errorStr.contains('INVALID_GEOMETRY')) {
        return 'Invalid scan geometry. One or more scans contain invalid 3D data.';
      }
      return 'Platform error: ${errorStr.replaceAll('PlatformException', '').trim()}';
    }

    // Generic error with cleaned message
    return 'Failed to combine scans: ${errorStr.replaceAll('Exception:', '').trim()}';
  }

  /// Feature 018: Generate navmesh from combined GLB
  Future<void> _handleGenerateNavmesh() async {
    if (_combinedScan == null || !_combinedScan!.canGenerateNavmesh()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GLB must be ready before generating navmesh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final documentsDirectory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      _isCombining = true;
    });

    try {
      // Show progress dialog
      if (!mounted) return;
      _showCombineProgressDialog();

      // Start navmesh generation
      final updatedScan = await _combinedScanService.generateNavmesh(
        combinedScan: _combinedScan!,
        documentsDirectory: documentsDirectory,
        onStatusChange: (status) {
          setState(() {
            _combinedScan = _combinedScan?.copyWith(status: status);
          });
        },
      );

      setState(() {
        _combinedScan = updatedScan;
        _isCombining = false;
      });

      print('✅ NavMesh generation complete!');
    } catch (e) {
      print('❌ Failed to generate navmesh: $e');

      setState(() {
        _isCombining = false;
        _combinedScan = _combinedScan?.copyWith(
          status: CombinedScanStatus.failed,
          errorMessage: 'NavMesh generation failed: $e',
        );
      });
    }
  }

  /// Show combine progress dialog
  void _showCombineProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<void>(
        // Rebuild dialog when state changes
        stream: Stream.periodic(const Duration(milliseconds: 100)),
        builder: (context, snapshot) {
          if (_combinedScan == null) {
            return const SizedBox();
          }

          return CombineProgressDialog(
            combinedScan: _combinedScan!,
            uploadProgress: _uploadProgress,
            onCancel: () {
              Navigator.of(context).pop();
              setState(() {
                _isCombining = false;
              });
            },
            onClose: () {
              Navigator.of(context).pop();
            },
            onRetry: () {
              Navigator.of(context).pop();
              // Determine which operation to retry based on current status
              if (_combinedScan!.status == CombinedScanStatus.failed) {
                // Check which stage failed to determine retry action
                if (_combinedScan!.combinedGlbLocalPath != null) {
                  // GLB exists, so navmesh generation failed - retry navmesh
                  _handleGenerateNavmesh();
                } else {
                  // No GLB, so combination failed - retry combination
                  _handleCombineScans();
                }
              }
            },
          );
        },
      ),
    );
  }
}

/// State holder for conversion dialog
class _ConversionDialogState {
  double progress = 0.0;
  String statusText = 'Starting conversion...';
  bool isConverting = true;
  String? errorMessage;
}
