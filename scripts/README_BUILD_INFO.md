# Build Info Generation

This directory contains the build information generation script for the app.

## Overview

The `generate_build_info.sh` script captures build-time information from git and environment variables, generating a Dart file that can be used throughout the app.

## Usage

### Manual Generation

```bash
./scripts/generate_build_info.sh
```

### During Build

The script can be integrated into your build process:

```bash
# Development build
./scripts/generate_build_info.sh && flutter build ios --debug

# Staging build
FLUTTER_ENV=staging ./scripts/generate_build_info.sh && flutter build ios --release

# Production build
FLUTTER_ENV=production ./scripts/generate_build_info.sh && flutter build ios --release
```

### CI/CD Integration

Add to your CI/CD pipeline before building:

```yaml
# Example for GitHub Actions
- name: Generate build info
  run: |
    chmod +x scripts/generate_build_info.sh
    FLUTTER_ENV=production ./scripts/generate_build_info.sh
```

## Generated File

**Output:** `lib/core/config/build_info.dart`

**Note:** This file is excluded from git (see `.gitignore`) as it's generated at build time.

### Example Content

```dart
class BuildInfo {
  static const String buildTime = '2026-01-06 13:42 UTC';
  static const String commitHash = 'a1b2c3d';
  static const String commitMessage = 'Fix Google OAuth redirect';
  static const String branch = 'main';
  static const String environment = 'staging';

  static String get formattedInfo => '''
──────── Status ────────
Build Time:   $buildTime
Commit:       $commitHash
Message:      $commitMessage
Branch:       $branch
Environment:  $environment
''';
}
```

## Environment Variables

- **FLUTTER_ENV**: Sets the environment (default: `staging`)
  - `development` - Local development builds
  - `staging` - Staging environment
  - `production` - Production environment

## Display in App

The build info is displayed in the Profile screen:

1. Navigate to Profile tab
2. Tap "Build Version" tile
3. View detailed build information in dialog
4. Copy to clipboard if needed

## Troubleshooting

### Script not executable

```bash
chmod +x scripts/generate_build_info.sh
```

### Git not available

If git is not available, the script will use default values:
- Commit: "unknown"
- Branch: "unknown"
- Message: "No commit message"

### Build info not found at runtime

Run the generation script before building:

```bash
./scripts/generate_build_info.sh
flutter run
```
