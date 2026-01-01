import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/projects/widgets/project_tab_navigation.dart';

void main() {
  group('ProjectTabNavigation', () {
    testWidgets('T021: displays three tabs (Viewer, Project data, Products)', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Assert
      expect(find.text('Viewer'), findsOneWidget);
      expect(find.text('Project data'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
    });

    testWidgets('T021: initially displays Viewer tab as selected', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Assert - Viewer should be the default/first tab
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, 0);
    });

    testWidgets('T021: switches to Project data tab when tapped', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Tap on "Project data" tab
      await tester.tap(find.text('Project data'));
      await tester.pumpAndSettle();

      // Assert
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, 1);
    });

    testWidgets('T021: switches to Products tab when tapped', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Tap on "Products" tab
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      // Assert
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, 2);
    });

    testWidgets('T021: tabs maintain state when switching between them', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Tap on "Project data" tab
      await tester.tap(find.text('Project data'));
      await tester.pumpAndSettle();

      // Tap back on "Viewer" tab
      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();

      // Assert - Viewer tab should be selected again
      final TabBar tabBar = tester.widget(find.byType(TabBar));
      expect(tabBar.controller?.index, 0);
    });

    testWidgets('T021: uses TabBarView for tab content', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProjectTabNavigation())),
      );

      // Assert - Should have TabBarView to display tab content
      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('T021: calls onTabChanged callback when tab switches', (
      WidgetTester tester,
    ) async {
      // Arrange
      int? selectedTabIndex;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectTabNavigation(
              onTabChanged: (index) => selectedTabIndex = index,
            ),
          ),
        ),
      );

      // Tap on "Products" tab
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedTabIndex, 2);
    });
  });
}
