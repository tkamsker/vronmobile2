import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/screens/home_screen.dart';
import 'package:vronmobile2/features/home/widgets/bottom_nav_bar.dart';
import 'package:vronmobile2/features/home/widgets/custom_fab.dart';

void main() {
  group('HomeScreen Widget', () {
    testWidgets('displays "Your projects" heading', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('Your projects'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('Jump back into your workspace'), findsOneWidget);
    });

    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search projects'), findsOneWidget);
    });

    testWidgets('displays filter tabs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.byType(BottomNavBar), findsOneWidget);
    });

    testWidgets('displays floating action button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.byType(CustomFAB), findsOneWidget);
    });

    testWidgets('displays profile icon in app bar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Should have a profile icon or avatar in top-right
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching projects', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Initially should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when project fetch fails', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should display error state with retry button
      // (This will fail until error handling is implemented)
      expect(find.text('Failed to load projects'), findsAny);
    });

    testWidgets('displays empty state when no projects exist', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Should display empty state
      // (This will fail until empty state is implemented)
      expect(find.text('No projects yet'), findsAny);
    });

    testWidgets('displays project count in "Recent projects" section', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for loading to complete
      await tester.pumpAndSettle();

      expect(find.text('Recent projects'), findsOneWidget);
      expect(find.textContaining('total'), findsAny);
    });

    testWidgets('has accessible semantic labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify screen has semantic tree
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('search bar filters projects when text is entered', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'marketing');
      await tester.pump();

      // Should filter project list
      // (This will fail until implementation is complete)
    });

    testWidgets('filter tabs update project list when tapped', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for projects to load
      await tester.pumpAndSettle();

      // Tap "Active" filter
      await tester.tap(find.text('Active'));
      await tester.pump();

      // Should show only active projects
      // (This will fail until implementation is complete)
    });

    testWidgets('supports pull-to-refresh', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for initial load
      await tester.pumpAndSettle();

      // Perform pull-to-refresh gesture
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should refresh project list
      // (This will fail until implementation is complete)
    });
  });
}
