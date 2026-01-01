import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_data.dart';
import 'scanning_screen.dart';

/// GLB Preview Screen (Requirements/PreviewGLB.jpg)
///
/// Shows 3D preview of GLB scan with:
/// - Interactive 3D model viewer
/// - Room dimensions (if available)
/// - "Save Scan" button
/// - "Scan Another Room" and "Scan Areas" buttons
class GlbPreviewScreen extends StatefulWidget {
  final ScanData scanData;

  const GlbPreviewScreen({super.key, required this.scanData});

  @override
  State<GlbPreviewScreen> createState() => _GlbPreviewScreenState();
}

class _GlbPreviewScreenState extends State<GlbPreviewScreen> {
  @override
  Widget build(BuildContext context) {
    // Extract dimensions from metadata if available
    final metadata = widget.scanData.metadata;
    final width = metadata?['width'] as double?;
    final height = metadata?['height'] as double?;

    // Determine which file to show (glbLocalPath or localPath if format is already GLB)
    final String glbPath =
        widget.scanData.glbLocalPath ??
        (widget.scanData.format == ScanFormat.glb
            ? widget.scanData.localPath
            : '');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan Preview', style: TextStyle(fontSize: 20)),
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
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Model Viewer
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: glbPath.isNotEmpty
                      ? ModelViewer(
                          src: 'file://$glbPath',
                          alt: '3D room scan',
                          ar: false,
                          autoRotate: true,
                          cameraControls: true,
                          backgroundColor: const Color(0xFFEEEEEE),
                        )
                      : Center(
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
                                'No GLB file available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Convert USDZ to GLB first',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            // Dimensions info
            if (width != null && height != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Width: ${_formatDimension(width)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Height: ${_formatDimension(height)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Save Scan button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveScan(),
                      icon: const Icon(Icons.save, size: 24),
                      label: const Text(
                        'Save Scan',
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

                  // Scan Another Room button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _scanAnotherRoom(),
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Scan Another Room',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade200, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Scan Areas button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _viewScanAreas(),
                      icon: const Icon(Icons.list, size: 24),
                      label: const Text(
                        'Scan Areas',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade200, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  // Debug Export GLB button (only shown in debug mode)
                  if (kDebugMode && glbPath.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _exportGlb(),
                        icon: const Icon(Icons.ios_share, size: 24),
                        label: const Text(
                          'Export GLB (Debug)',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade600,
                          side: BorderSide(
                            color: Colors.orange.shade200,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDimension(double value) {
    if (value < 100) {
      return '${value.toStringAsFixed(1)}cm';
    } else {
      return '${(value / 100).toStringAsFixed(2)}m';
    }
  }

  void _saveToProject() {
    // Navigate to SaveToProjectScreen or return with "save" action
    Navigator.of(context).pop({'action': 'save', 'scan': widget.scanData});
  }

  void _saveScan() {
    // Save scan locally (already in session)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan saved to session'),
        duration: Duration(seconds: 2),
      ),
    );

    // Return to scan list
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _scanAnotherRoom() async {
    // Navigate to ScanningScreen to start new scan
    final result = await Navigator.of(context).push<ScanData>(
      MaterialPageRoute(builder: (context) => const ScanningScreen()),
    );

    if (result != null && mounted) {
      // New scan completed, return to scan list
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _viewScanAreas() {
    // Return to scan list (AreaScan.jpg)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _exportGlb() async {
    // Get GLB file path
    final String glbPath =
        widget.scanData.glbLocalPath ??
        (widget.scanData.format == ScanFormat.glb
            ? widget.scanData.localPath
            : '');

    if (glbPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No GLB file available to export'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      print('📤 [GLB_PREVIEW] Exporting GLB file: $glbPath');

      // Check if file exists
      final file = File(glbPath);
      if (!await file.exists()) {
        throw Exception('GLB file not found at path: $glbPath');
      }

      // Get file size
      final fileSize = await file.length();
      print(
        '📦 [GLB_PREVIEW] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(glbPath)],
        text: 'Exported GLB scan',
        subject: 'Room Scan - ${DateTime.now().toString().split('.')[0]}',
      );

      print('✅ [GLB_PREVIEW] Export result: ${result.status}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GLB file exported: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [GLB_PREVIEW] Export failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
