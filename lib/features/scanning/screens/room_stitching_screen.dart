import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/scan_data.dart';
import 'package:vronmobile2/features/scanning/models/room_stitch_request.dart';
import 'package:vronmobile2/features/scanning/services/room_stitching_service.dart';
import 'package:vronmobile2/features/scanning/screens/room_stitch_progress_screen.dart';

/// Screen for selecting multiple scans to stitch together
///
/// User Flow:
/// 1. User views list of available scans with checkboxes
/// 2. User selects 2+ scans
/// 3. User taps "Start Stitching" button
/// 4. Navigation to RoomStitchProgressScreen
class RoomStitchingScreen extends StatefulWidget {
  final List<ScanData> scans;
  final RoomStitchingService stitchingService;
  final String projectId;
  final bool isGuestMode;

  const RoomStitchingScreen({
    super.key,
    required this.scans,
    required this.stitchingService,
    required this.projectId,
    this.isGuestMode = false,
  });

  @override
  State<RoomStitchingScreen> createState() => _RoomStitchingScreenState();
}

class _RoomStitchingScreenState extends State<RoomStitchingScreen> {
  final Set<String> _selectedScanIds = {};
  bool _isLoading = false;

  /// Returns display name for a scan
  /// Priority: metadata['roomName'] > "Scan N"
  String _getScanDisplayName(ScanData scan, int index) {
    final roomName = scan.metadata?['roomName'] as String?;
    if (roomName != null && roomName.isNotEmpty) {
      return roomName;
    }
    return 'Scan ${index + 1}';
  }

  /// Formats file size in MB
  String _formatFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Toggles selection for a scan
  void _toggleSelection(String scanId) {
    setState(() {
      if (_selectedScanIds.contains(scanId)) {
        _selectedScanIds.remove(scanId);
      } else {
        _selectedScanIds.add(scanId);
      }
    });
  }

  /// Checks if "Start Stitching" button should be enabled
  bool get _canStartStitching => _selectedScanIds.length >= 2;

  /// Starts the stitching process
  Future<void> _startStitching() async {
    // Guest mode check
    if (widget.isGuestMode) {
      _showAuthRequiredDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build room names map
      final roomNames = <String, String>{};
      for (int i = 0; i < widget.scans.length; i++) {
        final scan = widget.scans[i];
        if (_selectedScanIds.contains(scan.id)) {
          final roomName = scan.metadata?['roomName'] as String?;
          if (roomName != null && roomName.isNotEmpty) {
            roomNames[scan.id] = roomName;
          }
        }
      }

      // Create stitch request
      final request = RoomStitchRequest(
        projectId: widget.projectId,
        scanIds: _selectedScanIds.toList(),
        roomNames: roomNames.isNotEmpty ? roomNames : null,
      );

      // Start stitching
      final job = await widget.stitchingService.startStitching(request);

      if (!mounted) return;

      // Navigate to progress screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => RoomStitchProgressScreen(
            jobId: job.jobId,
            scanIds: _selectedScanIds.toList(),
            roomNames: roomNames.isNotEmpty ? roomNames : null,
            stitchingService: widget.stitchingService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(e.toString());
    }
  }

  /// Shows authentication required dialog for guest users
  void _showAuthRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Required'),
        content: const Text(
          'Please create an account or sign in to use room stitching. '
          'This feature requires backend processing.',
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

  /// Shows error dialog when stitching fails to start
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Failed to Start Stitching'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stitch Rooms'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.scans.isEmpty) {
      return const Center(
        child: Text('No scans available'),
      );
    }

    if (widget.scans.length == 1) {
      return _buildSingleScanWarning();
    }

    return Column(
      children: [
        _buildHelpText(),
        Expanded(
          child: ListView.builder(
            itemCount: widget.scans.length,
            itemBuilder: (context, index) => _buildScanItem(
              widget.scans[index],
              index,
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHelpText() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Select at least 2 scans to stitch',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
      ),
    );
  }

  Widget _buildSingleScanWarning() {
    return Column(
      children: [
        _buildHelpText(),
        Expanded(
          child: ListView.builder(
            itemCount: widget.scans.length,
            itemBuilder: (context, index) => _buildScanItem(
              widget.scans[index],
              index,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Need at least 2 scans to enable stitching',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildScanItem(ScanData scan, int index) {
    final isSelected = _selectedScanIds.contains(scan.id);
    final displayName = _getScanDisplayName(scan, index);
    final fileSize = _formatFileSize(scan.fileSizeBytes);

    return InkWell(
      onTap: () => _toggleSelection(scan.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Semantics(
              label: 'Select $displayName for stitching',
              checked: isSelected,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(scan.id),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _selectedScanIds.length;
    final selectionText = selectedCount == 0
        ? ''
        : '$selectedCount ${selectedCount == 1 ? 'scan' : 'scans'} selected';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectionText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                selectionText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          Semantics(
            label: 'Start stitching selected scans',
            button: true,
            enabled: _canStartStitching,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canStartStitching ? _startStitching : null,
                child: const Text('Start Stitching'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
