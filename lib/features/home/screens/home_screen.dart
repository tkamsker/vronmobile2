import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vronmobile2/features/auth/services/auth_service.dart';
import 'package:vronmobile2/core/navigation/routes.dart';

/// Home screen displayed after successful authentication
class HomeScreen extends StatefulWidget {
  final String? userEmail;

  const HomeScreen({super.key, this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (kDebugMode) print('🔓 [HOME] Logout button pressed');

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();
      if (kDebugMode) print('✅ [HOME] Logout successful - tokens cleared');

      if (!mounted) return;

      // Navigate back to login screen and clear navigation stack
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);

      if (kDebugMode) print('✅ [HOME] Navigated to login screen');
    } catch (e) {
      if (kDebugMode) print('❌ [HOME] Logout error: ${e.toString()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VRON'),
        automaticallyImplyLeading: false,
        actions: [
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Welcome section
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // User email
              if (widget.userEmail != null)
                Text(
                  widget.userEmail!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 48),

              // Success card
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Authentication Successful',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are now logged in to VRON',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Info section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Authentication Details',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.check,
                        'Access token stored securely',
                      ),
                      _buildInfoRow(Icons.check, 'AUTH_CODE generated'),
                      _buildInfoRow(
                        Icons.check,
                        'GraphQL client authenticated',
                      ),
                      _buildInfoRow(Icons.check, 'Platform: merchants'),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Logout button
              OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _handleLogout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red[700]!),
                  foregroundColor: Colors.red[700],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
