import Foundation
import SceneKit
import UniformTypeIdentifiers

/// Transform data for positioning a scan in the combined scene
struct ScanTransform {
    let positionX: Float
    let positionY: Float
    let rotation: Float  // degrees
    let scale: Float

    /// Convert canvas 2D position to 3D scene position
    /// Canvas (x,y) maps to SceneKit (x, 0, y) with Y as vertical axis
    var scenePosition: SCNVector3 {
        // Scale down from canvas pixels to meters (typical room scan is ~5m, canvas ~500px)
        let scaleFactor: Float = 0.01
        return SCNVector3(
            positionX * scaleFactor,
            0,  // Y is vertical, keep at ground level
            positionY * scaleFactor
        )
    }

    /// Convert rotation degrees to radians for SceneKit
    var rotationRadians: Float {
        return rotation * .pi / 180.0
    }
}

/// Result of USDZ combination operation
enum CombineResult {
    case success(path: String)
    case failure(error: String)
}

/// iOS native implementation for combining multiple USDZ files into one
/// Feature 018: Combined Scan to NavMesh Workflow
/// Uses SceneKit to load, transform, and merge USDZ scenes
class USDZCombiner {

    /// Combine multiple USDZ scans into a single USDZ file
    /// - Parameters:
    ///   - scanPaths: Array of absolute paths to source USDZ files
    ///   - transforms: Array of transform data (position, rotation, scale) for each scan
    ///   - outputPath: Desired output path for combined USDZ file
    /// - Returns: CombineResult with success path or failure error
    func combineScans(
        scanPaths: [String],
        transforms: [ScanTransform],
        outputPath: String
    ) -> CombineResult {
        // Validation
        guard scanPaths.count >= 2 else {
            return .failure(error: "Need at least 2 scans to combine")
        }

        guard scanPaths.count == transforms.count else {
            return .failure(error: "Scan paths and transforms count mismatch")
        }

        // Create combined scene
        let combinedScene = SCNScene()
        let rootNode = combinedScene.rootNode

        // Load and add each scan with transforms
        for (index, scanPath) in scanPaths.enumerated() {
            let transform = transforms[index]

            guard let scanScene = loadUSDZ(path: scanPath) else {
                return .failure(error: "Failed to load USDZ at \(scanPath)")
            }

            // Create container node for this scan
            let scanContainerNode = SCNNode()
            scanContainerNode.name = "scan_\(index)"

            // Copy all child nodes from scan scene
            for childNode in scanScene.rootNode.childNodes {
                let clonedNode = childNode.clone()
                scanContainerNode.addChildNode(clonedNode)
            }

            // Apply transforms
            applyTransform(to: scanContainerNode, transform: transform)

            // Add to combined scene
            rootNode.addChildNode(scanContainerNode)
        }

        // Export combined scene as USDZ
        do {
            try exportUSDZ(scene: combinedScene, toPath: outputPath)
            return .success(path: outputPath)
        } catch {
            return .failure(error: "Failed to export USDZ: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Load a USDZ file into an SCNScene
    private func loadUSDZ(path: String) -> SCNScene? {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ USDZ file not found at: \(path)")
            return nil
        }

        do {
            let scene = try SCNScene(url: url, options: [
                .checkConsistency: true,
                .flattenScene: false,  // Keep hierarchy intact
                .createNormalsIfAbsent: true,
                .preserveOriginalTopology: false
            ])
            return scene
        } catch {
            print("❌ Failed to load USDZ: \(error.localizedDescription)")
            return nil
        }
    }

    /// Apply position, rotation, and scale transforms to a node
    private func applyTransform(to node: SCNNode, transform: ScanTransform) {
        // Apply position
        node.position = transform.scenePosition

        // Apply rotation (around Y axis - vertical)
        node.eulerAngles = SCNVector3(0, transform.rotationRadians, 0)

        // Apply scale
        node.scale = SCNVector3(transform.scale, transform.scale, transform.scale)
    }

    /// Export an SCNScene as USDZ file
    private func exportUSDZ(scene: SCNScene, toPath path: String) throws {
        let url = URL(fileURLWithPath: path)

        // Ensure output directory exists
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Remove existing file if present
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }

        // Write USDZ
        // Note: SceneKit's write method for USDZ requires iOS 14.0+
        if #available(iOS 14.0, *) {
            try scene.write(
                to: url,
                options: nil,
                delegate: nil,
                progressHandler: nil
            )
        } else {
            throw NSError(
                domain: "USDZCombiner",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "USDZ export requires iOS 14.0+"]
            )
        }
    }

    /// Generate output filename for combined scan
    /// Format: combined_scan_{projectId}_{timestamp}.usdz
    static func generateOutputPath(projectId: String, documentsDirectory: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "combined_scan_\(projectId)_\(timestamp).usdz"
        return "\(documentsDirectory)/scans/combined/\(filename)"
    }
}
