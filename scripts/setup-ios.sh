#!/bin/bash
# Setup iOS development environment
# This script sets up everything needed for iOS builds both locally and in CI/CD
# Usage: ./scripts/setup-ios.sh

set -e

echo "🍎 [iOS Setup] Starting iOS environment setup..."

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "❌ [iOS Setup] Error: iOS development requires macOS"
  exit 1
fi

echo "✅ [iOS Setup] Running on macOS"

# 1. Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ [iOS Setup] Error: Xcode is not installed"
  echo "   Please install Xcode from the App Store"
  exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo "✅ [iOS Setup] Found: $XCODE_VERSION"

# 2. Check for Ruby
if ! command -v ruby &> /dev/null; then
  echo "❌ [iOS Setup] Error: Ruby is not installed"
  echo "   Please install Ruby (recommended: use rbenv or rvm)"
  exit 1
fi

RUBY_VERSION=$(ruby -v)
echo "✅ [iOS Setup] Found: $RUBY_VERSION"

# 3. Check for Bundler
if ! command -v bundle &> /dev/null; then
  echo "⚠️  [iOS Setup] Bundler not found, installing..."
  gem install bundler:2.5.22
  echo "✅ [iOS Setup] Bundler 2.5.22 installed"
else
  BUNDLER_VERSION=$(bundle -v)
  BUNDLER_MAJOR=$(echo "$BUNDLER_VERSION" | grep -oE '[0-9]+' | head -1)

  if [ "$BUNDLER_MAJOR" -ge 4 ]; then
    echo "⚠️  [iOS Setup] Bundler $BUNDLER_MAJOR.x detected (incompatible with fastlane)"
    echo "   Installing Bundler 2.5.22..."
    gem install bundler:2.5.22
    echo "✅ [iOS Setup] Bundler 2.5.22 installed"
  else
    echo "✅ [iOS Setup] Found: $BUNDLER_VERSION"
  fi
fi

# 4. Create Gemfile if it doesn't exist
GEMFILE_PATH="$PROJECT_ROOT/ios/Gemfile"
if [ ! -f "$GEMFILE_PATH" ]; then
  echo "📝 [iOS Setup] Creating ios/Gemfile..."
  cat > "$GEMFILE_PATH" <<'EOF'
source "https://rubygems.org"

# Bundler version compatible with fastlane
# fastlane 2.220 requires bundler < 3.0.0
gem "bundler", "~> 2.5.0"

# Fastlane for iOS automation (building, signing, uploading to TestFlight/App Store)
gem "fastlane", "~> 2.220"

# Plugins
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
EOF
  echo "✅ [iOS Setup] Gemfile created"
else
  echo "✅ [iOS Setup] Gemfile already exists"
fi

# 5. Install Ruby dependencies via Bundler
echo "📦 [iOS Setup] Installing Ruby gems..."
cd "$PROJECT_ROOT/ios"
bundle install
echo "✅ [iOS Setup] Ruby gems installed"

# 6. Check for CocoaPods
if ! command -v pod &> /dev/null; then
  echo "⚠️  [iOS Setup] CocoaPods not found"
  echo "   CocoaPods will be installed via Bundle (fastlane dependency)"
else
  POD_VERSION=$(pod --version)
  echo "✅ [iOS Setup] Found: CocoaPods $POD_VERSION"
fi

# 7. Install CocoaPods dependencies
echo "📦 [iOS Setup] Installing CocoaPods dependencies..."
cd "$PROJECT_ROOT/ios"
if [ -f "Podfile.lock" ]; then
  echo "   Using existing Podfile.lock"
  pod install
else
  echo "   No Podfile.lock found, running pod install..."
  pod install
fi
echo "✅ [iOS Setup] CocoaPods dependencies installed"

# 8. Summary
cd "$PROJECT_ROOT"
echo ""
echo "✨ [iOS Setup] Setup complete!"
echo ""
echo "📋 Summary:"
echo "   - Xcode: $XCODE_VERSION"
echo "   - Ruby: $(ruby -v | cut -d' ' -f2)"
echo "   - Bundler: $(bundle -v | cut -d' ' -f3)"
echo "   - Fastlane: $(bundle exec fastlane -v 2>/dev/null || echo 'installed')"
echo "   - CocoaPods: $(pod --version)"
echo ""
echo "🚀 Ready to build iOS app!"
echo ""
echo "Next steps:"
echo "   Local development:"
echo "     flutter run -d <ios-device-id>"
echo ""
echo "   Build for TestFlight:"
echo "     cd ios && bundle exec fastlane ios build_upload_testflight"
echo ""
