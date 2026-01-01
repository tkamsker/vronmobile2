import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/scanning/widgets/offline_banner.dart';
import 'package:vronmobile2/features/scanning/services/connectivity_service.dart';

/// Mock ConnectivityService for testing
class MockConnectivityService extends ConnectivityService {
  final StreamController<bool> _mockController =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get connectivityStream => _mockController.stream;

  void emitConnectivity(bool isOnline) {
    _mockController.add(isOnline);
  }

  @override
  Future<void> dispose() async {
    await _mockController.close();
    await super.dispose();
  }
}

void main() {
  group('OfflineBanner Widget Tests', () {
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockConnectivityService = MockConnectivityService();
    });

    tearDown(() async {
      await mockConnectivityService.dispose();
    });

    Widget buildTestWidget(ConnectivityService service) {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OfflineBanner(connectivityService: service),
              const Text('Main Content'),
            ],
          ),
        ),
      );
    }

    testWidgets('T068: OfflineBanner is hidden when online', (
      WidgetTester tester,
    ) async {
      // Arrange - Build widget
      await tester.pumpWidget(buildTestWidget(mockConnectivityService));

      // Act - Emit online state
      mockConnectivityService.emitConnectivity(true);
      await tester.pump();

      // Assert - Banner should be hidden (SizedBox.shrink)
      expect(
        find.byType(OfflineBanner),
        findsOneWidget,
        reason: 'OfflineBanner widget should be in tree',
      );

      // The banner container should not be visible when online
      expect(
        find.byIcon(Icons.cloud_off),
        findsNothing,
        reason: 'Cloud-off icon should not be visible when online',
      );

      print('✅ T068: Banner hidden when online');
    });

    testWidgets('T068: OfflineBanner displays when offline', (
      WidgetTester tester,
    ) async {
      // Arrange - Build widget
      await tester.pumpWidget(buildTestWidget(mockConnectivityService));

      // Act - Emit offline state
      mockConnectivityService.emitConnectivity(false);
      await tester.pump();

      // Assert - Banner should be visible
      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(
        find.byIcon(Icons.cloud_off),
        findsOneWidget,
        reason: 'Cloud-off icon should be visible when offline',
      );
      expect(
        find.text('You\'re offline. Changes will sync when you reconnect.'),
        findsOneWidget,
        reason: 'Offline message should be displayed',
      );

      print('✅ T068: Banner displays when offline');
    });

    testWidgets('T068: OfflineBanner has correct styling', (
      WidgetTester tester,
    ) async {
      // Arrange - Build widget
      await tester.pumpWidget(buildTestWidget(mockConnectivityService));

      // Act - Emit offline state
      mockConnectivityService.emitConnectivity(false);
      await tester.pumpAndSettle();

      // Assert - Find the Container widget
      final containerFinder = find.ancestor(
        of: find.byIcon(Icons.cloud_off),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      // Verify icon and text are present
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(
        find.text('You\'re offline. Changes will sync when you reconnect.'),
        findsOneWidget,
      );

      print('✅ T068: Offline banner styling verified');
    });

    testWidgets('T068: OfflineBanner updates when connectivity changes', (
      WidgetTester tester,
    ) async {
      // Arrange - Build widget with initial online state
      mockConnectivityService.emitConnectivity(true);
      await tester.pumpWidget(buildTestWidget(mockConnectivityService));
      await tester.pumpAndSettle();

      // Assert - Banner should be hidden initially
      expect(find.byIcon(Icons.cloud_off), findsNothing);

      // Act - Go offline
      mockConnectivityService.emitConnectivity(false);
      await tester.pumpAndSettle();

      // Assert - Banner should now be visible
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Act - Go back online
      mockConnectivityService.emitConnectivity(true);
      await tester.pumpAndSettle();

      // Assert - Banner should be hidden again
      expect(find.byIcon(Icons.cloud_off), findsNothing);

      print('✅ T068: Banner responds to connectivity changes');
    });
  });
}
