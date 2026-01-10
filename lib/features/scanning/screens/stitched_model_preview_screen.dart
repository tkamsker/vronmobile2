import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vronmobile2/features/scanning/models/stitched_model.dart';

/// Screen for previewing a completed stitched 3D model
///
/// Features:
/// - 3D model viewer with AR support
/// - Metadata display (file size, polygon count, date)
/// - Export to share (GLB file)
/// - View in AR (iOS only)
/// - Save to project (requires authentication)
class StitchedModelPreviewScreen extends StatefulWidget {
  final StitchedModel stitchedModel;
  final bool? isIOS;
  final bool isGuestMode;

  const StitchedModelPreviewScreen({
    super.key,
    required this.stitchedModel,
    this.isIOS,
    this.isGuestMode = false,
  });

  @override
  State<StitchedModelPreviewScreen> createState() =>
      _StitchedModelPreviewScreenState();
}

class _StitchedModelPreviewScreenState
    extends State<StitchedModelPreviewScreen> {
  bool _isExporting = false;
  bool _fileExists = true;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  /// Checks if the model file exists on disk
  Future<void> _checkFileExists() async {
    final file = File(widget.stitchedModel.localPath);
    final exists = await file.exists();
    if (mounted) {
      setState(() {
        _fileExists = exists;
      });
    }
  }

  /// Formats file size in MB
  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 100) {
      return '${mb.round()} MB';
    } else if (mb >= 10) {
      return '${mb.round()} MB';
    } else {
      return '${mb.toStringAsFixed(1)} MB';
    }
  }

  /// Formats date for display
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats number with thousands separator
  String _formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Handles "View in AR" button tap (iOS only)
  Future<void> _viewInAR() async {
    if (!(widget.isIOS ?? Platform.isIOS)) {
      return;
    }

    try {
      final file = File(widget.stitchedModel.localPath);
      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorSnackBar('File not found');
        return;
      }

      // Launch AR Quick Look using url_launcher
      final uri = Uri.file(widget.stitchedModel.localPath);
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        if (!mounted) return;
        _showErrorSnackBar(
            'AR Quick Look is only available on iOS devices');
        return;
      }

      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to launch AR Quick Look: ${e.toString()}');
    }
  }

  /// Handles "Export GLB" button tap
  Future<void> _exportGLB() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final file = File(widget.stitchedModel.localPath);
      if (!await file.exists()) {
        if (!mounted) return;
        _showErrorSnackBar('File not found');
        return;
      }

      // Share the file using share_plus
      final message = 'Stitched model: ${widget.stitchedModel.displayName}';
      await Share.shareXFiles(
        [XFile(widget.stitchedModel.localPath)],
        text: message,
      );

      if (!mounted) return;

      // Announce completion for screen readers
      _announceToScreenReader('GLB file exported successfully');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to export: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  /// Handles "Save to Project" button tap
  Future<void> _saveToProject() async {
    // Guest mode check
    if (widget.isGuestMode) {
      _showAuthRequiredDialog();
      return;
    }

    // Show project selection dialog
    _showProjectSelectionDialog();
  }

  /// Shows authentication required dialog for guest users
  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Required'),
        content: const Text(
          'Please create an account or sign in to save models to projects.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows project selection dialog
  void _showProjectSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Project'),
        content: const Text(
          'Project selection and upload functionality will be implemented in a future release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  /// Announces message to screen readers
  void _announceToScreenReader(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stitched Model'),
      ),
      body: _fileExists ? _buildContent() : _buildFileNotFoundError(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3D Model Viewer
          _buildModelViewer(),

          // Metadata Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room names title
                Text(
                  widget.stitchedModel.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // File size
                _buildMetadataRow(
                  icon: Icons.insert_drive_file,
                  label: 'File size',
                  value: _formatFileSize(widget.stitchedModel.fileSizeBytes),
                  semanticLabel:
                      'File size ${_formatFileSize(widget.stitchedModel.fileSizeBytes).replaceAll('MB', 'megabytes')}',
                ),

                // Creation date
                _buildMetadataRow(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: _formatDate(widget.stitchedModel.createdAt),
                  semanticLabel: null,
                ),

                // Polygon count (if available)
                if (widget.stitchedModel.metadata?['polygonCount'] != null)
                  _buildMetadataRow(
                    icon: Icons.architecture,
                    label: 'Polygons',
                    value: _formatNumber(
                        widget.stitchedModel.metadata!['polygonCount'] as int),
                    semanticLabel:
                        '${_formatNumber(widget.stitchedModel.metadata!['polygonCount'] as int)} polygons',
                  ),

                // Texture count (if available)
                if (widget.stitchedModel.metadata?['textureCount'] != null)
                  _buildMetadataRow(
                    icon: Icons.texture,
                    label: 'Textures',
                    value: '${widget.stitchedModel.metadata!['textureCount']}',
                    semanticLabel: null,
                  ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // View in AR button (iOS only)
                Semantics(
                  label: 'View stitched model in augmented reality',
                  button: true,
                  enabled: widget.isIOS ?? Platform.isIOS,
                  child: ElevatedButton.icon(
                    onPressed: (widget.isIOS ?? Platform.isIOS) ? _viewInAR : null,
                    icon: const Icon(Icons.view_in_ar),
                    label: const Text('View in AR'),
                  ),
                ),
                const SizedBox(height: 12),

                // Export GLB button
                Semantics(
                  label: 'Export GLB file to share with others',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportGLB,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share),
                    label: const Text('Export GLB'),
                  ),
                ),
                const SizedBox(height: 12),

                // Save to Project button
                Semantics(
                  label: 'Save stitched model to project',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: _saveToProject,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Save to Project'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelViewer() {
    return Semantics(
      label: '3D model viewer showing stitched room model',
      child: SizedBox(
        height: 400,
        child: ModelViewer(
          src: 'file://${widget.stitchedModel.localPath}',
          ar: true,
          cameraControls: true,
          autoRotate: true,
          backgroundColor: const Color(0xFFEEEEEE),
        ),
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
    String? semanticLabel,
  }) {
    final content = Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: content,
    );
  }

  Widget _buildFileNotFoundError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'File not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The stitched model file could not be found.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkFileExists,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
