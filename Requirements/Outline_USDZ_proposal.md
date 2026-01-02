Here are two practical Flutter-friendly approaches (iOS-first on-device, with your existing Blender-headless fallback for everything else).

---

## 1) Get a floorplan / outline from a scanned USDZ

### Reality check

A **USDZ mesh alone** usually doesn’t contain “floorplan” semantics (walls/doors/floor polygons). So you have two routes:

### A) Best on iOS: use **RoomPlan** (if the USDZ was produced by RoomPlan / you can rescan)

RoomPlan can give you:

* a **2D floorplan polygon(s)** + room dimensions (metric),
* and also 3D models.

**Flutter plan**

* Flutter UI + capture flow
* iOS native (Swift) using RoomPlan
* Return to Flutter: floor polygon points, walls, openings as JSON.

**Why this is best:** you get a *clean* floorplan (not a noisy mesh projection).

---

### B) If you only have USDZ: derive an outline by **projecting the mesh to the ground plane**

This works if your USDZ is roughly aligned and metric.

**Algorithm (robust enough for production)**

1. **Load USDZ** into SceneKit (`SCNScene(url:)`) or Model I/O.
2. Traverse all `SCNNode`s with geometry.
3. For each geometry:

   * Extract vertex positions
   * Transform them into world space
4. **Find “floor-ish” vertices**:

   * Determine minY (lowest point)
   * Keep vertices with `y <= minY + epsilon` (e.g. 2–5 cm)
5. **Project to XZ** (ignore Y): points become 2D.
6. Convert to a polygon:

   * Quick: **Convex hull** (fast, but may overestimate)
   * Better: **Concave hull / alpha shape** (captures room shape better)
7. Optional cleanup:

   * simplify polygon (Ramer–Douglas–Peucker)
   * snap angles (orthogonalize) if you want “architectural” look
8. Return points to Flutter and draw with `CustomPainter`.

**Flutter architecture**

* Flutter calls native iOS via `MethodChannel`
* Swift returns `[[x,z], ...]` plus scale info

**Swift sketch (iOS)**

```swift
// MethodChannel: "usdz_tools"
func extractFloorOutline(usdzPath: String) throws -> [[Float]] {
    let url = URL(fileURLWithPath: usdzPath)
    let scene = try SCNScene(url: url, options: nil)

    var pts: [SIMD3<Float>] = []

    scene.rootNode.enumerateChildNodes { node, _ in
        guard let geom = node.geometry else { return }
        let t = node.simdWorldTransform

        for src in geom.sources(for: .vertex) {
            let stride = src.dataStride
            let offset = src.dataOffset
            let count  = src.vectorCount
            src.data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
                for i in 0..<count {
                    let base = i * stride + offset
                    let x = raw.load(fromByteOffset: base + 0, as: Float.self)
                    let y = raw.load(fromByteOffset: base + 4, as: Float.self)
                    let z = raw.load(fromByteOffset: base + 8, as: Float.self)
                    let pLocal = SIMD4<Float>(x,y,z,1)
                    let pWorld4 = t * pLocal
                    pts.append(SIMD3<Float>(pWorld4.x, pWorld4.y, pWorld4.z))
                }
            }
        }
    }

    guard let minY = pts.map({ $0.y }).min() else { return [] }
    let eps: Float = 0.05 // 5cm

    let floorPts2D: [SIMD2<Float>] = pts
        .filter { $0.y <= minY + eps }
        .map { SIMD2<Float>($0.x, $0.z) }

    // TODO: compute hull (convex or concave/alpha)
    let hull: [SIMD2<Float>] = convexHull(floorPts2D)

    return hull.map { [$0.x, $0.y] } // [x,z]
}
```

**Notes**

* Convex hull is easiest. If you want concave hull, implement alpha shape or use a small native geometry helper.
* If your USDZ is not “floor-aligned”, you’ll need to estimate the ground plane (PCA / plane fit) before projecting.

---

## 2) Connect several USDZ files into one “big” USDZ (ideally on-device)

### iOS on-device (recommended): **Model I/O merge + export**

Model I/O can import/export USD/USZ in many iOS versions (varies by OS), and it’s the most realistic “native merge” path.

**Merge concept**

* Load each USDZ as an `MDLAsset`
* Take each asset’s root objects, apply a transform (position/rotation/scale)
* Add them into one master `MDLAsset`
* Export as `.usdz`

**Swift sketch**

```swift
import ModelIO
import SceneKit

struct Placement {
    let tx: Float
    let ty: Float
    let tz: Float
    let yawRadians: Float
    let scale: Float
}

func mergeUSDZ(inputs: [(URL, Placement)], output: URL) throws {
    let master = MDLAsset()

    for (url, p) in inputs {
        let a = MDLAsset(url: url)
        for obj in a {
            guard let mdlObj = obj as? MDLObject else { continue }

            var t = matrix_identity_float4x4
            // translation
            t.columns.3 = SIMD4<Float>(p.tx, p.ty, p.tz, 1)
            // yaw rotation
            let c = cos(p.yawRadians), s = sin(p.yawRadians)
            let r = float4x4(SIMD4<Float>( c,0,s,0),
                             SIMD4<Float>( 0,1,0,0),
                             SIMD4<Float>(-s,0,c,0),
                             SIMD4<Float>( 0,0,0,1))
            // scale
            let sc = float4x4(SIMD4<Float>(p.scale,0,0,0),
                              SIMD4<Float>(0,p.scale,0,0),
                              SIMD4<Float>(0,0,p.scale,0),
                              SIMD4<Float>(0,0,0,1))

            let m = t * r * sc
            mdlObj.transform = MDLTransform(matrix: m)

            master.add(mdlObj)
        }
    }

    try master.export(to: output)
}
```

**Flutter plan**

* In Flutter you maintain a “scene graph” (list of USDZ + placements).
* Call `mergeUSDZ` via `MethodChannel` on iOS.
* Result: one big USDZ saved to app storage / share sheet.

**Caveats**

* Export support can be picky depending on iOS version and the content (materials/textures).
* If you hit export limitations: export **USD (not zipped)** or use your Blender pipeline.

---

### Cross-platform reality (Android)

Android does not have a first-class USDZ stack. So for Android you typically:

* convert USDZ → GLB (your Blender headless does this)
* merge GLBs (easy with glTF tooling)
* optionally convert back to USDZ server-side if you must deliver USDZ.

---

## A pragmatic “production” setup (what I’d do)

1. **iOS**

* If possible: capture with RoomPlan → floorplan JSON (clean) + model.
* Otherwise: USDZ mesh projection → outline polygon.
* Merge USDZ on-device using Model I/O where feasible.

2. **Android / fallback**

* Use your existing **Blender headless**:

  * USDZ → GLB
  * merge GLBs (or place into one scene)
  * keep GLB as the “big one” for VR import (often better anyway)

---

If you tell me:

* **Are the USDZ files from RoomPlan** (Apple’s RoomScan) or from another scanner?
* Do you need **accurate metric dimensions** in the floorplan (cm-precise), or just a visual outline?

…I can tighten the recommended path and give you a ready-to-drop Flutter `MethodChannel` + Swift plugin skeleton for both “outline” and “merge”.
