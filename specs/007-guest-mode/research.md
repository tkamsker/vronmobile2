# Research: Guest Mode Implementation

**Date**: 2025-12-24
**Feature**: 007-guest-mode

## Unknowns Resolved

### 1. Guest Session Management Pattern

**Decision**: Use shared_preferences for persistent guest state flag + Provider for runtime state

**Rationale**:
- `shared_preferences` provides simple key-value persistence across app restarts
- Lightweight and appropriate for boolean guest mode flag
- Integrates well with existing app architecture
- Provider (or StatefulWidget) manages runtime session state (no persistence across restarts per constitution)
- Follows existing authentication pattern (TokenStorage uses flutter_secure_storage, guest uses simpler shared_preferences)

**Alternatives Considered**:
- SQLite/Hive: Overkill for single boolean flag, adds unnecessary complexity
- flutter_secure_storage: Not needed since guest mode is not sensitive data (public information)
- In-memory only: Would require re-selection of guest mode after app restart (poor UX)

**Implementation**:
```dart
class GuestSessionManager {
  static const String _guestModeKey = 'is_guest_mode';
  final SharedPreferences _prefs;

  bool _isGuestMode = false;
  bool get isGuestMode => _isGuestMode;

  Future<void> enableGuestMode() async {
    _isGuestMode = true;
    await _prefs.setBool(_guestModeKey, true);
  }

  Future<void> disableGuestMode() async {
    _isGuestMode = false;
    await _prefs.setBool(_guestModeKey, false);
  }

  Future<void> initialize() async {
    _isGuestMode = _prefs.getBool(_guestModeKey) ?? false;
  }
}
```

---

### 2. Local Storage Strategy for Guest Scan Data

**Decision**: Use app documents directory via path_provider for guest GLB files

**Rationale**:
- `path_provider` provides cross-platform access to app-specific directories
- `getApplicationDocumentsDirectory()` provides persistent storage that survives app updates
- Files in this directory are automatically deleted when app is uninstalled (matches requirement)
- No user permission required (unlike external storage)
- Consistent with Flutter best practices for app-generated files

**Alternatives Considered**:
- External storage: Requires permission, not consistent with "local only" requirement
- Temporary directory: Files may be deleted by OS during app lifetime (unreliable)
- In-app database: Overkill for file references, GLB files are already binary blobs

**Implementation**:
```dart
class GuestStorageHelper {
  Future<String> getGuestStoragePath() async {
    final directory = await getApplicationDocumentsDirectory();
    final guestDir = Directory('${directory.path}/guest_scans');
    if (!await guestDir.exists()) {
      await guestDir.create(recursive: true);
    }
    return guestDir.path;
  }

  Future<File> saveGuestScan(String filename, Uint8List data) async {
    final path = await getGuestStoragePath();
    final file = File('$path/$filename');
    return await file.writeAsBytes(data);
  }
}
```

---

### 3. Backend Bypass Strategy

**Decision**: Add guest mode check to GraphQLService before all mutations/queries

**Rationale**:
- Centralized enforcement of "no backend calls in guest mode" requirement
- Prevents accidental backend calls from any feature code
- Explicit error handling for development (throws in debug, silent in release)
- Easy to test (mock GraphQLService, verify no calls made)
- Minimal code changes (single service modification vs. changes everywhere)

**Alternatives Considered**:
- Feature-level checks: Error-prone, easy to miss a call, duplicated logic
- Network interceptor: Too low-level, would block legitimate device-local operations
- Separate guest-specific services: Code duplication, maintenance burden

**Implementation**:
```dart
class GraphQLService {
  final GuestSessionManager _guestSession;

  Future<QueryResult> query(String query, {Map<String, dynamic>? variables}) async {
    if (_guestSession.isGuestMode) {
      if (kDebugMode) {
        throw StateError('Backend call attempted in guest mode: $query');
      }
      return QueryResult(/* empty result */);
    }
    // ... existing query logic
  }
}
```

---

### 4. Navigation Pattern for Guest Mode

**Decision**: Direct navigation to scanning screen, bypass home/projects screens

**Rationale**:
- Matches requirement FR-001: "navigate to scanning screen when Guest Mode tapped"
- Simplest implementation: `Navigator.pushNamed(context, '/scanning', arguments: {'guestMode': true})`
- Scanning screen checks guest mode and hides cloud-related features
- Consistent with existing navigation patterns in app

**Alternatives Considered**:
- Guest-specific scanning screen: Code duplication, maintenance burden
- Intermediate "guest home" screen: Adds unnecessary step, violates YAGNI
- Modal overlay on main screen: Confusing UX, doesn't match "navigate" requirement

**Implementation**:
```dart
// In main_screen.dart
void _handleGuestMode() async {
  await _guestSession.enableGuestMode();
  Navigator.pushReplacementNamed(
    context,
    '/scanning',
    arguments: {'guestMode': true},
  );
}

// In scanning_screen.dart
@override
void initState() {
  super.initState();
  final args = ModalRoute.of(context)?.settings.arguments as Map?;
  _isGuestMode = args?['guestMode'] ?? _guestSession.isGuestMode;
}
```

