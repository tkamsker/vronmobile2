import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/config/env_config.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Service for managing project data via GraphQL API
class ProjectService {
  final GraphQLService _graphql = GraphQLService();

  bool get _isDebug => EnvConfig.isDebug;

  ProjectService() {
    if (_isDebug) {
      print('🏗️  [PROJECT_SERVICE] Created ProjectService instance');
      print('🏗️  [PROJECT_SERVICE] GraphQL service ID: ${identityHashCode(_graphql)}');
    }
  }

  /// GraphQL query for fetching project list
  /// Note: VRGetProjectsInput (capital VR) is required, not VrGetProjectsInput
  static const String _getProjectsQuery = '''
    query GetProjects(\$input: VRGetProjectsInput!, \$lang: Language!) {
      getProjects(input: \$input) {
        id
        slug
        name {
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
    if (_isDebug) {
      print('📋 [PROJECT_SERVICE] getProjects() called');
      print('📋 [PROJECT_SERVICE] Language: $lang');
      print('📋 [PROJECT_SERVICE] Using GraphQL service ID: ${identityHashCode(_graphql)}');
    }

    final result = await _graphql.query(
      _getProjectsQuery,
      variables: {
        'input': {}, // Empty input object - fetches all projects
        'lang': lang,
      },
    );

    if (_isDebug) {
      print('📋 [PROJECT_SERVICE] Query completed');
      print('📋 [PROJECT_SERVICE] Processing result...');
    }

    return _graphql.handleResult(result, (data) {
      if (_isDebug) {
        print('📋 [PROJECT_SERVICE] Data received, extracting projects...');
        print('📋 [PROJECT_SERVICE] Data keys: ${data.keys.toList()}');
      }

      final projectsData = data['getProjects'] as List<dynamic>;

      if (_isDebug) {
        print('✅ [PROJECT_SERVICE] Found ${projectsData.length} projects');
      }

      return projectsData
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  /// Alias for getProjects (for compatibility)
  Future<List<Project>> fetchProjects({String lang = 'EN'}) async {
    return getProjects(lang: lang);
  }

  /// Fetch single project detail by ID
  Future<Project> fetchProjectDetail(
    String projectId, {
    String lang = 'EN',
  }) async {
    final result = await _graphql.query(
      _getProjectDetailQuery,
      variables: {'id': projectId, 'lang': lang},
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
      variables: {'id': projectId, 'input': input},
    );

    return _graphql.handleResult(result, (data) {
      final projectData = data['updateProject'] as Map<String, dynamic>;
      return Project.fromJson(projectData);
    });
  }
}
