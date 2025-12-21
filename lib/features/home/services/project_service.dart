import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Service for managing project data via GraphQL API
/// Based on the VRon API specification
class ProjectService {
  final GraphQLService _graphqlService;
  final String _language;

  ProjectService({GraphQLService? graphqlService, String language = 'EN'})
    : _graphqlService = graphqlService ?? GraphQLService(),
      _language = language;

  /// GraphQL query to fetch all projects for the authenticated user
  /// Based on the getProjects query from the VRon API
  static const String _projectsQuery = '''
    query GetProjects(\$lang: Language!) {
      getProjects(input: {}) {
        id
        slug
        imageUrl
        isLive
        liveDate
        name {
          text(lang: \$lang)
        }
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

  /// GraphQL query to fetch a single project by ID
  /// Based on the project query from the VRon API (UC10: Project Detail)
  static const String _projectDetailQuery = '''
    query GetProjectDetail(\$id: ID!, \$lang: Language!) {
      project(id: \$id) {
        id
        slug
        imageUrl
        isLive
        liveDate
        name {
          text(lang: \$lang)
        }
        description {
          text(lang: \$lang)
        }
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

  /// GraphQL mutation to update project master data
  /// Based on the updateProject mutation from the VRon API (UC11: Project Data)
  /// Note: Slug is read-only per clarification #3, only name and description are editable
  static const String _updateProjectMutation = '''
    mutation UpdateProject(\$id: ID!, \$data: UpdateProjectInput!, \$lang: Language!) {
      updateProject(id: \$id, data: \$data) {
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

  /// Fetch all projects for the authenticated user
  /// Returns a list of Project objects or throws an exception on error
  Future<List<Project>> fetchProjects() async {
    try {
      if (kDebugMode) {
        print('📦 [PROJECTS] Fetching projects (language: $_language)...');
      }

      final result = await _graphqlService.query(
        _projectsQuery,
        variables: {'lang': _language},
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch projects: ${error.message}');
        }

        throw Exception('Failed to fetch projects: ${exception.toString()}');
      }

      if (result.data == null || result.data!['getProjects'] == null) {
        if (kDebugMode) print('⚠️ [PROJECTS] No projects data in response');
        return [];
      }

      final projectsData = result.data!['getProjects'] as List;
      final projects = projectsData
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print('✅ [PROJECTS] Fetched ${projects.length} projects');
        for (final project in projects) {
          print('  - ${project.name} (${project.id}) - ${project.statusLabel}');
        }
      }

      return projects;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error: ${e.toString()}');
      rethrow;
    }
  }

  /// Fetch projects filtered by live status
  Future<List<Project>> fetchProjectsByLiveStatus(bool isLive) async {
    final allProjects = await fetchProjects();
    return allProjects.where((project) => project.isLive == isLive).toList();
  }

  /// Fetch projects filtered by subscription status
  Future<List<Project>> fetchProjectsBySubscriptionStatus(String status) async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) => project.subscription.status == status)
        .toList();
  }

  /// Fetch active projects (live and with active subscription)
  Future<List<Project>> fetchActiveProjects() async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) => project.isLive && project.subscription.isActive)
        .toList();
  }

  /// Search projects by name
  Future<List<Project>> searchProjects(String query) async {
    final allProjects = await fetchProjects();
    final lowerQuery = query.toLowerCase();
    return allProjects
        .where((project) => project.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Fetch a single project by ID with full details
  /// Returns a Project object or throws an exception on error
  Future<Project> getProjectDetail(String projectId) async {
    try {
      if (kDebugMode) {
        print('📦 [PROJECTS] Fetching project detail for ID: $projectId (language: $_language)...');
      }

      final result = await _graphqlService.query(
        _projectDetailQuery,
        variables: {
          'id': projectId,
          'lang': _language,
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to fetch project detail: ${error.message}');
        }

        throw Exception('Failed to fetch project detail: ${exception.toString()}');
      }

      if (result.data == null || result.data!['project'] == null) {
        if (kDebugMode) print('⚠️ [PROJECTS] No project data in response for ID: $projectId');
        throw Exception('Project not found: $projectId');
      }

      final projectData = result.data!['project'] as Map<String, dynamic>;
      final project = Project.fromJson(projectData);

      if (kDebugMode) {
        print('✅ [PROJECTS] Fetched project detail: ${project.name} (${project.id})');
        print('  - Status: ${project.statusLabel}');
        print('  - Description: ${project.description}');
      }

      return project;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error fetching project detail: ${e.toString()}');
      rethrow;
    }
  }

  /// Update project master data (name and description only, slug is read-only)
  /// Returns updated Project object or throws an exception on error
  /// Automatically uses last-write-wins strategy per clarification #1
  Future<Project> updateProject({
    required String projectId,
    required String name,
    required String description,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 [PROJECTS] Updating project $projectId (language: $_language)...');
        print('  - Name: $name');
        print('  - Description: $description');
      }

      final result = await _graphqlService.query(
        _updateProjectMutation,
        variables: {
          'id': projectId,
          'data': {
            'name': name,
            'description': description,
            // Note: slug is read-only per clarification #3
          },
          'lang': _language,
        },
      );

      if (result.hasException) {
        final exception = result.exception;
        if (kDebugMode) {
          print('❌ [PROJECTS] GraphQL exception: ${exception.toString()}');
        }

        if (exception?.graphqlErrors.isNotEmpty ?? false) {
          final error = exception!.graphqlErrors.first;
          if (kDebugMode) {
            print('❌ [PROJECTS] GraphQL error: ${error.message}');
          }
          throw Exception('Failed to update project: ${error.message}');
        }

        throw Exception('Failed to update project: ${exception.toString()}');
      }

      if (result.data == null || result.data!['updateProject'] == null) {
        if (kDebugMode) print('⚠️ [PROJECTS] No data in update response for ID: $projectId');
        throw Exception('Failed to update project: No data returned');
      }

      final projectData = result.data!['updateProject'] as Map<String, dynamic>;
      final updatedProject = Project.fromJson(projectData);

      if (kDebugMode) {
        print('✅ [PROJECTS] Updated project successfully: ${updatedProject.name}');
        print('  - New name: ${updatedProject.name}');
        print('  - New description: ${updatedProject.description}');
      }

      return updatedProject;
    } catch (e) {
      if (kDebugMode) print('❌ [PROJECTS] Error updating project: ${e.toString()}');
      rethrow;
    }
  }
}
