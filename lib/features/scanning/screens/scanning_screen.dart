import 'package:flutter/material.dart';
import '../models/lidar_capability.dart';
import '../models/scan_data.dart';
import '../services/scanning_service.dart';
import '../widgets/scan_button.dart';
import '../widgets/scan_progress.dart';
import '../../../core/constants/app_strings.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _checkCapability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes (interruption handling)
    if (_isScanning) {
      switch (state) {
        case AppLifecycleState.inactive:
        case AppLifecycleState.paused:
          _handleInterruption(InterruptionReason.backgrounded);
          break;
        default:
          break;
      }
    }
  }

  Future<void> _checkCapability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final capability = await _scanningService.checkCapability();
      setState(() {
        _capability = capability;
        _isLoading = false;
      });
    } catch (e) {
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
      final scanData = await _scanningService.startScan(
        onProgress: (progress) {
          setState(() {
            _scanProgress = progress;
          });
        },
      );

      setState(() {
        _completedScan = scanData;
        _isScanning = false;
        _scanProgress = 1.0;
      });

      // Show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.scanComplete),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanProgress = null;
        _errorMessage = _getErrorMessage(e);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? AppStrings.scanFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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

  Future<void> _handleInterruption(InterruptionReason reason) async {
    if (!_isScanning) return;

    final action = await _showInterruptionDialog();

    switch (action) {
      case InterruptionAction.savePartial:
        // Save current scan state as partial
        await _stopScan();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Partial scan saved'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        break;

      case InterruptionAction.discard:
        await _stopScan();
        setState(() {
          _scanProgress = null;
          _completedScan = null;
        });
        break;

      case InterruptionAction.continue_:
        // Continue scanning (do nothing)
        break;

      case null:
        // Dialog dismissed, treat as continue
        break;
    }
  }

  Future<InterruptionAction?> _showInterruptionDialog() async {
    return showDialog<InterruptionAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.scanInterruptedTitle),
        content: const Text(AppStrings.scanInterruptedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, InterruptionAction.discard),
            child: const Text(AppStrings.discardScanButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, InterruptionAction.savePartial),
            child: const Text(AppStrings.savePartialButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, InterruptionAction.continue_),
            child: const Text(AppStrings.continueScanButton),
          ),
        ],
      ),
    );
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
