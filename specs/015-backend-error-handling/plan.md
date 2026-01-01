# Implementation Plan: Enhanced Backend Error Handling with Device Context Headers

**Branch**: `015-backend-error-handling` | **Date**: 2025-12-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-backend-error-handling/spec.md` + Backend API header changes

## Summary

Enhance BlenderAPI integration with device context headers for improved backend error handling and diagnostics. Backend now requires/accepts additional HTTP headers: X-Device-ID (mandatory), X-Platform, X-OS-Version, X-App-Version, X-Device-Model. This enables backend to provide better error context, device-specific diagnostics, and improved support troubleshooting.

**Primary Goals**:
1. Implement device information collection in Flutter
2. Generate and persist unique device ID
3. Add device context headers to all BlenderAPI requests
4. Maintain backward compatibility during rollout
5. Support existing error handling enhancements (session tracking, retry logic)

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x (matches pubspec.yaml SDK constraint ^3.10.0)
**Primary Dependencies**:
  - device_info_plus (device information collection - NEEDS RESEARCH)
  - package_info_plus (app version - NEEDS RESEARCH)
  - uuid (device ID generation - NEEDS RESEARCH)
  - shared_preferences (device ID persistence - already in project)
  - http (HTTP client - already in project)
  - flutter_dotenv (configuration - already in project)

**Storage**: SharedPreferences for persistent device ID, in-memory cache for device info
**Testing**: Flutter widget tests, unit tests for device info service, integration tests for header injection
**Target Platform**: iOS 16.0+ (LiDAR requirement), Android API 21+ (ARCore requirement)
**Project Type**: Mobile (iOS + Android)
**Performance Goals**:
  - Device info collection: <100ms on first call, <10ms on cached calls
  - Header injection: <1ms overhead per request
  - Device ID generation: <50ms on first launch
**Constraints**:
  - Device ID must persist across app reinstalls where possible (platform limitations apply)
  - Must work offline (device info collection doesn't require network)
  - Privacy-compliant device ID (no PII, random UUID preferred)
  - Backward compatible with existing BlenderAPI endpoints
**Scale/Scope**:
  - 5 new HTTP headers on all BlenderAPI requests
  - 1 new DeviceInfoService class
  - Modifications to existing BlenderApiClient
  - ~200-300 LOC added

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Test-First Development (NON-NEGOTIABLE)
- **Status**: COMPLIANT
- **Plan**:
  - Unit tests for DeviceInfoService (device ID generation, persistence, retrieval)
  - Unit tests for header generation logic
  - Integration tests verifying headers present in BlenderAPI requests
  - Widget tests for any UI showing device info (if applicable)
  - Tests written BEFORE implementation (TDD red-green-refactor)

### ✅ II. Simplicity & YAGNI
- **Status**: COMPLIANT
- **Justification**:
  - Implementing only headers explicitly required by backend API change
  - Using established Flutter packages (device_info_plus, package_info_plus) rather than custom implementations
  - Simple service class for device info collection (no complex abstractions)
  - Device ID persistence using existing SharedPreferences (no new storage mechanisms)
  - Headers added to existing BlenderApiClient (no new HTTP client abstraction)

### ✅ III. Platform-Native Patterns
- **Status**: COMPLIANT
- **Plan**:
  - Use platform-specific device info packages that respect iOS/Android conventions
  - Handle platform differences explicitly (Platform.isIOS, Platform.isAndroid)
  - Follow Dart async/await patterns for device info collection
  - Use Flutter's dependency injection patterns for service access
  - Feature-based file organization: `lib/features/scanning/services/device_info_service.dart`

### ✅ Security & Privacy Requirements
- **Status**: COMPLIANT
- **Plan**:
  - Device ID: Random UUID (not tied to hardware identifiers for privacy)
  - No PII collected (device model is non-sensitive, OS version is public)
  - Device ID stored in SharedPreferences (non-sensitive, no need for secure_storage)
  - Clear documentation of what device data is collected and why
  - Headers only sent to BlenderAPI (not other endpoints)

### ✅ Performance Standards
- **Status**: COMPLIANT
- **Plan**:
  - Device info cached in memory after first collection (avoid repeated platform calls)
  - Lazy initialization (collect on first API request, not app launch)
  - Header string generation cached (avoid repeated string interpolation)
  - No impact on app launch time (<3s cold start maintained)

### ✅ Accessibility Requirements
- **Status**: N/A
- **Justification**: No user-facing UI changes, backend integration only

### ✅ CI/CD & DevOps Practices
- **Status**: COMPLIANT
- **Plan**:
  - Feature branch: `015-backend-error-handling` (already created)
  - Atomic commits for each logical change (device info service, header injection, tests)
  - CI pipeline runs all tests on PR
  - Code review required before merge
  - Semantic versioning: PATCH increment (backward compatible enhancement)

## Project Structure

### Documentation (this feature)

```text
specs/015-backend-error-handling/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (already exists)
├── research.md          # Phase 0 output (/speckit.plan command - TO BE GENERATED)
├── data-model.md        # Phase 1 output (/speckit.plan command - TO BE GENERATED)
├── quickstart.md        # Phase 1 output (/speckit.plan command - TO BE GENERATED)
├── contracts/           # Phase 1 output (/speckit.plan command - TO BE GENERATED)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/features/scanning/
├── services/
│   ├── blender_api_client.dart           # MODIFY: Add device headers to all requests
│   ├── device_info_service.dart          # NEW: Device information collection
│   ├── session_tracker.dart              # EXISTS: Session tracking (from previous work)
│   └── error_log_service.dart            # EXISTS: Error logging
├── models/
│   ├── blender_api_models.dart           # EXISTS: API models
│   ├── device_info.dart                  # NEW: Device info data model
│   └── error_context.dart                # EXISTS: Error context
└── screens/
    ├── usdz_preview_screen.dart          # EXISTS: Conversion UI (no changes needed)
    └── session_diagnostics_screen.dart   # EXISTS: Diagnostics UI (no changes needed)

