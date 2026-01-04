import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/projects/widgets/project_detail_header.dart';
import 'package:vronmobile2/features/projects/widgets/project_viewer_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_data_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_products_tab.dart';
import 'package:vronmobile2/features/projects/widgets/project_tab_navigation.dart';
import 'package:vronmobile2/features/scanning/services/scanning_service.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';
import 'package:vronmobile2/features/scanning/services/combined_scan_service.dart';
import 'package:vronmobile2/features/scanning/services/export_service.dart';
import 'package:vronmobile2/features/scanning/widgets/combine_progress_dialog.dart';
import 'package:vronmobile2/features/scanning/widgets/export_combined_dialog.dart';
import 'package:vronmobile2/core/constants/app_strings.dart';

/// Project Detail Screen (UC10)
/// Displays comprehensive project information with tabs:
/// - Viewer: 3D/VR viewer placeholder
/// - Project data: Edit form for name and description
/// - Products: Navigation to products list
///
/// Feature 018: Combined Scan to NavMesh Workflow
/// - Shows scan list with combine button
/// - Triggers combined scan workflow
class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final ProjectService? projectService;
  final List<ScanData>? scans; // For testing - allows dependency injection
  final bool? hasGlbReady; // For testing - mock GLB ready state

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    this.projectService,
    this.scans,
    this.hasGlbReady,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late final ProjectService _projectService;
  late final ScanningService _scanningService;
  late final CombinedScanService _combinedScanService;
  late final ExportService _exportService;
  Project? _project;
  List<ScanData> _scans = [];
  CombinedScan? _combinedScan;
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isCombining = false;
  bool _isExporting = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _projectService = widget.projectService ?? ProjectService();
    _scanningService = ScanningService();
    _combinedScanService = CombinedScanService();
    _exportService = ExportService();

    // Use injected scans for testing, or load from service in production
    if (widget.scans != null) {
      _scans = widget.scans!;
    }

    // Mock GLB ready state for testing
    if (widget.hasGlbReady == true) {
      _combinedScan = CombinedScan(
        id: 'test-combined',
        projectId: widget.projectId,
        scanIds: _scans.map((s) => s.id).toList(),
        localCombinedPath: '/test/combined.usdz',
        combinedGlbLocalPath: '/test/combined.glb',
        status: CombinedScanStatus.glbReady,
        createdAt: DateTime.now(),
      );
    }

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
      floatingActionButton: _project != null
          ? Semantics(
              label: 'Start LiDAR scanning',
              hint: 'Launch native RoomPlan UI to capture 3D room scan',
              button: true,
              child: FloatingActionButton.extended(
                onPressed: _isScanning ? null : () => _navigateToScanning(context),
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.threed_rotation),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Room'),
                tooltip: AppStrings.startScanButton,
              ),
            )
          : null,
    );
  }

  Future<void> _navigateToScanning(BuildContext context) async {
    print('🎯 [PROJECT] Starting LiDAR scan...');

    // Check capability first
    final capability = await _scanningService.checkCapability();
    print('🎯 [PROJECT] Capability: ${capability.support}');

    if (!capability.isScanningSupportpported) {
      print('❌ [PROJECT] LiDAR not supported: ${capability.unsupportedReason}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(capability.unsupportedReason ?? 'LiDAR scanning not supported'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      print('🎯 [PROJECT] Launching native RoomPlan UI...');
      // This will launch the native iOS RoomPlan scanning UI (like in the screenshot)
      final scanData = await _scanningService.startScan(
        onProgress: (progress) {
          print('📊 [PROJECT] Scan progress: ${(progress * 100).toInt()}%');
        },
      );

      print('✅ [PROJECT] Scan completed: ${scanData.localPath}');

      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan completed! File saved: ${scanData.fileSizeBytes} bytes'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [PROJECT] Scan failed: $e');

      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Feature 018: Start combined scan workflow
  Future<void> _handleCombineScans() async {
    if (_scans.length < 2) return;

    final documentsDirectory = (await getApplicationDocumentsDirectory()).path;

    setState(() {
      _isCombining = true;
    });

    try {
      // Show progress dialog
      if (!mounted) return;
      _showCombineProgressDialog();

      // Start combination
      final combinedScan = await _combinedScanService.createCombinedScan(
        projectId: widget.projectId,
        scans: _scans,
        documentsDirectory: documentsDirectory,
        onStatusChange: (status) {
          setState(() {
            _combinedScan = _combinedScan?.copyWith(status: status) ??
                CombinedScan(
                  id: 'temp',
                  projectId: widget.projectId,
                  scanIds: _scans.map((s) => s.id).toList(),
                  localCombinedPath: '',
                  status: status,
                  createdAt: DateTime.now(),
                );
          });
        },
      );

      setState(() {
        _combinedScan = combinedScan;
        _isCombining = false;
      });

      // Close progress dialog and show Generate NavMesh button
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isCombining = false;
        _combinedScan = _combinedScan?.copyWith(
          status: CombinedScanStatus.failed,
          errorMessage: _formatErrorMessage(e),
        );
      });

      // Dialog will show error state with retry option
    }
  }

  /// Format error messages to be user-friendly
  String _formatErrorMessage(dynamic error) {
    final errorStr = error.toString();

    // Network errors
    if (errorStr.contains('SocketException') ||
        errorStr.contains('HandshakeException') ||
        errorStr.contains('Connection refused')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Timeout errors
    if (errorStr.contains('TimeoutException') || errorStr.contains('timed out')) {
      return 'Operation timed out. The server took too long to respond. Please try again.';
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

    // API errors
    if (errorStr.contains('Failed to create session') ||
        errorStr.contains('401') ||
        errorStr.contains('403')) {
      return 'Authentication failed. Please check your API credentials.';
    }

    if (errorStr.contains('500') || errorStr.contains('502') || errorStr.contains('503')) {
      return 'Server error. The service is temporarily unavailable. Please try again later.';
    }

    // Generic error with cleaned message
    return 'Failed to combine scans: ${errorStr.replaceAll('Exception:', '').trim()}';
  }

  /// Feature 018: Generate navmesh from combined GLB
  Future<void> _handleGenerateNavmesh() async {
    if (_combinedScan == null || !_combinedScan!.canGenerateNavmesh()) {
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

      // Close progress dialog and show export dialog
      if (mounted) {
        Navigator.of(context).pop();
        _showExportDialog();
      }
    } catch (e) {
      setState(() {
        _isCombining = false;
        _combinedScan = _combinedScan?.copyWith(
          status: CombinedScanStatus.failed,
          errorMessage: _formatErrorMessage(e),
        );
      });

      // Dialog will show error state with retry option
    }
  }

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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportCombinedDialog(
        combinedScan: _combinedScan!,
        onExportGlb: () => _handleExportGlb(),
        onExportNavmesh: () => _handleExportNavmesh(),
        onExportBoth: () => _handleExportBoth(),
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Feature 018: Export combined GLB file
  Future<void> _handleExportGlb() async {
    if (_combinedScan == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _exportService.exportGlb(
        combinedScan: _combinedScan!,
      );

      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GLB file shared'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Feature 018: Export navmesh file
  Future<void> _handleExportNavmesh() async {
    if (_combinedScan == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _exportService.exportNavmesh(
        combinedScan: _combinedScan!,
      );

      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NavMesh file shared'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Feature 018: Export both files as ZIP
  Future<void> _handleExportBoth() async {
    if (_combinedScan == null) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final result = await _exportService.exportBothAsZip(
        combinedScan: _combinedScan!,
      );

      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ZIP file shared'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

        // Feature 018: Combined Scan Section
        if (_scans.isNotEmpty) _buildCombineScanSection(),

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

  /// Feature 018: Build combine scan section with button
  Widget _buildCombineScanSection() {
    final validScans = _scans.where((scan) {
      return scan.positionX != null || scan.positionY != null;
    }).toList();

    final canCombine = validScans.length >= 2;
    final hasGlbReady = _combinedScan?.status == CombinedScanStatus.glbReady;
    final isCompleted = _combinedScan?.status == CombinedScanStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scan count info
          Row(
            children: [
              const Icon(Icons.threed_rotation, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_scans.length} Scans',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (validScans.length < _scans.length) ...[
                const SizedBox(width: 8),
                Text(
                  '(${validScans.length} positioned)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Combine button or Generate NavMesh button
          if (isCompleted)
            // Show export button when complete
            ElevatedButton.icon(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.folder_zip),
              label: const Text('Export Combined Scan'),
            )
          else if (hasGlbReady)
            // Show Generate NavMesh button when GLB is ready
            ElevatedButton.icon(
              onPressed: _isCombining ? null : _handleGenerateNavmesh,
              icon: const Icon(Icons.map),
              label: const Text('Generate NavMesh'),
            )
          else
            // Show Combine button initially
            Tooltip(
              message: canCombine
                  ? 'Combine positioned scans into single GLB file'
                  : 'Need at least 2 scans with positions to combine',
              child: ElevatedButton.icon(
                onPressed: canCombine && !_isCombining
                    ? _handleCombineScans
                    : null,
                icon: const Icon(Icons.view_in_ar),
                label: Text('Combine ${_scans.length} Scans to GLB'),
              ),
            ),
        ],
      ),
    );
  }
}
