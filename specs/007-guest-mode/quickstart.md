# Quickstart Guide: Guest Mode Implementation

**Date**: 2025-12-24
**Feature**: 007-guest-mode
**For**: Developers implementing the guest mode feature

## Overview

This guide provides a step-by-step walkthrough for implementing guest mode in the vronmobile2 Flutter application. Guest mode allows users to access LiDAR scanning without authentication, with scans stored locally only.

---

## Prerequisites

### Required Knowledge
- Dart/Flutter development experience
- Understanding of Flutter state management (Provider or StatefulWidget)
- Familiarity with shared_preferences and local file storage
- Basic knowledge of app navigation patterns

### Required Tools
- Flutter SDK 3.x
- Dart 3.10+
- Git

---

## Architecture Overview

```
┌────────────────────────────────────────────────────┐
│              Main Screen (Unauthenticated)         │
│                                                     │
│  ┌──────────────────────────────────────────────┐ │
│  │         Guest Mode Button                    │ │
│  │   "Continue as Guest"                        │ │
│  └──────────────┬───────────────────────────────┘ │
└─────────────────┼──────────────────────────────────┘
                  │ Tap
                  ▼
┌─────────────────────────────────────────────────────┐
│          GuestSessionManager                        │
│     .enableGuestMode()                              │
│     Persist to shared_preferences                   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│          Navigate to Scanning Screen                │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│     Scanning Screen (Guest Mode Active)             │
│  ┌────────────────────────────────────────────┐    │
│  │  Guest Mode Banner (Always Visible)        │    │
│  │  "Guest Mode - Scans saved locally only"   │    │
│  └────────────────────────────────────────────┘    │
│                                                     │
│  - Scan controls (enabled)                         │
│  - "Save to Project" (HIDDEN)                      │
│  - "Export GLB" (enabled)                          │
└─────────────────┬───────────────────────────────────┘
                  │ Scan complete
                  ▼
┌─────────────────────────────────────────────────────┐
│          GuestStorageHelper                         │
│     .saveGuestScan(data)                            │
│     Save to /guest_scans/scan_*.glb                 │
└─────────────────────────────────────────────────────┘
```

---

## Step 1: Create Guest Session Manager (30 minutes)

### 1.1 Create Directory Structure

```bash
mkdir -p lib/features/guest/services
mkdir -p lib/features/guest/utils
mkdir -p test/features/guest/services
```

### 1.2 Implement GuestSessionManager

Create `lib/features/guest/services/guest_session_manager.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages guest mode session state
class GuestSessionManager {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _scanCountKey = 'guest_scan_count';

  final SharedPreferences _prefs;

  bool _isGuestMode = false;
  DateTime? _enteredAt;
  int _scanCount = 0;

  GuestSessionManager({SharedPreferences? prefs})
      : _prefs = prefs ?? throw ArgumentError('SharedPreferences required');

  /// Whether the current session is in guest mode
  bool get isGuestMode => _isGuestMode;

  /// When guest mode was activated (null if not in guest mode)
  DateTime? get enteredAt => _enteredAt;

  /// Number of scans in current guest session
  int get scanCount => _scanCount;

  /// Initialize guest session state from persistent storage
  Future<void> initialize() async {
    _isGuestMode = _prefs.getBool(_guestModeKey) ?? false;
    _scanCount = _prefs.getInt(_scanCountKey) ?? 0;

    if (_isGuestMode) {
      _enteredAt = DateTime.now(); // Approximate - not persisted
      if (kDebugMode) print('✅ [GUEST] Guest mode active, $scanCount scans');
    }
  }

  /// Enable guest mode
  Future<void> enableGuestMode() async {
    if (kDebugMode) print('🔐 [GUEST] Enabling guest mode');

    _isGuestMode = true;
    _enteredAt = DateTime.now();
    _scanCount = 0;

    await _prefs.setBool(_guestModeKey, true);
    await _prefs.setInt(_scanCountKey, 0);

    if (kDebugMode) print('✅ [GUEST] Guest mode enabled');
  }

  /// Disable guest mode (e.g., user creates account)
  Future<void> disableGuestMode() async {
    if (kDebugMode) print('🔐 [GUEST] Disabling guest mode');

    _isGuestMode = false;
    _enteredAt = null;
    _scanCount = 0;

    await _prefs.setBool(_guestModeKey, false);
    await _prefs.setInt(_scanCountKey, 0);

    if (kDebugMode) print('✅ [GUEST] Guest mode disabled');
  }

  /// Increment scan count
  Future<void> incrementScanCount() async {
    if (!_isGuestMode) return;

    _scanCount++;
    await _prefs.setInt(_scanCountKey, _scanCount);

    if (kDebugMode) print('📊 [GUEST] Scan count: $_scanCount');
  }
}
```

