import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_job.dart';
import 'package:vronmobile2/features/scanning/models/stitched_model.dart';
import 'package:vronmobile2/features/scanning/services/room_stitching_service.dart';
import 'package:vronmobile2/features/scanning/screens/stitched_model_preview_screen.dart';

/// Screen showing progress of a room stitching operation
///
/// Flow:
/// 1. Starts polling job status immediately on init
/// 2. Updates UI with status changes via callback
/// 3. On completion: downloads model and navigates to preview
/// 4. On failure: shows error dialog with retry option
class RoomStitchProgressScreen extends StatefulWidget {
  final String jobId;
  final List<String> scanIds;
  final Map<String, String>? roomNames;
  final RoomStitchingService stitchingService;

  const RoomStitchProgressScreen({
    super.key,
    required this.jobId,
    required this.scanIds,
    this.roomNames,
    required this.stitchingService,
  });

  @override
  State<RoomStitchProgressScreen> createState() =>
      _RoomStitchProgressScreenState();
}

class _RoomStitchProgressScreenState extends State<RoomStitchProgressScreen> {
  RoomStitchJob? _currentJob;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  /// Starts polling for job status updates
  Future<void> _startPolling() async {
    try {
      final completedJob = await widget.stitchingService.pollStitchStatus(
        jobId: widget.jobId,
        onStatusChange: (job) {
          if (mounted) {
            setState(() {
              _currentJob = job;
            });
          }
        },
      );

      if (!mounted) return;

      // Update final state
      setState(() {
        _currentJob = completedJob;
      });

      // Handle completion or failure
      if (completedJob.status == RoomStitchJobStatus.completed) {
        await _handleSuccess(completedJob);
      } else if (completedJob.status == RoomStitchJobStatus.failed) {
        _handleFailure(completedJob);
      }
    } on TimeoutException {
      if (!mounted) return;
      _showErrorDialog(
        'Stitching Timeout',
        'The stitching process took too long. Please try again with fewer scans or smaller rooms.',
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Stitching Failed', e.toString());
    }
  }

  /// Handles successful completion
  Future<void> _handleSuccess(RoomStitchJob job) async {
    if (job.resultUrl == null) {
      _showErrorDialog('Download Error', 'No result URL provided');
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
      });

      // Generate filename from room names or use default
      final filename = _generateFilename();

      // Download the stitched model
      final file = await widget.stitchingService.downloadStitchedModel(
        resultUrl: job.resultUrl!,
        filename: filename,
      );

      if (!mounted) return;

      // Create StitchedModel
      final model = StitchedModel.fromJob(
        job,
        file.path,
        await file.length(),
        widget.scanIds,
        widget.roomNames,
      );

      // Navigate to preview screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              StitchedModelPreviewScreen(stitchedModel: model),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
      });
      _showErrorDialog(
        'Download Failed',
        'Failed to download stitched model: ${e.toString()}',
      );
    }
  }

  /// Handles failure
  void _handleFailure(RoomStitchJob job) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Stitching Failed'),
        content: Text(job.errorMessage ?? 'Unknown error occurred'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit screen
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _startPolling(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Shows generic error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit screen
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _startPolling(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Shows cancellation confirmation dialog
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Stitching?'),
        content: const Text(
          'Are you sure you want to cancel? Progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No, Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit screen
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  /// Generates filename for stitched model
  String _generateFilename() {
    final timestamp = DateTime.now().toIso8601String().split('T')[0];

    if (widget.roomNames != null && widget.roomNames!.isNotEmpty) {
      final names = widget.roomNames!.values.toList();
      if (names.length == 1) {
        return 'stitched-${_sanitize(names[0])}-$timestamp.glb';
      } else if (names.length == 2) {
        return 'stitched-${_sanitize(names[0])}-${_sanitize(names[1])}-$timestamp.glb';
      } else {
        return 'stitched-${_sanitize(names[0])}-plus-${names.length - 1}-more-$timestamp.glb';
      }
    }

    return 'stitched-${widget.scanIds.length}-rooms-$timestamp.glb';
  }

  /// Sanitizes a string for use in filenames
  String _sanitize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Formats room names for display
  String _formatRoomNames() {
    if (widget.roomNames == null || widget.roomNames!.isEmpty) {
      return '${widget.scanIds.length} rooms';
    }

    final names = widget.roomNames!.values.toList();
    if (names.length == 1) {
      return names[0];
    } else if (names.length == 2) {
      return '${names[0]} + ${names[1]}';
    } else {
      return '${names[0]} + ${names[1]} + ${names.length - 2} more';
    }
  }

  /// Calculates estimated time remaining
  String? _getEstimatedTimeRemaining() {
    if (_currentJob == null ||
        _currentJob!.estimatedDurationSeconds == null ||
        _currentJob!.progress == 0) {
      return null;
    }

    final elapsed = _currentJob!.elapsedSeconds;
    final total = _currentJob!.estimatedDurationSeconds!;
    final remaining = total - elapsed;

    if (remaining <= 0) return null;

    if (remaining < 60) {
      return 'About $remaining seconds remaining';
    } else {
      final minutes = (remaining / 60).ceil();
      return 'About $minutes ${minutes == 1 ? 'minute' : 'minutes'} remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stitching Rooms'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Room names being stitched
            Text(
              _formatRoomNames(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress indicator
            Semantics(
              label: 'Stitching progress indicator',
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentJob == null || _currentJob!.progress == 0)
                      const CircularProgressIndicator(strokeWidth: 8)
                    else
                      CircularProgressIndicator(
                        // Guard against NaN values that can cause CoreGraphics errors
                        value:
                            (_currentJob!.progress.isNaN ||
                                !_currentJob!.progress.isFinite)
                            ? null
                            : _currentJob!.progress / 100,
                        strokeWidth: 8,
                      ),
                    if (_currentJob != null && _currentJob!.progress > 0)
                      Text(
                        '${_currentJob!.progress}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status message (with live region for accessibility)
            Semantics(
              liveRegion: true,
              child: Text(
                _isDownloading
                    ? 'Downloading...'
                    : _currentJob?.statusMessage ?? 'Waiting to start...',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Estimated time remaining
            if (_getEstimatedTimeRemaining() != null)
              Text(
                _getEstimatedTimeRemaining()!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),

            const Spacer(),

            // Cancel button
            if (!_isDownloading &&
                (_currentJob == null || !_currentJob!.isTerminal))
              TextButton(
                onPressed: _showCancelDialog,
                child: const Text('Cancel'),
              ),
          ],
        ),
      ),
    );
  }
}
