import 'package:flutter/material.dart';
import 'scan_list_screen.dart';

/// Router screen that shows the scan list (AreaScan.jpg)
///
/// Both guest and logged-in users see the scan list first.
/// Users can press "Scan another room" button to initiate new scan.
class LidarRouterScreen extends StatelessWidget {
  const LidarRouterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Always show scan list (matches Requirements/AreaScan.jpg)
    // The list can be empty, showing empty state with "Scan another room" button
    return const ScanListScreen();
  }
}