### 1.3 Write Unit Tests

Create `test/features/guest/services/guest_session_manager_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';

void main() {
  late SharedPreferences prefs;
  late GuestSessionManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    manager = GuestSessionManager(prefs: prefs);
  });

  group('GuestSessionManager', () {
    test('initializes with guest mode disabled by default', () async {
      await manager.initialize();
      expect(manager.isGuestMode, false);
      expect(manager.scanCount, 0);
    });

    test('enables guest mode and persists state', () async {
      await manager.enableGuestMode();

      expect(manager.isGuestMode, true);
      expect(manager.enteredAt, isNotNull);
      expect(manager.scanCount, 0);
      expect(prefs.getBool('is_guest_mode'), true);
    });

    test('disables guest mode and clears state', () async {
      await manager.enableGuestMode();
      await manager.disableGuestMode();

      expect(manager.isGuestMode, false);
      expect(manager.enteredAt, null);
      expect(manager.scanCount, 0);
      expect(prefs.getBool('is_guest_mode'), false);
    });

    test('increments scan count', () async {
      await manager.enableGuestMode();
      await manager.incrementScanCount();

      expect(manager.scanCount, 1);
      expect(prefs.getInt('guest_scan_count'), 1);
    });

    test('restores guest mode state on initialize', () async {
      await prefs.setBool('is_guest_mode', true);
      await prefs.setInt('guest_scan_count', 5);

      final newManager = GuestSessionManager(prefs: prefs);
      await newManager.initialize();

      expect(newManager.isGuestMode, true);
      expect(newManager.scanCount, 5);
    });
  });
}
```

---

## Step 2: Create Guest Storage Helper (20 minutes)

### 2.1 Implement Guest Storage Helper

Create `lib/features/guest/utils/guest_storage_helper.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Helper for managing guest scan files in local storage
class GuestStorageHelper {
  /// Get the path to guest scans directory
  Future<String> getGuestStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final guestDir = Directory('${directory.path}/guest_scans');

    if (!await guestDir.exists()) {
      await guestDir.create(recursive: true);
      if (kDebugMode) print('📁 [GUEST] Created guest_scans directory');
    }

    return guestDir.path;
  }

  /// Save a guest scan to local storage
  Future<File> saveGuestScan(Uint8List scanData) async {
    final path = await getGuestStoragePath();

    // Generate filename with timestamp
    final timestamp = DateTime.now();
    final filename = 'scan_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_'
                     '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.glb';

    final file = File('$path/$filename');

    if (kDebugMode) {
      print('💾 [GUEST] Saving scan to: ${file.path}');
      print('   Size: ${scanData.length} bytes');
    }

    await file.writeAsBytes(scanData);

    if (kDebugMode) print('✅ [GUEST] Scan saved successfully');

    return file;
  }

  /// List all guest scans
  Future<List<File>> listGuestScans() async {
    final path = await getGuestStoragePath();
    final directory = Directory(path);

    if (!await directory.exists()) {
      return [];
    }

    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.glb'))
        .cast<File>()
        .toList();

    if (kDebugMode) print('📂 [GUEST] Found ${files.length} guest scans');

    return files;
  }

  /// Delete a guest scan
  Future<void> deleteGuestScan(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      if (kDebugMode) print('🗑️  [GUEST] Deleted scan: $filePath');
    }
  }

  /// Get total size of all guest scans
  Future<int> getTotalGuestScansSize() async {
    final files = await listGuestScans();
    int totalSize = 0;

    for (final file in files) {
      final stat = await file.stat();
      totalSize += stat.size;
    }

    if (kDebugMode) {
      final sizeMB = (totalSize / 1024 / 1024).toStringAsFixed(2);
      print('💽 [GUEST] Total guest scans size: $sizeMB MB');
    }

    return totalSize;
  }
}
```

---

## Step 3: Modify GraphQL Service to Block Backend Calls (15 minutes)

### 3.1 Update GraphQL Service

Modify `lib/core/services/graphql_service.dart`:

