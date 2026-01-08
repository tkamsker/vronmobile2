import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scan_data.dart';
import '../models/conversion_result.dart';
import '../services/scan_upload_service.dart';
import '../services/scan_session_manager.dart';
import '../services/blender_api_service.dart';
import '../services/blenderapi_service.dart';
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
  late final BlenderApiService _blenderApiService;
  late final BlenderAPIService _blenderAPIService; // For navmesh generation
  final ScanSessionManager _sessionManager = ScanSessionManager();
  ConversionResult? _conversionResult;
  late ScanData _currentScanData;
  String? _glbLocalPath;
  double _conversionProgress = 0.0;
  String _conversionStatus = '';

  @override
  void initState() {
    super.initState();
    _uploadService = widget.uploadService ?? ScanUploadService();
    _blenderApiService = BlenderApiService();
    _blenderAPIService = BlenderAPIService(); // Initialize navmesh service
    _currentScanData = widget.scanData;
    _glbLocalPath = widget.scanData.glbLocalPath;
    _checkForExistingGlb();
  }

  Future<void> _checkForExistingGlb() async {
    if (_currentScanData.glbLocalPath != null) {
      final glbFile = File(_currentScanData.glbLocalPath!);
      if (await glbFile.exists()) {
        setState(() {
          _glbLocalPath = _currentScanData.glbLocalPath;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract dimensions from metadata if available
    final metadata = _currentScanData.metadata;
    final rawWidth = metadata?['width'] as double?;
    final rawHeight = metadata?['height'] as double?;

    // Guard against NaN values that can cause CoreGraphics errors
    final width = (rawWidth != null && !rawWidth.isNaN && rawWidth.isFinite)
        ? rawWidth
        : null;
    final height = (rawHeight != null && !rawHeight.isNaN && rawHeight.isFinite)
        ? rawHeight
        : null;

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
          TextButton.icon(
            onPressed: () => _deleteScan(),
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'Delete Scan',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
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

            // Button section - changes based on GLB availability
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_glbLocalPath == null ||
                      !File(_glbLocalPath!).existsSync()) ...[
                    // Convert to GLB button (when GLB doesn't exist)
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
                          _isConverting
                              ? '$_conversionStatus ${(_conversionProgress * 100).toInt()}%'
                              : 'Convert to GLB',
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
                  ] else ...[
                    // GLB exists - show navmesh, preview, and export buttons
                    // Create Navmesh button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _createNavmesh(),
                        icon: Icon(Icons.route, size: 24),
                        label: const Text(
                          'Create Navmesh',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preview GLB button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _previewGLB(),
                        icon: const Icon(Icons.view_in_ar, size: 20),
                        label: const Text('Preview GLB'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade400,
                          side: BorderSide(color: Colors.blue.shade400),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),

                    // Export GLB button (debug mode only)
                    if (kDebugMode) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _exportGLB(),
                          icon: const Icon(Icons.file_download, size: 20),
                          label: const Text('Export GLB (Debug)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade400,
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
      print(
        '🔍 [USDZ] Opening AR viewer in object mode for: ${_currentScanData.localPath}',
      );

      if (Platform.isIOS) {
        // Use url_launcher with URL fragment to start in object mode
        // #allowsContentScaling=0 tells AR Quick Look to start in object viewing mode
        final file = File(_currentScanData.localPath);
        if (!await file.exists()) {
          throw Exception('USDZ file not found');
        }

        final uri = Uri.file(
          _currentScanData.localPath,
          windows: false,
        ).replace(fragment: 'allowsContentScaling=0');

        if (!await canLaunchUrl(uri)) {
          throw Exception('Cannot launch AR viewer - URL not supported');
        }

        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ [USDZ] AR viewer launched successfully in object mode');
      } else {
        // LiDAR scanning is iOS-only, Android not supported
        throw Exception('AR viewing is only supported on iOS devices');
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
    print('🔄 [USDZ] Convert to GLB requested via Blender API');

    // Check if already converted
    if (_glbLocalPath != null && await File(_glbLocalPath!).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GLB file already exists!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    setState(() {
      _isConverting = true;
      _conversionProgress = 0.0;
      _conversionStatus = 'Starting...';
    });

    try {
      // Call Blender API to convert USDZ to GLB
      final glbPath = await _blenderApiService.convertUsdzToGlb(
        usdzPath: _currentScanData.localPath,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _conversionProgress = progress;
              _conversionStatus = status;
            });
          }
        },
      );

      print('✅ [USDZ] Conversion successful: $glbPath');

      // Update scan data with GLB path
      _currentScanData = _currentScanData.copyWith(glbLocalPath: glbPath);
      _sessionManager.updateScan(_currentScanData);

      setState(() {
        _glbLocalPath = glbPath;
        _isConverting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade400),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('GLB conversion completed successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
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

  void _showConversionInfoDialog() {
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
              'GLB conversion happens automatically when you save this scan to a project.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Backend API Conversion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you save this scan to a project, our backend will:\n'
                    '1. Upload your USDZ file\n'
                    '2. Convert it to GLB format\n'
                    '3. Store GLB locally for preview and navmesh creation',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Click "Ready to save" to proceed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveToProject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save to Project'),
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

  Future<void> _createNavmesh() async {
    print('🗺️ [USDZ] Create Navmesh requested');

    if (_glbLocalPath == null) {
      print('❌ [USDZ] Cannot create navmesh: GLB file not found');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GLB file must be converted first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate GLB file exists
    final glbFile = File(_glbLocalPath!);
    if (!await glbFile.exists()) {
      print('❌ [USDZ] GLB file does not exist: $_glbLocalPath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GLB file not found on device'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('📊 [USDZ] GLB file validated: ${glbFile.path}');
    print('📊 [USDZ] GLB file size: ${await glbFile.length()} bytes');

    // Show progress dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _NavmeshProgressDialog(
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );

    String? sessionId;
    try {
      print('🔄 [NAVMESH] Starting navmesh generation workflow');
      print('   Input GLB: ${glbFile.path}');

      // Step 1: Create BlenderAPI session
      print('🔄 [NAVMESH] Step 1/5: Creating BlenderAPI session...');
      sessionId = await _blenderAPIService.createSession();
      print('✅ [NAVMESH] Session created: $sessionId');

      // Step 2: Upload GLB file
      print('🔄 [NAVMESH] Step 2/5: Uploading GLB file (${await glbFile.length()} bytes)...');
      await _blenderAPIService.uploadGLB(
        sessionId: sessionId,
        glbFile: glbFile,
        onProgress: (progress) {
          print('📤 [NAVMESH] Upload progress: ${(progress * 100).toInt()}%');
        },
      );
      print('✅ [NAVMESH] GLB uploaded successfully');

      // Step 3: Start navmesh generation
      print('🔄 [NAVMESH] Step 3/5: Starting navmesh generation...');
      final inputFilename = glbFile.path.split('/').last;
      final outputFilename = 'navmesh_$inputFilename';

      await _blenderAPIService.startNavMeshGeneration(
        sessionId: sessionId,
        inputFilename: inputFilename,
        outputFilename: outputFilename,
        navmeshParams: BlenderAPIService.unityStandardNavMeshParams,
      );
      print('✅ [NAVMESH] NavMesh generation started');
      print('   Output filename: $outputFilename');

      // Step 4: Poll for completion
      print('🔄 [NAVMESH] Step 4/5: Polling for completion...');
      final status = await _blenderAPIService.pollStatus(
        sessionId: sessionId,
      );
      print('✅ [NAVMESH] NavMesh generation completed with status: $status');

      // Step 5: Download navmesh
      print('🔄 [NAVMESH] Step 5/5: Downloading navmesh...');
      final documentsDirectory = (await getApplicationDocumentsDirectory()).path;
      final navmeshPath = '$documentsDirectory/scans/navmesh/${_currentScanData.id}_navmesh.glb';

      // Ensure directory exists
      final navmeshDir = Directory('$documentsDirectory/scans/navmesh');
      if (!await navmeshDir.exists()) {
        await navmeshDir.create(recursive: true);
        print('📁 [NAVMESH] Created navmesh directory');
      }

      await _blenderAPIService.downloadNavMesh(
        sessionId: sessionId,
        filename: outputFilename,
        outputPath: navmeshPath,
      );
      print('✅ [NAVMESH] NavMesh downloaded to: $navmeshPath');

      // Update scan data with navmesh path (store in session, ScanData doesn't have navmeshLocalPath)
      // Note: ScanData model doesn't have navmeshLocalPath field, navmesh is stored separately
      print('✅ [NAVMESH] NavMesh file saved to: $navmeshPath');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('NavMesh created successfully!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      print('✅ [NAVMESH] NavMesh generation workflow completed successfully');
    } catch (e, stackTrace) {
      print('❌ [NAVMESH] NavMesh generation failed: $e');
      print('   Stack trace: $stackTrace');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('NavMesh Generation Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Failed to create navigation mesh:'),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createNavmesh(); // Retry
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } finally {
      // Always cleanup session
      if (sessionId != null) {
        try {
          print('🧹 [NAVMESH] Cleaning up BlenderAPI session...');
          await _blenderAPIService.deleteSession(sessionId: sessionId);
          print('✅ [NAVMESH] Session deleted');
        } catch (e) {
          print('⚠️ [NAVMESH] Failed to delete session: $e');
        }
      }
    }
  }

  Future<void> _previewGLB() async {
    print('👁️ [USDZ] Preview GLB requested');

    if (_glbLocalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GLB file not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to GLB preview screen
    final glbScanData = _currentScanData.copyWith(glbLocalPath: _glbLocalPath);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GlbPreviewScreen(scanData: glbScanData),
      ),
    );
  }

  Future<void> _exportGLB() async {
    print('📤 [USDZ] Export GLB requested (Debug mode)');

    if (_glbLocalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GLB file not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final glbFile = File(_glbLocalPath!);
      if (!await glbFile.exists()) {
        throw Exception('GLB file not found at path');
      }

      // Get Downloads directory (iOS: app documents, Android: Downloads)
      final downloadsDir = await getApplicationDocumentsDirectory();
      final fileName = 'exported_${_glbLocalPath!.split('/').last}';
      final exportPath = '${downloadsDir.path}/$fileName';

      // Copy file to exports location
      await glbFile.copy(exportPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GLB exported successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  exportPath,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      print('✅ [USDZ] GLB exported to: $exportPath');
    } catch (e) {
      print('❌ [USDZ] Export failed: $e');
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

  void _saveToProject() {
    // Navigate to SaveToProjectScreen or return with "save" action
    // Pass the updated scan data with glbLocalPath if available
    final updatedScanData = _currentScanData.copyWith(
      glbLocalPath: _glbLocalPath,
    );
    Navigator.of(context).pop({'action': 'save', 'scan': updatedScanData});
  }

  /// Delete scan and all associated files (USDZ and GLB if exists)
  Future<void> _deleteScan() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade400),
            const SizedBox(width: 12),
            const Text(
              'Delete Scan?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '• USDZ file',
              style: TextStyle(color: Colors.grey.shade300),
            ),
            if (_glbLocalPath != null)
              Text(
                '• GLB file',
                style: TextStyle(color: Colors.grey.shade300),
              ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      print('🗑️ [USDZ] Deleting scan files...');

      // Delete USDZ file
      final usdzFile = File(_currentScanData.localPath);
      if (await usdzFile.exists()) {
        await usdzFile.delete();
        print('✅ [USDZ] Deleted USDZ file: ${_currentScanData.localPath}');
      }

      // Delete GLB file if it exists
      if (_glbLocalPath != null) {
        final glbFile = File(_glbLocalPath!);
        if (await glbFile.exists()) {
          await glbFile.delete();
          print('✅ [USDZ] Deleted GLB file: $_glbLocalPath');
        }
      }

      // Remove scan from session manager
      _sessionManager.removeScan(_currentScanData.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with delete action
        Navigator.of(context).pop({'action': 'delete', 'scan': _currentScanData});
      }
    } catch (e) {
      print('❌ [USDZ] Error deleting scan: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete scan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

/// Progress dialog for navmesh generation
class _NavmeshProgressDialog extends StatelessWidget {
  final VoidCallback onCancel;

  const _NavmeshProgressDialog({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Generating NavMesh'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Creating navigation mesh from GLB file...'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStep('1. Create BlenderAPI session'),
                _buildStep('2. Upload GLB file'),
                _buildStep('3. Generate NavMesh'),
                _buildStep('4. Poll for completion'),
                _buildStep('5. Download NavMesh'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This may take 1-2 minutes depending on model complexity',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
