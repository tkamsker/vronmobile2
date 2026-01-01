import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class ScanProgress extends StatelessWidget {
  final double? progress; // 0.0 to 1.0, null for indeterminate
  final VoidCallback? onStop;
  final Duration? elapsedTime;

  const ScanProgress({super.key, this.progress, this.onStop, this.elapsedTime});

  @override
  Widget build(BuildContext context) {
    final isComplete = progress != null && progress! >= 1.0;
    final progressPercent = progress != null ? (progress! * 100).round() : 0;

    return Semantics(
      label: AppStrings.scanProgressSemantics,
      hint: AppStrings.scanProgressHint,
      value: progress != null ? '$progressPercent%' : 'scanning',
      child: Card(
        elevation: 4.0,
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                isComplete
                    ? AppStrings.scanComplete
                    : AppStrings.scanInProgress,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),

              // Progress indicator
              LinearProgressIndicator(
                value: progress,
                minHeight: 8.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(height: 12.0),

              // Progress percentage and elapsed time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (progress != null)
                    Text(
                      '$progressPercent%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (elapsedTime != null)
                    Text(
                      _formatDuration(elapsedTime!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),

              // Stop button (only shown during scan, not when complete)
              if (!isComplete && onStop != null) ...[
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop),
                    label: Text(AppStrings.stopScanButton),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ],

              // Completion message
              if (isComplete) ...[
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 24.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          AppStrings.scanSaved,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
