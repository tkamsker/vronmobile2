# Data Model: Guest Mode

**Date**: 2025-12-24
**Feature**: 007-guest-mode

## Overview

This document defines the data structures and entities involved in guest mode functionality. Guest mode is a simplified, unauthenticated session that allows users to access LiDAR scanning without cloud synchronization.

---

## Core Entities

### 1. GuestSession

**Purpose**: Represents the current guest mode state and provides session management

**Fields**:
- `isGuestMode`: bool - Whether the current session is in guest mode
- `enteredAt`: DateTime? - When guest mode was activated (for analytics/debugging)
- `scanCount`: int - Number of scans performed in current guest session

**Storage**:
- `isGuestMode` persisted in shared_preferences (key: `is_guest_mode`)
- `enteredAt` and `scanCount` are runtime only (not persisted)

**Lifecycle**:
1. Created on app launch by reading shared_preferences
2. Activated when user taps "Guest Mode" button
3. Deactivated when user creates account or explicitly logs in
4. Persists across app restarts until explicitly deactivated

**Validation Rules**:
- `isGuestMode` defaults to false if not set
- `scanCount` cannot be negative
- `enteredAt` set only when transitioning to guest mode

**Usage**:
```dart
class GuestSession {
  bool _isGuestMode;
  DateTime? _enteredAt;
  int _scanCount;

  GuestSession({
    required bool isGuestMode,
    DateTime? enteredAt,
    int scanCount = 0,
  })  : _isGuestMode = isGuestMode,
        _enteredAt = enteredAt,
        _scanCount = scanCount;

  bool get isGuestMode => _isGuestMode;
  DateTime? get enteredAt => _enteredAt;
  int get scanCount => _scanCount;

  void incrementScanCount() {
    _scanCount++;
  }

  void activate() {
    _isGuestMode = true;
    _enteredAt = DateTime.now();
    _scanCount = 0;
  }

  void deactivate() {
    _isGuestMode = false;
    _enteredAt = null;
    _scanCount = 0;
  }
}
```

---

### 2. LocalScanMetadata

**Purpose**: Metadata for guest scans stored locally (without backend synchronization)

**Fields**:
- `id`: String - Unique identifier (UUID)
- `filename`: String - GLB file name (e.g., `scan_20251224_143022.glb`)
- `filePath`: String - Full path to GLB file on device
- `createdAt`: DateTime - When scan was created
- `fileSize`: int - Size in bytes
- `thumbnailPath`: String? - Optional thumbnail image path

**Storage**:
- Metadata in shared_preferences (JSON array under key: `guest_scans_metadata`)
- GLB files in app documents directory: `{appDir}/guest_scans/{filename}`

**Lifecycle**:
1. Created when guest completes a scan
2. Persists until app uninstall or user manually deletes
3. No backend synchronization
4. No automatic cleanup

**Validation Rules**:
- `id` must be unique UUID
- `filename` must match pattern: `scan_YYYYMMDD_HHMMSS.glb`
- `filePath` must exist on filesystem
- `fileSize` must be > 0
- `createdAt` cannot be in the future

**Usage**:
```dart
class LocalScanMetadata {
  final String id;
  final String filename;
  final String filePath;
  final DateTime createdAt;
  final int fileSize;
  final String? thumbnailPath;

  LocalScanMetadata({
    required this.id,
    required this.filename,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
    this.thumbnailPath,
  });

  factory LocalScanMetadata.fromJson(Map<String, dynamic> json) {
    return LocalScanMetadata(
      id: json['id'] as String,
      filename: json['filename'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileSize: json['fileSize'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'thumbnailPath': thumbnailPath,
    };
  }
}
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface                          │
│                     (Main Screen)                           │
└────────────┬────────────────────────────────────────────────┘
             │ Tap "Guest Mode"
             ▼
┌─────────────────────────────────────────────────────────────┐
│                GuestSessionManager                          │
│             .enableGuestMode()                              │
└────────────┬────────────────────────────────────────────────┘
             │ Persist state
             ▼
┌─────────────────────────────────────────────────────────────┐
│              SharedPreferences                              │
│          key: is_guest_mode = true                          │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                 Navigation Service                          │
│       Navigator.pushNamed('/scanning')                      │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│               Scanning Screen                               │
│          (LiDAR feature - UC14)                             │
│     - Shows guest mode banner                               │
│     - Hides cloud save options                              │
└────────────┬────────────────────────────────────────────────┘
             │ Scan complete
             ▼
┌─────────────────────────────────────────────────────────────┐
│            GuestStorageHelper                               │
│       .saveGuestScan(data)                                  │
└────────────┬────────────────────────────────────────────────┘
             │ Write to filesystem
             ▼
┌─────────────────────────────────────────────────────────────┐
│         App Documents Directory                             │
│    /guest_scans/scan_20251224_143022.glb                    │
└────────────┬────────────────────────────────────────────────┘
             │ Save metadata
             ▼
┌─────────────────────────────────────────────────────────────┐
│          SharedPreferences                                  │
│     key: guest_scans_metadata = [...]                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Backend Bypass Flow

```
┌─────────────────────────────────────────────────────────────┐
│              Any Feature Code                               │
│      Attempts GraphQL mutation/query                        │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│               GraphQLService                                │
│        .query() or .mutate()                                │
└────────────┬────────────────────────────────────────────────┘
             │ Check guest mode
             ▼
         ┌───────────────┐
         │ Is Guest Mode?│
         └───┬───────┬───┘
             │ YES   │ NO
             │       │
             ▼       ▼
    ┌────────────┐  ┌────────────────┐
    │Block call  │  │Execute GraphQL │
    │Return empty│  │request         │
    └────────────┘  └────────────────┘
