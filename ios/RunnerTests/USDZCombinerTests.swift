import XCTest
import SceneKit
@testable import Runner

/// Test suite for USDZCombiner iOS native implementation
/// Feature 018: Combined Scan to NavMesh Workflow
/// Tests: T012, T013, T014
class USDZCombinerTests: XCTestCase {

    var combiner: USDZCombiner!
    var testDocumentsDirectory: URL!
    var mockScanPaths: [String] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        combiner = USDZCombiner()

        // Setup test documents directory
        testDocumentsDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("USDZCombinerTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDocumentsDirectory, withIntermediateDirectories: true)

        // Create mock USDZ files for testing
        mockScanPaths = try createMockUSDZFiles()
    }

    override func tearDownWithError() throws {
        // Clean up test files
        if FileManager.default.fileExists(atPath: testDocumentsDirectory.path) {
            try FileManager.default.removeItem(at: testDocumentsDirectory)
        }
        combiner = nil
        mockScanPaths = []
        try super.tearDownWithError()
    }

    // MARK: - T012: Test combineScans() with 2 scans

    func testCombineScansWithTwoScans() throws {
        // Given: 2 mock USDZ scan files
        XCTAssertEqual(mockScanPaths.count, 2, "Should have 2 mock scan files")

        // And: Transforms for positioning
        let transforms = [
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 0.0, scale: 1.0),
            ScanTransform(positionX: 150.0, positionY: 0.0, rotation: 90.0, scale: 1.0)
        ]

        // And: Output path
        let outputPath = testDocumentsDirectory
            .appendingPathComponent("combined_test.usdz")
            .path

