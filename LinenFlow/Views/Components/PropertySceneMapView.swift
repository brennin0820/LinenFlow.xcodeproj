import CoreLocation
import SceneKit
import SwiftUI
import UIKit

struct PropertySceneMapView: View {
    let mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)]
    var focusTowerID: UUID?
    var selectedTowerID: UUID?
    var isExpanded: Bool = true
    var isInteractive: Bool = true
    var shouldOrbit: Bool = false
    var onTowerSelected: ((Tower) -> Void)? = nil

    @State private var sceneUnavailable = false

    var body: some View {
        Group {
            if sceneUnavailable || mappedTowers.isEmpty {
                fallbackImagery
            } else {
                PropertySceneMapRepresentable(
                    mappedTowers: mappedTowers,
                    focusTowerID: focusTowerID,
                    selectedTowerID: selectedTowerID,
                    isExpanded: isExpanded,
                    isInteractive: isInteractive,
                    shouldOrbit: shouldOrbit,
                    onTowerSelected: onTowerSelected,
                    onSceneFailure: { sceneUnavailable = true }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fallbackImagery: some View {
        Image("property_overview")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
    }
}

// MARK: - UIKit / SceneKit bridge

private struct PropertySceneMapRepresentable: UIViewRepresentable {
    let mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)]
    var focusTowerID: UUID?
    var selectedTowerID: UUID?
    var isExpanded: Bool
    var isInteractive: Bool
    var shouldOrbit: Bool
    var onTowerSelected: ((Tower) -> Void)?
    var onSceneFailure: () -> Void

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1)
        view.antialiasingMode = .multisampling4X
        view.autoenablesDefaultLighting = false
        view.allowsCameraControl = false
        view.isPlaying = true
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator

        let scene = context.coordinator.makeScene(mappedTowers: mappedTowers)
        view.scene = scene
        view.pointOfView = scene.rootNode.childNode(withName: "orbitCamera", recursively: true)
        context.coordinator.attach(to: view)
        context.coordinator.syncHighlight(
            focusTowerID: focusTowerID,
            selectedTowerID: selectedTowerID
        )
        context.coordinator.syncCamera(
            focusTowerID: focusTowerID,
            isExpanded: isExpanded,
            animated: false
        )

        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard uiView.scene != nil else { return }
        context.coordinator.isInteractive = isInteractive
        context.coordinator.shouldOrbit = shouldOrbit
        context.coordinator.onTowerSelected = onTowerSelected
        context.coordinator.syncHighlight(
            focusTowerID: focusTowerID,
            selectedTowerID: selectedTowerID
        )
        context.coordinator.syncCamera(
            focusTowerID: focusTowerID,
            isExpanded: isExpanded,
            animated: true
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSceneFailure: onSceneFailure)
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, SCNSceneRendererDelegate {
        private weak var scnView: SCNView?
        private var scene: SCNScene?
        private var cameraNode: SCNNode?
        private var towerNodes: [UUID: SCNNode] = [:]
        private var orbitStart = Date.now

        var isInteractive = true
        var shouldOrbit = false
        var onTowerSelected: ((Tower) -> Void)?
        private let onSceneFailure: () -> Void

        private var azimuth: Float = 0.42
        private var elevation: Float = 0.62
        private var distance: Float = 14.5
        private var target = SCNVector3Zero
        private var panStartAzimuth: Float = 0
        private var panStartElevation: Float = 0
        private var activeFocusTowerID: UUID?
        private var mappedTowerCache: [UUID: Tower] = [:]

        init(onSceneFailure: @escaping () -> Void) {
            self.onSceneFailure = onSceneFailure
        }

        func makeScene(
            mappedTowers: [(tower: Tower, coordinate: CLLocationCoordinate2D)]
        ) -> SCNScene {
            let scene = SCNScene()
            scene.background.contents = UIColor(red: 0.04, green: 0.06, blue: 0.10, alpha: 1)

            addLighting(to: scene.rootNode)
            addTerrain(to: scene.rootNode)
            addWaterAccent(to: scene.rootNode)

            let placements = HiltonPropertyMap.scenePositions(from: mappedTowers)
            mappedTowerCache = Dictionary(uniqueKeysWithValues: mappedTowers.map { ($0.tower.id, $0.tower) })
            towerNodes.removeAll()
            for entry in placements {
                let node = makeTowerNode(tower: entry.tower, at: entry.position)
                scene.rootNode.addChildNode(node)
                towerNodes[entry.tower.id] = node
            }

            let camera = SCNNode()
            camera.name = "orbitCamera"
            camera.camera = SCNCamera()
            camera.camera?.fieldOfView = 48
            camera.camera?.zNear = 0.1
            camera.camera?.zFar = 200
            camera.camera?.wantsHDR = true
            camera.camera?.bloomIntensity = 0.35
            camera.camera?.bloomThreshold = 0.85
            scene.rootNode.addChildNode(camera)
            cameraNode = camera
            applyCameraTransform(animated: false)

            self.scene = scene
            return scene
        }

        func attach(to view: SCNView) {
            scnView = view
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            pan.delegate = self
            pinch.delegate = self
            tap.delegate = self
            view.addGestureRecognizer(pan)
            view.addGestureRecognizer(pinch)
            view.addGestureRecognizer(tap)
        }

        func syncHighlight(focusTowerID: UUID?, selectedTowerID: UUID?) {
            for (id, node) in towerNodes {
                let isFocused = id == focusTowerID || id == selectedTowerID
                applyHighlight(to: node, isFocused: isFocused)
            }
        }

        func syncCamera(focusTowerID: UUID?, isExpanded: Bool, animated: Bool) {
            activeFocusTowerID = focusTowerID
            if let focusTowerID, let node = towerNodes[focusTowerID] {
                target = node.position
                distance = isExpanded ? 7.2 : 9.5
                elevation = 0.72
            } else {
                target = SCNVector3Zero
                distance = isExpanded ? 14.5 : 16.5
                elevation = 0.62
            }
            applyCameraTransform(animated: animated)
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard shouldOrbit, activeFocusTowerID == nil else { return }
            let elapsed = Float(Date.now.timeIntervalSince(orbitStart))
            azimuth = 0.42 + sin(elapsed / 9) * 0.24
            elevation = 0.62 + sin(elapsed / 7) * 0.12
            applyCameraTransform(animated: false)
        }

        // MARK: Scene content

        private func addLighting(to root: SCNNode) {
            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.color = UIColor(white: 0.35, alpha: 1)
            root.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.color = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
            key.light?.intensity = 950
            key.eulerAngles = SCNVector3(-0.85, 0.55, 0)
            root.addChildNode(key)

            let fill = SCNNode()
            fill.light = SCNLight()
            fill.light?.type = .directional
            fill.light?.color = UIColor(red: 0.2, green: 0.45, blue: 0.55, alpha: 1)
            fill.light?.intensity = 280
            fill.eulerAngles = SCNVector3(-0.35, -1.1, 0)
            root.addChildNode(fill)
        }

        private func addTerrain(to root: SCNNode) {
            let plane = SCNPlane(width: 18, height: 18)
            let material = SCNMaterial()
            if let image = UIImage(named: "property_overview") {
                material.diffuse.contents = image
                material.diffuse.wrapS = .clamp
                material.diffuse.wrapT = .clamp
            } else {
                material.diffuse.contents = makeGradientTexture()
            }
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.92
            material.metalness.contents = 0.04
            plane.firstMaterial = material

            let ground = SCNNode(geometry: plane)
            ground.eulerAngles.x = -.pi / 2
            ground.position = SCNVector3(0, -0.02, 0)
            root.addChildNode(ground)

            let rim = SCNNode(geometry: SCNTorus(ringRadius: 8.8, pipeRadius: 0.03))
            rim.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.08)
            rim.geometry?.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.12)
            rim.eulerAngles.x = .pi / 2
            rim.position = SCNVector3(0, 0.01, 0)
            root.addChildNode(rim)
        }

        private func addWaterAccent(to root: SCNNode) {
            let water = SCNNode(geometry: SCNPlane(width: 18, height: 4.5))
            water.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 0.05, green: 0.28, blue: 0.38, alpha: 0.55)
            water.geometry?.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.08)
            water.geometry?.firstMaterial?.isDoubleSided = true
            water.geometry?.firstMaterial?.lightingModel = .constant
            water.eulerAngles.x = -.pi / 2
            water.position = SCNVector3(0, -0.015, 6.2)
            root.addChildNode(water)
        }

        private func makeTowerNode(tower: Tower, at position: SCNVector3) -> SCNNode {
            let root = SCNNode()
            root.name = "tower-\(tower.id.uuidString)"
            root.position = position

            let color = uiColor(from: tower.identityColorHex)
            let height = pillarHeight(for: tower)

            let pillar = SCNNode(geometry: SCNCylinder(radius: 0.22, height: CGFloat(height)))
            pillar.name = "pillar"
            pillar.position.y = height / 2
            let pillarMaterial = SCNMaterial()
            pillarMaterial.diffuse.contents = color
            pillarMaterial.emission.contents = color.withAlphaComponent(0.15)
            pillarMaterial.lightingModel = .physicallyBased
            pillarMaterial.roughness.contents = 0.35
            pillarMaterial.metalness.contents = 0.12
            pillar.geometry?.firstMaterial = pillarMaterial
            root.addChildNode(pillar)

            let cap = SCNNode(geometry: SCNSphere(radius: 0.16))
            cap.position.y = height + 0.08
            cap.geometry?.firstMaterial?.diffuse.contents = color
            cap.geometry?.firstMaterial?.emission.contents = color.withAlphaComponent(0.35)
            root.addChildNode(cap)

            let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.34, pipeRadius: 0.025))
            ring.name = "focusRing"
            ring.geometry?.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.85)
            ring.geometry?.firstMaterial?.emission.contents = color
            ring.eulerAngles.x = .pi / 2
            ring.position.y = 0.04
            ring.isHidden = true
            root.addChildNode(ring)

            let label = makeLabelNode(text: tower.name, color: color)
            label.position.y = height + 0.55
            root.addChildNode(label)

            return root
        }

        private func makeLabelNode(text: String, color: UIColor) -> SCNNode {
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

        private func makeLabelTexture(text: String, color: UIColor) -> UIImage {
            let size = CGSize(width: 220, height: 58)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
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

        private func makeGradientTexture() -> UIImage {
            let size = CGSize(width: 512, height: 512)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                let colors = [
                    UIColor(red: 0.08, green: 0.14, blue: 0.12, alpha: 1).cgColor,
                    UIColor(red: 0.04, green: 0.10, blue: 0.16, alpha: 1).cgColor
                ] as CFArray
                let space = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }

        private func pillarHeight(for tower: Tower) -> Float {
            let normalized = Float(tower.floorCount) / 33.0
            return 0.9 + normalized * 1.8
        }

        private func applyHighlight(to node: SCNNode, isFocused: Bool) {
            guard let pillar = node.childNode(withName: "pillar", recursively: false),
                  let material = pillar.geometry?.firstMaterial else { return }

            let ring = node.childNode(withName: "focusRing", recursively: false)
            ring?.isHidden = !isFocused

            SCNTransaction.begin()
            SCNTransaction.animationDuration = isFocused ? 0.28 : 0.22
            material.emission.intensity = isFocused ? 1.1 : 0.15
            node.scale = isFocused ? SCNVector3(1.08, 1.12, 1.08) : SCNVector3(1, 1, 1)
            SCNTransaction.commit()

            if isFocused {
                let pulse = CABasicAnimation(keyPath: "opacity")
                pulse.fromValue = 0.55
                pulse.toValue = 1.0
                pulse.duration = 1.1
                pulse.autoreverses = true
                pulse.repeatCount = .infinity
                ring?.addAnimation(pulse, forKey: "pulse")
            } else {
                ring?.removeAllAnimations()
            }
        }

        private func applyCameraTransform(animated: Bool) {
            guard let cameraNode else { return }
            let cosElev = cos(elevation)
            let x = target.x + distance * cosElev * sin(azimuth)
            let y = target.y + distance * sin(elevation)
            let z = target.z + distance * cosElev * cos(azimuth)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = animated ? 0.45 : 0
            cameraNode.position = SCNVector3(x, y, z)
            cameraNode.look(at: target)
            SCNTransaction.commit()
        }

        private func uiColor(from hex: String?) -> UIColor {
            if let hex, let color = Color(hex: hex) {
                return UIColor(color)
            }
            return UIColor.cyan
        }

        // MARK: Gestures

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isInteractive else { return }
            switch gesture.state {
            case .began:
                panStartAzimuth = azimuth
                panStartElevation = elevation
                orbitStart = .now
            case .changed:
                let translation = gesture.translation(in: gesture.view)
                azimuth = panStartAzimuth - Float(translation.x) * 0.005
                elevation = min(1.15, max(0.28, panStartElevation + Float(translation.y) * 0.004))
                applyCameraTransform(animated: false)
            default:
                break
            }
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard isInteractive else { return }
            if gesture.state == .changed {
                distance = min(22, max(5.5, distance / Float(gesture.scale)))
                gesture.scale = 1
                applyCameraTransform(animated: false)
            }
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard isInteractive, let view = scnView else { return }
            let location = gesture.location(in: view)
            let hits = view.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue])
            for hit in hits {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix("tower-"),
                       let id = UUID(uuidString: String(name.dropFirst("tower-".count))),
                       let tower = mappedTowerCache[id] {
                        onTowerSelected?(tower)
                        activeFocusTowerID = id
                        syncHighlight(focusTowerID: id, selectedTowerID: id)
                        syncCamera(focusTowerID: id, isExpanded: true, animated: true)
                        return
                    }
                    node = current.parent
                }
            }
        }
    }
}

extension PropertySceneMapRepresentable.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
