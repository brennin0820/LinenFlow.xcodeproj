import SceneKit
import UIKit

/// Builds detailed SceneKit tower geometry for the property map.
enum TowerSceneFactory {
    private static let maxReferenceFloors: Float = 33

    static func makeNode(for tower: Tower, at position: SCNVector3) -> SCNNode {
        let root = SCNNode()
        root.name = "tower-\(tower.id.uuidString)"
        root.position = position

        let spec = spec(for: tower)
        let accent = uiColor(from: tower.identityColorHex)

        let podium = makePodium(spec: spec, accent: accent)
        root.addChildNode(podium)

        let building = makeBuilding(spec: spec, tower: tower, accent: accent)
        building.name = "building"
        building.position.y = spec.podiumHeight
        root.addChildNode(building)

        let roof = makeRoof(spec: spec, accent: accent)
        roof.position.y = spec.podiumHeight + spec.bodyHeight + spec.roofHeight / 2
        root.addChildNode(roof)

        let antenna = makeAntenna(spec: spec, accent: accent)
        antenna.position.y = spec.podiumHeight + spec.bodyHeight + spec.roofHeight + spec.antennaHeight / 2
        root.addChildNode(antenna)

        let ring = makeFocusRing(color: accent)
        root.addChildNode(ring)

        let label = makeLabelNode(text: tower.name, color: accent)
        label.position.y = totalHeight(for: spec) + 0.42
        root.addChildNode(label)

        root.eulerAngles.y = facingAngle(toward: .zero, from: position)

        return root
    }

    static func buildingHeight(for tower: Tower) -> Float {
        let normalized = Float(tower.floorCount) / maxReferenceFloors
        return 0.9 + normalized * 1.8
    }

    // MARK: - Spec

    private struct Spec {
        let width: Float
        let depth: Float
        let bodyHeight: Float
        let podiumHeight: Float
        let roofHeight: Float
        let antennaHeight: Float
    }

    private static func spec(for tower: Tower) -> Spec {
        let normalized = Float(tower.floorCount) / maxReferenceFloors
        let total = buildingHeight(for: tower)
        let podiumHeight = total * 0.14
        let roofHeight = max(0.08, total * 0.07)
        let antennaHeight: Float = 0.14
        let bodyHeight = max(0.45, total - podiumHeight - roofHeight)
        let width = 0.34 + normalized * 0.14
        let depth = width * 0.74

        return Spec(
            width: width,
            depth: depth,
            bodyHeight: bodyHeight,
            podiumHeight: podiumHeight,
            roofHeight: roofHeight,
            antennaHeight: antennaHeight
        )
    }

    private static func totalHeight(for spec: Spec) -> Float {
        spec.podiumHeight + spec.bodyHeight + spec.roofHeight + spec.antennaHeight
    }

    // MARK: - Geometry

    private static func makePodium(spec: Spec, accent: UIColor) -> SCNNode {
        let width = CGFloat(spec.width * 1.22)
        let depth = CGFloat(spec.depth * 1.18)
        let height = CGFloat(spec.podiumHeight)
        let box = SCNBox(width: width, height: height, length: depth, chamferRadius: 0.015)
        box.materials = [makeSurfaceMaterial(color: accent.withAlphaComponent(0.55), roughness: 0.82, metalness: 0.06)]
        let node = SCNNode(geometry: box)
        node.position.y = height / 2
        return node
    }

    private static func makeBuilding(spec: Spec, tower: Tower, accent: UIColor) -> SCNNode {
        let width = CGFloat(spec.width)
        let depth = CGFloat(spec.depth)
        let height = CGFloat(spec.bodyHeight)
        let box = SCNBox(width: width, height: height, length: depth, chamferRadius: 0.012)

        let facade = facadeTexture(for: tower, accent: accent)
        let sideColor = accent.withAlphaComponent(0.72)
        let backColor = accent.withAlphaComponent(0.58)
        let roofEdgeColor = accent.withAlphaComponent(0.9)

        box.materials = [
            makeFacadeMaterial(image: facade),
            makeSurfaceMaterial(color: sideColor, roughness: 0.48, metalness: 0.1),
            makeSurfaceMaterial(color: backColor, roughness: 0.55, metalness: 0.08),
            makeSurfaceMaterial(color: sideColor, roughness: 0.48, metalness: 0.1),
            makeSurfaceMaterial(color: roofEdgeColor, roughness: 0.35, metalness: 0.14),
            makeSurfaceMaterial(color: accent.withAlphaComponent(0.45), roughness: 0.88, metalness: 0.04)
        ]

        let node = SCNNode(geometry: box)
        node.position.y = height / 2
        return node
    }

    private static func makeRoof(spec: Spec, accent: UIColor) -> SCNNode {
        let width = CGFloat(spec.width * 1.14)
        let depth = CGFloat(spec.depth * 1.1)
        let height = CGFloat(spec.roofHeight)
        let box = SCNBox(width: width, height: height, length: depth, chamferRadius: 0.008)
        box.materials = [makeSurfaceMaterial(color: accent, roughness: 0.28, metalness: 0.18, emission: 0.22)]
        return SCNNode(geometry: box)
    }

