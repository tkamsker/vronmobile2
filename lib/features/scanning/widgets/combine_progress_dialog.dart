import 'package:flutter/material.dart';
import 'package:vronmobile2/features/scanning/models/combined_scan.dart';

/// Progress dialog for Combined Scan to NavMesh workflow
/// Feature 018: Combined Scan to NavMesh Workflow
/// Shows status updates through all 9 workflow stages
class CombineProgressDialog extends StatefulWidget {
  final CombinedScan combinedScan;
  final double uploadProgress;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  const CombineProgressDialog({
    Key? key,
    required this.combinedScan,
    this.uploadProgress = 0.0,
    this.onCancel,
    this.onClose,
    this.onRetry,
  }) : super(key: key);

  @override
  State<CombineProgressDialog> createState() => _CombineProgressDialogState();
}

class _CombineProgressDialogState extends State<CombineProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              _getTitle(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Status steps list
            ..._buildStatusSteps(),

            const SizedBox(height: 24),

            // Progress indicator (if active)
            if (_isProcessing()) ...[
              _buildProgressIndicator(),
              const SizedBox(height: 24),
            ],

            // Error message (if failed)
            if (widget.combinedScan.status == CombinedScanStatus.failed) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.combinedScan.errorMessage ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action button
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.combinedScan.status) {
      case CombinedScanStatus.combining:
      case CombinedScanStatus.uploadingUsdz:
      case CombinedScanStatus.processingGlb:
        return 'Combining Room Scans';
      case CombinedScanStatus.glbReady:
        return 'Combined GLB Ready';
      case CombinedScanStatus.uploadingToBlender:
      case CombinedScanStatus.generatingNavmesh:
      case CombinedScanStatus.downloadingNavmesh:
        return 'Generating NavMesh';
      case CombinedScanStatus.completed:
        return 'NavMesh Ready';
      case CombinedScanStatus.failed:
        return 'Failed';
    }
  }

  List<Widget> _buildStatusSteps() {
    return [
      _buildStep(
        title: 'Combining scans...',
        status: _getStepStatus(CombinedScanStatus.combining),
      ),
      _buildStep(
        title: 'Uploading to server...',
        status: _getStepStatus(CombinedScanStatus.uploadingUsdz),
      ),
      _buildStep(
        title: 'Creating Combined GLB',
        status: _getStepStatus(CombinedScanStatus.processingGlb),
      ),
      // Show navmesh steps only if we've reached glbReady or beyond
      if (_hasReachedGlbReady()) ...[
        _buildStep(
          title: 'Uploading GLB to BlenderAPI...',
          status: _getStepStatus(CombinedScanStatus.uploadingToBlender),
        ),
        _buildStep(
          title: 'Generating NavMesh...',
          status: _getStepStatus(CombinedScanStatus.generatingNavmesh),
        ),
        _buildStep(
          title: 'Downloading NavMesh...',
          status: _getStepStatus(CombinedScanStatus.downloadingNavmesh),
        ),
      ],
    ];
  }

  Widget _buildStep({
    required String title,
    required _StepStatus status,
  }) {
    IconData icon;
    Color color;

    switch (status) {
      case _StepStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case _StepStatus.inProgress:
        icon = Icons.pending;
        color = Theme.of(context).primaryColor;
        break;
      case _StepStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: status == _StepStatus.pending ? Colors.grey : null,
                fontWeight: status == _StepStatus.inProgress
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StepStatus _getStepStatus(CombinedScanStatus targetStatus) {
    final currentIndex = CombinedScanStatus.values.indexOf(widget.combinedScan.status);
    final targetIndex = CombinedScanStatus.values.indexOf(targetStatus);

    if (widget.combinedScan.status == CombinedScanStatus.failed) {
      // Show which step failed
      if (targetIndex < currentIndex) {
        return _StepStatus.completed;
      } else if (targetIndex == currentIndex) {
        return _StepStatus.inProgress; // Failed at this step
      } else {
        return _StepStatus.pending;
      }
    }

    if (targetIndex < currentIndex) {
      return _StepStatus.completed;
    } else if (targetIndex == currentIndex) {
      return _StepStatus.inProgress;
    } else {
      return _StepStatus.pending;
    }
  }

  bool _hasReachedGlbReady() {
    final currentIndex = CombinedScanStatus.values.indexOf(widget.combinedScan.status);
    final glbReadyIndex = CombinedScanStatus.values.indexOf(CombinedScanStatus.glbReady);
    return currentIndex >= glbReadyIndex;
  }

  bool _isProcessing() {
    return widget.combinedScan.status != CombinedScanStatus.completed &&
        widget.combinedScan.status != CombinedScanStatus.failed &&
        widget.combinedScan.status != CombinedScanStatus.glbReady;
  }

  Widget _buildProgressIndicator() {
    // Use linear progress for upload stages with known progress
    if (widget.combinedScan.status == CombinedScanStatus.uploadingUsdz ||
        widget.combinedScan.status == CombinedScanStatus.uploadingToBlender) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: widget.uploadProgress),
          const SizedBox(height: 8),
          Text(
            '${(widget.uploadProgress * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    // Use circular progress for other processing stages
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildActionButton() {
    if (widget.combinedScan.status == CombinedScanStatus.completed) {
      // Show Close button when complete
      return ElevatedButton(
        onPressed: widget.onClose,
        child: const Text('Close'),
      );
    } else if (widget.combinedScan.status == CombinedScanStatus.failed) {
      // Show Retry and Close buttons when failed
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.onRetry != null) ...[
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(width: 12),
          ],
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Close'),
          ),
        ],
      );
    } else if (widget.combinedScan.status == CombinedScanStatus.glbReady) {
      // GLB ready state - no action button (will auto-close or proceed)
      return ElevatedButton(
        onPressed: widget.onClose,
        child: const Text('Close'),
      );
    } else {
      // Show Cancel button during processing
      return TextButton(
        onPressed: widget.onCancel,
        child: const Text('Cancel'),
      );
    }
  }
}

enum _StepStatus {
  completed,
  inProgress,
  pending,
}
