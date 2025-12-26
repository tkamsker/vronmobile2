import 'package:flutter/material.dart';
import '../services/scan_session_manager.dart';
import 'scan_list_screen.dart';
import 'scanning_screen.dart';
import '../../../main.dart' show guestSessionManager;

/// Router screen that decides whether to show scan list or start new scan
/// - Logged-in users: Always show scan list (can be empty)
/// - Guest mode: Show scanning screen directly
class LidarRouterScreen extends StatelessWidget {
  const LidarRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Guest mode: Go directly to scanning screen (auto-launches)
    if (guestSessionManager.isGuestMode) {
      return const ScanningScreen();
    }

    // Logged-in mode: Always show scan list
    // User can press "Scan another room" to start scanning
    return const ScanListScreen();
  }
}