    private static func makeAntenna(spec: Spec, accent: UIColor) -> SCNNode {
        let radius = CGFloat(min(0.018, spec.width * 0.045))
        let cylinder = SCNCylinder(radius: radius, height: CGFloat(spec.antennaHeight))
        cylinder.materials = [makeSurfaceMaterial(color: accent, roughness: 0.22, metalness: 0.35, emission: 0.35)]
        return SCNNode(geometry: cylinder)
    }

    private static func makeFocusRing(color: UIColor) -> SCNNode {
        let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.38, pipeRadius: 0.028))
        ring.name = "focusRing"
        ring.geometry?.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.85)
        ring.geometry?.firstMaterial?.emission.contents = color
        ring.eulerAngles.x = .pi / 2
        ring.position.y = 0.04
        ring.isHidden = true
        return ring
    }

    // MARK: - Materials

    private static func makeSurfaceMaterial(
        color: UIColor,
        roughness: CGFloat,
        metalness: CGFloat,
        emission: CGFloat = 0.12
    ) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color.withAlphaComponent(emission)
        material.lightingModel = .physicallyBased
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        return material
    }

    private static func makeFacadeMaterial(image: UIImage) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = image
        material.emission.contents = image
        material.emission.intensity = 0.18
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.42
        material.metalness.contents = 0.08
        material.isDoubleSided = false
        return material
    }

    // MARK: - Textures

    private static func facadeTexture(for tower: Tower, accent: UIColor) -> UIImage {
        let assetName = "tower_\(tower.name.lowercased())"
        if let image = UIImage(named: assetName) {
            return image
        }
        return proceduralFacade(for: tower, accent: accent)
    }

    private static func proceduralFacade(for tower: Tower, accent: UIColor) -> UIImage {
        let size = CGSize(width: 160, height: 320)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1).setFill()
            ctx.fill(rect)

            let floorCount = max(4, min(12, tower.floorCount / 3))
            let floorHeight = (rect.height - 36) / CGFloat(floorCount)
            let colors = bandColors(base: accent, count: floorCount)

            for index in 0..<floorCount {
                let bandRect = CGRect(
                    x: 10,
                    y: 18 + CGFloat(index) * floorHeight,
                    width: rect.width - 20,
                    height: floorHeight - 4
                )
                colors[index].setFill()
                UIBezierPath(roundedRect: bandRect, cornerRadius: 4).fill()

                let windowWidth = (bandRect.width - 36) / 4
                for column in 0..<4 {
                    let windowRect = CGRect(
                        x: bandRect.minX + 8 + CGFloat(column) * (windowWidth + 6),
                        y: bandRect.minY + floorHeight * 0.22,
                        width: windowWidth,
                        height: floorHeight * 0.42
                    )
                    UIColor.white.withAlphaComponent(0.82).setFill()
                    UIBezierPath(roundedRect: windowRect, cornerRadius: 2).fill()
                }
            }

            accent.setFill()
            UIBezierPath(rect: CGRect(x: 8, y: 8, width: rect.width - 16, height: 10)).fill()
        }
    }

    private static func bandColors(base: UIColor, count: Int) -> [UIColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        base.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return (0..<count).map { index in
            let shift = CGFloat(index) / CGFloat(max(count - 1, 1)) * 0.18 - 0.09
            return UIColor(
                hue: (hue + shift).truncatingRemainder(dividingBy: 1),
                saturation: min(1, saturation + 0.08),
                brightness: min(1, brightness + (index.isMultiple(of: 2) ? 0.06 : -0.04)),
                alpha: alpha
            )
        }
    }

    // MARK: - Label

    private static func makeLabelNode(text: String, color: UIColor) -> SCNNode {
        let plane = SCNPlane(width: 1.6, height: 0.42)
        plane.firstMaterial?.diffuse.contents = makeLabelTexture(text: text, color: color)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.lightingModel = .constant
        let node = SCNNode(geometry: plane)
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = .Y
        node.constraints = [constraint]
        return node
    }

    private static func makeLabelTexture(text: String, color: UIColor) -> UIImage {
        let size = CGSize(width: 220, height: 58)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 16)
            color.withAlphaComponent(0.92).setFill()
            path.fill()
            UIColor.white.withAlphaComponent(0.25).setStroke()
            path.lineWidth = 1
            path.stroke()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let string = NSAttributedString(string: text, attributes: attrs)
            let textSize = string.size()
            string.draw(at: CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            ))
        }
    }

    // MARK: - Helpers

    private static func facingAngle(toward target: SCNVector3, from position: SCNVector3) -> Float {
        let dx = target.x - position.x
        let dz = target.z - position.z
        return atan2(dx, dz)
    }

    private static func uiColor(from hex: String?) -> UIColor {
        if let hex, let color = Color(hex: hex) {
            return UIColor(color)
        }
        return UIColor.cyan
    }
}
