import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/project_data/widgets/project_form.dart';
import '../../../helpers/test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeI18nForTest();
  });

  group('ProjectForm Widget Tests - Name Validation', () {
    testWidgets('displays name field', (WidgetTester tester) async {
      // Arrange
      final nameController = TextEditingController();
      final descriptionController = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectForm(
              nameController: nameController,
              descriptionController: descriptionController,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('shows error when name is empty', (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: '');
      final descriptionController = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ProjectForm(
                nameController: nameController,
                descriptionController: descriptionController,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      // Assert
      expect(find.textContaining('required'), findsOneWidget);
    });

    testWidgets('shows error when name is too short',
        (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: 'AB');
      final descriptionController = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ProjectForm(
                nameController: nameController,
                descriptionController: descriptionController,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      // Assert
      expect(find.textContaining('at least 3'), findsOneWidget);
    });

    testWidgets('accepts valid name', (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: 'Valid Project Name');
      final descriptionController = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ProjectForm(
                nameController: nameController,
                descriptionController: descriptionController,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      final isValid = formKey.currentState!.validate();

      // Assert
      expect(isValid, isTrue);
    });
  });

  group('ProjectForm Widget Tests - Description Validation', () {
    testWidgets('accepts empty description', (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: 'Valid Name');
      final descriptionController = TextEditingController(text: '');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ProjectForm(
                nameController: nameController,
                descriptionController: descriptionController,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      final isValid = formKey.currentState!.validate();

      // Assert
      expect(isValid, isTrue);
    });

    testWidgets('shows error when description is too long',
        (WidgetTester tester) async {
      // Arrange
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: 'Valid Name');
      final longDescription = 'A' * 501; // 501 characters
      final descriptionController = TextEditingController(text: longDescription);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ProjectForm(
                nameController: nameController,
                descriptionController: descriptionController,
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      // Assert - Look for error message, not character counter
      expect(find.textContaining('less than 500'), findsOneWidget);
    });
  });
}
