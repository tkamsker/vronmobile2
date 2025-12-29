#!/bin/bash
# LiDAR Scanning - Device Test Preparation Script
# Run this before testing on physical device

set -e

echo "========================================="
echo "LiDAR Scanning Device Test Preparation"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running from project root
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Must run from project root${NC}"
    echo "Usage: ./scripts/prepare-device-test.sh"
    exit 1
fi

echo "Step 1: Checking Flutter environment..."
echo "----------------------------------------"

# Check Flutter version
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter SDK.${NC}"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter installed: $FLUTTER_VERSION${NC}"

# Check Dart version
DART_VERSION=$(dart --version 2>&1 | head -n 1)
echo -e "${GREEN}✅ Dart: $DART_VERSION${NC}"

echo ""
echo "Step 2: Checking iOS environment..."
echo "----------------------------------------"

# Check if on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}⚠️  Not on macOS. iOS device testing requires macOS + Xcode.${NC}"
    exit 1
fi

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode not found. Please install Xcode from App Store.${NC}"
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✅ Xcode installed: $XCODE_VERSION${NC}"

# Check CocoaPods
if ! command -v pod &> /dev/null; then
    echo -e "${YELLOW}⚠️  CocoaPods not found. Installing...${NC}"
    sudo gem install cocoapods
fi

POD_VERSION=$(pod --version)
echo -e "${GREEN}✅ CocoaPods: $POD_VERSION${NC}"

echo ""
echo "Step 3: Checking connected devices..."
echo "----------------------------------------"

# List Flutter devices
echo "Available devices:"
flutter devices

# Check for iOS device
DEVICE_COUNT=$(flutter devices | grep -c "ios" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No iOS devices detected.${NC}"
    echo "   Please connect your iPhone/iPad with LiDAR via USB cable."
    echo ""
    echo "   Required devices (iOS 16.0+):"
    echo "   - iPhone 12 Pro / 13 Pro / 14 Pro / 15 Pro"
    echo "   - iPad Pro with LiDAR (2020 or later)"
    echo ""
    read -p "Press Enter after connecting device..."
    flutter devices
fi

echo ""
echo "Step 4: Verifying Info.plist permissions..."
echo "----------------------------------------"

INFO_PLIST="ios/Runner/Info.plist"
if [ ! -f "$INFO_PLIST" ]; then
    echo -e "${RED}❌ Info.plist not found at $INFO_PLIST${NC}"
    exit 1
fi

# Check for camera permission
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
    echo -e "${GREEN}✅ Camera permission (NSCameraUsageDescription) configured${NC}"
else
    echo -e "${YELLOW}⚠️  Camera permission missing. Adding to Info.plist...${NC}"
    # Note: This is a simplified add - in production, use proper XML parsing
    echo "   Please manually add to Info.plist:"
    echo "   <key>NSCameraUsageDescription</key>"
    echo "   <string>This app requires camera access to scan rooms with LiDAR sensor</string>"
fi

echo ""
echo "Step 5: Installing dependencies..."
echo "----------------------------------------"

echo "Installing Flutter packages..."
flutter pub get

echo ""
echo "Installing iOS pods..."
cd ios
pod install
cd ..

echo -e "${GREEN}✅ Dependencies installed${NC}"

echo ""
echo "Step 6: Verifying project configuration..."
echo "----------------------------------------"

# Check for flutter_roomplan dependency
if grep -q "flutter_roomplan" "pubspec.yaml"; then
    echo -e "${GREEN}✅ flutter_roomplan dependency configured${NC}"
else
    echo -e "${RED}❌ flutter_roomplan not found in pubspec.yaml${NC}"
    echo "   Add to dependencies:"
    echo "   flutter_roomplan: ^1.0.7"
    exit 1
fi

# Check minimum iOS version
PODFILE="ios/Podfile"
if grep -q "platform :ios, '16.0'" "$PODFILE"; then
    echo -e "${GREEN}✅ iOS 16.0+ platform configured in Podfile${NC}"
else
    echo -e "${YELLOW}⚠️  iOS platform version may need updating to 16.0+${NC}"
    echo "   Check ios/Podfile: platform :ios, '16.0'"
fi

echo ""
echo "Step 7: Pre-flight checklist..."
echo "----------------------------------------"

echo ""
echo "📋 Device Testing Checklist:"
echo ""
echo "Hardware:"
echo "  [ ] LiDAR-capable device connected (iPhone 12 Pro+ or iPad Pro 2020+)"
echo "  [ ] Device iOS version ≥ 16.0"
echo "  [ ] Device has sufficient storage (> 1 GB free)"
echo "  [ ] Device battery > 20%"
echo ""
echo "Xcode Setup:"
echo "  [ ] Apple Developer account signed in to Xcode"
echo "  [ ] Device trusted in Xcode (Window > Devices and Simulators)"
echo "  [ ] Signing & Capabilities configured for Runner target"
echo ""
echo "App Configuration:"
echo "  [ ] Camera permission in Info.plist"
echo "  [ ] Bundle identifier is unique"
echo "  [ ] flutter_roomplan dependency added"
echo ""

echo ""
echo "========================================="
echo "Ready to Test!"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "Option 1 - Flutter CLI:"
echo "  flutter run"
echo ""
echo "Option 2 - Xcode:"
echo "  open ios/Runner.xcworkspace"
echo "  Select your device and click Run (▶️)"
echo ""
echo "Option 3 - Release Build (better performance):"
echo "  flutter run --release"
echo ""
echo "📖 Full testing guide: specs/014-lidar-scanning/DEVICE_TESTING_GUIDE.md"
echo ""
echo -e "${GREEN}✅ All checks passed! Ready for device testing.${NC}"