```dart
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';

class GraphQLService {
  final GuestSessionManager _guestSession;

  GraphQLService({
    GuestSessionManager? guestSession,
  })  : _guestSession = guestSession ?? GuestSessionManager();

  Future<QueryResult> query(String query, {Map<String, dynamic>? variables}) async {
    // Guest mode check - block all backend calls
    if (_guestSession.isGuestMode) {
      if (kDebugMode) {
        print('❌ [GUEST] Backend call blocked: $query');
        throw StateError('Backend operation not allowed in guest mode: $query');
      } else {
        print('⚠️ [GUEST] Backend call blocked silently');
      }
      return QueryResult(
        data: {},
        exception: null,
        source: QueryResultSource.cache,
      );
    }

    // ... existing query logic
  }

  Future<QueryResult> mutate(String mutation, {Map<String, dynamic>? variables}) async {
    // Guest mode check - block all backend calls
    if (_guestSession.isGuestMode) {
      if (kDebugMode) {
        print('❌ [GUEST] Backend mutation blocked: $mutation');
        throw StateError('Backend operation not allowed in guest mode: $mutation');
      } else {
        print('⚠️ [GUEST] Backend mutation blocked silently');
      }
      return QueryResult(
        data: {},
        exception: null,
        source: QueryResultSource.cache,
      );
    }

    // ... existing mutate logic
  }
}
```

---

## Step 4: Add Guest Mode Button to Main Screen (15 minutes)

### 4.1 Update Main Screen

Modify `lib/features/auth/screens/main_screen.dart`:

```dart
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';

class MainScreen extends StatefulWidget {
  // ... existing code

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GuestSessionManager _guestSession = GuestSessionManager();
  bool _isGuestLoading = false;

  // ... existing code

  void _handleGuestMode() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      await _guestSession.enableGuestMode();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/scanning');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enter guest mode: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing code

      // Add guest mode button
      Semantics(
        label: 'Continue as Guest',
        hint: 'Scan rooms without creating an account',
        button: true,
        child: ElevatedButton(
          onPressed: _isGuestLoading ? null : _handleGuestMode,
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 56),
          ),
          child: _isGuestLoading
              ? CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Continue as Guest'),
                  ],
                ),
        ),
      ),
    );
  }
}
```

---

## Step 5: Add Guest Mode Banner to Scanning Screen (20 minutes)

### 5.1 Create Guest Mode Banner Widget

Create `lib/features/guest/widgets/guest_mode_banner.dart`:

```dart
import 'package:flutter/material.dart';

class GuestModeBanner extends StatelessWidget {
  final VoidCallback onSignUp;

  const GuestModeBanner({
    Key? key,
    required this.onSignUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Guest Mode Active',
      hint: 'You are using the app without an account. Scans are saved on this device only.',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 20,
              color: Colors.amber.shade900,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Guest Mode - Scans saved locally only',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
            Semantics(
              label: 'Sign Up',
              hint: 'Create an account to save scans to the cloud',
              button: true,
              child: TextButton(
                onPressed: onSignUp,
                child: Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.2 Update Scanning Screen

Modify `lib/features/lidar/screens/scanning_screen.dart`:

```dart
import 'package:vronmobile2/features/guest/services/guest_session_manager.dart';
import 'package:vronmobile2/features/guest/widgets/guest_mode_banner.dart';

class ScanningScreen extends StatefulWidget {
  // ... existing code
}

class _ScanningScreenState extends State<ScanningScreen> {
  final GuestSessionManager _guestSession = GuestSessionManager();

  @override
  void initState() {
    super.initState();
    _guestSession.initialize();
  }

