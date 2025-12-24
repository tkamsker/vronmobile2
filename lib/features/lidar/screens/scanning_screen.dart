import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/features/guest/widgets/guest_mode_banner.dart';
import 'package:vronmobile2/features/guest/widgets/account_creation_dialog.dart';

/// Scanning screen for LiDAR scanning
/// Handles both guest mode and authenticated mode
class ScanningScreen extends StatefulWidget {
  final GuestSessionManager guestSessionManager;

  const ScanningScreen({
    super.key,
    required this.guestSessionManager,
  });

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  bool get _isGuestMode => widget.guestSessionManager.isGuestMode;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🎯 [SCANNING] Screen initialized. Guest mode: $_isGuestMode');
    }
  }

  /// T034: Show account creation dialog
  void _promptAccountCreation() {
    showDialog(
      context: context,
      builder: (context) => AccountCreationDialog(
        onSignUp: _handleSignUp,
      ),
    );
  }

  /// T036: Handle Sign Up action - disable guest mode and navigate to signup
  Future<void> _handleSignUp() async {
    if (kDebugMode) print('🔐 [GUEST] Sign Up pressed - disabling guest mode');

    try {
      // Disable guest mode
      await widget.guestSessionManager.disableGuestMode();

      if (!mounted) return;

      // Navigate to signup screen
      if (kDebugMode) print('🔐 [GUEST] Navigating to signup screen');
      Navigator.pushNamed(context, AppRoutes.signup);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [GUEST] Failed to handle sign up: ${e.toString()}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to proceed to sign up: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleExportGLB() {
    if (kDebugMode) print('📦 [SCANNING] Export GLB pressed');
    // TODO: Implement GLB export (Phase 5)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GLB export coming soon')),
    );
  }

  void _handleSaveToProject() {
    if (kDebugMode) print('☁️ [SCANNING] Save to Project pressed');
    // TODO: Implement save to project (authenticated users only)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save to project coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Scanning'),
      ),
      body: Column(
        children: [
          // T032: Show guest mode banner conditionally
          if (_isGuestMode)
            GuestModeBanner(
              onSignUpPressed: _promptAccountCreation, // T035: Wire Sign Up button
            ),

          // Main scanning area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Scanning Area',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isGuestMode
                        ? 'Guest Mode - Scans saved locally'
                        : 'Scan and save to cloud',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // T033: Hide "Save to Project" button in guest mode
                if (!_isGuestMode)
                  ElevatedButton.icon(
                    onPressed: _handleSaveToProject,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Save to Project'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),

                if (!_isGuestMode) const SizedBox(height: 12),

                // Export GLB button (available in both modes)
                OutlinedButton.icon(
                  onPressed: _handleExportGLB,
                  icon: const Icon(Icons.download),
                  label: const Text('Export GLB'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
