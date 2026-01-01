import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_ar_viewer/native_ar_viewer.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_data.dart';
import '../services/blender_api_client.dart';
import '../services/scan_session_manager.dart';
import '../models/blender_api_models.dart';
import 'scanning_screen.dart';
import 'glb_preview_screen.dart';
import 'session_diagnostics_screen.dart';

/// USDZ Preview Screen (Requirements/USDZ_Preview.jpg)
///
/// Shows 3D preview of USDZ scan with:
/// - Room dimensions (if available in metadata)
/// - "Convert to GLB" button to trigger local conversion
/// - "Ready to save" button to proceed with upload
class UsdzPreviewScreen extends StatefulWidget {
  final ScanData scanData;

  const UsdzPreviewScreen({super.key, required this.scanData});

  @override
  State<UsdzPreviewScreen> createState() => _UsdzPreviewScreenState();
}

class _UsdzPreviewScreenState extends State<UsdzPreviewScreen> {
  bool _isConverting = false;
  double _conversionProgress = 0.0;
  String _conversionStatus = '';
  BlenderApiClient? _apiClient;
  String? _lastFailedSessionId; // Store session ID for diagnostics

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
            onPressed: _isConverting ? null : () => _convertAndSave(),
            child: Text(
              _isConverting ? 'Converting...' : 'Ready to save',
              style: TextStyle(
                color: _isConverting ? Colors.grey : Colors.blue,
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
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.9,
                              ),
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
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade600,
                          ),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
      print('📄 [BlenderAPI] Source file: ${widget.scanData.localPath}');

      // ========================================
      // BACKEND-ALIGNED WORKFLOW (Option A)
      // Following proven workflow from:
      // - simple_convert_test.py
      // - download_result.sh
      // NO artificial waits (backend handles synchronization)
      // ========================================

      // Step 1: Create session (10% progress)
      setState(() {
        _conversionStatus = 'Creating session...';
        _conversionProgress = 0.1;
      });

      final session = await _apiClient!.createSession();
      sessionId = session.sessionId;
      print('✅ [BlenderAPI] Session created: $sessionId');
      print('⏰ [BlenderAPI] Session expires: ${session.expiresAt}');

      // Step 2: Upload USDZ file (10% → 40% progress)
      setState(() {
        _conversionStatus = 'Uploading USDZ file...';
        _conversionProgress = 0.1;
      });

      final usdzFile = File(widget.scanData.localPath);
      final fileSizeBytes = await usdzFile.length();
      final fileSizeMB = (fileSizeBytes / 1024 / 1024).toStringAsFixed(2);
      print('📦 [BlenderAPI] File size: $fileSizeMB MB ($fileSizeBytes bytes)');

