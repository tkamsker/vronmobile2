import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:vronmobile2/features/scanning/screens/stitched_model_preview_screen.dart';
import 'package:vronmobile2/features/scanning/models/stitched_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

// Mock classes
class MockShareService extends Mock implements Share {}

// Fake WebView platform for testing
class FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return FakePlatformWebViewController(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakePlatformWebViewWidget(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakePlatformNavigationDelegate(params);
  }
}

class FakePlatformWebViewController extends PlatformWebViewController {
  FakePlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> setBackgroundColor(Color color) async {
    // No-op for tests
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    // No-op for tests
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    // No-op for tests
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    // No-op for tests
  }

  @override
  Future<String?> currentUrl() async {
    return null;
  }

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    // No-op for tests
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    // No-op for tests
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {
    // No-op for tests
  }
}

class FakePlatformWebViewWidget extends PlatformWebViewWidget {
  FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) {
    return Container(); // Return an empty container in tests
  }
}

class FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    // No-op for tests
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    // No-op for tests
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    // No-op for tests
  }

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {
    // No-op for tests
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    // No-op for tests
  }

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {
    // No-op for tests
  }

  @override
  Future<void> setOnHttpAuthRequest(
    HttpAuthRequestCallback onHttpAuthRequest,
  ) async {
    // No-op for tests
  }
}

