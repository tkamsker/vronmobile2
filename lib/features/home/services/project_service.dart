import 'package:flutter/foundation.dart';
import 'package:vronmobile2/core/services/graphql_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Service for managing project data via GraphQL API
/// Based on the VRon API specification
class ProjectService {
  final GraphQLService _graphqlService;
  final String _language;

  ProjectService({
    GraphQLService? graphqlService,
    String language = 'EN',
  })  : _graphqlService = graphqlService ?? GraphQLService(),
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
  Future<List<Project>> fetchProjectsBySubscriptionStatus(
    String status,
  ) async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) => project.subscription.status == status)
        .toList();
  }

  /// Fetch active projects (live and with active subscription)
  Future<List<Project>> fetchActiveProjects() async {
    final allProjects = await fetchProjects();
    return allProjects
        .where((project) =>
            project.isLive && project.subscription.isActive)
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
}
