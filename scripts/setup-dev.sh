#!/bin/bash
# Master development environment setup script
# Sets up both Android and iOS development environments
# Usage: ./scripts/setup-dev.sh [android|ios|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 VRonMobile2 Development Environment Setup"
echo "============================================="
echo ""

# Parse command line argument
SETUP_TARGET="${1:-all}"

case "$SETUP_TARGET" in
  android)
    echo "📱 Setting up Android environment only..."
    echo ""
    bash "$SCRIPT_DIR/setup-android.sh"
    ;;
  ios)
    echo "🍎 Setting up iOS environment only..."
    echo ""
    bash "$SCRIPT_DIR/setup-ios.sh"
    ;;
  all)
    echo "📱 Setting up Android and iOS environments..."
    echo ""

    # Setup Android first
    echo "============================================="
    echo "1/2: Android Setup"
    echo "============================================="
    echo ""
    bash "$SCRIPT_DIR/setup-android.sh"

    echo ""
    echo "============================================="
    echo "2/2: iOS Setup"
    echo "============================================="
    echo ""

    # Check if running on macOS for iOS setup
    if [[ "$OSTYPE" == "darwin"* ]]; then
      bash "$SCRIPT_DIR/setup-ios.sh"
    else
      echo "⏭️  [Setup] Skipping iOS setup (macOS required)"
    fi
    ;;
  *)
    echo "❌ Error: Invalid argument '$SETUP_TARGET'"
    echo ""
    echo "Usage: $0 [android|ios|all]"
    echo ""
    echo "Examples:"
    echo "  $0          # Setup both Android and iOS (default)"
    echo "  $0 all      # Setup both Android and iOS"
    echo "  $0 android  # Setup Android only"
    echo "  $0 ios      # Setup iOS only"
    exit 1
    ;;
esac

echo ""
echo "============================================="
echo "✨ Development environment ready!"
echo "============================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Configure environment variables:"
echo "   ./scripts/switch-env.sh stage    # Use staging environment"
echo "   ./scripts/switch-env.sh main     # Use production environment"
echo ""
echo "2. Run the app:"
echo "   flutter run                      # Run on connected device"
echo "   flutter run -d <device-id>       # Run on specific device"
echo ""
echo "3. Build for release:"
echo "   flutter build apk --flavor stage --release              # Android APK (stage)"
echo "   flutter build appbundle --flavor prod --release         # Android AAB (prod)"
echo "   cd ios && bundle exec fastlane ios build_upload_testflight  # iOS TestFlight"
echo ""