  Future<void> _promptAccountCreation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign up to unlock:'),
            SizedBox(height: 8),
            _buildBullet('Save scans to the cloud'),
            _buildBullet('Access from any device'),
            _buildBullet('Share with team members'),
            _buildBullet('Unlimited scan storage'),
            SizedBox(height: 12),
            Text(
              'Note: Guest scans cannot be migrated to your account.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Continue as Guest'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Up'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _guestSession.disableGuestMode();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/signup');
      }
    }
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show guest mode banner if in guest mode
          if (_guestSession.isGuestMode)
            GuestModeBanner(onSignUp: _promptAccountCreation),

          // ... existing scanning UI

          // Hide "Save to Project" button in guest mode
          if (!_guestSession.isGuestMode)
            ElevatedButton(
              onPressed: _saveToProject,
              child: Text('Save to Project'),
            ),

          // Always show "Export GLB" (works in guest mode)
          ElevatedButton(
            onPressed: _exportGLB,
            child: Text('Export GLB'),
          ),
        ],
      ),
    );
  }
}
```

---

## Step 6: Testing (45 minutes)

### 6.1 Run Unit Tests

```bash
flutter test test/features/guest/
```

### 6.2 Manual Testing Checklist

**Guest Mode Activation**:
- [ ] Tap "Continue as Guest" on main screen
- [ ] Verify navigation to scanning screen within 1 second
- [ ] Verify guest mode banner displays

**Scanning in Guest Mode**:
- [ ] Perform a LiDAR scan
- [ ] Verify scan completes successfully
- [ ] Verify "Save to Project" button is HIDDEN (not just disabled)
- [ ] Verify "Export GLB" button is visible

**Local Storage**:
- [ ] Export scan to device storage
- [ ] Check app documents directory: `/guest_scans/scan_*.glb`
- [ ] Verify file exists and is valid GLB

**Backend Blocking**:
- [ ] Attempt to trigger a backend operation (if any UI allows)
- [ ] In debug mode: Verify exception is thrown
- [ ] Check logs: Verify backend call was blocked

**Account Upgrade**:
- [ ] Tap "Sign Up" in banner
- [ ] Verify dialog displays with benefits
- [ ] Tap "Sign Up" → Verify navigation to sign-up screen
- [ ] Tap "Continue as Guest" → Verify stays in guest mode

**Session Persistence**:
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify still in guest mode
- [ ] Verify guest mode banner still displays

---

## Common Issues & Solutions

### Issue 1: Guest Mode Button Not Showing

**Symptom**: "Continue as Guest" button doesn't appear on main screen

**Solution**:
1. Verify you're on the main screen in unauthenticated state
2. Check that button is not conditionally hidden
3. Ensure `GuestSessionManager` is initialized

### Issue 2: Backend Calls Not Blocked

**Symptom**: Backend calls succeed even in guest mode

**Solution**:
1. Verify `GraphQLService` has guest mode check
2. Check that `GuestSessionManager` instance is injected correctly
3. Ensure `isGuestMode` flag is properly set
4. Add debug logging to verify check is executed

### Issue 3: Guest Scans Not Persisting

**Symptom**: Guest scans disappear after app restart

**Solution**:
1. Verify files are saved to app documents directory (not temp directory)
2. Check file path: should be `{appDir}/guest_scans/scan_*.glb`
3. Ensure metadata is saved to shared_preferences
4. Check for file write permissions (should not be needed for app documents dir)

### Issue 4: Navigation Fails

**Symptom**: Tapping "Continue as Guest" doesn't navigate to scanning screen

**Solution**:
1. Check route name: `/scanning` should be registered in MaterialApp
2. Verify Navigator is mounted before pushReplacementNamed
3. Check for navigation guards blocking guest users
4. Add error handling around navigation call

---

## Performance Checklist

Before deploying:

- [ ] Guest mode activation < 1 second (measure with Stopwatch)
- [ ] File save operations < 500ms (measure with Stopwatch)
- [ ] No memory leaks (profile with Flutter DevTools)
- [ ] No backend calls in guest mode (verify with network inspector)
- [ ] 60 fps maintained during navigation (check DevTools Performance tab)

---

## Security Checklist

Before deploying:

- [ ] Guest mode flag not exposed in API calls
- [ ] Guest scans stored in app-private directory
- [ ] No sensitive data in guest mode logs
- [ ] Backend calls completely blocked (no bypass possible)
- [ ] Error messages don't expose implementation details

---

## Deployment Checklist

- [ ] All unit tests passing
- [ ] All widget tests passing
- [ ] All integration tests passing
- [ ] Manual QA completed on iOS and Android
- [ ] Accessibility tested with screen reader
- [ ] Code review completed
- [ ] Documentation updated (CLAUDE.md if needed)

---

## Next Steps

After completing implementation:

1. ✅ Guest mode implemented
2. ⏭️ Run full test suite
3. ⏭️ Deploy to staging environment
4. ⏭️ Perform UAT (User Acceptance Testing)
5. ⏭️ Deploy to production
6. ⏭️ Monitor usage metrics

---

## Resources

### Code References
- [spec.md](./spec.md) - Feature specification
- [research.md](./research.md) - Technical research
- [data-model.md](./data-model.md) - Data structures
- [contracts/ui-behavior.md](./contracts/ui-behavior.md) - UI contracts

### External Documentation
- [shared_preferences](https://pub.dev/packages/shared_preferences)
- [path_provider](https://pub.dev/packages/path_provider)
- [Flutter Navigation](https://docs.flutter.dev/development/ui/navigation)

---

## Support

For questions or issues:
- Review the contracts document for UI behavior requirements
- Check the data model for state management details
- Refer to research.md for implementation decisions
