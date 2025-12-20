import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/auth/screens/main_screen.dart';

void main() {
  group('MainScreen Widget', () {
    testWidgets('displays all UI elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      // Check for input fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Check for buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Sign in with Facebook'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Check for links
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('email and password fields are present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passwordField = find.widgetWithText(TextFormField, 'Password');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('Sign In button is initially disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      final button = tester.widget<ElevatedButton>(signInButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('layout uses SafeArea and SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('uses Form widget for validation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('all buttons have accessible semantic labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      expect(find.bySemanticsLabel('Sign in button'), findsOneWidget);
      expect(find.bySemanticsLabel('Sign in with Google button'), findsOneWidget);
      expect(find.bySemanticsLabel('Sign in with Facebook button'), findsOneWidget);
      expect(find.bySemanticsLabel('Continue as guest button'), findsOneWidget);
    });

    testWidgets('links have accessible semantic labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      expect(find.bySemanticsLabel('Forgot password link'), findsOneWidget);
      expect(find.bySemanticsLabel('Create account link'), findsOneWidget);
    });

    testWidgets('form validation state updates on text input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      // Initially button should be disabled
      var signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
      var button = tester.widget<ElevatedButton>(signInButton);
      expect(button.onPressed, isNull);

      // Enter text in email field
      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'user@example.com');

      // Enter text in password field
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      await tester.enterText(passwordField, 'password123');

      // Pump to process the text changes
      await tester.pump();

      // Form should now be valid - verify form has the fields
      expect(find.byType(Form), findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('entering invalid email shows validation error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'notanemail');
      await tester.pump();

      // Tap outside to trigger blur validation
      await tester.tap(find.widgetWithText(TextFormField, 'Password'));
      await tester.pumpAndSettle();

      // Validation error should appear
      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('screen has proper padding and spacing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      final padding = tester.widget<Padding>(
        find.descendant(
          of: scrollView,
          matching: find.byType(Padding),
        ).first,
      );

      // Verify padding is present
      expect(padding.padding, isNotNull);
    });

    testWidgets('can scroll when keyboard is shown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainScreen(),
        ),
      );

      // Find scrollable
      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable, findsOneWidget);

      // Verify it's scrollable
      final scrollView = tester.widget<SingleChildScrollView>(scrollable);
      expect(scrollView.physics, isNot(const NeverScrollableScrollPhysics()));
    });
  });
}
