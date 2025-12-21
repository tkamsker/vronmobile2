import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/home/widgets/bottom_nav_bar.dart';

/// Profile/Settings screen for managing account and app preferences
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final I18nService _i18nService = I18nService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _darkModeEnabled = false;
  bool _notificationsEnabled = false;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Load user email from secure storage (saved during login)
    final email = await _secureStorage.read(key: 'user_email');

    setState(() {
      _userEmail = email;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.logOut'.tr()),
        content: Text('profile.logOutMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('profile.logOut'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear all auth tokens
      await _secureStorage.delete(key: 'auth_code');
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.deleteAll();

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (route) => false,
        );
      }
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return; // Already on profile screen

    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => route.settings.name == AppRoutes.main,
        );
        break;
      case 1: // Projects (same as home)
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => route.settings.name == AppRoutes.main,
        );
        break;
      case 2: // LiDAR
        Navigator.pushNamed(context, AppRoutes.lidar);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildAccountSection(),
                    _buildDivider(),
                    _buildAccountOptionsSection(),
                    _buildDivider(),
                    _buildAppPreferencesSection(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    _buildLogoutMessage(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3, // Profile tab is active
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'profile.title'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'profile.signedIn'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'profile.subtitle'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'profile.lastSynced'.tr(params: {'time': '2 min'}),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.account'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'profile.accountDescription'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 36, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userEmail?.split('@')[0].toUpperCase() ?? 'User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail ?? 'user@example.com',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOptionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.lock_outline,
            title: 'profile.changePassword'.tr(),
            subtitle: 'profile.changePasswordDescription'.tr(),
            onTap: () {
              // TODO: Navigate to change password screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change password - Coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildListTile(
            icon: Icons.link,
            title: 'profile.connectedAccounts'.tr(),
            subtitle: 'profile.connectedAccountsDescription'.tr(),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSocialBadge('profile.google'.tr(), Colors.red[50]!),
                const SizedBox(width: 8),
                _buildSocialBadge('profile.facebook'.tr(), Colors.blue[50]!),
              ],
            ),
            onTap: () {
              // TODO: Navigate to connected accounts screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connected accounts - Coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.appPreferences'.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'profile.appPreferencesDescription'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'profile.darkMode'.tr(),
            subtitle: 'profile.darkModeDescription'.tr(),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // TODO: Implement dark mode
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dark mode - Coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'profile.notifications'.tr(),
            subtitle: 'profile.notificationsDescription'.tr(),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications - Coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildListTile(
            icon: Icons.language,
            title: 'profile.languageSetting'.tr(),
            subtitle: 'profile.languageSettingDescription'.tr(),
            trailing: Text(
              _i18nService.getLanguageName(_i18nService.currentLanguage),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.language);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.grey[700]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ] else
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBadge(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[50],
            foregroundColor: Colors.red[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'profile.logOut'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Text(
        'profile.logOutMessage'.tr(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
