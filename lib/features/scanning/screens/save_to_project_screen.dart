import 'package:flutter/material.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/models/conversion_result.dart';
import 'package:vronmobile2/features/scanning/services/scan_upload_service.dart';

/// Screen for selecting a project and uploading scan
///
/// User flow:
/// 1. User completes a scan in logged-in mode
/// 2. This screen shows list of user's projects
/// 3. User selects project to upload scan to
/// 4. Upload begins with progress indicator
/// 5. Shows conversion status until complete
class SaveToProjectScreen extends StatefulWidget {
  final ScanData scanData;

  const SaveToProjectScreen({super.key, required this.scanData});

  @override
  State<SaveToProjectScreen> createState() => _SaveToProjectScreenState();
}

class _SaveToProjectScreenState extends State<SaveToProjectScreen> {
  final ProjectService _projectService = ProjectService();
  final ScanUploadService _uploadService = ScanUploadService();

  List<Project>? _projects;
  bool _isLoadingProjects = false;
  String? _projectLoadError;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  ConversionStatus? _conversionStatus;
  ConversionResult? _uploadResult;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _projectLoadError = null;
    });

    try {
      final projects = await _projectService.fetchProjects();
      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _projectLoadError = 'Failed to load projects: $e';
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _uploadToProject(Project project) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _conversionStatus = null;
      _uploadError = null;
      _uploadResult = null;
    });

    try {
      print(
        '📤 [SAVE] Starting upload to project ${project.name} (${project.id})',
      );

      // Upload and poll for completion
      final result = await _uploadService.uploadAndPoll(
        scanData: widget.scanData,
        projectId: project.id,
        onProgress: (progress) {
          print('📊 [SAVE] Upload progress: ${(progress * 100).toInt()}%');
          if (mounted) {
            setState(() {
              _uploadProgress = progress;

              // Map progress to conversion status
              if (progress < 0.5) {
                _conversionStatus = ConversionStatus.pending;
              } else if (progress < 1.0) {
                _conversionStatus = ConversionStatus.inProgress;
              }
            });
          }
        },
      );

      print('✅ [SAVE] Upload complete! Status: ${result.conversionStatus}');

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadResult = result;
          _conversionStatus = result.conversionStatus;
          _uploadProgress = 1.0;
        });

        // Show success dialog
        if (result.isSuccess) {
          await _showSuccessDialog(project);
        } else if (result.conversionStatus == ConversionStatus.failed) {
          setState(() {
            _uploadError = result.error?.message ?? 'Conversion failed';
          });
        }
      }
    } catch (e) {
      print('❌ [SAVE] Upload error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadError = 'Upload failed: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_uploadError!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadToProject(project),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showSuccessDialog(Project project) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Upload Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Scan uploaded to ${project.name}'),
            const SizedBox(height: 8),
            Text(
              '📦 File size: ${(widget.scanData.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            if (_uploadResult?.glbUrl != null) ...[
              const SizedBox(height: 8),
              Text('🎉 GLB conversion complete'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(
                context,
              ).pop(_uploadResult); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Scan to Project'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scan info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(bottom: BorderSide(color: Colors.blue.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Format: ${widget.scanData.format.name.toUpperCase()}'),
                  Text(
                    'Size: ${(widget.scanData.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
                  ),
                  Text('Captured: ${_formatTime(widget.scanData.capturedAt)}'),
                ],
              ),
            ),

            // Upload progress (if uploading)
            if (_isUploading) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 12),
                    Text(
                      _getProgressMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error message (if any)
            if (_uploadError != null && !_isUploading) ...[
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploadError!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Project list
            Expanded(child: _buildProjectList()),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    if (_isLoadingProjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_projectLoadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _projectLoadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProjects,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_projects == null || _projects!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a project first to save scans',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _projects!.length,
      itemBuilder: (context, index) {
        final project = _projects![index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isUploading ? null : () => _uploadToProject(project),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Project image/icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: project.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(project.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: project.imageUrl.isEmpty
                      ? Icon(
                          Icons.folder,
                          color: Colors.blue.shade600,
                          size: 32,
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Project info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (project.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action indicator
                if (_isUploading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getProgressMessage() {
    if (_uploadProgress < 0.5) {
      return 'Uploading file... ${(_uploadProgress * 100).toInt()}%';
    } else if (_conversionStatus == ConversionStatus.inProgress) {
      return 'Converting USDZ to GLB... ${(_uploadProgress * 100).toInt()}%';
    } else if (_conversionStatus == ConversionStatus.completed) {
      return 'Conversion complete!';
    } else {
      return 'Processing... ${(_uploadProgress * 100).toInt()}%';
    }
  }
}
