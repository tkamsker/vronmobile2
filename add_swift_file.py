#!/usr/bin/env python3
"""
Add RoomOutlineExtractor.swift to Xcode project.pbxproj file
"""
import uuid
import sys

PROJECT_FILE = "ios/Runner.xcodeproj/project.pbxproj"

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_swift_file():
    """Add RoomOutlineExtractor.swift to the Xcode project"""

    # Read the project file
    try:
        with open(PROJECT_FILE, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"❌ Error: {PROJECT_FILE} not found")
        return False

    # Check if already added
    if 'RoomOutlineExtractor.swift' in content:
        print("⚠️  RoomOutlineExtractor.swift already in project")
        return True

    # Generate UUIDs
    file_ref_uuid = generate_uuid()
    build_file_uuid = generate_uuid()

    print(f"Generated UUIDs:")
    print(f"  FILE_REF: {file_ref_uuid}")
    print(f"  BUILD_FILE: {build_file_uuid}")

    # Backup
    with open(PROJECT_FILE + '.backup', 'w') as f:
        f.write(content)
    print("✅ Backed up project file")

    # Find AppDelegate.swift references to use as anchor points
    appdelegate_build = "74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */"
    appdelegate_ref = "74858FAE1ED2DC5600515810 /* AppDelegate.swift */"

    if appdelegate_build not in content or appdelegate_ref not in content:
        print("❌ Error: Could not find AppDelegate.swift references")
        return False

    # 1. Add PBXBuildFile entry
    build_entry = f"\t\t{build_file_uuid} /* RoomOutlineExtractor.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* RoomOutlineExtractor.swift */; }};"
    content = content.replace(
        f"\t\t{appdelegate_build} = {{isa = PBXBuildFile; fileRef = 74858FAE1ED2DC5600515810 /* AppDelegate.swift */; }};",
        f"\t\t{appdelegate_build} = {{isa = PBXBuildFile; fileRef = 74858FAE1ED2DC5600515810 /* AppDelegate.swift */; }};\n{build_entry}"
    )

    # 2. Add PBXFileReference entry
    file_entry = f"\t\t{file_ref_uuid} /* RoomOutlineExtractor.swift */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = RoomOutlineExtractor.swift; sourceTree = \"<group>\"; }};"
    content = content.replace(
        f"\t\t{appdelegate_ref} = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = \"<group>\"; }};",
        f"\t\t{appdelegate_ref} = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = \"<group>\"; }};\n{file_entry}"
    )

    # 3. Add to PBXGroup (Runner folder children)
    group_entry = f"\t\t\t\t{file_ref_uuid} /* RoomOutlineExtractor.swift */,"
    content = content.replace(
        f"\t\t\t\t{appdelegate_ref.split()[0]} /* AppDelegate.swift */,",
        f"\t\t\t\t{appdelegate_ref.split()[0]} /* AppDelegate.swift */,\n{group_entry}"
    )

    # 4. Add to PBXSourcesBuildPhase (files to compile)
    sources_entry = f"\t\t\t\t{build_file_uuid} /* RoomOutlineExtractor.swift in Sources */,"
    content = content.replace(
        f"\t\t\t\t{appdelegate_build.split()[0]} /* AppDelegate.swift in Sources */,",
        f"\t\t\t\t{appdelegate_build.split()[0]} /* AppDelegate.swift in Sources */,\n{sources_entry}"
    )

    # Write updated content
    with open(PROJECT_FILE, 'w') as f:
        f.write(content)

    print("✅ Added RoomOutlineExtractor.swift to Xcode project")
    return True

if __name__ == "__main__":
    success = add_swift_file()
    sys.exit(0 if success else 1)