```

---

## Validation Rules

### GuestSession Validation

| Field | Validation | Error Message |
|-------|------------|---------------|
| isGuestMode | Must be boolean | "Invalid guest mode state" |
| scanCount | Must be >= 0 | "Scan count cannot be negative" |
| enteredAt | If set, cannot be in future | "Invalid entry timestamp" |

### LocalScanMetadata Validation

| Field | Validation | Error Message |
|-------|------------|---------------|
| id | Must be valid UUID format | "Invalid scan ID" |
| filename | Must match pattern `scan_YYYYMMDD_HHMMSS.glb` | "Invalid filename format" |
| filePath | File must exist on filesystem | "Scan file not found" |
| fileSize | Must be > 0 bytes | "Invalid file size" |
| createdAt | Cannot be in future | "Invalid creation date" |

### Business Rules

1. **Guest Session Activation**:
   - Can activate guest mode from unauthenticated state only
   - Cannot activate guest mode if user is already authenticated
   - Guest session persists until explicit deactivation or account creation

2. **Local Scan Storage**:
   - Each scan gets unique UUID identifier
   - Filename includes timestamp for easy sorting
   - Metadata stored separately from file data
   - No limit on number of guest scans (limited only by device storage)

3. **Backend Operations**:
   - ALL backend operations blocked in guest mode (zero tolerance)
   - Debug mode: Throws exception on attempted backend call
   - Production mode: Silent skip with warning log

4. **Account Upgrade**:
   - Guest can upgrade to account at any time
   - Guest scan data is NOT automatically migrated (per spec assumptions)
   - User explicitly informed that guest data won't be migrated

---

## State Transitions

```
┌─────────────────┐
│ Unauthenticated │
│ (Default State) │
└────────┬────────┘
         │ Tap "Guest Mode"
         ▼
┌─────────────────┐
│  Guest Active   │◄───────────┐
│ (isGuestMode =  │            │
│      true)      │            │
└────────┬────────┘            │
         │                     │
         ├─────────────────────┤
         │ Perform Scans       │
         │ (increment count)   │
         │                     │
         │ Tap "Sign Up"       │
         │ or                  │
         │ Login               │
         ▼                     │
┌─────────────────┐            │
│  Authenticated  │            │
│ (isGuestMode =  │            │
│     false)      │            │
└─────────────────┘            │
                               │
         ┌─────────────────────┤
         │ Logout              │
         ▼                     │
┌─────────────────┐            │
│ Unauthenticated │────────────┘
│ (guest flag     │
│   cleared)      │
└─────────────────┘
```

---

## Storage Locations

| Data | Storage Location | Persistence | Format |
|------|-----------------|-------------|--------|
| Guest mode flag | SharedPreferences (`is_guest_mode`) | Across app restarts | Boolean |
| Scan metadata | SharedPreferences (`guest_scans_metadata`) | Across app restarts | JSON array |
| GLB scan files | App documents dir (`/guest_scans/`) | Until app uninstall | Binary GLB |
| Session scan count | Memory only (Provider state) | Session only | Integer |
| Entry timestamp | Memory only (Provider state) | Session only | DateTime |

---

## Privacy & Security Considerations

1. **Data Minimization**:
   - Guest mode collects minimal data (just scan files)
   - No user identification or tracking
   - No analytics in guest mode (optional: basic usage metrics OK)

2. **Local Storage Security**:
   - Scan files stored in app-specific directory (not accessible by other apps)
   - No encryption needed (scans are not sensitive personal data)
   - Files automatically deleted on app uninstall

3. **No Backend Exposure**:
   - Zero guest data transmitted to backend
   - Guest session state never sent to server
   - Backend has no knowledge of guest users

4. **User Transparency**:
   - Clear disclosure that guest data is device-local only
   - Warning that data lost on app uninstall
   - Explicit notice that guest scans cannot be migrated

---

## Testing Scenarios

### Happy Path
1. User taps "Guest Mode" → Session activated, flag persisted
2. User scans room → GLB saved locally, metadata updated
3. User exports scan → GLB file copied to device storage
4. User closes app → Guest session persists
5. User reopens app → Still in guest mode, scans available

### Edge Cases
1. **Storage Full**: Scan save fails → Show error "Device storage full"
2. **App Uninstall**: All guest data deleted automatically by OS
3. **Multiple Scans**: All scans stored independently, no conflicts
4. **Upgrade During Scan**: Current scan preserved in memory until complete

### Error Paths
1. **Backend Call Attempted**: Blocked by GraphQLService, debug exception thrown
2. **Invalid File Path**: Scan save fails, error logged, user notified
3. **Corrupt Metadata**: Attempt recovery, worst case: clear metadata list

---

## Migration Path

**No data migration required** - this is a new feature.

Existing users:
- Default guest mode flag is false (no change in behavior)
- Users explicitly opt into guest mode
- No impact on existing authenticated sessions

---

## Next Steps

1. ✅ Data model defined
2. ⏭️ Create UI behavior contracts (contracts/ directory)
3. ⏭️ Generate quickstart guide for developers
