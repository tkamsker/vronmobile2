import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_data.dart';
import '../services/scan_session_manager.dart';
import 'scanning_screen.dart';

/// Screen showing list of scans for current session
/// Matches design from Requirements/ScanList.jpg
class ScanListScreen extends StatefulWidget {
  final String? projectName;

  const ScanListScreen({
    super.key,
    this.projectName,
  });

  @override
  State<ScanListScreen> createState() => _ScanListScreenState();
}

class _ScanListScreenState extends State<ScanListScreen> {
  final ScanSessionManager _sessionManager = ScanSessionManager();

  @override
  Widget build(BuildContext context) {
    final scans = _sessionManager.scans;
    final lastUpdated = scans.isNotEmpty
        ? scans.map((s) => s.capturedAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Scan Areas', style: TextStyle(fontSize: 20)),
            Text(
              'Separate scans with size & time',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Project header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.projectName ?? 'Current Session',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${scans.length} ${scans.length == 1 ? 'scan' : 'scans'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatRelativeDate(lastUpdated),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scan list
            Expanded(
              child: scans.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: scans.length,
                      itemBuilder: (context, index) {
                        final scan = scans[index];
                        return _buildScanCard(scan, index + 1);
                      },
                    ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Scan another room button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _scanAnotherRoom(),
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'Scan another room',
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

                  // Room stitching button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: scans.length >= 2 ? () => _roomStitching() : null,
                      icon: Icon(
                        Icons.auto_awesome_mosaic,
                        size: 24,
                        color: scans.length >= 2
                            ? Colors.blue.shade600
                            : Colors.grey.shade400,
                      ),
                      label: Text(
                        'Room stitching',
                        style: TextStyle(
                          fontSize: 18,
                          color: scans.length >= 2
                              ? Colors.blue.shade600
                              : Colors.grey.shade400,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: scans.length >= 2
                              ? Colors.blue.shade600
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
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

  Widget _buildScanCard(ScanData scan, int scanNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Scan icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.threed_rotation,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Scan info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan $scanNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(scan.capturedAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons row (USDZ, GLBView, Delete)
          Row(
            children: [
              // USDZ button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewUsdzPreview(scan),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('USDZ'),
                ),
              ),
              const SizedBox(width: 8),

              // GLBView button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewGlbPreview(scan),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('GLBView'),
                ),
              ),
              const SizedBox(width: 8),

              // Delete button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteScan(scan),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.threed_rotation,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning to create your first 3D room',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) {
      return 'Today · ${DateFormat('HH:mm').format(date)}';
    } else if (scanDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM d · HH:mm').format(date);
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scanDate = DateTime(date.year, date.month, date.day);

    if (scanDate == today) {
      return 'Today · ${DateFormat('HH:mm').format(date)}';
    } else if (scanDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('MMM d · HH:mm').format(date);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _scanAnotherRoom() async {
    final result = await Navigator.of(context).push<ScanData>(
      MaterialPageRoute(
        builder: (context) => const ScanningScreen(),
      ),
    );

    if (result != null) {
      // Scan was already added to session in ScanningScreen
      // Just refresh the UI to show the updated list
      setState(() {});
    }
  }

  void _roomStitching() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room stitching feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewScanDetails(ScanData scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scan ${scan.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Format: ${scan.format.name.toUpperCase()}'),
            Text('Size: ${_formatFileSize(scan.fileSizeBytes)}'),
            Text('Captured: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(scan.capturedAt)}'),
            Text('Status: ${scan.status.name}'),
            if (scan.localPath.isNotEmpty)
              Text('Path: ${scan.localPath}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteScan(scan);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteScan(ScanData scan) {
    setState(() {
      _sessionManager.removeScan(scan.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Scan deleted'),
        duration: const Duration(seconds: 20),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _sessionManager.addScan(scan);
            });
          },
        ),
      ),
    );
  }
}
