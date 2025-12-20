import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/widgets/email_input.dart';

void main() {
  group('EmailInput Widget', () {
    testWidgets('displays email label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInput(
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('shows email keyboard type', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInput(controller: controller),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('does not obscure text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInput(controller: controller),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, false);
    });

    testWidgets('displays validation error for empty email', (tester) async {
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: EmailInput(controller: controller),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('displays validation error for invalid email format', (tester) async {
      final controller = TextEditingController(text: 'notanemail');
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: EmailInput(controller: controller),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('does not display error for valid email', (tester) async {
      final controller = TextEditingController(text: 'user@example.com');
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: EmailInput(controller: controller),
            ),
          ),
        ),
      );

      // Trigger validation
      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, true);
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Invalid email format'), findsNothing);
    });

    testWidgets('has accessible semantic label', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmailInput(controller: controller),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(EmailInput));
      expect(semantics.label, contains('Email'));
    });
  });
}
