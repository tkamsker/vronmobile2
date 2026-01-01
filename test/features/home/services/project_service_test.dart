import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/services/project_service.dart';
import '../../../test_helpers.dart';

// Mock GraphQL service for testing
class MockGraphQLService extends GraphQLService {
  QueryResult? mockResult;
  Exception? mockException;
  List<QueryResult>? mockResults; // Support multiple sequential responses
  int _callCount = 0;

  @override
  Future<QueryResult> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }

    // If mockResults is set, return responses in sequence
    if (mockResults != null && mockResults!.isNotEmpty) {
      if (_callCount < mockResults!.length) {
        return mockResults![_callCount++];
      }
      // Return last result if we've exhausted the list
      return mockResults!.last;
    }

    return mockResult!;
  }

  @override
  Future<QueryResult> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
  }) async {
    if (mockException != null) {
      throw mockException!;
    }

    // If mockResults is set, return responses in sequence
    if (mockResults != null && mockResults!.isNotEmpty) {
      if (_callCount < mockResults!.length) {
        return mockResults![_callCount++];
      }
      return mockResults!.last;
    }

    return mockResult!;
  }

  void reset() {
    mockResult = null;
    mockException = null;
    mockResults = null;
    _callCount = 0;
  }
}

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment();
  });

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
      mockGraphQLService.reset();
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
              'imageUrl':
                  'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
              'isLive': true,
              'liveDate': '2025-12-20T10:30:00Z',
              'subscription': {
                'isActive': true,
                'isTrial': false,
                'status': 'ACTIVE',
                'canChoosePlan': false,
                'hasExpired': false,
                'prices': {
                  'currency': 'EUR',
                  'monthly': 29.99,
                  'yearly': 299.99,
                },
              },
            },
            {
              'id': 'proj_456',
              'slug': 'product-roadmap',
              'name': {'text': 'Product Roadmap'},
              'imageUrl':
                  'https://cdn.vron.one/projects/proj_456/thumbnail.jpg',
              'isLive': false,
              'subscription': {
                'isActive': false,
                'isTrial': true,
                'status': 'TRIAL_EXPIRED',
                'canChoosePlan': true,
                'hasExpired': true,
                'prices': {
                  'currency': 'EUR',
                  'monthly': 29.99,
                  'yearly': 299.99,
                },
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
        final projects = await projectService.fetchProjectsBySubscriptionStatus(
          'ACTIVE',
        );

        // Assert
        expect(projects.length, 1);
        expect(projects[0].subscription.status, 'ACTIVE');
      });
    });

    group('fetchActiveProjects', () {
      test(
        'filters projects that are live and have active subscription',
        () async {
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
        },
      );
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
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
            {
              'id': 'proj_456',
              'slug': 'product-roadmap',
              'name': {'text': 'Product Roadmap'},
              'imageUrl': '',
              'isLive': true,
              'subscription': {
                'isActive': true,
                'status': 'ACTIVE',
                'prices': {},
              },
            },
            {
              'id': 'proj_789',
              'slug': 'mobile-marketing',
              'name': {'text': 'Mobile Marketing'},
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
          'getVRProject': {
            'id': 'proj_123',
            'slug': 'marketing-analytics',
            'name': {'text': 'Marketing Analytics'},
            'description': {
              'text':
                  'Comprehensive analytics dashboard for marketing campaigns',
            },
            'liveDate': '2025-12-20T10:30:00Z',
            'isOwner': true,
            'subscription': {
              'isTrial': false,
              'status': 'ACTIVE',
              'canChoosePlan': false,
              'renewalInterval': 'MONTHLY',
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
        expect(
          project.description,
          'Comprehensive analytics dashboard for marketing campaigns',
        );
        expect(project.isLive, true); // Inferred from liveDate
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

    // T010: Tests for createProject mutation
    group('createProject', () {
      test('T010: creates project successfully with valid data', () async {
        // Arrange
        const name = 'Test Project';
        const slug = 'test-project';
        const description = 'A test project description';

        final mockData = {
          'createProject': {
            'id': 'proj_new123',
            'slug': slug,
            'name': {'text': name},
            'description': {'text': description},
            'imageUrl': '',
            'isLive': false,
            'liveDate': null,
            'subscription': {
              'isActive': false,
              'isTrial': false,
              'status': 'NOT_STARTED',
              'canChoosePlan': true,
              'hasExpired': false,
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
        final project = await projectService.createProject(
          name: name,
          slug: slug,
          description: description,
        );

        // Assert
        expect(project.id, 'proj_new123');
        expect(project.name, name);
        expect(project.slug, slug);
        expect(project.description, description);
        expect(project.isLive, false);
        expect(project.subscription.status, 'NOT_STARTED');
      });

      test('T010: creates project without description', () async {
        // Arrange
        const name = 'Minimal Project';
        const slug = 'minimal-project';

        final mockData = {
          'createProject': {
            'id': 'proj_min123',
            'slug': slug,
            'name': {'text': name},
            'description': {'text': ''},
            'imageUrl': '',
            'isLive': false,
            'subscription': {
              'isActive': false,
              'status': 'NOT_STARTED',
              'prices': {},
            },
          },
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final project = await projectService.createProject(
          name: name,
          slug: slug,
        );

        // Assert
        expect(project.id, 'proj_min123');
        expect(project.name, name);
        expect(project.slug, slug);
      });

      test('T010: throws exception on duplicate slug error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Slug already exists',
                extensions: {'code': 'DUPLICATE_SLUG'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(
          () => projectService.createProject(
            name: 'Test Project',
            slug: 'duplicate-slug',
          ),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('already exists'),
            ),
          ),
        );
      });

      test('T010: throws exception on validation error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Name must be between 3 and 100 characters',
                extensions: {'code': 'VALIDATION_ERROR'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(
          () => projectService.createProject(
            name: 'AB', // Too short
            slug: 'valid-slug',
          ),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('must be between'),
            ),
          ),
        );
      });

      test('T010: throws exception on invalid slug format', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message:
                    'Slug must contain only lowercase letters, numbers, and hyphens',
                extensions: {'code': 'VALIDATION_ERROR'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(
          () => projectService.createProject(
            name: 'Valid Name',
            slug: 'Invalid Slug!',
          ),
          throwsA(
            predicate(
              (e) => e is Exception && e.toString().contains('lowercase'),
            ),
          ),
        );
      });

      test('T010: throws exception on network error', () async {
        // Arrange
        mockGraphQLService.mockException = Exception(
          'Network connection failed',
        );

        // Act & Assert
        expect(
          () => projectService.createProject(
            name: 'Test Project',
            slug: 'test-project',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('T010: throws exception when no data returned', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: {'createProject': null},
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act & Assert
        expect(
          () => projectService.createProject(
            name: 'Test Project',
            slug: 'test-project',
          ),
          throwsA(
            predicate(
              (e) =>
                  e is Exception && e.toString().contains('No data returned'),
            ),
          ),
        );
      });
    });

    // T048-T050: Tests for updateProject mutation (TDD - these should FAIL initially)
    group('updateProject', () {
      test(
        'T048: updates project successfully and returns updated project',
        () async {
          // Arrange
          const projectId = 'proj_123';
          const updatedName = 'Updated Project Name';
          const updatedDescription = 'Updated description';

          // First call: mutation response (updateProjectDetails returns true)
          final mutationResponse = {'updateProjectDetails': true};

          // Second call: getProjectDetail refresh response
          final refreshResponse = {
            'getVRProject': {
              'id': projectId,
              'slug': 'marketing-analytics',
              'name': {'text': updatedName},
              'description': {'text': updatedDescription},
              'liveDate': '2025-12-20T10:30:00Z',
              'isOwner': true,
              'subscription': {
                'isTrial': false,
                'status': 'ACTIVE',
                'canChoosePlan': false,
                'renewalInterval': 'MONTHLY',
                'prices': {
                  'currency': 'EUR',
                  'monthly': 29.99,
                  'yearly': 299.99,
                },
              },
            },
          };

          // Mock sequential responses: mutation then refresh
          mockGraphQLService.mockResults = [
            QueryResult(
              data: mutationResponse,
              source: QueryResultSource.network,
              options: QueryOptions(document: mockDocument),
            ),
            QueryResult(
              data: refreshResponse,
              source: QueryResultSource.network,
              options: QueryOptions(document: mockDocument),
            ),
          ];

          // Act
          final updatedProject = await projectService.updateProject(
            projectId: projectId,
            name: updatedName,
            slug: 'test-project',
            description: updatedDescription,
          );

          // Assert
          expect(updatedProject.id, projectId);
          expect(updatedProject.name, updatedName);
          expect(updatedProject.description, updatedDescription);
        },
      );

      test('T049: throws exception on validation error', () async {
        // Arrange
        mockGraphQLService.mockResult = QueryResult(
          data: null,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(
                message: 'Validation failed: Name is required',
                extensions: {'code': 'VALIDATION_ERROR'},
              ),
            ],
          ),
        );

        // Act & Assert
        expect(
          () => projectService.updateProject(
            projectId: 'proj_123',
            name: '',
            slug: 'test-slug',
            description: 'Test',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('T050: throws exception on network error', () async {
        // Arrange
        mockGraphQLService.mockException = Exception('Network error');

        // Act & Assert
        expect(
          () => projectService.updateProject(
            projectId: 'proj_123',
            name: 'Test',
            slug: 'test-slug',
            description: 'Test description',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
