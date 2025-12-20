import 'package:flutter/material.dart';
import 'package:vronmobile2/core/theme/app_theme.dart';
import 'package:vronmobile2/core/navigation/routes.dart';
import 'package:vronmobile2/features/auth/screens/main_screen.dart';

void main() {
  runApp(const VronApp());
}

class VronApp extends StatelessWidget {
  const VronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VRON',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.main,
      routes: {
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.createAccount: (context) => const PlaceholderScreen(title: 'Create Account'),
        AppRoutes.guestMode: (context) => const PlaceholderScreen(title: 'Guest Mode'),
      },
      debugShowCheckedModeBanner: false,
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
      appBar: AppBar(
        title: Text(title),
      ),
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
