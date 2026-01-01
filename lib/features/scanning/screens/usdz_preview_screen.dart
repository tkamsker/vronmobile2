import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_data.dart';
import '../models/conversion_result.dart';
import '../services/scan_upload_service.dart';
import 'scanning_screen.dart';

/// USDZ Preview Screen (Requirements/USDZ_Preview.jpg)
///
/// Shows 3D preview of USDZ scan with:
/// - Room dimensions (if available in metadata)
/// - "Convert to GLB" button to trigger local conversion
/// - "Ready to save" button to proceed with upload
class UsdzPreviewScreen extends StatefulWidget {
  final ScanData scanData;
  final String? projectId;
  final ScanUploadService? uploadService;

  const UsdzPreviewScreen({
    super.key,
    required this.scanData,
    this.projectId,
    this.uploadService,
  });

  @override
  State<UsdzPreviewScreen> createState() => _UsdzPreviewScreenState();
}

class _UsdzPreviewScreenState extends State<UsdzPreviewScreen> {
  bool _isConverting = false;
  late final ScanUploadService _uploadService;
  ConversionResult? _conversionResult;

  @override
  void initState() {
    super.initState();
    _uploadService = widget.uploadService ?? ScanUploadService();
  }

  @override
  Widget build(BuildContext context) {
    // Extract dimensions from metadata if available
    final metadata = widget.scanData.metadata;
    final rawWidth = metadata?['width'] as double?;
    final rawHeight = metadata?['height'] as double?;

    // Guard against NaN values that can cause CoreGraphics errors
    final width = (rawWidth != null && !rawWidth.isNaN && rawWidth.isFinite) ? rawWidth : null;
    final height = (rawHeight != null && !rawHeight.isNaN && rawHeight.isFinite) ? rawHeight : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('USDZ Preview', style: TextStyle(fontSize: 20)),
            Text(
              'Post view of your current scan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _saveToProject(),
            child: const Text(
              'Ready to save',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Preview Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // 3D Preview placeholder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.threed_rotation,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'USDZ 3D Model',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (width != null && height != null) ...[
                            Text(
                              'Width ${_formatDimension(width)} • Height ${_formatDimension(height)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _viewInAR(),
                            icon: const Icon(Icons.view_in_ar),
                            label: const Text('View in AR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3D rotate icon (bottom right)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.threed_rotation,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                      ),
                    ),

                    // Dimensions overlay
                    if (width != null)
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'Width ${_formatDimension(width)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              backgroundColor: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    if (height != null)
                      Positioned(
                        right: 80,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              'Height ${_formatDimension(height)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                backgroundColor: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Convert to GLB button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isConverting ? null : () => _convertToGLB(),
                      icon: _isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.transform, size: 24),
                      label: Text(
                        _isConverting ? 'Converting...' : 'Convert to GLB',
                        style: const TextStyle(fontSize: 18),
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

                  // Scan Another Room button
                  TextButton.icon(
                    onPressed: () => _scanAnotherRoom(),
                    icon: const Icon(Icons.add),
                    label: const Text('Scan Another Room'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanAnotherRoom(),
        child: const Icon(Icons.threed_rotation),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _formatDimension(double value) {
    if (value < 100) {
      return '${value.toStringAsFixed(1)}cm';
    } else {
      return '${(value / 100).toStringAsFixed(2)}m';
    }
  }

  Future<void> _viewInAR() async {
    try {
      print('🔍 [USDZ] Opening AR viewer in object mode for: ${widget.scanData.localPath}');

      if (Platform.isIOS) {
        // Use url_launcher with URL fragment to start in object mode
        // #allowsContentScaling=0 tells AR Quick Look to start in object viewing mode
        final file = File(widget.scanData.localPath);
        if (!await file.exists()) {
          throw Exception('USDZ file not found');
        }

        final uri = Uri.file(
          widget.scanData.localPath,
          windows: false,
        ).replace(fragment: 'allowsContentScaling=0');

        if (!await canLaunchUrl(uri)) {
          // Fallback to native_ar_viewer if url_launcher doesn't work
          await NativeArViewer.launchAR(widget.scanData.localPath);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        print('✅ [USDZ] AR viewer launched successfully in object mode');
      } else {
        // Android fallback (though LiDAR is iOS-only)
        await NativeArViewer.launchAR(widget.scanData.localPath);
      }
    } catch (e) {
      print('❌ [USDZ] Failed to launch AR viewer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open AR viewer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _convertToGLB() async {
    print('🔄 [USDZ] Starting backend GLB conversion');

    // Check if projectId is available
    if (widget.projectId == null || widget.projectId!.isEmpty) {
      _showProjectRequiredDialog();
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      // Step 1: Upload USDZ to backend
      print('📤 [USDZ] Uploading to backend for conversion...');
      final uploadResult = await _uploadService.uploadScan(
        scanData: widget.scanData,
        projectId: widget.projectId!,
        onProgress: (progress) {
          print('📊 [USDZ] Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (!uploadResult.success) {
        throw Exception(uploadResult.message ?? 'Upload failed');
      }

      final scanId = uploadResult.scanId;
      if (scanId == null) {
        throw Exception('No scan ID returned from upload');
      }

      print('✅ [USDZ] Upload complete. Scan ID: $scanId');
      print('🔄 [USDZ] Polling conversion status...');

      // Step 2: Poll for conversion status
      final conversionResult = await _uploadService.pollConversionStatus(
        scanId: scanId,
        onStatusChange: (status) {
          print('📊 [USDZ] Conversion status: ${status.name}');
        },
      );

      setState(() {
        _conversionResult = conversionResult;
        _isConverting = false;
      });

      if (!mounted) return;

      // Step 3: Show result
      if (conversionResult.isSuccess && conversionResult.glbUrl != null) {
        _showConversionSuccessDialog(conversionResult.glbUrl!);
      } else {
        final errorMessage = conversionResult.error?.message ??
                            conversionResult.message ??
                            'Conversion failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [USDZ] Conversion failed: $e');
      setState(() {
        _isConverting = false;
      });

      if (mounted) {
        _showConversionErrorDialog(e.toString());
      }
    }
  }

  void _showProjectRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Project Required'),
          ],
        ),
        content: const Text(
          'To convert this USDZ file to GLB format, please save it to a project first. '
          'The conversion will be processed on our servers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveToProject();
            },
            child: const Text('Save to Project'),
          ),
        ],
      ),
    );
  }

  void _showConversionSuccessDialog(String glbUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Conversion Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your USDZ file has been successfully converted to GLB format!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GLB file is ready',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The GLB file is now available in your project and can be viewed in the web viewer.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  void _showConversionErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Conversion Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The GLB conversion failed with the following error:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can still save the USDZ file to your project and try conversion again later.',
              style: TextStyle(fontSize: 12),
            ),
          ],
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

  void _saveToProject() {
    // Navigate to SaveToProjectScreen or return with "save" action
    Navigator.of(context).pop({'action': 'save', 'scan': widget.scanData});
  }

  Future<void> _scanAnotherRoom() async {
    // Navigate to ScanningScreen to start new scan
    final result = await Navigator.of(context).push<ScanData>(
      MaterialPageRoute(
        builder: (context) => const ScanningScreen(),
      ),
    );

    if (result != null && mounted) {
      // New scan completed, return to scan list
      Navigator.of(context).pop(result);
    }
  }
}
