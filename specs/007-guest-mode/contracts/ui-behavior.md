# UI Behavior Contracts: Guest Mode

**Date**: 2025-12-24
**Feature**: 007-guest-mode
**Type**: Frontend UI Contracts

## Overview

Since guest mode has no backend API interactions, this contract defines the UI behavior and component interactions that other features must respect when guest mode is active.

---

## Contract 1: Main Screen - Guest Mode Entry Point

### Component: Main Screen (`lib/features/auth/screens/main_screen.dart`)

**Contract**: MUST display "Guest Mode" button when user is unauthenticated

**Input Conditions**:
- User is on main screen
- User is NOT authenticated (no valid auth token)

**Required Behavior**:
```dart
// Guest Mode button
Semantics(
  label: 'Continue as Guest',
  hint: 'Scan rooms without creating an account',
  button: true,
  child: ElevatedButton(
    onPressed: _handleGuestMode,
    child: Row(
      children: [
        Icon(Icons.person_outline),
        SizedBox(width: 8),
        Text('Continue as Guest'),
      ],
    ),
  ),
)
```

**On Button Tap**:
1. Call `GuestSessionManager.enableGuestMode()`
2. Wait for async completion
3. Navigate to scanning screen: `Navigator.pushReplacementNamed(context, '/scanning')`
4. Navigation MUST complete within 1 second (SC-001)

**Error Handling**:
- If enableGuestMode() fails → Show SnackBar error, stay on main screen
- If navigation fails → Log error, retry navigation

**Accessibility**:
- Button MUST have semantic label: "Continue as Guest"
- Button MUST have semantic hint: "Scan rooms without creating an account"
- Button MUST have `button: true` semantics property
- Touch target size MUST be >= 44x44 logical pixels

---

## Contract 2: Scanning Screen - Guest Mode Indicator

### Component: Scanning Screen (`lib/features/lidar/screens/scanning_screen.dart`)

**Contract**: MUST display guest mode banner when in guest session

**Input Conditions**:
- `GuestSessionManager.isGuestMode` returns true
- User navigated to scanning screen

**Required Behavior**:
```dart
// Guest mode banner (always visible at top)
if (_guestSession.isGuestMode) {
  Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: Colors.amber.shade100,
    child: Row(
      children: [
        Icon(Icons.person_outline, size: 20, color: Colors.amber.shade900),
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
        TextButton(
          onPressed: _promptAccountCreation,
          child: Text('Sign Up'),
        ),
      ],
    ),
  ),
}
```

**Banner Requirements**:
- MUST be always visible (not dismissible)
- MUST use amber color scheme (amber.shade100 background, amber.shade900 text/icon)
- MUST include icon: `Icons.person_outline`
- MUST include text: "Guest Mode - Scans saved locally only"
- MUST include "Sign Up" button

**"Sign Up" Button Behavior**:
- Tap → Show account creation prompt dialog
- Dialog includes:
  - Title: "Create Account"
  - Message: Benefits of creating account (cloud save, multi-device, sharing)
  - Actions: "Continue as Guest" (cancel) and "Sign Up" (confirm)
- If user confirms → Navigate to sign-up screen
- If user cancels → Remain in guest mode

---

## Contract 3: Scanning Screen - Feature Visibility Rules

### Component: Scanning Screen Action Bar

**Contract**: MUST hide cloud-dependent features in guest mode

**Hidden Features** (when `isGuestMode == true`):
1. "Save to Project" button
2. "Share to Team" option
3. Cloud sync indicator
4. Project selector dropdown

**Visible Features** (allowed in guest mode):
1. "Export GLB" button (local export only)
2. Scan preview
3. Scan controls (start, stop, reset)
4. Local scan history (guest scans only)

**Implementation**:
```dart
// Conditional rendering based on guest mode
if (!_guestSession.isGuestMode) {
  ElevatedButton(
    onPressed: _saveToProject,
    child: Text('Save to Project'),
  ),
}

// Always visible (works in guest mode)
ElevatedButton(
  onPressed: _exportGLB,
  child: Text('Export GLB'),
)
```

**Contract Validation**:
- Review UI in guest mode → Verify cloud features are HIDDEN (not just disabled)
- Attempt to access hidden feature → Should be impossible (no UI element exists)

---

## Contract 4: GraphQL Service - Backend Call Blocking

### Component: GraphQL Service (`lib/core/services/graphql_service.dart`)

**Contract**: MUST block all backend calls when in guest mode

