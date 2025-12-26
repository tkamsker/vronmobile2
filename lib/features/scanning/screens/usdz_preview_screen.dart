import 'package:flutter/material.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';
import '../models/scan_data.dart';
import 'scanning_screen.dart';

/// USDZ Preview Screen (Requirements/USDZ_Preview.jpg)
///
/// Shows 3D preview of USDZ scan with:
/// - Room dimensions (if available in metadata)
/// - "Convert to GLB" button to trigger local conversion
/// - "Ready to save" button to proceed with upload
class UsdzPreviewScreen extends StatefulWidget {
  final ScanData scanData;

  const UsdzPreviewScreen({
    super.key,
    required this.scanData,
  });

  @override
  State<UsdzPreviewScreen> createState() => _UsdzPreviewScreenState();
}

class _UsdzPreviewScreenState extends State<UsdzPreviewScreen> {
  bool _isConverting = false;

  @override
  Widget build(BuildContext context) {
    // Extract dimensions from metadata if available
    final metadata = widget.scanData.metadata;
    final width = metadata?['width'] as double?;
    final height = metadata?['height'] as double?;

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
      print('🔍 [USDZ] Opening AR viewer for: ${widget.scanData.localPath}');

      // Use native AR viewer (iOS QuickLook)
      await NativeArViewer.launchAR(widget.scanData.localPath);

      print('✅ [USDZ] AR viewer launched successfully');
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
    // Phase 1: Show info dialog about server-side conversion
    // On-device conversion requires USD SDK integration (4-8 week project)
    print('ℹ️ [USDZ] Convert to GLB: Showing Phase 2 info dialog');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('GLB Conversion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'On-device USDZ→GLB conversion is not supported due to iOS framework limitations.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Available options:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• View USDZ in native AR viewer (tap "View in AR")'),
            const SizedBox(height: 4),
            const Text('• Save to project for server-side GLB conversion'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Server-side conversion will be available in the next update.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
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
