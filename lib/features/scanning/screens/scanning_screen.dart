import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lidar_capability.dart';
import '../models/scan_data.dart';
import '../services/scanning_service.dart';
import '../services/scan_session_manager.dart';
import '../widgets/scan_button.dart';
import '../widgets/scan_progress.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/config/env_config.dart';
import '../../../main.dart' show guestSessionManager;
import 'save_to_project_screen.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  final ScanningService _scanningService = ScanningService();

  LidarCapability? _capability;
  bool _isLoading = false;
  bool _isScanning = false;
  double? _scanProgress;
  DateTime? _scanStartTime;
  Duration? _elapsedTime;
  ScanData? _completedScan;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCapability();
  }

  Future<void> _checkCapability() async {
    print('🎯 [SCANNING] Checking device capability...');
    setState(() {
      _isLoading = true;
    });

    try {
      final capability = await _scanningService.checkCapability();
      print('🎯 [SCANNING] Capability check complete: ${capability.support}');
      if (capability.unsupportedReason != null) {
        print('🎯 [SCANNING] Reason: ${capability.unsupportedReason}');
      }
      setState(() {
        _capability = capability;
        _isLoading = false;
      });

      // For guest mode, auto-launch if supported
      // For logged-in mode, user will press "Scan another room" button
      if (capability.isScanningSupportpported && guestSessionManager.isGuestMode) {
        print('🎯 [SCANNING] Guest mode: Auto-launching native RoomPlan UI...');
        // Small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _startScan();
        }
      }
    } catch (e) {
      print('❌ [SCANNING] Capability check failed: $e');
      setState(() {
        _errorMessage = 'Failed to check device capability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startScan() async {
    if (_capability == null || !_capability!.isScanningSupportpported) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStartTime = DateTime.now();
      _elapsedTime = Duration.zero;
      _completedScan = null;
      _errorMessage = null;
    });

    // Start elapsed time tracking
    _startElapsedTimeTracking();

    try {
      print('🎯 [SCANNING] Calling startScan()...');
      final scanData = await _scanningService.startScan(
        onProgress: (progress) {
          print('📊 [SCANNING] Progress: ${(progress * 100).toInt()}%');
          if (mounted) {
            setState(() {
              _scanProgress = progress;
            });
          }
        },
      );

      print('✅ [SCANNING] Scan completed! Path: ${scanData.localPath}');
      print('📦 [SCANNING] File size: ${scanData.fileSizeBytes} bytes');

      if (mounted) {
        // Check if user is in guest mode or logged-in
        final isGuestMode = guestSessionManager.isGuestMode;

        setState(() {
          _isScanning = false;
          _completedScan = scanData;
          _scanProgress = 1.0;
        });

        if (isGuestMode) {
          // Guest mode: Show success dialog with account creation prompt
          print('🎉 [SCANNING] Guest mode: Showing success dialog');
          await _showGuestSuccessDialog(scanData);
        } else {
          // Logged-in mode: Navigate to SaveToProjectScreen for upload
          print('🎉 [SCANNING] Logged-in mode: Navigating to SaveToProjectScreen');
          if (mounted) {
            final uploadResult = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SaveToProjectScreen(scanData: scanData),
              ),
            );

            // After upload completes (or user cancels), go back to scan list
            if (mounted) {
              print('🔙 [SCANNING] Returning to scan list');
              // Save to session if upload was successful
              if (uploadResult != null) {
                print('✅ [SCANNING] Upload successful, saving to session');
                ScanSessionManager().addScan(scanData);
              }
              Navigator.of(context).pop(scanData); // Return to scan list
              print('✅ [SCANNING] Navigation completed successfully');
            }
          }
        }
      }
    } catch (e) {
      print('❌ [SCANNING] Scan error: $e');
      print('❌ [SCANNING] Error type: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanProgress = null;
          _errorMessage = _getErrorMessage(e);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? AppStrings.scanFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _startScan(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showGuestSuccessDialog(ScanData scanData) async {
    return showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Scan Complete!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Room scanned successfully'),
                const SizedBox(height: 8),
                Text('📦 Size: ${(scanData.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
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
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Create an account to:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('• Save scans permanently', style: TextStyle(color: Colors.blue.shade900)),
                      Text('• Upload to server', style: TextStyle(color: Colors.blue.shade900)),
                      Text('• Stitch multiple rooms', style: TextStyle(color: Colors.blue.shade900)),
                      Text('• Access from any device', style: TextStyle(color: Colors.blue.shade900)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to main screen
                },
                child: const Text('Done'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to main screen

                  // Launch merchant web app for account creation
                  final url = Uri.parse(EnvConfig.vronMerchantsUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print('❌ Could not launch $url');
                  }
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        );
  }

  Future<void> _stopScan() async {
    await _scanningService.stopScan();
    setState(() {
      _isScanning = false;
      _scanProgress = null;
      _elapsedTime = null;
    });
  }

  void _startElapsedTimeTracking() {
    Future.doWhile(() async {
      if (!_isScanning || _scanStartTime == null) {
        return false;
      }

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && _isScanning) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_scanStartTime!);
        });
      }

      return _isScanning;
    });
  }

  String _getErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('permission')) {
      return AppStrings.scanPermissionDenied;
    } else if (errorString.contains('storage')) {
      return AppStrings.scanStorageFull;
    } else if (errorString.contains('timeout')) {
      return AppStrings.scanTimeout;
    } else {
      return AppStrings.scanFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scanningTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Capability info or error
                    if (_errorMessage != null) ...[
                      _buildErrorCard(),
                      const SizedBox(height: 16.0),
                    ],

                    // Scanning status
                    if (_isScanning && _scanProgress != null) ...[
                      ScanProgress(
                        progress: _scanProgress,
                        elapsedTime: _elapsedTime,
                        onStop: _stopScan,
                      ),
                      const SizedBox(height: 24.0),
                    ],

                    // Completed scan info
                    if (_completedScan != null && !_isScanning) ...[
                      ScanProgress(
                        progress: 1.0,
                        elapsedTime: _elapsedTime,
                      ),
                      const SizedBox(height: 24.0),
                    ],

                    // Start scan button
                    if (!_isScanning && _capability != null)
                      ScanButton(
                        capability: _capability!,
                        onPressed: _startScan,
                        isLoading: false,
                      ),

                    const SizedBox(height: 24.0),

                    // Instructions
                    if (!_isScanning && _capability?.isScanningSupportpported == true)
                      _buildInstructionsCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32.0),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scanning Instructions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            _buildInstructionItem('1. Tap "Start Scanning" to begin'),
            _buildInstructionItem('2. Move your device slowly around the room'),
            _buildInstructionItem('3. Capture walls, floors, and furniture'),
            _buildInstructionItem('4. The scan completes automatically'),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20.0, color: Colors.green),
          const SizedBox(width: 8.0),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
