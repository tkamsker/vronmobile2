#!/bin/bash

# Script to add RoomOutlineExtractor.swift to Xcode project

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

# Check if file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: $PROJECT_FILE not found"
    exit 1
fi

# Generate UUIDs (using random hex strings)
FILE_REF_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)
BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)

echo "Generated UUIDs:"
echo "  FILE_REF: $FILE_REF_UUID"
echo "  BUILD_FILE: $BUILD_FILE_UUID"

# Backup original file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo "✅ Backed up project file"

# Add PBXBuildFile entry (after AppDelegate.swift build file)
sed -i '' "/74858FAF1ED2DC5600515810 \/\* AppDelegate.swift in Sources \*\//a\\
		${BUILD_FILE_UUID} /* RoomOutlineExtractor.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${FILE_REF_UUID} /* RoomOutlineExtractor.swift */; };
" "$PROJECT_FILE"

# Add PBXFileReference entry (after AppDelegate.swift file reference)
sed -i '' "/74858FAE1ED2DC5600515810 \/\* AppDelegate.swift \*\/ = {isa = PBXFileReference/a\\
		${FILE_REF_UUID} /* RoomOutlineExtractor.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = RoomOutlineExtractor.swift; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"

# Add to PBXGroup children (Runner folder)
sed -i '' "/74858FAE1ED2DC5600515810 \/\* AppDelegate.swift \*\//a\\
				${FILE_REF_UUID} /* RoomOutlineExtractor.swift */,
" "$PROJECT_FILE"

# Add to PBXSourcesBuildPhase files
sed -i '' "/74858FAF1ED2DC5600515810 \/\* AppDelegate.swift in Sources \*\//a\\
				${BUILD_FILE_UUID} /* RoomOutlineExtractor.swift in Sources */,
" "$PROJECT_FILE"

echo "✅ Added RoomOutlineExtractor.swift to Xcode project"
echo ""
echo "To verify, run:"
echo "  flutter clean && flutter build ios --debug --no-codesign"
echo ""
echo "If there are issues, restore backup:"
echo "  cp ${PROJECT_FILE}.backup $PROJECT_FILE"

