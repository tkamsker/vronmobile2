#!/bin/bash
# Setup Android development environment
# This script checks and sets up everything needed for Android builds both locally and in CI/CD
# Usage: ./scripts/setup-android.sh

set -e

echo "🤖 [Android Setup] Starting Android environment setup..."

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# 1. Check for Java/JDK
if ! command -v java &> /dev/null; then
  echo "❌ [Android Setup] Error: Java is not installed"
  echo "   Please install Java 17 or later"
  echo "   macOS: brew install openjdk@17"
  echo "   Linux: sudo apt-get install openjdk-17-jdk"
  exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo "✅ [Android Setup] Found: Java $JAVA_VERSION"

# 2. Check for Android SDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
  echo "❌ [Android Setup] Error: Android SDK not found"
  echo "   Please set ANDROID_HOME or ANDROID_SDK_ROOT environment variable"
  echo ""
  echo "   Common locations:"
  echo "     macOS: ~/Library/Android/sdk"
  echo "     Linux: ~/Android/Sdk"
  echo ""
  echo "   Add to your shell config (~/.bashrc, ~/.zshrc, etc.):"
  echo "     export ANDROID_HOME=\$HOME/Library/Android/sdk"
  echo "     export PATH=\$PATH:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools"
  exit 1
fi

ANDROID_SDK=${ANDROID_HOME:-$ANDROID_SDK_ROOT}
echo "✅ [Android Setup] Found: Android SDK at $ANDROID_SDK"

# 3. Check for Flutter
if ! command -v flutter &> /dev/null; then
  echo "❌ [Android Setup] Error: Flutter is not installed"
  echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo "✅ [Android Setup] Found: $FLUTTER_VERSION"

# 4. Check Android project configuration
ANDROID_DIR="$PROJECT_ROOT/android"
if [ ! -d "$ANDROID_DIR" ]; then
  echo "❌ [Android Setup] Error: android/ directory not found"
  exit 1
fi

echo "✅ [Android Setup] Android project directory exists"

# 5. Check for build.gradle.kts
BUILD_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
if [ ! -f "$BUILD_GRADLE" ]; then
  echo "❌ [Android Setup] Error: android/app/build.gradle.kts not found"
  exit 1
fi

echo "✅ [Android Setup] build.gradle.kts exists"

# 6. Check for product flavors in build.gradle.kts
if ! grep -q "productFlavors" "$BUILD_GRADLE"; then
  echo "⚠️  [Android Setup] Warning: No product flavors found in build.gradle.kts"
  echo "   The CI/CD pipeline expects 'stage' and 'prod' flavors"
  echo ""
  echo "   Would you like to add them now? (y/N)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "📝 [Android Setup] Adding product flavors to build.gradle.kts..."

    # Backup original file
    cp "$BUILD_GRADLE" "$BUILD_GRADLE.backup"

    # Add flavors after defaultConfig block
    awk '
      /defaultConfig \{/ { in_default=1 }
      /^\s*\}/ {
        if (in_default) {
          print
          print ""
          print "    flavorDimensions += \"environment\""
          print "    productFlavors {"
          print "        create(\"stage\") {"
          print "            dimension = \"environment\""
          print "            applicationIdSuffix = \".stage\""
          print "            versionNameSuffix = \"-stage\""
          print "        }"
          print "        create(\"prod\") {"
          print "            dimension = \"environment\""
          print "            // Production uses the base applicationId from defaultConfig"
          print "        }"
          print "    }"
          in_default=0
          next
        }
      }
      { print }
    ' "$BUILD_GRADLE.backup" > "$BUILD_GRADLE"

    echo "✅ [Android Setup] Product flavors added"
    echo "   Backup saved to: $BUILD_GRADLE.backup"
  else
    echo "⏭️  [Android Setup] Skipping flavor configuration"
  fi
else
  echo "✅ [Android Setup] Product flavors configured"
fi

# 7. Check Flutter dependencies
echo "📦 [Android Setup] Checking Flutter dependencies..."
cd "$PROJECT_ROOT"
flutter pub get
echo "✅ [Android Setup] Flutter dependencies installed"

# 8. Run Flutter doctor
echo "🔍 [Android Setup] Running Flutter doctor..."
flutter doctor

# 9. Summary
echo ""
echo "✨ [Android Setup] Setup complete!"
echo ""
echo "📋 Summary:"
echo "   - Java: $JAVA_VERSION"
echo "   - Android SDK: $ANDROID_SDK"
echo "   - Flutter: $(flutter --version | head -n 1 | cut -d' ' -f2)"
echo ""
echo "🚀 Ready to build Android app!"
echo ""
echo "Next steps:"
echo "   Local development:"
echo "     flutter run"
echo ""
echo "   Build stage APK:"
echo "     flutter build apk --flavor stage --release"
echo ""
echo "   Build stage AAB (for Play Store):"
echo "     flutter build appbundle --flavor stage --release"
echo ""
echo "   Build prod AAB:"
echo "     flutter build appbundle --flavor prod --release"
echo ""
