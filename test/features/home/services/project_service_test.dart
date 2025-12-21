import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';

// Mock GraphQL service for testing
class MockGraphQLService extends GraphQLService {
  QueryResult? mockResult;
  Exception? mockException;

  @override
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }
    return mockResult!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProjectService', () {
    late MockGraphQLService mockGraphQLService;
    late ProjectService projectService;

    // Valid GraphQL document for mocking
    final mockDocument = gql('''
      query GetProjects(\$lang: Language!) {
        getProjects(input: {}) {
          id
          slug
          name { text(lang: \$lang) }
        }
      }
    ''');

    setUp(() {
      mockGraphQLService = MockGraphQLService();
      projectService = ProjectService(graphqlService: mockGraphQLService);
    });

    group('fetchProjects', () {
      test('returns list of projects on successful API call', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
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
                'prices': {'currency': 'EUR', 'monthly': 29.99, 'yearly': 299.99},
              },
            },
            {
              'id': 'proj_456',
              'slug': 'product-roadmap',
              'name': {'text': 'Product Roadmap'},
              'imageUrl': 'https://cdn.vron.one/projects/proj_456/thumbnail.jpg',
              'isLive': false,
              'subscription': {
                'isActive': false,
                'isTrial': true,
                'status': 'TRIAL_EXPIRED',
                'canChoosePlan': true,
                'hasExpired': true,
                'prices': {'currency': 'EUR', 'monthly': 29.99, 'yearly': 299.99},
              },
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjects();

        // Assert
        expect(projects.length, 2);
        expect(projects[0].id, 'proj_123');
        expect(projects[0].name, 'Marketing Analytics');
        expect(projects[0].isLive, true);
        expect(projects[1].id, 'proj_456');
        expect(projects[1].name, 'Product Roadmap');
        expect(projects[1].isLive, false);
      });

      test('returns empty list when no projects exist', () async {
        // Arrange
        final mockData = {'getProjects': []};

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjects();

        // Assert
        expect(projects, isEmpty);
      });

      test('returns empty list when getProjects is null', () async {
        // Arrange
        final mockData = {'getProjects': null};

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjects();

        // Assert
        expect(projects, isEmpty);
      });

      test('throws exception on GraphQL error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Unauthorized',
                extensions: {'code': 'UNAUTHENTICATED'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(() => projectService.fetchProjects(), throwsA(isA<Exception>()));
      });

      test('throws exception on network error', () async {
        // Arrange
        mockGraphQLService.mockException = Exception('Network error');

        // Act & Assert
        expect(() => projectService.fetchProjects(), throwsA(isA<Exception>()));
      });
    });

    group('fetchProjectsByLiveStatus', () {
      test('filters projects by live status', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
              'id': 'proj_123',
              'slug': 'project-1',
              'name': {'text': 'Project 1'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
            {
              'id': 'proj_456',
              'slug': 'project-2',
              'name': {'text': 'Project 2'},
              'imageUrl': '',
              'isLive': false,
              'subscription': {
                'isActive': false,
                'status': 'NOT_STARTED',
                'prices': {},
              },
            },
            {
              'id': 'proj_789',
              'slug': 'project-3',
              'name': {'text': 'Project 3'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjectsByLiveStatus(true);

        // Assert
        expect(projects.length, 2);
        expect(projects[0].isLive, true);
        expect(projects[1].isLive, true);
      });
    });

    group('fetchProjectsBySubscriptionStatus', () {
      test('filters projects by subscription status', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
              'id': 'proj_123',
              'slug': 'project-1',
              'name': {'text': 'Project 1'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
            {
              'id': 'proj_456',
              'slug': 'project-2',
              'name': {'text': 'Project 2'},
              'imageUrl': '',
              'isLive': false,
              'subscription': {
                'isActive': false,
                'status': 'TRIAL_EXPIRED',
                'prices': {},
              },
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjectsBySubscriptionStatus('ACTIVE');

        // Assert
        expect(projects.length, 1);
        expect(projects[0].subscription.status, 'ACTIVE');
      });
    });

    group('fetchActiveProjects', () {
      test('filters projects that are live and have active subscription', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
              'id': 'proj_123',
              'slug': 'project-1',
              'name': {'text': 'Project 1'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
            {
              'id': 'proj_456',
              'slug': 'project-2',
              'name': {'text': 'Project 2'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': false,
                'status': 'TRIAL_EXPIRED',
                'prices': {},
              },
            },
            {
              'id': 'proj_789',
              'slug': 'project-3',
              'name': {'text': 'Project 3'},
              'imageUrl': '',
              'isLive': false,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchActiveProjects();

        // Assert
        expect(projects.length, 1);
        expect(projects[0].isLive, true);
        expect(projects[0].subscription.isActive, true);
      });
    });

    group('searchProjects', () {
      test('searches projects by name (case-insensitive)', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
              'id': 'proj_123',
              'slug': 'marketing-analytics',
              'name': {'text': 'Marketing Analytics'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {'isActive': true, 'status': 'ACTIVE', 'prices': {}},
            },
            {
              'id': 'proj_456',
              'slug': 'product-roadmap',
              'name': {'text': 'Product Roadmap'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {'isActive': true, 'status': 'ACTIVE', 'prices': {}},
            },
            {
              'id': 'proj_789',
              'slug': 'mobile-marketing',
              'name': {'text': 'Mobile Marketing'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {'isActive': true, 'status': 'ACTIVE', 'prices': {}},
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.searchProjects('marketing');

        // Assert
        expect(projects.length, 2);
        expect(projects[0].name, 'Marketing Analytics');
        expect(projects[1].name, 'Mobile Marketing');
      });

      test('returns empty list when no matches found', () async {
        // Arrange
        final mockData = {
          'getProjects': [
            {
              'id': 'proj_123',
              'slug': 'marketing-analytics',
              'name': {'text': 'Marketing Analytics'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {'isActive': true, 'status': 'ACTIVE', 'prices': {}},
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.searchProjects('nonexistent');

        // Assert
        expect(projects, isEmpty);
      });
    });

    // T014-T015: Tests for getProjectDetail method (TDD - these should FAIL initially)
    group('getProjectDetail', () {
      test('T014: returns project details on successful API call', () async {
        // Arrange
        final mockData = {
          'project': {
            'id': 'proj_123',
            'slug': 'marketing-analytics',
            'name': {'text': 'Marketing Analytics'},
            'description': {'text': 'Comprehensive analytics dashboard for marketing campaigns'},
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
          },
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final project = await projectService.getProjectDetail('proj_123');

        // Assert
        expect(project.id, 'proj_123');
        expect(project.slug, 'marketing-analytics');
        expect(project.name, 'Marketing Analytics');
        expect(project.description, 'Comprehensive analytics dashboard for marketing campaigns');
        expect(project.imageUrl, 'https://cdn.vron.one/projects/proj_123/thumbnail.jpg');
        expect(project.isLive, true);
        expect(project.subscription.isActive, true);
        expect(project.subscription.status, 'ACTIVE');
      });

      test('T015: throws exception on GraphQL error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Project not found',
                extensions: {'code': 'NOT_FOUND'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(
          () => projectService.getProjectDetail('invalid_id'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