**Input Conditions**:
- Any code calls `GraphQLService.query()` or `GraphQLService.mutate()`
- `GuestSessionManager.isGuestMode` returns true

**Required Behavior**:
```dart
Future<QueryResult> query(String query, {Map<String, dynamic>? variables}) async {
  // Guest mode check FIRST (before any network operation)
  if (_guestSession.isGuestMode) {
    if (kDebugMode) {
      print('❌ [GUEST] Backend call blocked: $query');
      throw StateError('Backend operation not allowed in guest mode: $query');
    } else {
      print('⚠️ [GUEST] Backend call blocked silently');
    }
    return QueryResult(/* empty result with no errors */);
  }

  // ... existing query logic
}
```

**Debug Mode Behavior**:
- Throw `StateError` exception
- Print detailed error message with query/mutation name
- MUST crash app in debug to catch violations early

**Production Mode Behavior**:
- Return empty `QueryResult` (no exception)
- Log warning message
- Silently skip backend call

**Contract Validation**:
- Unit test: Mock `isGuestMode = true`, attempt query → Verify exception in debug
- Integration test: Enable guest mode, trigger feature requiring backend → Verify no network call

---

## Contract 5: Guest Storage Helper - Local File Operations

### Component: Guest Storage Helper (`lib/features/guest/utils/guest_storage_helper.dart`)

**Contract**: MUST save guest scans to app documents directory

**Input**:
- Scan data: `Uint8List` (GLB binary data)
- Filename pattern: `scan_YYYYMMDD_HHMMSS.glb`

**Required Behavior**:
```dart
Future<File> saveGuestScan(Uint8List scanData) async {
  // 1. Get app documents directory
  final directory = await getApplicationDocumentsDirectory();

  // 2. Create guest_scans subdirectory if needed
  final guestDir = Directory('${directory.path}/guest_scans');
  if (!await guestDir.exists()) {
    await guestDir.create(recursive: true);
  }

  // 3. Generate filename with timestamp
  final timestamp = DateTime.now();
  final filename = 'scan_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_'
                   '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}.glb';

  // 4. Write file
  final file = File('${guestDir.path}/$filename');
  await file.writeAsBytes(scanData);

  // 5. Save metadata to shared_preferences
  await _saveMetadata(file.path, scanData.length);

  return file;
}
```

**Output**:
- Returns `File` object with path to saved GLB
- File is guaranteed to exist on filesystem
- Metadata is persisted in shared_preferences

**Error Handling**:
- Storage full → Throw `FileSystemException` with message "Device storage full"
- Permission denied → Should not occur (app documents dir requires no permission)
- Write failure → Throw exception with OS error details

**Contract Validation**:
- Unit test: Mock file system, verify correct path structure
- Integration test: Save scan, verify file exists at expected path
- Error test: Mock storage full, verify exception thrown

---

## Contract 6: Account Creation Prompt Dialog

### Component: Account Creation Dialog

**Contract**: MUST prompt user when attempting restricted feature in guest mode

**Trigger Conditions**:
- Guest user taps "Save to Project" (if accidentally shown)
- Guest user accesses any authenticated-only feature
- Guest user taps "Sign Up" in banner

**Required Dialog UI**:
```dart
AlertDialog(
  title: Text('Create Account'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Sign up to unlock:'),
      SizedBox(height: 8),
      _BulletPoint('Save scans to the cloud'),
      _BulletPoint('Access from any device'),
      _BulletPoint('Share with team members'),
      _BulletPoint('Unlimited scan storage'),
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
)
```

**User Actions**:
1. **Continue as Guest**: Dialog closes, user remains in guest mode, returns to previous screen
2. **Sign Up**: Guest mode disabled, navigate to sign-up screen (`/signup`)

**Contract Validation**:
- Widget test: Verify dialog displays correct text and buttons
- Integration test: Tap "Sign Up" → Verify navigation to sign-up screen
- State test: After "Continue as Guest" → Verify still in guest mode

---

## Contract 7: Navigation Rules

### Component: App Navigation

**Contract**: Guest users MUST NOT access authenticated screens

**Blocked Routes** (when `isGuestMode == true`):
- `/home` - Home screen (requires projects list from backend)
- `/projects` - Projects list screen
- `/projects/:id` - Project detail screen
- `/profile` - User profile screen
- `/settings` - Account settings screen

**Allowed Routes** (in guest mode):
- `/` - Main screen (can return to switch modes)
- `/scanning` - Scanning screen (guest mode enabled)
- `/signup` - Sign-up screen (upgrade path)
- `/login` - Login screen (switch to auth mode)

