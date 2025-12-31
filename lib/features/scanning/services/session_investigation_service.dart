import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:vronmobile2/features/scanning/models/session_diagnostics.dart';

/// Custom exception for session investigation errors
class SessionInvestigationException implements Exception {
  final String message;
  final int? statusCode;

  SessionInvestigationException(this.message, {this.statusCode});

  @override
  String toString() => 'SessionInvestigationException: $message (status: $statusCode)';
}

/// Service for investigating BlenderAPI session state
///
/// Calls GET /sessions/{sessionId}/investigate endpoint to retrieve:
/// - Session status and lifecycle information
/// - Workspace file structure
/// - Log summaries and error details
/// - Full diagnostic data for debugging
class SessionInvestigationService {
  final http.Client _client;
  late final String _baseUrl;

  SessionInvestigationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client() {
    _baseUrl = baseUrl ??
        dotenv.env['BLENDER_API_BASE_URL'] ??
        'https://api.example.com'; // Fallback for tests
  }

  /// Investigate session and retrieve full diagnostics
  ///
  /// Throws [SessionInvestigationException] on errors
  Future<SessionDiagnostics> investigate(
    String sessionId, {
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/sessions/$sessionId/investigate');

      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return SessionDiagnostics.fromJson(json);
        } catch (e) {
          throw SessionInvestigationException(
            'Invalid response format from server',
            statusCode: response.statusCode,
          );
        }
      } else {
        _handleError(response);
        // Unreachable, but required for type safety
        throw SessionInvestigationException(
          'Unknown error',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw SessionInvestigationException(
        'Network error: ${e.message}',
      );
    } catch (e) {
      if (e is SessionInvestigationException) {
        rethrow;
      }
      throw SessionInvestigationException(
        'Unexpected error: $e',
      );
    }
  }

  /// Handle HTTP error responses
  Never _handleError(http.Response response) {
    final statusCode = response.statusCode;
    String message;

    try {
      final body = jsonDecode(response.body);
      message = body['error'] ?? body['message'] ?? 'Unknown error';
    } catch (_) {
      message = response.body.isEmpty ? 'No error message' : response.body;
    }

    switch (statusCode) {
      case 404:
        throw SessionInvestigationException(
          'Session not found: $message',
          statusCode: statusCode,
        );
      case 401:
        throw SessionInvestigationException(
          'Unauthorized: $message',
          statusCode: statusCode,
        );
      case 429:
        throw SessionInvestigationException(
          'Rate limit exceeded: $message',
          statusCode: statusCode,
        );
      case 500:
        throw SessionInvestigationException(
          'Server error: $message',
          statusCode: statusCode,
        );
      default:
        throw SessionInvestigationException(
          'HTTP $statusCode: $message',
          statusCode: statusCode,
        );
    }
  }
}
