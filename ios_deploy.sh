#!/bin/bash

# iOS Deploy Script for Xcode 26.2
# Builds and deploys Flutter app to physical device

set -e

# Use Xcode 26.2 as the active developer directory
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

DEVICE_ID="00008140-0005185602DB001C"
PROJECT_ROOT="/Users/thomaskamsker/Documents/Atom/vron.one/mobile/vronmobile2"
XCODE_PATH="/Applications/Xcode.app/Contents/Developer/usr/bin"

cd "$PROJECT_ROOT/ios"

echo "🔧 Building with Xcode..."
"$XCODE_PATH/xcodebuild" \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  -allowProvisioningUpdates \
  | grep -v "^$" | grep -E "(BUILD|error|warning|note:|===|Signing|Installing)"

echo "📱 Installing on device..."
# Find the actual build location in DerivedData
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
  com.vron.vronmobile2

echo "✅ App launched successfully!"
echo ""
echo "Note: For hot reload, you'll need to fix the Xcode automation permission."
echo "Go to: System Settings > Privacy & Security > Automation > Terminal > Enable Xcode"