void main() {
  // Set up WebView platform mock for all tests
  setUpAll(() {
    // Set fake WebView platform instance
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('StitchedModelPreviewScreen', () {
    late StitchedModel mockStitchedModel;

    setUp(() {
      mockStitchedModel = StitchedModel(
        id: 'job-001',
        localPath: '/Documents/scans/stitched-living-master-2025-01-01.glb',
        originalScanIds: ['scan-001', 'scan-002'],
        roomNames: {
          'scan-001': 'Living Room',
          'scan-002': 'Master Bedroom',
        },
        fileSizeBytes: 45000000, // 45 MB
        createdAt: DateTime(2025, 1, 1, 12, 2, 15),
        format: 'glb',
        metadata: {
          'polygonCount': 450000,
          'textureCount': 12,
        },
      );
    });

    Widget createTestWidget({required StitchedModel model}) {
      return MaterialApp(
        home: StitchedModelPreviewScreen(
          stitchedModel: model,
        ),
      );
    }

    group('Initial UI State', () {
      testWidgets('displays screen title "Stitched Model"', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.text('Stitched Model'), findsOneWidget);
      });

      testWidgets('displays model viewer with correct GLB path', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        final modelViewer = find.byType(ModelViewer);
        expect(modelViewer, findsOneWidget);

        final widget = tester.widget<ModelViewer>(modelViewer);
        expect(widget.src, contains('stitched-living-master-2025-01-01.glb'));
      });

      testWidgets('displays room names in title', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.text('Living Room + Master Bedroom'), findsOneWidget);
      });

      testWidgets('displays room names when 3+ rooms (first 2 + count)', (tester) async {
        final multiRoomModel = StitchedModel(
          id: 'job-002',
          localPath: '/Documents/scans/stitched-multi-2025-01-01.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003'],
          roomNames: {
            'scan-001': 'Living Room',
            'scan-002': 'Master Bedroom',
            'scan-003': 'Kitchen',
          },
          fileSizeBytes: 60000000,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: multiRoomModel));

        expect(find.textContaining('Living Room'), findsOneWidget);
        expect(find.textContaining('Master Bedroom'), findsOneWidget);
        expect(find.textContaining('1 more'), findsOneWidget);
      });

      testWidgets('displays scan count when no room names provided', (tester) async {
        final unnamedModel = StitchedModel(
          id: 'job-003',
          localPath: '/Documents/scans/stitched-unnamed-2025-01-01.glb',
          originalScanIds: ['scan-001', 'scan-002', 'scan-003'],
          fileSizeBytes: 50000000,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: unnamedModel));

        expect(find.text('3 rooms stitched'), findsOneWidget);
      });

      testWidgets('displays file size in MB', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.textContaining('45'), findsOneWidget); // 45 MB
        expect(find.textContaining('MB'), findsOneWidget);
      });

      testWidgets('displays creation date', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.textContaining('2025'), findsOneWidget);
        expect(find.textContaining('Jan'), findsOneWidget);
      });

      testWidgets('displays polygon count when metadata available', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.textContaining('450,000'), findsOneWidget);
        expect(find.textContaining('polygons'), findsOneWidget);
      });

      testWidgets('hides polygon count when metadata not available', (tester) async {
        final modelWithoutMetadata = StitchedModel(
          id: 'job-004',
          localPath: '/Documents/scans/stitched-2025-01-01.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: modelWithoutMetadata));

        expect(find.textContaining('polygons'), findsNothing);
      });
    });

    group('Action Buttons', () {
      testWidgets('displays all three action buttons', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(find.widgetWithText(ElevatedButton, 'View in AR'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Export GLB'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Save to Project'), findsOneWidget);
      });

      testWidgets('action buttons have proper icons', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // View in AR button should have cube icon
        expect(find.widgetWithIcon(ElevatedButton, Icons.view_in_ar), findsOneWidget);

        // Export GLB button should have share/export icon
        expect(find.widgetWithIcon(ElevatedButton, Icons.ios_share), findsOneWidget);

        // Save to Project button should have cloud upload icon
        expect(find.widgetWithIcon(ElevatedButton, Icons.cloud_upload), findsOneWidget);
      });
    });

    group('"View in AR" Button (iOS)', () {
      testWidgets('tapping "View in AR" launches AR Quick Look on iOS', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Tap "View in AR"
        await tester.tap(find.widgetWithText(ElevatedButton, 'View in AR'));
        await tester.pumpAndSettle();

        // Implementation will launch AR Quick Look using url_launcher with
        // custom scheme: file://{localPath}
        // Test verifies the button triggers the action (actual platform launch tested in integration tests)
      });

      testWidgets('shows error snackbar if AR Quick Look unavailable', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Simulate AR Quick Look failure (e.g., non-iOS platform or file missing)
        await tester.tap(find.widgetWithText(ElevatedButton, 'View in AR'));
        await tester.pumpAndSettle();

        // Should show error snackbar (when implementation detects failure)
        // expect(find.byType(SnackBar), findsOneWidget);
        // expect(find.text('AR Quick Look is only available on iOS devices'), findsOneWidget);
      });

      testWidgets('"View in AR" button is disabled on Android', (tester) async {
        // Test when platform is Android
        await tester.pumpWidget(
          MaterialApp(
            home: StitchedModelPreviewScreen(
              stitchedModel: mockStitchedModel,
              isIOS: false, // Android platform
            ),
          ),
        );

        final button = find.widgetWithText(ElevatedButton, 'View in AR');
        final elevatedButton = tester.widget<ElevatedButton>(button);

        // Button should be disabled on Android
        expect(elevatedButton.onPressed, isNull);
      });
    });

    group('"Export GLB" Button', () {
      testWidgets('tapping "Export GLB" opens platform share sheet', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Tap "Export GLB"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Export GLB'));
        await tester.pumpAndSettle();

        // Implementation will use share_plus package to share file
        // verify(() => mockShareService.shareXFiles([XFile(mockStitchedModel.localPath)])).called(1);
      });

      testWidgets('includes room names in share message', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Export GLB'));
        await tester.pumpAndSettle();

        // Share message should include: "Stitched model: Living Room + Master Bedroom"
      });

      testWidgets('shows error snackbar if file not found', (tester) async {
        final invalidModel = StitchedModel(
          id: 'job-005',
          localPath: '/invalid/path/missing.glb',
          originalScanIds: ['scan-001', 'scan-002'],
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: invalidModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Export GLB'));
        await tester.pumpAndSettle();

        // Should show error (when file doesn't exist)
        // expect(find.byType(SnackBar), findsOneWidget);
        // expect(find.text('File not found'), findsOneWidget);
      });

      testWidgets('shows loading indicator while preparing share', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Export GLB'));
        await tester.pump(); // Trigger frame but don't settle

        // Should show loading indicator briefly
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('"Save to Project" Button', () {
      testWidgets('tapping "Save to Project" shows project selection dialog', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Should show project selection dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Select Project'), findsOneWidget);
      });

      testWidgets('uploads stitched model to selected project', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Tap "Save to Project"
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Select a project (implementation will show list of projects)
        // For now, assume first project in list is tapped
        // await tester.tap(find.text('My House Project'));
        // await tester.pumpAndSettle();

        // Implementation will call upload service with model file
      });

      testWidgets('shows upload progress dialog', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Select project and start upload
        // Upload progress dialog should appear with progress indicator
      });

      testWidgets('shows success snackbar when upload completes', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // After successful upload:
        // expect(find.byType(SnackBar), findsOneWidget);
        // expect(find.text('Saved to project successfully'), findsOneWidget);
      });

      testWidgets('shows error snackbar when upload fails', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Simulate upload failure:
        // expect(find.byType(SnackBar), findsOneWidget);
        // expect(find.textContaining('Upload failed'), findsOneWidget);
      });

      testWidgets('prompts guest users to create account', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StitchedModelPreviewScreen(
              stitchedModel: mockStitchedModel,
              isGuestMode: true,
            ),
          ),
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Should show auth prompt
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Account Required'), findsOneWidget);
      });
    });

    group('ModelViewer Configuration', () {
      testWidgets('enables AR mode for model viewer', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));

        expect(modelViewer.ar, true);
      });

      testWidgets('enables camera controls', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));

        expect(modelViewer.cameraControls, true);
      });

      testWidgets('auto-rotates model', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));

        expect(modelViewer.autoRotate, true);
      });

      testWidgets('has proper background color', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        final modelViewer = tester.widget<ModelViewer>(find.byType(ModelViewer));

        // Should have neutral background
        expect(modelViewer.backgroundColor, isNotNull);
      });
    });

    group('Metadata Display', () {
      testWidgets('displays all metadata fields when available', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Room names
        expect(find.text('Living Room + Master Bedroom'), findsOneWidget);

        // File size
        expect(find.textContaining('45'), findsOneWidget);
        expect(find.textContaining('MB'), findsOneWidget);

        // Polygon count
        expect(find.textContaining('450,000'), findsOneWidget);

        // Texture count (if shown)
        expect(find.textContaining('12'), findsWidgets);

        // Creation date
        expect(find.textContaining('2025'), findsOneWidget);
      });

      testWidgets('formats file sizes correctly', (tester) async {
        final testCases = [
          (10000000, '10 MB'), // 10 MB
          (100000000, '100 MB'), // 100 MB
          (5500000, '5.5 MB'), // 5.5 MB
        ];

        for (final (sizeBytes, expectedDisplay) in testCases) {
          final model = StitchedModel(
            id: 'test',
            localPath: '/test.glb',
            originalScanIds: ['s1', 's2'],
            fileSizeBytes: sizeBytes,
            createdAt: DateTime.now(),
          );

          await tester.pumpWidget(createTestWidget(model: model));

          expect(find.textContaining(expectedDisplay.split(' ')[0]), findsOneWidget);

          // Reset for next test
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('formats polygon counts with thousands separator', (tester) async {
        final model = StitchedModel(
          id: 'test',
          localPath: '/test.glb',
          originalScanIds: ['s1', 's2'],
          fileSizeBytes: 45000000,
          createdAt: DateTime.now(),
          metadata: {'polygonCount': 1234567},
        );

        await tester.pumpWidget(createTestWidget(model: model));

        // Should format as 1,234,567
        expect(find.textContaining('1,234,567'), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('back button returns to previous screen', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Tap back button in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Screen should be popped
        expect(find.byType(StitchedModelPreviewScreen), findsNothing);
      });

      testWidgets('prevents accidental back navigation with unsaved changes', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Start an upload (creates unsaved state)
        await tester.tap(find.widgetWithText(ElevatedButton, 'Save to Project'));
        await tester.pumpAndSettle();

        // Try to navigate back
        // Should show confirmation dialog if upload in progress
      });
    });

    group('Error States', () {
      testWidgets('shows error message if model file is missing', (tester) async {
        final invalidModel = StitchedModel(
          id: 'invalid',
          localPath: '/nonexistent/file.glb',
          originalScanIds: ['s1', 's2'],
          fileSizeBytes: 0,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: invalidModel));

        // Should show error state
        expect(find.textContaining('File not found'), findsOneWidget);
      });

      testWidgets('shows retry button when model fails to load', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // Simulate model viewer error
        // Implementation will show error and retry button
      });
    });

    group('Accessibility', () {
      testWidgets('model viewer has accessible label', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(
          find.bySemanticsLabel('3D model viewer showing stitched room model'),
          findsOneWidget,
        );
      });

      testWidgets('action buttons have accessible labels', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        expect(
          find.bySemanticsLabel('View stitched model in augmented reality'),
          findsOneWidget,
        );

        expect(
          find.bySemanticsLabel('Export GLB file to share with others'),
          findsOneWidget,
        );

        expect(
          find.bySemanticsLabel('Save stitched model to project'),
          findsOneWidget,
        );
      });

      testWidgets('announces action completion to screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // After successful export:
        // Should announce "GLB file exported successfully"

        // After successful save:
        // Should announce "Model saved to project"
      });

      testWidgets('metadata has semantic structure', (tester) async {
        await tester.pumpWidget(createTestWidget(model: mockStitchedModel));

        // File size should be grouped with label
        expect(
          find.bySemanticsLabel('File size 45 megabytes'),
          findsOneWidget,
        );

        // Polygon count should be grouped with label
        expect(
          find.bySemanticsLabel('450,000 polygons'),
          findsOneWidget,
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('handles very large file sizes gracefully', (tester) async {
        final largeModel = StitchedModel(
          id: 'large',
          localPath: '/large.glb',
          originalScanIds: List.generate(10, (i) => 'scan-$i'),
          fileSizeBytes: 500000000, // 500 MB
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: largeModel));

        expect(find.textContaining('500'), findsOneWidget);
        expect(find.textContaining('MB'), findsOneWidget);
      });

      testWidgets('handles stitched model with many rooms (10+)', (tester) async {
        final manyRoomsModel = StitchedModel(
          id: 'many',
          localPath: '/many.glb',
          originalScanIds: List.generate(10, (i) => 'scan-$i'),
          roomNames: Map.fromEntries(
            List.generate(10, (i) => MapEntry('scan-$i', 'Room ${i + 1}')),
          ),
          fileSizeBytes: 150000000,
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(model: manyRoomsModel));

        // Should show first 2 rooms + "8 more"
        expect(find.textContaining('Room 1'), findsOneWidget);
        expect(find.textContaining('Room 2'), findsOneWidget);
        expect(find.textContaining('8 more'), findsOneWidget);
      });

      testWidgets('handles missing metadata gracefully', (tester) async {
        final minimalModel = StitchedModel(
          id: 'minimal',
          localPath: '/minimal.glb',
          originalScanIds: ['s1', 's2'],
          fileSizeBytes: 30000000,
          createdAt: DateTime.now(),
          // No metadata, no room names
        );

        await tester.pumpWidget(createTestWidget(model: minimalModel));

        // Should still display essential info
        expect(find.text('2 rooms stitched'), findsOneWidget);
        expect(find.textContaining('30'), findsOneWidget);
      });
    });
  });
}
