import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/guest/widgets/account_creation_dialog.dart';

void main() {
  group('AccountCreationDialog Widget', () {
    // T026: Test account creation dialog
    testWidgets('displays dialog with correct title and message', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AccountCreationDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Create an Account?'), findsOneWidget);
      expect(
        find.text(
          'Create an account to save your scans to the cloud and access them from any device.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('has Continue as Guest button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AccountCreationDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.widgetWithText(TextButton, 'Continue as Guest'),
        findsOneWidget,
      );
    });

    testWidgets('has Sign Up button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AccountCreationDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets('Continue as Guest button closes dialog', (
      WidgetTester tester,
    ) async {
      bool dialogClosed = false;

      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AccountCreationDialog(),
                  ).then((_) {
                    dialogClosed = true;
                  });
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(TextButton, 'Continue as Guest'));
      await tester.pumpAndSettle();

      // Assert - dialog should be closed
      expect(find.text('Create an Account?'), findsNothing);
    });

    testWidgets('Sign Up button triggers navigation callback', (
      WidgetTester tester,
    ) async {
      bool signUpPressed = false;

      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AccountCreationDialog(
                      onSignUp: () {
                        signUpPressed = true;
                      },
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle();

      // Assert
      expect(signUpPressed, true);
    });

    testWidgets('has proper semantic labels for accessibility', (
      WidgetTester tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AccountCreationDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert - verify semantic labels exist
      expect(find.bySemanticsLabel('Continue as Guest button'), findsOneWidget);
      expect(find.bySemanticsLabel('Sign Up button'), findsOneWidget);
    });
  });
}