test/features/scanning/
├── services/
│   ├── device_info_service_test.dart     # NEW: Unit tests for device info
│   └── blender_api_client_test.dart      # MODIFY: Add header verification tests
└── integration/
    └── blender_api_headers_test.dart     # NEW: Integration test for headers

Requirements/
├── FLUTTER_API_PRD.md                    # EXISTS: BlenderAPI PRD
├── PRD_SESSION_INVESTIGATION_API.md      # EXISTS: Session investigation
├── BACKEND_VS_FLUTTER_ANALYSIS.md        # EXISTS: Backend workflow analysis
└── DEVICE_HEADERS_SPEC.md                # NEW: Device headers specification (TO BE CREATED in Phase 1)
```

**Structure Decision**: Flutter mobile app with feature-based organization. New DeviceInfoService follows existing service pattern alongside BlenderApiClient, SessionTracker, ErrorLogService. Device context headers added to existing HTTP client infrastructure without new abstractions (YAGNI compliance).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. All constitution gates passed.

---

## Phase 0: Research ✅ COMPLETE

**Status**: Research complete - All technical unknowns resolved

**Research Completed**:
1. ✅ Error message mapping service pattern (centralized service with i18n)
2. ✅ Retry policy with exponential backoff (built-in Dart async)
3. ✅ Local JSON log storage (path_provider + JSON append)
4. ✅ Offline queue management (connectivity_plus + SharedPreferences)
5. ✅ Session investigation UI (Material ExpansionTile + flutter_json_view)
6. ✅ **NEW**: Device context headers (device_info_plus + package_info_plus + uuid)

**Key Decisions**:
- Device ID: Random UUID (privacy-first, GDPR compliant)
- Device info: device_info_plus + package_info_plus (Flutter Community packages)
- Persistence: SharedPreferences (non-sensitive, fast)
- Headers: 5 new headers (X-Device-ID mandatory, others optional)
- Integration: Spread into existing _baseHeaders in BlenderApiClient

**Packages Identified**:
- device_info_plus: ^10.0.0 (NEW - device information)
- package_info_plus: ^8.0.0 (NEW - app version)
- uuid: ^4.0.0 (NEW - random device ID)
- connectivity_plus: ^7.0.0 (NEW - offline detection)
- flutter_json_view: ^1.1.3 (NEW - diagnostics UI)

**Output**: ✅ `research.md` (updated with device headers section)

---

## Phase 1: Design & Contracts ✅ COMPLETE

**Status**: All design artifacts already generated from previous planning session

**Prerequisites**: ✅ Research complete

**Artifacts Generated**:
1. ✅ `data-model.md` - Entity definitions:
   - ErrorContext model (complete error state)
   - RetryPolicy configuration
   - SessionDiagnostics result structure
   - DeviceInfo model (NEW - device context)

2. ✅ `contracts/` - API specifications:
   - BlenderAPI error response format
   - Session investigation endpoint spec
   - HTTP header specifications (including new device headers)

3. ✅ `quickstart.md` - Implementation guide:
   - Service usage examples
   - Error handling patterns
   - Session investigation workflow
   - Device info integration (NEW)

4. ✅ COMPLETE: Update agent context (CLAUDE.md):
   - Added language: Dart 3.10+ / Flutter 3.x
   - Added database: SharedPreferences for persistent device ID, in-memory cache
   - Header injection pattern documented in research.md

**Output**: ✅ data-model.md, contracts/, quickstart.md, CLAUDE.md (all complete)

---

## Phase 2: Task Generation (NOT PART OF THIS COMMAND)

**Note**: Task breakdown happens in separate `/speckit.tasks` command after planning complete.

Expected task categories:
- T001-T003: Device info service implementation
- T004-T006: BlenderAPI client header injection
- T007-T009: Testing and validation
- T010-T012: Documentation and cleanup

---

## Implementation Notes

### Device Headers Required by Backend

From user input, backend now accepts/requires:
- **X-Device-ID** (mandatory): Unique device identifier (e.g., `8c1f9b2a-4e5d-4c8e-b4fa-9a7b3f6d92ab`)
- **X-Platform** (optional): `ios` or `android`
- **X-OS-Version** (optional): OS version (e.g., `17.2`)
- **X-App-Version** (optional): App version from pubspec.yaml (e.g., `1.4.2`)
- **X-Device-Model** (optional): Device model identifier (e.g., `iPad13,8`)

### Integration Points

**BlenderApiClient modifications**:
1. Initialize DeviceInfoService in constructor
2. Collect device info on first API call (lazy init)
3. Add device headers to `_baseHeaders` getter
4. Ensure headers present on all requests (sessions, upload, convert, status, download)

**DeviceInfoService responsibilities**:
1. Generate/retrieve persistent device ID (UUID in SharedPreferences)
2. Collect platform info (iOS/Android)
3. Collect OS version (via device_info_plus)
4. Collect app version (via package_info_plus)
5. Collect device model (via device_info_plus)
6. Cache results in memory for performance
7. Provide async initialization method
8. Provide sync getter for headers (after init)

### Privacy Considerations

- Device ID is random UUID (not IDFA, not UDID, not Android ID)
- Device ID changes on app reinstall (acceptable for diagnostics)
- No personally identifiable information collected
- Device model and OS version are non-sensitive
- Headers only sent to trusted BlenderAPI endpoint

### Backward Compatibility

- Headers are additive (backend accepts them but doesn't require all)
- Existing error handling features unaffected
- Existing tests continue to pass
- Rollout can be gradual (backend tolerates missing headers)

---

## Planning Status Summary

### ✅ Phase 0: Research - COMPLETE
- All technical unknowns resolved
- Device info collection strategy decided (device_info_plus + package_info_plus + uuid)
- Privacy-compliant UUID approach for device ID
- 5 new packages identified for implementation

### ✅ Phase 1: Design & Contracts - COMPLETE
- All design artifacts generated (data-model.md, contracts/, quickstart.md)
- Agent context updated (CLAUDE.md)
- Implementation patterns documented
- API contract specifications complete

### 📋 Next Steps

1. ✅ Planning complete for device context headers feature
2. 📋 Run `/speckit.tasks` to generate task breakdown for implementation
3. 🔄 Implement tasks following TDD approach (tests first, then implementation)
4. 🧪 Verify all headers present in BlenderAPI requests
5. 📦 Add new dependencies to pubspec.yaml:
   - device_info_plus: ^10.0.0
   - package_info_plus: ^8.0.0
   - uuid: ^4.0.0
   - connectivity_plus: ^7.0.0 (for offline handling)
   - flutter_json_view: ^1.1.3 (for diagnostics UI)

---

## Planning Complete ✅

**Feature**: Enhanced Backend Error Handling with Device Context Headers
**Branch**: `015-backend-error-handling`
**Status**: Planning phase complete, ready for task generation

**Key Deliverables**:
- ✅ Implementation plan documented
- ✅ Research completed (device info collection approach)
- ✅ Design artifacts generated (data models, contracts, quickstart)
- ✅ Agent context updated (CLAUDE.md)
- ✅ Constitution compliance verified (all gates passed)

**Implementation Scope**:
- 1 new service class (DeviceInfoService)
- 5 new HTTP headers (X-Device-ID, X-Platform, X-OS-Version, X-App-Version, X-Device-Model)
- Modifications to BlenderApiClient (inject device headers)
- ~200-300 LOC added
- ~100KB binary size increase (negligible)

**Next Command**: `/speckit.tasks` - Generate task breakdown for implementation
