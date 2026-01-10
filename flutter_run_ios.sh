#!/bin/bash
# Flutter Run Script for iOS
# Single-Xcode setup: always use /Applications/Xcode.app (Xcode 26.2)

set -e

# Use main Xcode.app as developer directory
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

echo "Using Xcode (DEVELOPER_DIR): $DEVELOPER_DIR"
echo "Xcode version:"
xcodebuild -version | head -2
echo ""

# Run Flutter command with all arguments passed through
flutter "$@"

