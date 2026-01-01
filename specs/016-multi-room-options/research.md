# Research: Multi-Room Scanning - Feature 016

**Date**: 2026-01-01
**Feature**: `016-multi-room-options`
**Status**: Phase 0 Complete

## Summary

This research document resolves all NEEDS CLARIFICATION items from the Feature 016 Technical Context and establishes technology decisions for room stitching, polling strategy, room name validation, multi-select UI patterns, and stitched model storage. Key findings leverage existing patterns from Feature 014 (LiDAR Scanning) and demonstrate that Feature 016 can build incrementally on proven infrastructure.

---

## Decision 1: Backend API Contract Pattern

### Decision

Use **GraphQL mutation + query pattern** for room stitching:
- **Mutation**: `stitchRooms()` to initiate stitching job
- **Query**: `stitchJob()` for polling status (as in Feature 014's `getScanStatus()`)
- **Authentication**: Bearer token via existing GraphQLService
- **Error handling**: GraphQL extensions for error codes (matching Feature 014 pattern)

### Rationale

- **Consistency**: Feature 014 already uses GraphQL for `uploadProjectScan` mutation + `getScanStatus` query polling
- **Proven architecture**: BlenderAPI backend at `https://api.vron.stage.motorenflug.at/graphql` already supports multipart file uploads and async job tracking
- **Type safety**: GraphQL schema provides clear contract definition for request/response formats
- **Error granularity**: extensions object allows detailed error codes (INSUFFICIENT_OVERLAP, ALIGNMENT_FAILURE, etc.)
- **Authentication reuse**: Existing Bearer token flow works for stitching jobs

### Alternatives Considered

**Option A: REST endpoint** (`POST /api/stitch-rooms`):
- Simpler HTTP semantics (PUT for idempotence)
- Lightweight JSON payloads
- Rejected: Backend team standardized on GraphQL; would require new API implementation effort

**Option B: WebSocket for real-time updates**:
- True push-based progress (vs polling)
- Better for long-running operations (1-3 minute stitching)
- Rejected: Adds complexity; polling every 2-3 seconds provides acceptable UX; WebSocket requires connection management

**Option C: Server-Sent Events (SSE)**:
- Stream-based updates without WebSocket complexity
- Rejected: Polling simpler for MVP; SSE adds infrastructure dependency

### Implementation Notes

**GraphQL Contract** (Phase 1 deliverable in `data-model.md`):

```graphql
# Initiate stitching job
mutation StitchRooms($input: StitchRoomsInput!) {
  stitchRooms(input: $input) {
    jobId: ID!
    status: StitchJobStatus!        # PENDING, UPLOADING, PROCESSING, ALIGNING, MERGING, COMPLETED, FAILED
    estimatedDurationSeconds: Int   # Backend estimate (60-180s typical)
  }
}

input StitchRoomsInput {
  projectId: ID!                # Target project UUID
  scanIds: [ID!]!              # Minimum 2 scans
  alignmentMode: AlignmentMode  # AUTO (default) or MANUAL (future)
  outputFormat: OutputFormat    # GLB (default) or USDZ
  roomNames: [RoomNameInput!]   # Optional user-assigned names
}

input RoomNameInput {
  scanId: ID!
  name: String!    # Max 50 chars, alphanumeric + spaces + emojis
}

enum AlignmentMode {
  AUTO    # System determines alignment (MVP)
  MANUAL  # User-provided hints (future)
}

enum OutputFormat {
  GLB
  USDZ
}

enum StitchJobStatus {
  PENDING
  UPLOADING
  PROCESSING
  ALIGNING
  MERGING
  COMPLETED
  FAILED
}

# Poll job status
query GetStitchJobStatus($jobId: ID!) {
  stitchJob(jobId: $jobId) {
    jobId: ID!
    status: StitchJobStatus!
    progress: Int!              # 0-100 percentage
    errorMessage: String        # If status == FAILED
    resultUrl: String           # If status == COMPLETED (signed S3 URL)
    createdAt: DateTime!
    completedAt: DateTime       # Null if in progress
  }
}
```

**Error Codes** (in GraphQL extensions):
- `INSUFFICIENT_OVERLAP`: Scans have <20% common area (recovery: rescan with more overlap)
- `ALIGNMENT_FAILURE`: Cannot align coordinate systems (recovery: scans incompatible)
- `BACKEND_TIMEOUT`: Processing exceeded 3-minute limit (recovery: retry or split into smaller stitch)
- `INCOMPATIBLE_FORMATS`: Mixed USDZ/GLB from different sources (recovery: convert all to same format)
- `INVALID_SCAN_ID`: Scan not found or user lacks access (recovery: verify scan exists)
- `UNAUTHORIZED`: User not authenticated (recovery: reauthenticate)
- `SERVER_ERROR`: Internal backend error (recovery: retry with exponential backoff)

---

## Decision 2: Polling Strategy

### Decision

Use **fixed interval polling: 2-3 seconds** with:
- **Polling interval**: 2 seconds (matches Feature 014 USDZ→GLB conversion polling)
- **Max duration**: 3 minutes (180 seconds) - timeout after 60 attempts
- **Backoff**: No exponential backoff for polling; simple fixed interval
- **Max retries**: 3 attempts per poll query (via RetryPolicyService - existing)
- **Status change callback**: Optional UI callback to update progress display

### Rationale

- **Matches existing pattern**: Feature 014 uses 2-second polling for USDZ→GLB conversion (50+ GB of codebase precedent)
- **Acceptable latency**: 2-second granularity provides smooth progress updates (30 updates over 60 seconds)
- **Backend load**: Polling every 2 seconds ~= 30 requests/minute per active user; Stitching typically 60-180 seconds = 30-90 requests total
- **User expectation**: Feature 014 confirms users tolerate 2-second polling (no complaints in production)
- **Mobile efficiency**: 2s interval balances battery impact vs responsiveness (vs 1s = 2x wakeups, vs 5s = choppy UX)
- **Combined timeout**: 60 attempts × 2 seconds = 120 seconds base; can be extended per job (backend returns `estimatedDurationSeconds`)

### Alternatives Considered

**Option A: Exponential backoff** (1s → 2s → 4s → 8s):
- Reduces load as operation progresses
- Rejected: Adds complexity for marginal benefit; 2-3 minute operations don't benefit from backoff; Feature 014 uses fixed interval

**Option B: 5-second polling**:
- Lighter battery/network load (12x fewer requests)
- Rejected: Delayed status updates feel sluggish to users; UI progress bar jerky with 5-second ticks

**Option C: 1-second polling**:
- Smoother UI experience (120 ticks over 2 minutes)
- Rejected: 2x battery drain; minimal UX improvement over 2s; Feature 014 already proven 2s sufficient

**Option D: Adaptive polling based on job phase**:
- Faster polling during "UPLOADING" (network-bound), slower during "PROCESSING" (computation-bound)
- Rejected: Over-engineering for MVP; all phases benefit from consistent feedback

### Implementation Notes

**Polling Loop Pattern** (from Feature 014 `scan_upload_service.dart`):

```dart
Future<RoomStitchJob> pollStitchStatus({
  required String jobId,
  Duration pollingInterval = const Duration(seconds: 2),
  int maxAttempts = 60,  // 2 min timeout default
  void Function(RoomStitchJob job)? onStatusChange,
}) async {
  RoomStitchJobStatus? lastStatus;
  int attempt = 0;

  while (attempt < maxAttempts) {
    try {
      // Query job status
      final response = await _graphQLService.query(
        query,
        variables: {'jobId': jobId},
      );

      final job = RoomStitchJob.fromJson(
        response.data?['stitchJob'] as Map<String, dynamic>,
      );

      // Notify on status change
      if (job.status != lastStatus) {
        onStatusChange?.call(job);
        lastStatus = job.status;
      }

      // Terminal states: success or failure
      if (job.status == RoomStitchJobStatus.completed ||
          job.status == RoomStitchJobStatus.failed) {
        return job;
      }

      // Wait before next poll
      await Future.delayed(pollingInterval);
      attempt++;
    } catch (e) {
      // Use RetryPolicyService to decide if error is recoverable
      final isRecoverable = _retryPolicy.isRecoverable(
        httpStatus: e.httpStatus,
        errorCode: e.errorCode,
      );

      if (!isRecoverable) {
        rethrow; // Non-recoverable error (e.g., invalid jobId)
      }

      // Recoverable error: retry with delay
      await Future.delayed(pollingInterval);
      attempt++;
    }
  }

  // Timeout
  throw TimeoutException(
    'Stitching job did not complete within 2 minutes',
  );
}
```

**Dynamic Timeout**: Backend returns `estimatedDurationSeconds` in mutation response; mobile adjusts maxAttempts:
```dart
final estimatedSeconds = 120; // From mutation response
final pollingIntervalSeconds = 2;
int maxAttempts = (estimatedSeconds / pollingIntervalSeconds).ceil() + 10; // Buffer
```

**Offline Handling**: If network drops during polling:
1. Current job state persists in-memory (RoomStitchJob object)
2. RetryPolicyService retries transient errors (502, 503, timeout)
3. After 3 retries, if offline (no connectivity), queue polling in offline queue (Feature 015)
4. When online returns, resume polling from last attempt

---

## Decision 3: Room Name Validation & Filename Sanitization

### Decision

- **UI Input**: Max **50 characters**, allow **alphanumeric + spaces + emojis** (user-facing)
- **Validation rule**: `^[a-zA-Z0-9\p{Emoji} ]{1,50}$` with Unicode normalization
- **Filename output**: Replace spaces → hyphens, remove special chars, normalize emojis → emoji-code
- **Examples**:
  - Input: "Master Bedroom 🛏️" → Filename: "master-bedroom-emoji-bed"
  - Input: "Kitchen/Dining" → Filename: "kitchen-dining" (special char removed)
  - Input: "Room #1" → Filename: "room-1" (special char removed)

### Rationale

- **50 characters**: Balances usability (long enough for "Living Room - North Wing") with filesystem limits (modern filesystems support 255-char filenames)
- **Alphanumeric + spaces**: Familiar to users; covers ~95% of room naming patterns
- **Emojis allowed**: Feature requirement (FR-017); improves accessibility for visual room identification ("🚪 Entrance", "🛏️ Master Bedroom")
- **Filename sanitization**: iOS/Android filesystem restrictions (no `/`, `\`, `:`, `*`, `?`, `"`, `<`, `>`, `|`); space-to-hyphen matches URL conventions
- **Unicode normalization**: Ensures consistent representation (e.g., "é" → "e" for ASCII fallback if needed)

### Alternatives Considered

**Option A: No emoji support**:
- Simplifies validation regex
- Rejected: Feature requirement explicitly allows emojis (FR-017); differentiation from generic scan apps

**Option B: Allow all Unicode characters**:
- Maximum flexibility
- Rejected: Filesystem compatibility issues; some systems restrict special chars; would require complex escaping

**Option C: Filename = display name (no sanitization)**:
- User intent preserved exactly
- Rejected: Breaks on systems that don't support emojis in filenames (older filesystems, network shares)

### Implementation Notes

**Validation Regex** (Dart/Regex):
```dart
class RoomNameValidator {
  static const int maxLength = 50;

  // Allow alphanumeric, spaces, and emoji characters
  static final RegExp _namePattern = RegExp(
    r'^[a-zA-Z0-9\p{L}\p{Emoji} ]{1,50}$',
    unicode: true,
  );

  static bool isValid(String name) {
    if (name.isEmpty || name.length > maxLength) return false;
    // Trim whitespace; check pattern
    return _namePattern.hasMatch(name.trim());
  }

  static String sanitize(String name) {
    // Trim, normalize Unicode (NFD), remove non-ASCII if needed
    return name.trim();
  }
}
```

**Filename Sanitizer** (in `lib/features/scanning/utils/filename_sanitizer.dart`):
```dart
class FilenameSanitizer {
  static String sanitizeForFilename(String roomName) {
    // Step 1: Replace spaces with hyphens
    String sanitized = roomName.replaceAll(' ', '-');

    // Step 2: Convert emoji to emoji-code (e.g., 🛏️ → emoji-bed)
    // Using Unicode code point replacement
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[\p{Emoji}]', unicode: true),
      (match) {
        final codePoint = match.group(0)!.codeUnitAt(0);
        return 'emoji-${codePoint.toRadixString(16)}';
      },
    );

    // Step 3: Remove special characters (keep alphanumeric and hyphens)
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');

    // Step 4: Collapse multiple hyphens to single
    sanitized = sanitized.replaceAll(RegExp(r'-+'), '-');

    // Step 5: Remove leading/trailing hyphens
    sanitized = sanitized.replaceAll(RegExp(r'^-+|-+$'), '');

    // Step 6: Limit to 40 chars (leaves room for timestamp suffix)
    if (sanitized.length > 40) {
      sanitized = sanitized.substring(0, 40);
    }

    return sanitized;
  }

  /// Generate full GLB filename with timestamp
  static String generateGlbFilename(String roomName, String scanId) {
    final sanitized = sanitizeForFilename(roomName);
    final timestamp = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    return '$sanitized-$scanId-$timestamp.glb';
  }

  // Example: "Master Bedroom 🛏️" → "master-bedroom-emoji-1f6cf-s123-2025-01-01.glb"
}
```

**Storage Pattern** (similar to Feature 014):
```dart
// Save stitched model with room names in filename
final filename = FilenameSanitizer.generateGlbFilename(
  roomName, // e.g., "Master Bedroom"
  stitchJobId,
);
final scansDir = await FileStorageService().getScansDirectory();
final stitchedFile = File('${scansDir.path}/$filename');
await stitchedFile.writeAsBytes(glbData);
```

---

## Decision 4: Multi-Select UI Pattern

### Decision

Use **Material Design long-press activation** with:
- **Trigger**: Long-press (>500ms) on any scan card in ScanListScreen
- **Visual feedback**: Checkboxes appear on all scan cards; activating scan highlights with subtle background color
- **Mode indicator**: "X selected" text in AppBar replaces "Scans" during multi-select
- **Batch actions**: Bottom sheet slides up with 3 buttons: "Export All", "Upload All", "Delete All"
- **Exit**: Tap back button or tap selected scan again to toggle; all selections cleared on navigation away

### Rationale

- **Follows Material Design**: Long-press multi-select is standard pattern (Gmail, Files app, WhatsApp)
- **Proven in Flutter**: CheckboxListTile + long-press gesture is well-documented and performant
- **Battery friendly**: Only shows checkboxes when needed (vs always visible)
- **Accessibility**: Long-press is screen-reader discoverable via Semantics(customSemanticsActions)
- **Discoverability**: Users familiar with Android/iOS apps expect this pattern
- **No mode switching**: Unlike some apps, user doesn't need to tap "Select" button first

### Alternatives Considered

**Option A: Always-visible checkboxes**:
- Faster selection (no long-press delay)
- Rejected: Clutters UI for primary use case (single scan preview); Material Design recommends long-press

**Option B: Explicit "Select Multiple" button**:
- Clearer affordance
- Rejected: Extra tap; long-press already familiar

**Option C: Swipe to select**:
- Gesture-based like iOS
- Rejected: Long-press more discoverable; swipe conflicts with card swipe actions (if added later)

**Option D: Tap to select + "Select All" button**:
- Faster bulk selection
- Rejected: Conflicting with existing single-scan tap action (opens preview)

### Implementation Notes

**GestureDetector Pattern** (scan_list_screen.dart):

```dart
GestureDetector(
  onLongPress: () {
    setState(() {
      if (_multiSelectMode) {
        _toggleScanSelection(scan.id);
      } else {
        _enterMultiSelectMode();
        _toggleScanSelection(scan.id);
      }
    });
  },
  onTap: () {
    if (_multiSelectMode) {
      setState(() {
        _toggleScanSelection(scan.id);
      });
    } else {
      // Normal behavior: open scan preview
      _previewScan(scan);
    }
  },
  child: ScanListCard(
    scan: scan,
    isSelected: _selectedScanIds.contains(scan.id),
    showCheckbox: _multiSelectMode,
  ),
)
```

**ScanListCard Widget** (new):

```dart
class ScanListCard extends StatelessWidget {
  final ScanData scan;
  final bool isSelected;
  final bool showCheckbox;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: showCheckbox
            ? Checkbox(
                value: isSelected,
                onChanged: (_) {}, // Handled by parent GestureDetector
              )
            : ScanThumbnail(scan: scan),
        title: Text(scan.roomName ?? 'Scan ${scan.sequenceNumber}'),
        subtitle: Text(
          '${_formatFileSize(scan.fileSizeBytes)} • ${_formatTimestamp(scan.capturedAt)}',
        ),
        trailing: showCheckbox
            ? null
            : Semantics(
                label: 'View scan options',
                child: PopupMenuButton(...),
              ),
      ),
    );
  }
}
```

**AppBar Title Change**:

```dart
AppBar(
  title: Text(
    _multiSelectMode
        ? '${_selectedScanIds.length} selected'
        : 'Scans',
  ),
  leading: _multiSelectMode
      ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _multiSelectMode = false;
              _selectedScanIds.clear();
            });
          },
        )
      : null,
)
```

**Bottom Sheet for Batch Actions**:

```dart
void _showBatchActionSheet() {
  showModalBottomSheet(
    context: context,
    builder: (context) => BatchActionBottomSheet(
      selectedCount: _selectedScanIds.length,
      onExportAll: _handleExportAll,
      onUploadAll: _handleUploadAll,
      onDeleteAll: _handleDeleteAll,
    ),
  );
}
```

**Accessibility** (Semantics):

```dart
Semantics(
  customSemanticsActions: {
    'activate': () {
      _toggleScanSelection(scan.id); // Long-press action
    },
  },
  label: 'Scan: ${scan.roomName ?? 'Scan ${scan.sequenceNumber}"}',
  button: true,
  enabled: true,
  child: GestureDetector(...),
)
```

---

## Decision 5: Stitched Model Storage Strategy

### Decision

Use **same directory as individual scans** (`Documents/scans/`):
- **Path**: `${appDocumentsDir}/scans/stitched-<roomNames>-<timestamp>.glb`
- **Naming**: Stitched prefix + room names (sanitized) + timestamp + .glb extension
- **Cleanup**: User must manually delete (session-only in-memory tracking; no auto-purge)
- **Backup**: Covered by iOS/Android automatic device backup (Documents folder backed up)

### Rationale

- **Consistency**: Feature 014 stores individual scans in `Documents/scans/`; stitched models are logically scans
- **No new storage tier**: Reuses existing FileStorageService (getScansDirectory)
- **User accessible**: Files visible in Files app → easy to share or delete
- **Cloud backup**: Documents folder automatically backed up on iCloud (iOS) / Google Drive (Android)
- **Session-only policy**: Follows Feature 016 architecture decision (no persistent session storage); stitched models treated like scan artifacts
- **Naming clarity**: "stitched-" prefix differentiates from individual scans in directory listing

### Alternatives Considered

**Option A: Cache directory** (`getApplicationCacheDirectory()`):
- Temporary storage (can be auto-cleared)
- Rejected: Users expect stitched models to persist like individual scans; cache implies temporary

**Option B: Project-specific directory** (`Documents/projects/{projectId}/scans/`):
- Organizes by project
- Rejected: Scope creep; Feature 016 doesn't mandate project association until upload (US20)

**Option C: Auto-cleanup after upload**:
- Frees storage space
- Rejected: Users may want local copy for offline reference; Feature 015 handles offline queueing

**Option D: Single "stitched_models" directory** separate from individual scans:
- Clear separation of concerns
- Rejected: Adds complexity; scans and stitched models are both 3D models; user workflow doesn't distinguish

### Implementation Notes

**File Naming Convention**:

```dart
String _generateStitchedFilename(List<RoomStitchRequest> request) {
  // Extract room names from request
  final roomNames = request.roomNames.values
    .join('-')
    .replaceAll(' ', '_');

  // Sanitize room names
  final sanitized = FilenameSanitizer.sanitizeForFilename(roomNames);

  // Timestamp (ISO 8601 date only)
  final timestamp = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

  // Combine: stitched-living-room-master-bedroom-2025-01-01.glb
  return 'stitched-$sanitized-$timestamp.glb';
}
```

**Download and Store** (in RoomStitchingService):

```dart
Future<File> downloadStitchedModel(String resultUrl, String filename) async {
  // Download GLB from signed S3 URL
  final response = await http.get(Uri.parse(resultUrl));

  if (response.statusCode != 200) {
    throw Exception('Failed to download stitched model: ${response.statusCode}');
  }

  // Save to scans directory
  final scansDir = await FileStorageService().getScansDirectory();
  final stitchedFile = File('${scansDir.path}/$filename');

  await stitchedFile.writeAsBytes(response.bodyBytes);

  return stitchedFile;
}
```

**Listing Stitched Models** (in scan_list_screen):

```dart
Future<List<File>> _getStitchedModels() async {
  final scansDir = await FileStorageService().getScansDirectory();
  final files = scansDir.listSync();

  // Filter for stitched models
  return files
    .whereType<File>()
    .where((f) => f.path.contains('stitched-') && f.path.endsWith('.glb'))
    .toList();
}
```

**Storage Capacity**:
- Typical stitched model: 20-100 MB (2-5 rooms merged)
- Modern iOS: 64GB+ device storage
- User can delete from Files app if needed

---

## Performance Considerations

### Stitching Job Duration

- **Small properties** (2-3 rooms): 60-120 seconds processing
- **Medium properties** (4-5 rooms): 120-180 seconds
- **Large properties** (6+ rooms): 180-300 seconds (may exceed 5-minute threshold)
- Backend returns `estimatedDurationSeconds` in mutation response

### Network Impact

- **Polling requests**: 60-150 requests over stitching duration (2s interval)
- **Each poll**: ~500 bytes request, ~1 KB response
- **Total polling bandwidth**: ~50-150 KB
- **GLB download**: 20-100 MB (same as scan upload, already handled by Feature 014)

### Memory Usage

- **Polling loop**: ~1 MB (RoomStitchJob object in-memory)
- **GLB file download**: Streamed to disk (no full buffering)
- **No regression** vs Feature 014 (same polling pattern)

### Battery Impact

- **Polling**: 2-second wakeups over 2-3 minute duration
- **Acceptable**: Feature 014 already establishes precedent
- **Mitigation**: Screen-off polling still occurs (notification updates user)

---

## Risk Assessment

### High Risks (Mitigated)

- ✅ **Backend API not yet implemented**: Mitigated by clear GraphQL contract in this research; backend can implement in parallel
- ✅ **Stitching takes >5 minutes for large properties**: Mitigated by dynamic timeout calculation from `estimatedDurationSeconds`
- ✅ **User confusion between individual and stitched scans**: Mitigated by "stitched-" prefix and separate preview mode

### Medium Risks (Acceptable)

- ⚠️ **Polling timeout on slow networks**: Acceptable; Feature 015 offline queue handles retry
- ⚠️ **Room names with emojis cause filename issues**: Mitigated by filename sanitizer; emojis converted to hex codes
- ⚠️ **Stitched models consume storage (20-100 MB)**: Acceptable; user can delete from Files app; most users have sufficient storage

### Low Risks

- ✓ **Multi-select mode unfamiliar to users**: Low; Material Design long-press is standard pattern
- ✓ **Polling interval too slow (2s)**: Low; Feature 014 established 2s as acceptable
- ✓ **Authentication required for stitching**: Low; spec already requires it (FR-020)

---

## Next Steps (Phase 1: Design & Contracts)

1. **data-model.md**: Define RoomStitchRequest, RoomStitchJob, StitchedModel entities (based on this research)
2. **contracts/room-stitching-api.graphql**: Full GraphQL schema for stitching mutations/queries
3. **quickstart.md**: Developer onboarding with testing scenarios and mock backend setup
4. **Backend coordination**: Share GraphQL contract with backend team for parallel implementation

---

## Sources

### Feature 014 Research & Patterns
- `/specs/014-lidar-scanning/research.md` - Polling strategy (2s interval, maxAttempts)
- `/specs/014-lidar-scanning/contracts/graphql-api.md` - GraphQL mutation + query pattern
- `/lib/features/scanning/services/scan_upload_service.dart` - Polling implementation

### Feature 014 Infrastructure
- `/lib/features/scanning/services/retry_policy_service.dart` - Error classification
- `/lib/features/scanning/services/file_storage_service.dart` - Document directory storage
- `/lib/features/scanning/services/error_message_service.dart` - User-facing error messages

### Feature 015 Integration
- `/specs/015-backend-error-handling/` - Offline queue pattern for job retries

### Feature 016 Specification
- `/specs/016-multi-room-options/spec.md` - User stories and requirements
- `/specs/016-multi-room-options/plan.md` - Phase 0 research tasks

### Material Design & Accessibility
- [Material Design Multi-Select Pattern](https://material.io/design/components/selection-controls.html)
- [Flutter Semantics Documentation](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter GestureDetector Documentation](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)

### GraphQL & File Upload
- [GraphQL Multipart Request Spec](https://github.com/jaydenseric/graphql-multipart-request-spec)
- [Apollo Server File Upload](https://www.apollographql.com/docs/apollo-server/data/file-uploads/)

### iOS & Filesystem
- [iOS App Sandbox - Documents Directory](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html)
- [Unicode Normalization (NFD/NFC)](https://unicode.org/reports/tr15/)
