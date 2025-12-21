import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/widgets/password_input.dart';

void main() {
  group('PasswordInput Widget', () {
    testWidgets('displays password label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordInput(controller: TextEditingController()),
          ),
        ),
      );

      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('obscures text by default', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordInput(controller: controller)),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
    });

    testWidgets('shows visibility toggle button', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordInput(controller: controller)),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('toggles password visibility when icon is tapped', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordInput(controller: controller)),
        ),
      );

      // Initially obscured
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, false);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Obscured again
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, true);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('displays validation error for empty password', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: PasswordInput(controller: controller),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('does not display error for non-empty password', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'password123');
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: PasswordInput(controller: controller),
            ),
          ),
        ),
      );

      // Trigger validation
      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, true);
      expect(find.text('Password is required'), findsNothing);
    });

    testWidgets('has accessible semantic label', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PasswordInput(controller: controller)),
        ),
      );

      final semantics = tester.getSemantics(find.byType(PasswordInput));
      expect(semantics.label, contains('Password'));
    });
  });
}
