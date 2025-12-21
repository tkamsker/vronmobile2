import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/project_detail/widgets/project_action_buttons.dart';

void main() {
  group('ProjectActionButtons Widget Tests', () {
    testWidgets('displays Project Data button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActionButtons(
              onProjectDataTap: () {},
              onProductsTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Project Data'), findsOneWidget);
    });

    testWidgets('displays Products button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActionButtons(
              onProjectDataTap: () {},
              onProductsTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Products'), findsOneWidget);
    });

    testWidgets('calls onProjectDataTap when Project Data button is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool projectDataTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActionButtons(
              onProjectDataTap: () => projectDataTapped = true,
              onProductsTap: () {},
            ),
          ),
        ),
      );

      final projectDataButton = find.textContaining('Project Data');
      await tester.tap(projectDataButton);
      await tester.pumpAndSettle();

      // Assert
      expect(projectDataTapped, isTrue);
    });

    testWidgets('calls onProductsTap when Products button is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool productsTapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActionButtons(
              onProjectDataTap: () {},
              onProductsTap: () => productsTapped = true,
            ),
          ),
        ),
      );

      final productsButton = find.textContaining('Products');
      await tester.tap(productsButton);
      await tester.pumpAndSettle();

      // Assert
      expect(productsTapped, isTrue);
    });

    testWidgets('renders both buttons with correct layout', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActionButtons(
              onProjectDataTap: () {},
              onProductsTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });
  });
}
