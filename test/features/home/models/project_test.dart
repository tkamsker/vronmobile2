import 'package:flutter_test/flutter_test.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_subscription.dart';

void main() {
  group('Project Model', () {
    final testDate = DateTime.parse('2025-12-20T10:30:00Z');

    // Helper to create a test subscription
    ProjectSubscription createTestSubscription({
      bool isActive = true,
      bool isTrial = false,
      String status = 'ACTIVE',
      String renewalInterval = 'MONTHLY',
    }) {
      return ProjectSubscription(
        isActive: isActive,
        isTrial: isTrial,
        status: status,
        canChoosePlan: false,
        hasExpired: false,
        currency: 'EUR',
        price: 29.99,
        renewalInterval: renewalInterval,
        startedAt: testDate,
        expiresAt: testDate.add(const Duration(days: 30)),
        renewsAt: testDate.add(const Duration(days: 30)),
        prices: const ProjectSubscriptionPrices(
          currency: 'EUR',
          monthly: 29.99,
          yearly: 299.99,
        ),
      );
    }

    test('creates Project from valid JSON with I18NField', () {
      final json = {
        'id': 'proj_123',
        'slug': 'marketing-analytics',
        'name': {'text': 'Marketing Analytics'},
        'imageUrl': 'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
        'isLive': true,
        'liveDate': '2025-12-20T10:30:00Z',
        'subscription': {
          'isActive': true,
          'isTrial': false,
          'status': 'ACTIVE',
          'canChoosePlan': false,
          'hasExpired': false,
          'currency': 'EUR',
          'price': 29.99,
          'renewalInterval': 'MONTHLY',
          'startedAt': '2025-12-20T10:30:00Z',
          'expiresAt': '2026-01-20T10:30:00Z',
          'renewsAt': '2026-01-20T10:30:00Z',
          'prices': {'currency': 'EUR', 'monthly': 29.99, 'yearly': 299.99},
        },
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj_123');
      expect(project.slug, 'marketing-analytics');
      expect(project.name, 'Marketing Analytics');
      expect(
        project.imageUrl,
        'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
      );
      expect(project.isLive, true);
      expect(project.liveDate, testDate);
      expect(project.subscription.isActive, true);
      expect(project.subscription.status, 'ACTIVE');
    });

    test('creates Project from JSON with direct string name', () {
      final json = {
        'id': 'proj_456',
        'slug': 'product-roadmap',
        'name': 'Product Roadmap',
        'imageUrl': '',
        'isLive': false,
        'subscription': {},
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj_456');
      expect(project.slug, 'product-roadmap');
      expect(project.name, 'Product Roadmap');
      expect(project.isLive, false);
      expect(project.liveDate, null);
    });

    test('creates Project from JSON with missing optional fields', () {
      final json = {
        'id': 'proj_789',
        'slug': 'test-project',
        'name': {'text': 'Test Project'},
        'isLive': true,
        'subscription': {'isActive': false, 'status': 'NOT_STARTED'},
      };

      final project = Project.fromJson(json);

      expect(project.id, 'proj_789');
      expect(project.name, 'Test Project');
      expect(project.imageUrl, '');
      expect(project.isLive, true);
      expect(project.subscription.isActive, false);
    });

    test('statusLabel returns correct values', () {
      // Live + Active
      final liveActive = Project(
        id: '1',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: true, isTrial: false),
      );
      expect(liveActive.statusLabel, 'Live');

      // Live + Trial
      final liveTrial = Project(
        id: '2',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: false, isTrial: true),
      );
      expect(liveTrial.statusLabel, 'Live (Trial)');

      // Live + Inactive
      final liveInactive = Project(
        id: '3',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: false, isTrial: false),
      );
      expect(liveInactive.statusLabel, 'Live (Inactive)');

      // Not Live
      final notLive = Project(
        id: '4',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: false,
        subscription: createTestSubscription(),
      );
      expect(notLive.statusLabel, 'Not Live');
    });

    test('statusColorHex returns correct colors', () {
      // Green for Live + Active
      final liveActive = Project(
        id: '1',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: true),
      );
      expect(liveActive.statusColorHex, '#4CAF50');

      // Orange for Live + Trial
      final liveTrial = Project(
        id: '2',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: false, isTrial: true),
      );
      expect(liveTrial.statusColorHex, '#FF9800');

      // Gray for Not Live
      final notLive = Project(
        id: '3',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: false,
        subscription: createTestSubscription(),
      );
      expect(notLive.statusColorHex, '#9E9E9E');

      // Red for Live + Inactive
      final liveInactive = Project(
        id: '4',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: false, isTrial: false),
      );
      expect(liveInactive.statusColorHex, '#F44336');
    });

    test('shortDescription returns correct descriptions', () {
      final liveActive = Project(
        id: '1',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(isActive: true),
      );
      expect(liveActive.shortDescription, 'Live • Active subscription');

      final notLiveTrial = Project(
        id: '2',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: false,
        subscription: createTestSubscription(isTrial: true),
      );
      expect(notLiveTrial.shortDescription, 'Not published • Trial');
    });

    test('teamInfo derives from subscription', () {
      final monthly = Project(
        id: '1',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(renewalInterval: 'MONTHLY'),
      );
      expect(monthly.teamInfo, 'Monthly plan');

      final yearly = Project(
        id: '2',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(renewalInterval: 'YEARLY'),
      );
      expect(yearly.teamInfo, 'Yearly plan');
    });

    test('updatedAt uses liveDate or subscription dates', () {
      final withLiveDate = Project(
        id: '1',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        liveDate: testDate,
        subscription: createTestSubscription(),
      );
      expect(withLiveDate.updatedAt, testDate);

      final withoutLiveDate = Project(
        id: '2',
        slug: 'test',
        name: 'Test',
        imageUrl: '',
        isLive: true,
        subscription: createTestSubscription(),
      );
      expect(withoutLiveDate.updatedAt, isNotNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Project(
        id: 'proj_001',
        slug: 'original-slug',
        name: 'Original Title',
        imageUrl: 'https://example.com/image.jpg',
        isLive: false,
        subscription: createTestSubscription(),
      );

      final updated = original.copyWith(
        name: 'Updated Title',
        isLive: true,
      );

      expect(updated.id, 'proj_001');
      expect(updated.name, 'Updated Title');
      expect(updated.isLive, true);
      expect(updated.slug, 'original-slug');
    });

    test('equality works correctly', () {
      final project1 = Project(
        id: 'proj_001',
        slug: 'test-project',
        name: 'Test Project',
        imageUrl: 'https://example.com/image.jpg',
        isLive: true,
        liveDate: testDate,
        subscription: createTestSubscription(),
      );

      final project2 = Project(
        id: 'proj_001',
        slug: 'test-project',
        name: 'Test Project',
        imageUrl: 'https://example.com/image.jpg',
        isLive: true,
        liveDate: testDate,
        subscription: createTestSubscription(),
      );

      final project3 = Project(
        id: 'proj_002',
        slug: 'different-project',
        name: 'Different Project',
        imageUrl: 'https://example.com/image.jpg',
        isLive: false,
        subscription: createTestSubscription(),
      );

      expect(project1, equals(project2));
      expect(project1, isNot(equals(project3)));
      expect(project1.hashCode, equals(project2.hashCode));
    });

    test('toString returns readable format', () {
      final project = Project(
        id: 'proj_123',
        slug: 'test-project',
        name: 'Test Project',
        imageUrl: 'https://example.com/image.jpg',
        isLive: true,
        subscription: createTestSubscription(),
      );

      final result = project.toString();

      expect(result, contains('proj_123'));
      expect(result, contains('Test Project'));
      expect(result, contains('test-project'));
      expect(result, contains('true')); // isLive
    });
  });
}