        // When: Combining scans
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should succeed
        switch result {
        case .success(let path):
            XCTAssertEqual(path, outputPath, "Output path should match")
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), "Combined USDZ file should exist")

            // Verify file is valid USDZ
            let fileURL = URL(fileURLWithPath: path)
            XCTAssertNoThrow(try SCNScene(url: fileURL, options: nil), "Combined file should be valid USDZ")

        case .failure(let error):
            XCTFail("Combine should succeed, but failed with: \(error)")
        }
    }

    func testCombineScansWithInsufficientScans() {
        // Given: Only 1 scan (insufficient)
        let singleScan = [mockScanPaths[0]]
        let singleTransform = [ScanTransform(positionX: 0, positionY: 0, rotation: 0, scale: 1.0)]
        let outputPath = testDocumentsDirectory.appendingPathComponent("output.usdz").path

        // When: Attempting to combine
        let result = combiner.combineScans(
            scanPaths: singleScan,
            transforms: singleTransform,
            outputPath: outputPath
        )

        // Then: Should fail with validation error
        switch result {
        case .success:
            XCTFail("Should fail with insufficient scans")
        case .failure(let error):
            XCTAssertTrue(error.contains("at least 2 scans"), "Error should mention minimum scan count")
        }
    }

    func testCombineScansWithMismatchedCounts() {
        // Given: 2 scans but only 1 transform
        let transforms = [ScanTransform(positionX: 0, positionY: 0, rotation: 0, scale: 1.0)]
        let outputPath = testDocumentsDirectory.appendingPathComponent("output.usdz").path

        // When: Attempting to combine
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should fail with mismatch error
        switch result {
        case .success:
            XCTFail("Should fail with count mismatch")
        case .failure(let error):
            XCTAssertTrue(error.contains("mismatch"), "Error should mention count mismatch")
        }
    }

    // MARK: - T013: Test transform application (position, rotation, scale)

    func testTransformApplicationPosition() throws {
        // Given: Scans with different positions
        let transforms = [
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 0.0, scale: 1.0),
            ScanTransform(positionX: 200.0, positionY: 100.0, rotation: 0.0, scale: 1.0)
        ]
        let outputPath = testDocumentsDirectory.appendingPathComponent("positioned.usdz").path

        // When: Combining with position transforms
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should succeed and create valid scene
        guard case .success(let path) = result else {
            XCTFail("Combine should succeed")
            return
        }

        // Load combined scene and verify node positions
        let scene = try SCNScene(url: URL(fileURLWithPath: path), options: nil)
        let rootNode = scene.rootNode

        // Verify we have 2 container nodes
        XCTAssertEqual(rootNode.childNodes.count, 2, "Should have 2 scan container nodes")

        // Verify first scan at origin (0, 0, 0)
        let firstNode = rootNode.childNodes[0]
        XCTAssertEqual(firstNode.position.x, 0.0, accuracy: 0.01)
        XCTAssertEqual(firstNode.position.z, 0.0, accuracy: 0.01)

        // Verify second scan at transformed position (200 * 0.01 = 2.0, 0, 100 * 0.01 = 1.0)
        let secondNode = rootNode.childNodes[1]
        XCTAssertEqual(secondNode.position.x, 2.0, accuracy: 0.01, "X should be scaled from canvas")
        XCTAssertEqual(secondNode.position.z, 1.0, accuracy: 0.01, "Z should be scaled from canvas Y")
    }

    func testTransformApplicationRotation() throws {
        // Given: Scans with different rotations
        let transforms = [
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 0.0, scale: 1.0),
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 90.0, scale: 1.0)
        ]
        let outputPath = testDocumentsDirectory.appendingPathComponent("rotated.usdz").path

        // When: Combining with rotation transforms
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should succeed
        guard case .success(let path) = result else {
            XCTFail("Combine should succeed")
            return
        }

        // Load and verify rotation
        let scene = try SCNScene(url: URL(fileURLWithPath: path), options: nil)
        let rootNode = scene.rootNode

        // First scan should have 0 rotation
        let firstNode = rootNode.childNodes[0]
        XCTAssertEqual(firstNode.eulerAngles.y, 0.0, accuracy: 0.01)

        // Second scan should have 90 degree rotation (π/2 radians)
        let secondNode = rootNode.childNodes[1]
        let expectedRotation = Float.pi / 2.0
        XCTAssertEqual(secondNode.eulerAngles.y, expectedRotation, accuracy: 0.01)
    }

    func testTransformApplicationScale() throws {
        // Given: Scans with different scales
        let transforms = [
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 0.0, scale: 1.0),
            ScanTransform(positionX: 0.0, positionY: 0.0, rotation: 0.0, scale: 1.5)
        ]
        let outputPath = testDocumentsDirectory.appendingPathComponent("scaled.usdz").path

        // When: Combining with scale transforms
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should succeed
        guard case .success(let path) = result else {
            XCTFail("Combine should succeed")
            return
        }

        // Load and verify scale
        let scene = try SCNScene(url: URL(fileURLWithPath: path), options: nil)
        let rootNode = scene.rootNode

        // First scan should have scale 1.0
        let firstNode = rootNode.childNodes[0]
        XCTAssertEqual(firstNode.scale.x, 1.0, accuracy: 0.01)

        // Second scan should have scale 1.5
        let secondNode = rootNode.childNodes[1]
        XCTAssertEqual(secondNode.scale.x, 1.5, accuracy: 0.01)
        XCTAssertEqual(secondNode.scale.y, 1.5, accuracy: 0.01)
        XCTAssertEqual(secondNode.scale.z, 1.5, accuracy: 0.01)
    }

    // MARK: - T014: Test scene export as USDZ

    func testSceneExportAsUSDZ() throws {
        // Given: Valid scans and transforms
        let transforms = [
            ScanTransform(positionX: 0, positionY: 0, rotation: 0, scale: 1.0),
            ScanTransform(positionX: 100, positionY: 50, rotation: 45, scale: 1.0)
        ]
        let outputPath = testDocumentsDirectory.appendingPathComponent("export_test.usdz").path

        // When: Combining and exporting
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: outputPath
        )

        // Then: Should create valid USDZ file
        guard case .success(let path) = result else {
            XCTFail("Export should succeed")
            return
        }

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))

        // Verify file has .usdz extension
        XCTAssertTrue(path.hasSuffix(".usdz"), "Output should be USDZ file")

        // Verify file is not empty
        let attributes = try FileManager.default.attributesOfItem(atPath: path)
        let fileSize = attributes[.size] as? Int ?? 0
        XCTAssertGreaterThan(fileSize, 0, "USDZ file should not be empty")

        // Verify file can be loaded as SCNScene
        let fileURL = URL(fileURLWithPath: path)
        let scene = try SCNScene(url: fileURL, options: nil)
        XCTAssertNotNil(scene.rootNode, "Scene should have root node")
        XCTAssertEqual(scene.rootNode.childNodes.count, 2, "Scene should have 2 scan nodes")
    }

    func testOutputPathCreatesIntermediateDirectories() throws {
        // Given: Output path with nested directories that don't exist
        let nestedPath = testDocumentsDirectory
            .appendingPathComponent("level1/level2/level3/output.usdz")
            .path

        let transforms = [
            ScanTransform(positionX: 0, positionY: 0, rotation: 0, scale: 1.0),
            ScanTransform(positionX: 100, positionY: 0, rotation: 0, scale: 1.0)
        ]

        // When: Combining to nested path
        let result = combiner.combineScans(
            scanPaths: mockScanPaths,
            transforms: transforms,
            outputPath: nestedPath
        )

        // Then: Should create directories and file
        guard case .success(let path) = result else {
            XCTFail("Should create intermediate directories")
            return
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testGenerateOutputPath() {
        // Given: Project ID and documents directory
        let projectId = "project-123"
        let documentsDir = testDocumentsDirectory.path

        // When: Generating output path
        let outputPath = USDZCombiner.generateOutputPath(
            projectId: projectId,
            documentsDirectory: documentsDir
        )

        // Then: Should follow naming convention
        XCTAssertTrue(outputPath.contains("combined_scan_"), "Should have combined_scan prefix")
        XCTAssertTrue(outputPath.contains(projectId), "Should contain project ID")
        XCTAssertTrue(outputPath.hasSuffix(".usdz"), "Should have .usdz extension")
        XCTAssertTrue(outputPath.contains("/scans/combined/"), "Should be in correct subdirectory")
    }

    // MARK: - Helper Methods

    /// Create mock USDZ files for testing
    /// Returns array of 2 file paths
    private func createMockUSDZFiles() throws -> [String] {
        var paths: [String] = []

        for index in 0..<2 {
            // Create simple cube scene
            let scene = SCNScene()
            let cubeGeometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
            let cubeNode = SCNNode(geometry: cubeGeometry)
            cubeNode.name = "cube_\(index)"
            scene.rootNode.addChildNode(cubeNode)

            // Export as USDZ
            let fileName = "mock_scan_\(index).usdz"
            let filePath = testDocumentsDirectory.appendingPathComponent(fileName)

            if #available(iOS 14.0, *) {
                try scene.write(to: filePath, options: nil, delegate: nil, progressHandler: nil)
                paths.append(filePath.path)
            } else {
                throw XCTSkip("USDZ export requires iOS 14.0+")
            }
        }

        return paths
    }
}
