import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_data.dart';
import '../services/blender_api_client.dart';
import '../models/blender_api_models.dart';
import 'scanning_screen.dart';
import 'glb_preview_screen.dart';

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
  double _conversionProgress = 0.0;
  String _conversionStatus = '';
  BlenderApiClient? _apiClient;

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
                  // Conversion progress indicator
                  if (_isConverting && _conversionProgress > 0) ...[
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _conversionProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _conversionStatus,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${(_conversionProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

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
    setState(() {
      _isConverting = true;
      _conversionProgress = 0.0;
      _conversionStatus = 'Initializing...';
    });

    String? sessionId;

    try {
      // Initialize BlenderAPI client
      _apiClient = BlenderApiClient();
      print('🔄 [BlenderAPI] Starting USDZ→GLB conversion');

      // Step 1: Create session (10% progress)
      setState(() {
        _conversionStatus = 'Creating session...';
        _conversionProgress = 0.1;
      });

      final session = await _apiClient!.createSession();
      sessionId = session.sessionId;
      print('✅ [BlenderAPI] Session created: $sessionId');

      // Step 2: Upload USDZ file (10% → 40% progress)
      setState(() {
        _conversionStatus = 'Uploading USDZ file...';
        _conversionProgress = 0.1;
      });

      final usdzFile = File(widget.scanData.localPath);
      final uploadResponse = await _apiClient!.uploadFile(
        sessionId: sessionId,
        file: usdzFile,
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              final uploadProgress = sent / total;
              _conversionProgress = 0.1 + (uploadProgress * 0.3); // 10% → 40%
            });
          }
        },
      );
      print('✅ [BlenderAPI] File uploaded: ${uploadResponse.filename}');

      // Step 3: Start conversion (40% progress)
      setState(() {
        _conversionStatus = 'Starting conversion...';
        _conversionProgress = 0.4;
      });

      final outputFilename = uploadResponse.filename.replaceAll('.usdz', '.glb');
      await _apiClient!.startConversion(
        sessionId: sessionId,
        inputFilename: uploadResponse.filename,
        outputFilename: outputFilename,
        conversionParams: ConversionParams(
          applyScale: false,
          mergeMeshes: false,
          targetScale: 1.0,
        ),
      );
      print('✅ [BlenderAPI] Conversion started');

      // Step 4: Poll status (40% → 80% progress)
      setState(() {
        _conversionStatus = 'Converting...';
      });

      BlenderApiStatus? finalStatus;
      await for (final status in _apiClient!.pollStatus(sessionId: sessionId)) {
        if (mounted) {
          setState(() {
            // Map BlenderAPI progress (0-100) to our progress (40% → 80%)
            _conversionProgress = 0.4 + (status.progress / 100 * 0.4);
            _conversionStatus = 'Converting... ${status.progress}%';
          });
          print('📊 [BlenderAPI] Progress: ${status.progress}%');
        }

        if (status.isCompleted) {
          finalStatus = status;
          break;
        }
      }

      if (finalStatus?.result == null) {
        throw Exception('Conversion completed but no result returned');
      }

      print('✅ [BlenderAPI] Conversion complete: ${finalStatus!.result!.filename}');

      // Step 5: Download GLB (80% → 100% progress)
      setState(() {
        _conversionStatus = 'Downloading GLB...';
        _conversionProgress = 0.8;
      });

      final glbFile = await _apiClient!.downloadFile(
        sessionId: sessionId,
        filename: finalStatus.result!.filename,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              final downloadProgress = received / total;
              _conversionProgress = 0.8 + (downloadProgress * 0.2); // 80% → 100%
            });
          }
        },
      );

      // Save GLB file permanently
      final documentsDir = await getApplicationDocumentsDirectory();
      final permanentPath = '${documentsDir.path}/${finalStatus.result!.filename}';
      final permanentFile = await glbFile.copy(permanentPath);
      print('✅ [BlenderAPI] GLB saved: $permanentPath');

      // Cleanup session
      if (sessionId != null) {
        await _apiClient!.deleteSession(sessionId);
        print('🧹 [BlenderAPI] Session cleaned up');
      }

      setState(() {
        _conversionStatus = 'Conversion complete!';
        _conversionProgress = 1.0;
      });

      // Show success and navigate to GLB preview
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Create ScanData for GLB
        final glbScanData = ScanData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          localPath: permanentPath,
          format: ScanFormat.glb,
          capturedAt: DateTime.now(),
          fileSizeBytes: finalStatus.result!.sizeBytes,
          status: ScanStatus.completed,
          metadata: {
            'converted_from': widget.scanData.id,
            'polygon_count': finalStatus.result!.polygonCount,
            'mesh_count': finalStatus.result!.meshCount,
            'material_count': finalStatus.result!.materialCount,
          },
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GlbPreviewScreen(scanData: glbScanData),
          ),
        );
      }
    } on BlenderApiException catch (e) {
      print('❌ [BlenderAPI] Error: $e');

      if (mounted) {
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
            content: Text(e.userMessage),
            actions: [
              if (e.statusCode != 401 && e.statusCode != 0)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _convertToGLB(); // Retry
                  },
                  child: const Text('Retry'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ [BlenderAPI] Unexpected error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _convertToGLB,
            ),
          ),
        );
      }
    } finally {
      // Cleanup session if still exists
      if (sessionId != null) {
        try {
          await _apiClient?.deleteSession(sessionId);
        } catch (e) {
          print('⚠️ [BlenderAPI] Failed to cleanup session: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isConverting = false;
          _conversionProgress = 0.0;
          _conversionStatus = '';
        });
      }

      _apiClient?.dispose();
      _apiClient = null;
    }
  }

  @override
  void dispose() {
    _apiClient?.dispose();
    super.dispose();
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
