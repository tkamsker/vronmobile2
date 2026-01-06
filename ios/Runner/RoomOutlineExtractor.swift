import Foundation
import SceneKit
import ModelIO

/// Native iOS service for extracting 2D floor plan outlines from USDZ/GLB 3D models
/// Projects mesh vertices to ground plane (XZ) and generates convex hull polygon
class RoomOutlineExtractor {

    /// Extract 2D outline from USDZ or GLB file
    /// - Parameter url: File URL to USDZ or GLB model
    /// - Returns: Array of [x, z] coordinate pairs representing the outline polygon
    func extractOutline(from url: URL) -> [[Double]]? {
        // Load 3D scene
        guard let scene = try? SCNScene(url: url, options: nil) else {
            print("❌ Failed to load scene from \(url)")
            return nil
        }

        // Extract all vertices from the scene
        var allVertices: [SCNVector3] = []
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                let worldVertices = self.extractWorldVertices(from: geometry, node: node)
                allVertices.append(contentsOf: worldVertices)
            }
        }

        guard !allVertices.isEmpty else {
            print("❌ No vertices found in scene")
            return nil
        }

        // Find floor-level vertices
        let floorVertices = findFloorVertices(allVertices)

        guard floorVertices.count >= 3 else {
            print("❌ Not enough floor vertices found: \(floorVertices.count)")
            return nil
        }

        // Project to 2D (XZ plane)
        let points2D = floorVertices.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.z)) }

        // Compute convex hull
        let hull = convexHull(points2D)

        // Optional: simplify polygon
        let simplified = simplifyPolygon(hull, tolerance: 0.05)

        // Convert to coordinate array for Flutter
        let coordinates = simplified.map { [Double($0.x), Double($0.y)] }

        print("✅ Extracted outline with \(coordinates.count) vertices from \(allVertices.count) mesh vertices")
        return coordinates
    }

    /// Extract vertices from geometry and transform to world space
    private func extractWorldVertices(from geometry: SCNGeometry, node: SCNNode) -> [SCNVector3] {
        var vertices: [SCNVector3] = []

        // Get vertex sources
        guard let vertexSources = geometry.sources(for: .vertex).first else {
            return []
        }

        let vertexCount = vertexSources.vectorCount
        let stride = vertexSources.dataStride
        let offset = vertexSources.dataOffset

        vertexSources.data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            for i in 0..<vertexCount {
                let vertexOffset = offset + (i * stride)

                // Read float values (assuming float3)
                let x = bytes.load(fromByteOffset: vertexOffset, as: Float.self)
                let y = bytes.load(fromByteOffset: vertexOffset + 4, as: Float.self)
                let z = bytes.load(fromByteOffset: vertexOffset + 8, as: Float.self)

                // Transform to world space
                let localVertex = SCNVector3(x, y, z)
                let worldVertex = node.convertPosition(localVertex, to: nil)
                vertices.append(worldVertex)
            }
        }

        return vertices
    }

    /// Find vertices at floor level (lowest points + epsilon threshold)
    private func findFloorVertices(_ vertices: [SCNVector3], epsilon: Float = 0.05) -> [SCNVector3] {
        guard let minY = vertices.map({ $0.y }).min() else {
            return []
        }

        let threshold = minY + epsilon
        return vertices.filter { $0.y <= threshold }
    }

    /// Compute convex hull using Graham scan algorithm
    private func convexHull(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count >= 3 else { return points }

        // Find bottom-most point (or left-most if tie)
        guard let pivot = points.min(by: { p1, p2 in
            p1.y < p2.y || (p1.y == p2.y && p1.x < p2.x)
        }) else { return points }

        // Sort by polar angle with respect to pivot
        let sorted = points.sorted { p1, p2 in
            let angle1 = atan2(p1.y - pivot.y, p1.x - pivot.x)
            let angle2 = atan2(p2.y - pivot.y, p2.x - pivot.x)
            if angle1 == angle2 {
                // If same angle, closer point comes first
                return distance(p1, pivot) < distance(p2, pivot)
            }
            return angle1 < angle2
        }

        var hull: [CGPoint] = []

        for point in sorted {
            // Remove points that make clockwise turn
            while hull.count >= 2 {
                let p1 = hull[hull.count - 2]
                let p2 = hull[hull.count - 1]
                if crossProduct(p1, p2, point) <= 0 {
                    hull.removeLast()
                } else {
                    break
                }
            }
            hull.append(point)
        }

        return hull
    }

    /// Cross product to determine turn direction
    private func crossProduct(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        return (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
    }

    /// Calculate distance between two points
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Simplify polygon using Ramer-Douglas-Peucker algorithm
    private func simplifyPolygon(_ points: [CGPoint], tolerance: Double) -> [CGPoint] {
        guard points.count > 2 else { return points }

        // Find point with maximum distance from line segment
        var maxDistance: CGFloat = 0
        var maxIndex = 0
        let firstPoint = points.first!
        let lastPoint = points.last!

        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(points[i], from: firstPoint, to: lastPoint)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }

        // If max distance is greater than tolerance, recursively simplify
        if maxDistance > tolerance {
            let leftSegment = Array(points[0...maxIndex])
            let rightSegment = Array(points[maxIndex..<points.count])

            let leftSimplified = simplifyPolygon(leftSegment, tolerance: tolerance)
            let rightSimplified = simplifyPolygon(rightSegment, tolerance: tolerance)

            return leftSimplified + rightSimplified.dropFirst()
        } else {
            return [firstPoint, lastPoint]
        }
    }

    /// Calculate perpendicular distance from point to line segment
    private func perpendicularDistance(_ point: CGPoint, from start: CGPoint, to end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y

        let numerator = abs(dy * point.x - dx * point.y + end.x * start.y - end.y * start.x)
        let denominator = sqrt(dx * dx + dy * dy)

        return denominator == 0 ? 0 : numerator / denominator
    }
}
