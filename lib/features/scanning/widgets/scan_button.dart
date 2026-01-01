import 'package:flutter/material.dart';
import '../models/lidar_capability.dart';
import '../../../core/constants/app_strings.dart';

class ScanButton extends StatelessWidget {
  final LidarCapability capability;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ScanButton({
    super.key,
    required this.capability,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = capability.isScanningSupportpported && !isLoading;

    return Semantics(
      label: AppStrings.startScanButtonSemantics,
      hint: AppStrings.startScanButtonHint,
      button: true,
      enabled: isEnabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56.0, // Ensure minimum 44x44 touch target
            child: ElevatedButton(
              onPressed: isEnabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      AppStrings.startScanButton,
                      style: const TextStyle(fontSize: 16.0),
                    ),
            ),
          ),
          if (!capability.isScanningSupportpported) ...[
            const SizedBox(height: 12.0),
            _buildUnsupportedMessage(),
          ],
        ],
      ),
    );
  }

  Widget _buildUnsupportedMessage() {
    String message = AppStrings.lidarNotSupported;

    switch (capability.support) {
      case LidarSupport.notApplicable:
        message = AppStrings.lidarIOSOnly;
        break;
      case LidarSupport.oldIOS:
        message = AppStrings.lidarOldIOSVersion;
        break;
      case LidarSupport.noLidar:
        message = AppStrings.lidarRequiresIPhone12Pro;
        break;
      case LidarSupport.supported:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 20.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 14.0),
            ),
          ),
        ],
      ),
    );
  }
}
