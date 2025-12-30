import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/services/file_upload_service.dart';
import 'package:vronmobile2/features/scanning/services/scan_session_manager.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';

/// Screen for uploading existing GLB files from device storage
///
/// Supports User Story 2: Upload GLB File
/// - File picker integration
/// - Validation feedback
/// - Success confirmation
class FileUploadScreen extends StatefulWidget {
  final FileUploadService? uploadService;

  const FileUploadScreen({
    super.key,
    this.uploadService,
  });

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  late final FileUploadService _uploadService;
  final ScanSessionManager _sessionManager = ScanSessionManager();

  bool _isLoading = false;
  String? _errorMessage;
  ScanData? _uploadedScan;

  @override
  void initState() {
    super.initState();
    _uploadService = widget.uploadService ?? FileUploadService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload GLB File'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.upload_file,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Upload 3D Model',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Select a GLB file from your device to add to this project.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // File requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirement(Icons.check_circle_outline, 'Format: GLB'),
                    _buildRequirement(
                        Icons.check_circle_outline, 'Max size: 250 MB'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upload button
              if (!_isLoading && _uploadedScan == null)
                ElevatedButton.icon(
                  onPressed: _handleUploadTap,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Select GLB File'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing file...'),
                    ],
                  ),
                ),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // Success message with file details
              if (_uploadedScan != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade700, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'File uploaded successfully!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFileDetail(
                        'Filename',
                        _uploadedScan!.localPath.split('/').last,
                      ),
                      _buildFileDetail(
                        'Size',
                        _uploadService
                            .formatFileSize(_uploadedScan!.fileSizeBytes),
                      ),
                      _buildFileDetail(
                        'Format',
                        _uploadedScan!.format.name.toUpperCase(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],

              const Spacer(),

              // Alternative: scan with LiDAR
              if (_uploadedScan == null)
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Use LiDAR Scanner Instead'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.blue.shade900)),
        ],
      ),
    );
  }

  Widget _buildFileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUploadTap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ScanData? scanData = await _uploadService.pickAndValidateGLB();

      if (!mounted) return;

      if (scanData != null) {
        // Success - add to session
        _sessionManager.addScan(scanData);

        setState(() {
          _uploadedScan = scanData;
          _isLoading = false;
        });
      } else {
        // User cancelled or validation failed
        setState(() {
          _errorMessage = _determineErrorMessage();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _determineErrorMessage() {
    // Since pickAndValidateGLB returns null for both cancellation and validation failures,
    // we show a generic message. A more sophisticated implementation could track the reason.
    return 'File selection cancelled or validation failed. Please ensure the file is a valid GLB file under 250 MB.';
  }
}
