import 'package:flutter/material.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/project_data/screens/project_data_screen.dart';
import 'package:vronmobile2/features/project_detail/screens/project_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize i18n service
  await I18nService().initialize();

  // Initialize GraphQL service
  GraphQLService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: I18nService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'VRon Mobile',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
          routes: {
            '/project-detail': (context) {
              // Extract project ID from arguments
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              final projectId = args?['projectId'] as String? ?? '';
              return ProjectDetailScreen(projectId: projectId);
            },
            '/project-data': (context) {
              // Extract arguments for project data edit screen
              final args =
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>?;
              final projectId = args?['projectId'] as String? ?? '';
              final initialName = args?['initialName'] as String? ?? '';
              final initialDescription = args?['initialDescription'] as String? ?? '';
              return ProjectDataScreen(
                projectId: projectId,
                initialName: initialName,
                initialDescription: initialDescription,
              );
            },
          },
        );
      },
    );
  }
}

/// Temporary home screen for testing navigation to project detail
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VRon Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to VRon Mobile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/project-detail',
                  arguments: {'projectId': 'test-project-id'},
                );
              },
              child: const Text('View Project Detail'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: This is a temporary home screen.\nFeature 002 (home screen) will replace this.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