      // Upload with explicit asset type (matches backend: X-Asset-Type: model/vnd.usdz+zip)
      final uploadResponse = await _apiClient!.uploadFile(
        sessionId: sessionId,
        file: usdzFile,
        assetType: 'model/vnd.usdz+zip', // ✅ Explicit, matches backend test
        onProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _conversionProgress = 0.4; // Upload complete
            });
          }
        },
      );
      print('✅ [BlenderAPI] File uploaded: ${uploadResponse.filename}');
      print('📊 [BlenderAPI] Upload size: ${uploadResponse.sizeBytes} bytes');

      // Step 3: Start conversion (40% progress)
      setState(() {
        _conversionStatus = 'Starting conversion...';
        _conversionProgress = 0.4;
      });

      // Generate output filename (matches backend: filename.replace('.usdz', '.glb'))
      final outputFilename = uploadResponse.filename.replaceAll(
        '.usdz',
        '.glb',
      );
      print('🎯 [BlenderAPI] Target output: $outputFilename');

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

      // Step 4: Poll status until completed (40% → 80% progress)
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
          print(
            '📊 [BlenderAPI] Status: ${status.sessionStatus}, '
            'Progress: ${status.progress}%, '
            'Stage: ${status.processingStage}',
          );
        }

        if (status.isCompleted) {
          finalStatus = status;
          print('✅ [BlenderAPI] Conversion completed');
          if (status.result != null) {
            print(
              '📁 [BlenderAPI] Result filename: ${status.result!.filename}',
            );
            print(
              '📊 [BlenderAPI] Result size: ${status.result!.sizeBytes} bytes',
            );
            if (status.result!.polygonCount != null) {
              print('🔺 [BlenderAPI] Polygons: ${status.result!.polygonCount}');
            }
          }
          break;
        }
      }

      if (finalStatus?.result == null) {
        throw BlenderApiException(
          statusCode: 500,
          message: 'Conversion completed but no result returned',
          sessionId: sessionId,
        );
      }

      // Step 5: Download GLB immediately (80% → 100% progress)
      // ⚠️ NO ARTIFICIAL WAIT - Backend handles file system synchronization
      setState(() {
        _conversionStatus = 'Downloading GLB...';
        _conversionProgress = 0.8;
      });

      print(
        '⬇️ [BlenderAPI] Starting download: ${finalStatus!.result!.filename}',
      );
      final glbFile = await _apiClient!.downloadFile(
        sessionId: sessionId,
        filename: finalStatus.result!.filename,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              final downloadProgress = received / total;
              _conversionProgress =
                  0.8 + (downloadProgress * 0.2); // 80% → 100%
            });
          }
        },
      );
      print('✅ [BlenderAPI] Download complete: ${glbFile.path}');

      // Save GLB file permanently
      final documentsDir = await getApplicationDocumentsDirectory();
      final permanentPath =
          '${documentsDir.path}/${finalStatus.result!.filename}';
      final permanentFile = await glbFile.copy(permanentPath);
      final savedSize = await permanentFile.length();
      print('💾 [BlenderAPI] Saved to: $permanentPath');
      print('✓ [BlenderAPI] File size verified: $savedSize bytes');

      // Step 6: Cleanup session immediately after download
      // ⚠️ NO ARTIFICIAL WAIT - Backend handles HTTP stream closure
      if (sessionId != null) {
        print('🧹 [BlenderAPI] Deleting session: $sessionId');
        await _apiClient!.deleteSession(sessionId);
        print('✅ [BlenderAPI] Session cleaned up');
      }

      setState(() {
        _conversionStatus = 'Conversion complete!';
        _conversionProgress = 1.0;
      });

      // Show success and navigate to GLB preview
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Update existing USDZ scan with GLB path instead of creating new scan
        final updatedScan = widget.scanData.copyWith(
          glbLocalPath: permanentPath,
          metadata: {
            ...?widget.scanData.metadata,
            'glb_conversion_date': DateTime.now().toIso8601String(),
            'polygon_count': finalStatus.result!.polygonCount,
            'mesh_count': finalStatus.result!.meshCount,
            'material_count': finalStatus.result!.materialCount,
          },
        );

        // Update scan in session manager
        ScanSessionManager().updateScan(updatedScan);
        print('✅ [USDZ_PREVIEW] Updated scan with GLB path: $permanentPath');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GlbPreviewScreen(scanData: updatedScan),
          ),
        );
      }
    } on BlenderApiException catch (e, stackTrace) {
      print('❌ [BlenderAPI] BlenderApiException caught');
      print('   Status Code: ${e.statusCode}');
      print('   Error Code: ${e.errorCode}');
      print('   Message: ${e.message}');
      print('   Session ID: ${e.sessionId ?? sessionId}');
      print('   Recoverable: ${e.isRecoverable}');
      print('   User Message: ${e.userMessage}');
      if (e.recommendedAction != null) {
        print('   Recommended Action: ${e.recommendedAction}');
      }

      // Handle rate limit errors (429 TOO_MANY_REQUESTS) with automatic cleanup
      if (e.statusCode == 429 && e.errorCode == 'TOO_MANY_REQUESTS') {
        print(
          '🧹 [BlenderAPI] Handling rate limit error - attempting session cleanup',
        );

        if (mounted) {
          // Show cleanup dialog
          final shouldCleanup = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text('Too Many Sessions'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You have reached the limit of 3 concurrent sessions.\n\n'
                    'Would you like to clean up old sessions and retry?',
                  ),
                  if (e.details != null &&
                      e.details!['tracked_sessions'] != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tracked sessions: ${e.details!['tracked_sessions']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clean Up & Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );

          if (shouldCleanup == true && mounted) {
            // Show cleanup progress
            setState(() {
              _conversionStatus = 'Cleaning up old sessions...';
              _conversionProgress = 0.05;
            });

            try {
              // Clean up all tracked sessions
              final cleaned = await _apiClient!.cleanupAllSessions();
              print('✅ [BlenderAPI] Cleaned up $cleaned sessions');

              if (mounted) {
                setState(() {
                  _conversionStatus = 'Retrying conversion...';
                  _conversionProgress = 0.1;
                });

                // Wait a bit before retrying
                await Future.delayed(const Duration(milliseconds: 500));

                // Retry conversion
                await _convertToGLB();
                return; // Exit error handler - retry is in progress
              }
            } catch (cleanupError) {
              print('❌ [BlenderAPI] Cleanup failed: $cleanupError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to clean up sessions: $cleanupError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        }

        // Reset conversion state after failed cleanup or cancel
        if (mounted) {
          setState(() {
            _isConverting = false;
            _conversionProgress = 0.0;
            _conversionStatus = '';
          });
        }
        return; // Exit error handler
      }

      // Store session ID for diagnostics
      setState(() {
        _lastFailedSessionId = e.sessionId ?? sessionId;
      });

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.userMessage),
                if (e.recommendedAction != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    e.recommendedAction!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (e.sessionId != null || sessionId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Session ID: ${e.sessionId ?? sessionId}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (e.errorCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error Code: ${e.errorCode}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (e.sessionId != null || sessionId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionDiagnosticsScreen(
                          sessionId: e.sessionId ?? sessionId!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Details'),
                ),
              if (e.isRecoverable)
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
    } catch (e, stackTrace) {
      print('❌ [BlenderAPI] Unexpected error: $e');
      print(
        '   Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}',
      );
      if (sessionId != null) {
        print('   Session ID: $sessionId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _convertToGLB,
            ),
          ),
        );
      }
    } finally {
      // Cleanup session if still exists (final safety net)
      if (sessionId != null) {
        try {
          print('🧹 [BlenderAPI] Final cleanup check for session: $sessionId');
          await _apiClient?.deleteSession(sessionId);
          print('✅ [BlenderAPI] Final cleanup completed');
        } catch (e) {
          print('⚠️ [BlenderAPI] Final cleanup failed (non-critical): $e');
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

  /// Convert to GLB and then save
  Future<void> _convertAndSave() async {
    print('💾 [USDZ_PREVIEW] Ready to save - checking for GLB conversion');

    // Check if already converted
    if (widget.scanData.glbLocalPath != null &&
        await File(widget.scanData.glbLocalPath!).exists()) {
      print('✅ [USDZ_PREVIEW] GLB already exists, proceeding to save');
      _saveToProject();
      return;
    }

    print('⚠️ [USDZ_PREVIEW] No GLB file found, requesting conversion');

    // Show dialog to confirm conversion
    final shouldConvert = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to GLB?'),
        content: const Text(
          'This scan needs to be converted to GLB format for saving. '
          'This may take a few moments.\n\n'
          'Would you like to convert now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (shouldConvert != true || !mounted) return;

    // Trigger conversion
    await _convertToGLB();

    // After successful conversion, navigate to GLB preview which has save button
    // The GLB preview screen will handle the actual save action
  }

  Future<void> _scanAnotherRoom() async {
    // Navigate to ScanningScreen to start new scan
    final result = await Navigator.of(context).push<ScanData>(
      MaterialPageRoute(builder: (context) => const ScanningScreen()),
    );

    if (result != null && mounted) {
      // New scan completed, return to scan list
      Navigator.of(context).pop(result);
    }
  }
}