---

### 5. Guest Mode Indication in UI

**Decision**: Add visual indicator banner in scanning screen + hide cloud features

**Rationale**:
- Clear visual feedback that user is in guest mode
- Follows iOS/Android patterns for special modes (private browsing, airplane mode)
- Banner is non-intrusive but always visible
- Cloud features (Save to Project, etc.) are hidden, not just disabled (reduces confusion)

**Alternatives Considered**:
- Toast message: Ephemeral, user might miss it
- Dialog on entry: Interrupts flow, annoying for repeat users
- Watermark: Too subtle, might be ignored

**Implementation**:
```dart
// Guest mode banner widget
class GuestModeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16),
          SizedBox(width: 8),
          Text('Guest Mode - Scans saved locally only'),
          Spacer(),
          TextButton(
            onPressed: () => _promptAccountCreation(context),
            child: Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
```

---

### 6. Account Upgrade Flow

**Decision**: Add "Sign Up" button in guest mode banner + dialog prompt when accessing restricted features

**Rationale**:
- Meets requirement FR-007: "prompt account creation when guest attempts authenticated features"
- Two paths to upgrade: proactive (banner button) and reactive (feature gate)
- Dialog explains what user will gain by creating account
- Navigation preserves scan data temporarily (in memory) during sign-up flow

**Alternatives Considered**:
- Forced upgrade after N scans: Feels like nagware, poor UX
- No upgrade path: Missing opportunity to convert users
- Automatic upgrade: Confusing, users expect explicit action

**Implementation**:
```dart
Future<void> _promptAccountCreation(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Create Account'),
      content: Text('Sign up to save scans to the cloud, access from any device, and share with team members.'),
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
    Navigator.pushReplacementNamed(context, '/signup');
  }
}
```

---

### 7. Guest Data Cleanup

**Decision**: No automatic cleanup - guest data persists until app uninstall or manual clear

**Rationale**:
- Simplest implementation (no scheduled cleanup logic)
- User might return to guest mode later, data still available
- App uninstall automatically removes all app data (OS handles cleanup)
- Users can manually clear via system settings if needed
- Reduces complexity and potential bugs

**Alternatives Considered**:
- Cleanup after N days: Requires background task, battery drain, complexity
- Cleanup on account creation: User might want to keep guest scans separately
- Prompt to delete on exit: Annoying, users expect data to persist

**Implementation**: No code needed - rely on OS behavior

---

### 8. Error Handling for Guest Mode Violations

**Decision**: Silent failure in production, loud failure in debug mode

**Rationale**:
- Production: Don't crash app if accidental backend call occurs, silently skip
- Debug: Throw exception to catch bugs early during development
- Logging: Always log attempts for monitoring and debugging
- Follows Flutter best practices (kDebugMode for debug-only behavior)

**Implementation**:
```dart
if (_guestSession.isGuestMode) {
  if (kDebugMode) {
    print('❌ [GUEST] Backend call blocked: $operation');
    throw StateError('Backend operation not allowed in guest mode: $operation');
  } else {
    print('⚠️ [GUEST] Backend call blocked silently: $operation');
  }
  return null; // or appropriate empty response
}
```

---

## Implementation Best Practices

### 1. Guest Mode Detection Pattern
```dart
// Centralized check via service
if (_guestSession.isGuestMode) {
  // Guest-specific behavior
} else {
  // Authenticated behavior
}
```

### 2. Feature Flag Pattern for UI
```dart
// Hide cloud features in guest mode
if (!_guestSession.isGuestMode) {
  ElevatedButton(
    onPressed: _saveToProject,
    child: Text('Save to Project'),
  ),
}
```

### 3. Test Strategy
- Unit tests: GuestSessionManager state transitions
- Widget tests: Guest mode button, banner visibility
- Integration tests: Complete guest workflow (tap button → scan → export)
- Mock tests: Verify backend calls are blocked

---

## Known Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Guest data loss on uninstall | High | Clear disclosure in guest mode banner |
| Accidental backend call in guest mode | Medium | Debug-mode exceptions + centralized checks in GraphQLService |
| Storage space exhaustion | Low | Guest scans limited by device storage; no artificial limits |
| Confusion about guest vs authenticated features | Medium | Clear visual banner + feature hiding (not just disabling) |

---

## Dependencies Confirmation

**No new dependencies required** - all features use existing packages:
- `shared_preferences: ^2.2.2` (existing)
- `path_provider` (existing - listed in dependencies)
- `graphql_flutter: ^5.1.0` (existing)
- `flutter: sdk` (existing)

---

## Next Steps

1. ✅ Research complete
2. ⏭️ Proceed to Phase 1: Data Model & Contracts
   - Define GuestSession state model
   - Define GuestScan local file structure
   - Document UI behavior contracts
   - Generate quickstart guide for developers
