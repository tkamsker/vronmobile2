import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_operation.dart';

/// Service for managing offline operation queue and connectivity monitoring
///
/// Features:
/// - Real-time connectivity monitoring via connectivity_plus
/// - Persistent operation queue using SharedPreferences
/// - Automatic queue processing when connectivity restored
/// - Custom operation executor registration
///
/// Usage:
/// ```dart
/// final service = ConnectivityService();
/// await service.initialize();
///
/// // Register executor
/// service.registerOperationExecutor((operation) async {
///   // Execute operation...
///   return true; // success
/// });
///
/// // Queue operation when offline
/// await service.queueOperation(pendingOp);
///
/// // Process queue when online
/// await service.processQueue();
/// ```
class ConnectivityService {
  static const String _queueKey = 'offline_operations_queue';

  final Connectivity _connectivity = Connectivity();
  final String? _testDirectory;

  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<bool> Function(PendingOperation operation)? _operationExecutor;

  bool _initialized = false;
  bool _disposed = false;

  ConnectivityService({String? testDirectory}) : _testDirectory = testDirectory;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_initialized) return;

    _connectivityController = StreamController<bool>.broadcast();

    // Start monitoring connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final isOnline = await _checkConnectivity(results);
      if (!_disposed) {
        _connectivityController?.add(isOnline);
      }

      // Auto-process queue when connectivity restored
      if (isOnline && _operationExecutor != null) {
        await processQueue();
      }
    });

    // Emit initial connectivity state
    final initialState = await isOnline();
    if (!_disposed) {
      _connectivityController?.add(initialState);
    }

    _initialized = true;
  }

  /// Stream of connectivity changes (true = online, false = offline)
  Stream<bool> get connectivityStream {
    if (_connectivityController == null) {
      throw StateError(
        'ConnectivityService not initialized. Call initialize() first.',
      );
    }
    return _connectivityController!.stream;
  }

  /// Check if device is currently online
  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _checkConnectivity(results);
    } catch (e) {
      print('⚠️ [ConnectivityService] Error checking connectivity: $e');
      return false; // Assume offline on error
    }
  }

  /// Helper to evaluate connectivity results
  Future<bool> _checkConnectivity(List<ConnectivityResult> results) async {
    // If the list is empty or contains only 'none', device is offline
    if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
      return false;
    }

    // Device has some form of connectivity (mobile, wifi, ethernet, etc.)
    return true;
  }

  /// Queue operation for later execution when connectivity restored
  Future<void> queueOperation(PendingOperation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      final List<PendingOperation> queue = queueJson != null
          ? (json.decode(queueJson) as List)
                .map((item) => PendingOperation.fromJson(item))
                .toList()
          : [];

      queue.add(operation);

      final updatedJson = json.encode(queue.map((op) => op.toJson()).toList());
      await prefs.setString(_queueKey, updatedJson);

      print('📥 [ConnectivityService] Operation queued: ${operation.id}');
    } catch (e) {
      print('❌ [ConnectivityService] Error queueing operation: $e');
      rethrow;
    }
  }

  /// Get all pending operations from queue
  Future<List<PendingOperation>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(queueJson);
      return jsonList.map((item) => PendingOperation.fromJson(item)).toList();
    } catch (e) {
      print('❌ [ConnectivityService] Error getting pending operations: $e');
      return [];
    }
  }

  /// Register executor function for processing queued operations
  void registerOperationExecutor(
    Future<bool> Function(PendingOperation operation) executor,
  ) {
    _operationExecutor = executor;
  }

  /// Process all queued operations (execute if online)
  Future<void> processQueue() async {
    if (_operationExecutor == null) {
      print(
        '⚠️ [ConnectivityService] No operation executor registered. Call registerOperationExecutor() first.',
      );
      return;
    }

    final online = await isOnline();
    if (!online) {
      print(
        '📴 [ConnectivityService] Device offline, skipping queue processing',
      );
      return;
    }

    final operations = await getPendingOperations();
    if (operations.isEmpty) {
      print('✅ [ConnectivityService] Queue is empty, nothing to process');
      return;
    }

    print(
      '🔄 [ConnectivityService] Processing ${operations.length} queued operations',
    );

    final successfulOperations = <String>[];

    for (final operation in operations) {
      try {
        final success = await _operationExecutor!(operation);
        if (success) {
          successfulOperations.add(operation.id);
          print('✅ [ConnectivityService] Operation executed: ${operation.id}');
        } else {
          print('❌ [ConnectivityService] Operation failed: ${operation.id}');
        }
      } catch (e) {
        print(
          '❌ [ConnectivityService] Error executing operation ${operation.id}: $e',
        );
      }
    }

    // Remove successful operations from queue
    for (final operationId in successfulOperations) {
      await removeOperation(operationId);
    }

    print(
      '✅ [ConnectivityService] Queue processed: ${successfulOperations.length}/${operations.length} successful',
    );
  }

  /// Remove specific operation from queue
  Future<void> removeOperation(String operationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson == null) {
        return;
      }

      final List<PendingOperation> queue = (json.decode(queueJson) as List)
          .map((item) => PendingOperation.fromJson(item))
          .toList();

      queue.removeWhere((op) => op.id == operationId);

      final updatedJson = json.encode(queue.map((op) => op.toJson()).toList());
      await prefs.setString(_queueKey, updatedJson);

      print('🗑️ [ConnectivityService] Operation removed: $operationId');
    } catch (e) {
      print('❌ [ConnectivityService] Error removing operation: $e');
    }
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      print('🗑️ [ConnectivityService] Queue cleared');
    } catch (e) {
      print('❌ [ConnectivityService] Error clearing queue: $e');
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    _disposed = true;
    await _connectivitySubscription?.cancel();
    await _connectivityController?.close();
    _operationExecutor = null;
  }
}
