import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

/// Banner widget that displays when device is offline
///
/// Features:
/// - Automatically shows/hides based on connectivity state
/// - Uses StreamBuilder to listen to connectivity changes
/// - Displays clear offline message with icon
/// - Non-intrusive design (top banner)
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       OfflineBanner(connectivityService: connectivityService),
///       // ... rest of your content
///     ],
///   ),
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  final ConnectivityService connectivityService;

  const OfflineBanner({Key? key, required this.connectivityService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectivityService.connectivityStream,
      initialData: true, // Assume online initially
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        // Hide banner when online
        if (isOnline) {
          return const SizedBox.shrink();
        }

        // Show banner when offline
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'re offline. Changes will sync when you reconnect.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
