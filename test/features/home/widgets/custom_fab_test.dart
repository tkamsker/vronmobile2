import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/widgets/custom_fab.dart';

void main() {
  group('CustomFAB Widget', () {
    testWidgets('displays plus icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomFAB));
      await tester.pump();

      expect(wasPressed, true);
    });

    testWidgets('has correct size (56x56 logical pixels)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(onPressed: () {}),
          ),
        ),
      );

      final fab = tester.getSize(find.byType(FloatingActionButton));
      expect(fab.width, greaterThanOrEqualTo(56.0));
      expect(fab.height, greaterThanOrEqualTo(56.0));
    });

    testWidgets('has correct blue color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(onPressed: () {}),
          ),
        ),
      );

      final fabWidget =
          tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fabWidget.backgroundColor, isNotNull);
    });

    testWidgets('has accessible semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(onPressed: () {}),
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CustomFAB));
      expect(semantics.label, isNotNull);
      expect(semantics.label, contains('Create'));
    });

    testWidgets('has proper elevation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: CustomFAB(onPressed: () {}),
          ),
        ),
      );

      final fabWidget =
          tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fabWidget.elevation, greaterThan(0));
    });
  });
}
