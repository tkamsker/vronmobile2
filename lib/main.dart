import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/core/theme/app_theme.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/features/auth/screens/main_screen.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/profile/screens/language_screen.dart';
import 'package:vronmobile2/features/profile/screens/profile_screen.dart';
import 'package:vronmobile2/features/products/screens/product_detail_screen.dart';
import 'package:vronmobile2/features/products/screens/products_list_screen.dart';
import 'package:vronmobile2/features/projects/screens/project_detail_screen.dart';
import 'package:vronmobile2/features/projects/screens/create_project_screen.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/features/lidar/screens/scanning_screen.dart';

/// Global guest session manager instance
late GuestSessionManager guestSessionManager;

void main() async {
  // Ensure Flutter is initialized before loading environment
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize i18n service (load translations and saved language preference)
  await I18nService().initialize();

  // Load environment configuration from .env file
  await EnvConfig.initialize();

  // Initialize guest session manager
  final prefs = await SharedPreferences.getInstance();
  guestSessionManager = GuestSessionManager(prefs: prefs);
  await guestSessionManager.initialize();

  runApp(const VronApp());
}

class VronApp extends StatelessWidget {
  const VronApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to i18n service for language changes and rebuild UI
    return ListenableBuilder(
      listenable: I18nService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'VRON',
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.main,
          routes: {
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.home: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return HomeScreen(userEmail: email);
        },
        AppRoutes.createAccount: (context) =>
            const PlaceholderScreen(title: 'Create Account'),
        AppRoutes.guestMode: (context) =>
            ScanningScreen(guestSessionManager: guestSessionManager),
        AppRoutes.projectDetail: (context) {
          final projectId = ModalRoute.of(context)?.settings.arguments as String?;
          if (projectId == null) {
            return const PlaceholderScreen(title: 'Error: No project ID');
          }
          return ProjectDetailScreen(projectId: projectId);
        },
        AppRoutes.createProject: (context) =>
            const CreateProjectScreen(),
        AppRoutes.products: (context) => const ProductsListScreen(),
        AppRoutes.productDetail: (context) {
          final productId = ModalRoute.of(context)?.settings.arguments as String?;
          if (productId == null) {
            return const PlaceholderScreen(title: 'Error: No product ID');
          }
          return ProductDetailScreen(productId: productId);
        },
        AppRoutes.lidar: (context) =>
            const PlaceholderScreen(title: 'LiDAR Scanner'),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.language: (context) => const LanguageScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Screen: $title\n(To be implemented)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
