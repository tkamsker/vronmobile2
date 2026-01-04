#!/bin/bash

# Flutter Deploy Script for Xcode 26.2
# Builds with Flutter (includes debug support) and deploys to physical device
# Bypasses the Xcode automation issue that prevents `flutter run` from working

set -e

# Use Xcode 26.2 as the active developer directory
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

DEVICE_ID="00008140-0005185602DB001C"
PROJECT_ROOT="/Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2"

cd "$PROJECT_ROOT"

echo "🔨 Building with Flutter (debug mode with debugging support)..."
# Build and sign with xcodebuild directly (Flutter's signing doesn't work with dual Xcode)
cd "$PROJECT_ROOT/ios"
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  FLUTTER_BUILD_NAME=1.0.0 \
  FLUTTER_BUILD_NUMBER=1 \
  | grep -v "^$" | grep -E "(BUILD|error|warning|Signing)"

echo "📱 Installing on device..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products/Debug-iphoneos -name "Runner.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "❌ Error: Could not find Runner.app in DerivedData"
  exit 1
fi
echo "📦 Found app at: $APP_PATH"

xcrun devicectl device install app \
  --device "$DEVICE_ID" \
  "$APP_PATH"

echo "🚀 Launching app..."
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  --start-stopped \
  --terminate-existing \
  com.vron.vronmobile2

cd "$PROJECT_ROOT"

echo ""
echo "✅ App launched with Flutter debugging support!"
echo ""
echo "📱 To enable hot reload, run this in another terminal:"
echo "   flutter attach -d $DEVICE_ID"
echo ""
