import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';
import 'package:vronmobile2/features/home/models/project_status.dart';
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
      query GetProjects {
        projects {
          id
          title
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
          'projects': [
            {
              'id': 'proj_123',
              'title': 'Marketing Analytics',
              'description': 'Realtime overview of campaign performance.',
              'status': 'active',
              'imageUrl':
                  'https://cdn.vron.one/projects/proj_123/thumbnail.jpg',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '4 teammates',
            },
            {
              'id': 'proj_456',
              'title': 'Product Roadmap',
              'description': 'Plan feature releases across quarters.',
              'status': 'paused',
              'imageUrl':
                  'https://cdn.vron.one/projects/proj_456/thumbnail.jpg',
              'updatedAt': '2025-12-19T15:45:00Z',
              'teamInfo': '7 teammates',
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
        expect(projects[0].title, 'Marketing Analytics');
        expect(projects[0].status, ProjectStatus.active);
        expect(projects[1].id, 'proj_456');
        expect(projects[1].title, 'Product Roadmap');
        expect(projects[1].status, ProjectStatus.paused);
      });

      test('returns empty list when no projects exist', () async {
        // Arrange
        final mockData = {
          'projects': [],
        };

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

      test('returns empty list when projects is null', () async {
        // Arrange
        final mockData = {
          'projects': null,
        };

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
        expect(
          () => projectService.fetchProjects(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws exception on network error', () async {
        // Arrange
        mockGraphQLService.mockException = Exception('Network error');

        // Act & Assert
        expect(
          () => projectService.fetchProjects(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('fetchProjectsByStatus', () {
      test('filters projects by active status', () async {
        // Arrange
        final mockData = {
          'projects': [
            {
              'id': 'proj_123',
              'title': 'Project 1',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
            {
              'id': 'proj_456',
              'title': 'Project 2',
              'description': '',
              'status': 'paused',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
            {
              'id': 'proj_789',
              'title': 'Project 3',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.fetchProjectsByStatus('active');

        // Assert
        expect(projects.length, 2);
        expect(projects[0].status, ProjectStatus.active);
        expect(projects[1].status, ProjectStatus.active);
      });
    });

    group('searchProjects', () {
      test('searches projects by title (case-insensitive)', () async {
        // Arrange
        final mockData = {
          'projects': [
            {
              'id': 'proj_123',
              'title': 'Marketing Analytics',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
            {
              'id': 'proj_456',
              'title': 'Product Roadmap',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
            {
              'id': 'proj_789',
              'title': 'Mobile Marketing',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
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
        expect(projects[0].title, 'Marketing Analytics');
        expect(projects[1].title, 'Mobile Marketing');
      });

      test('returns empty list when no matches found', () async {
        // Arrange
        final mockData = {
          'projects': [
            {
              'id': 'proj_123',
              'title': 'Marketing Analytics',
              'description': '',
              'status': 'active',
              'imageUrl': '',
              'updatedAt': '2025-12-20T10:30:00Z',
              'teamInfo': '',
            },
          ],
        };

        mockGraphQLService.mockResult = QueryResult(
          data: mockData,
          source: QueryResultSource.network,
          options: QueryOptions(document: mockDocument),
        );

        // Act
        final projects = await projectService.searchProjects('nomatch');

        // Assert
        expect(projects, isEmpty);
      });
    });
  });
}
