import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Session Tracker - Keeps track of BlenderAPI sessions for cleanup
///
/// Problem: BlenderAPI has a limit of 3 concurrent sessions per API key.
/// If sessions aren't properly cleaned up, users hit 429 TOO_MANY_REQUESTS errors.
///
/// Solution: Track all created sessions and provide bulk cleanup functionality.
/// Based on: /microservices/blenderapi/test_rate_limit.sh
///
/// Usage:
/// ```dart
/// final tracker = SessionTracker();
/// await tracker.addSession(sessionId);  // Track new session
/// await tracker.cleanupAllSessions(apiClient);  // Clean all tracked sessions
/// await tracker.removeSession(sessionId);  // Remove from tracking after cleanup
/// ```
class SessionTracker {
  static const String _storageKey = 'blender_api_sessions';
  static const Duration _sessionMaxAge = Duration(hours: 1); // Match backend TTL

  /// Add a session to tracking
  Future<void> addSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getSessions();

    // Add new session with timestamp
    sessions[sessionId] = DateTime.now().toIso8601String();

    // Clean up expired sessions from tracking (older than 1 hour)
    final now = DateTime.now();
    sessions.removeWhere((id, timestamp) {
      final sessionTime = DateTime.parse(timestamp);
      return now.difference(sessionTime) > _sessionMaxAge;
    });

    await prefs.setString(_storageKey, json.encode(sessions));
    print('📝 [SESSION_TRACKER] Added session: $sessionId (${sessions.length} total)');
  }

  /// Remove a session from tracking (after successful deletion)
  Future<void> removeSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getSessions();

    if (sessions.remove(sessionId) != null) {
      await prefs.setString(_storageKey, json.encode(sessions));
      print('✅ [SESSION_TRACKER] Removed session: $sessionId (${sessions.length} remaining)');
    }
  }

  /// Get all tracked session IDs
  Future<List<String>> getTrackedSessions() async {
    final sessions = await _getSessions();
    return sessions.keys.toList();
  }

  /// Get count of tracked sessions
  Future<int> getSessionCount() async {
    final sessions = await _getSessions();
    return sessions.length;
  }

  /// Clean up all tracked sessions using the API client
  /// Returns count of successfully cleaned sessions
  Future<int> cleanupAllSessions(dynamic apiClient) async {
    final sessions = await _getSessions();
    if (sessions.isEmpty) {
      print('⚠️ [SESSION_TRACKER] No sessions to clean up');
      return 0;
    }

    print('🧹 [SESSION_TRACKER] Cleaning up ${sessions.length} tracked sessions...');

    int cleaned = 0;
    int failed = 0;

    for (final sessionId in sessions.keys.toList()) {
      try {
        await apiClient.deleteSession(sessionId);
        await removeSession(sessionId);
        cleaned++;
        print('  ✓ Cleaned session: $sessionId');
      } catch (e) {
        failed++;
        print('  ✗ Failed to clean session: $sessionId - $e');
        // Still remove from tracking (might be already expired)
        await removeSession(sessionId);
      }
    }

    print('🧹 [SESSION_TRACKER] Cleanup complete: $cleaned succeeded, $failed failed');
    return cleaned;
  }

  /// Clean up specific old sessions (older than specified duration)
  Future<int> cleanupOldSessions(dynamic apiClient,
      {Duration maxAge = const Duration(minutes: 30)}) async {
    final sessions = await _getSessions();
    final now = DateTime.now();
    final oldSessions = <String>[];

    // Find old sessions
    for (final entry in sessions.entries) {
      final sessionTime = DateTime.parse(entry.value);
      if (now.difference(sessionTime) > maxAge) {
        oldSessions.add(entry.key);
      }
    }

    if (oldSessions.isEmpty) {
      print('⚠️ [SESSION_TRACKER] No old sessions to clean up');
      return 0;
    }

    print('🧹 [SESSION_TRACKER] Cleaning up ${oldSessions.length} old sessions (>${maxAge.inMinutes}min)...');

    int cleaned = 0;
    for (final sessionId in oldSessions) {
      try {
        await apiClient.deleteSession(sessionId);
        await removeSession(sessionId);
        cleaned++;
        print('  ✓ Cleaned old session: $sessionId');
      } catch (e) {
        print('  ✗ Failed to clean old session: $sessionId - $e');
        // Still remove from tracking
        await removeSession(sessionId);
      }
    }

    return cleaned;
  }

  /// Clear all tracking (without deleting on server)
  /// Use this to reset tracking after known cleanup or app reset
  Future<void> clearTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('🗑️ [SESSION_TRACKER] Cleared all session tracking');
  }

  /// Private: Get sessions map from storage
  Future<Map<String, String>> _getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_storageKey);

    if (sessionsJson == null || sessionsJson.isEmpty) {
      return {};
    }

    try {
      final decoded = json.decode(sessionsJson);
      return Map<String, String>.from(decoded);
    } catch (e) {
      print('⚠️ [SESSION_TRACKER] Error decoding sessions: $e');
      return {};
    }
  }

  /// Get session info for debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    final sessions = await _getSessions();
    final now = DateTime.now();

    final info = <String, dynamic>{
      'total': sessions.length,
      'sessions': <Map<String, dynamic>>[],
    };

    for (final entry in sessions.entries) {
      final sessionTime = DateTime.parse(entry.value);
      final age = now.difference(sessionTime);

      info['sessions'].add({
        'id': entry.key,
        'created': entry.value,
        'age_minutes': age.inMinutes,
        'is_expired': age > _sessionMaxAge,
      });
    }

    return info;
  }
}