**Navigation Guard Implementation**:
```dart
// In MaterialApp route configuration
onGenerateRoute: (settings) {
  // Check if route requires authentication
  final requiresAuth = _requiresAuthentication(settings.name);

  if (requiresAuth && _guestSession.isGuestMode) {
    // Redirect to account creation prompt
    return MaterialPageRoute(
      builder: (_) => _AccountRequiredScreen(
        attemptedRoute: settings.name,
      ),
    );
  }

  // ... normal route handling
}
```

**Contract Validation**:
- Integration test: Enable guest mode, attempt to navigate to `/projects` → Verify blocked
- Integration test: Verify redirect to account prompt screen

---

## Contract 8: Accessibility Requirements

### Global Accessibility Contracts

**Contract**: All guest mode UI elements MUST be accessible

**Required Implementations**:

1. **Guest Mode Button** (Main Screen):
   ```dart
   Semantics(
     label: 'Continue as Guest',
     hint: 'Scan rooms without creating an account. Guest scans are saved locally only.',
     button: true,
     child: ElevatedButton(...),
   )
   ```

2. **Guest Mode Banner**:
   ```dart
   Semantics(
     label: 'Guest Mode Active',
     hint: 'You are using the app without an account. Scans are saved on this device only.',
     child: Container(...),
   )
   ```

3. **Sign Up Button** (in banner):
   ```dart
   Semantics(
     label: 'Sign Up',
     hint: 'Create an account to save scans to the cloud',
     button: true,
     child: TextButton(...),
   )
   ```

4. **Export GLB Button**:
   ```dart
   Semantics(
     label: 'Export Scan',
     hint: 'Save scan file to device storage',
     button: true,
     child: ElevatedButton(...),
   )
   ```

**Validation**:
- Screen reader test (TalkBack/VoiceOver): Verify all elements have proper labels
- Semantic tree inspection: Verify all interactive elements marked with `button: true`
- Contrast check: Verify all text meets WCAG AA standards (4.5:1 minimum)

---

## Summary of Contracts

| Contract | Component | Type | Enforcement |
|----------|-----------|------|-------------|
| 1 | Main Screen | UI | Manual QA + Widget Test |
| 2 | Scanning Screen Banner | UI | Widget Test |
| 3 | Feature Visibility | UI Logic | Integration Test |
| 4 | Backend Call Blocking | Service | Unit Test + Integration Test |
| 5 | Local File Operations | Storage | Unit Test + Integration Test |
| 6 | Account Creation Dialog | UI | Widget Test |
| 7 | Navigation Guards | Routing | Integration Test |
| 8 | Accessibility | Global | Semantic Tree + Manual QA |

---

## Contract Testing Strategy

### Unit Tests (Services)
- `GuestSessionManager`: State transitions, persistence
- `GuestStorageHelper`: File operations, metadata management
- `GraphQLService`: Backend blocking in guest mode

### Widget Tests (UI Components)
- Guest mode button: Rendering, tap handling
- Guest mode banner: Visibility, "Sign Up" button
- Account creation dialog: UI, button actions

### Integration Tests (Full Workflows)
- Complete guest flow: Main screen → Scan → Export
- Feature gating: Attempt backend operation → Verify blocked
- Account upgrade: Guest → Sign Up → Authenticated
- Navigation guards: Guest tries to access projects → Blocked

---

## Compliance Verification Checklist

Before merging guest mode implementation, verify:

- [ ] Guest mode button exists on main screen (unauthenticated state)
- [ ] Guest mode banner displays in scanning screen
- [ ] Cloud features are HIDDEN (not disabled) in guest mode
- [ ] ALL backend calls are blocked (GraphQLService check)
- [ ] Guest scans save to local storage successfully
- [ ] GLB export works in guest mode
- [ ] Account creation prompt displays when accessing restricted features
- [ ] Navigation guards prevent access to authenticated screens
- [ ] All UI elements have proper Semantics labels
- [ ] All contracts have corresponding tests (unit, widget, or integration)

---

## Contract Violations

Any code that violates these contracts MUST NOT be merged. Common violations to watch for:

- ❌ Showing "Save to Project" button in guest mode (violates Contract 3)
- ❌ Making backend calls in guest mode (violates Contract 4)
- ❌ Saving guest scans to wrong directory (violates Contract 5)
- ❌ Allowing navigation to `/home` in guest mode (violates Contract 7)
- ❌ Missing Semantics labels on buttons (violates Contract 8)

**Enforcement**: Code review must verify all contracts before approval.
