import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Service for managing project data via GraphQL API
class ProjectService {
  final GraphQLService _graphql = GraphQLService();

  /// GraphQL query for fetching project list
  static const String _getProjectsQuery = '''
    query GetProjects(\$lang: Language!) {
      projects {
        id
        slug
        name {
          text(lang: \$lang)
        }
        description {
          text(lang: \$lang)
        }
        imageUrl
        isLive
        subscription {
          isActive
          isTrial
          status
        }
      }
    }
  ''';

  /// GraphQL query for fetching single project detail
  static const String _getProjectDetailQuery = '''
    query GetProjectDetail(\$id: ID!, \$lang: Language!) {
      project(id: \$id) {
        id
        slug
        name {
          text(lang: \$lang)
        }
        description {
          text(lang: \$lang)
        }
        imageUrl
        isLive
        liveDate
        subscription {
          isActive
          isTrial
          status
          canChoosePlan
          hasExpired
          currency
          price
          renewalInterval
          startedAt
          expiresAt
          renewsAt
          prices {
            currency
            monthly
            yearly
          }
        }
      }
    }
  ''';

  /// GraphQL mutation for updating project
  static const String _updateProjectMutation = '''
    mutation UpdateProject(\$id: ID!, \$input: ProjectUpdateInput!) {
      updateProject(id: \$id, input: \$input) {
        id
        slug
        name {
          text(lang: EN)
        }
        description {
          text(lang: EN)
        }
      }
    }
  ''';

  /// Fetch list of projects
  Future<List<Project>> getProjects({String lang = 'EN'}) async {
    final result = await _graphql.query(
      _getProjectsQuery,
      variables: {'lang': lang},
    );

    return _graphql.handleResult(result, (data) {
      final projectsData = data['projects'] as List<dynamic>;
      return projectsData
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Fetch single project detail by ID
  Future<Project> fetchProjectDetail(
    String projectId, {
    String lang = 'EN',
  }) async {
    final result = await _graphql.query(
      _getProjectDetailQuery,
      variables: {
        'id': projectId,
        'lang': lang,
      },
    );

    return _graphql.handleResult(result, (data) {
      final projectData = data['project'] as Map<String, dynamic>;
      return Project.fromJson(projectData);
    });
  }

  /// Update project data (name, description, etc.)
  Future<Project> updateProject(
    String projectId,
    Map<String, dynamic> input,
  ) async {
    final result = await _graphql.mutate(
      _updateProjectMutation,
      variables: {
        'id': projectId,
        'input': input,
      },
    );

    return _graphql.handleResult(result, (data) {
      final projectData = data['updateProject'] as Map<String, dynamic>;
      return Project.fromJson(projectData);
    });
  }
}
