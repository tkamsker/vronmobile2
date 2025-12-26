import 'package:flutter/material.dart';
import '../services/scan_session_manager.dart';
import 'scan_list_screen.dart';
import 'scanning_screen.dart';

/// Router screen that decides whether to show scan list or start new scan
/// Based on whether scans exist in current session
class LidarRouterScreen extends StatelessWidget {
  const LidarRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = ScanSessionManager();

    // If scans exist, show list; otherwise show scanning screen
    if (sessionManager.hasScans) {
      return const ScanListScreen();
    } else {
      return const ScanningScreen();
    }
  }
}
