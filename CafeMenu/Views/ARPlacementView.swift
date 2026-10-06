import ARKit
import os
import RealityKit
import SwiftUI

struct ARPlacementView: View {
    var namespace: Namespace.ID

    @Environment(CafeSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var modelPlaced = false

    private var selected: MenuItem {
        session.selected ?? MenuCatalog.chocolate
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                if selected.id != MenuCatalog.applePie.id {
                    companion
                        .position(x: geo.size.width * 0.32, y: geo.size.height * 0.34)
                }
                FoodPhoto(item: selected, diameter: min(geo.size.width * 0.52, 220), namespace: namespace)
                    .opacity(modelPlaced ? 0 : 1)
                    .position(x: geo.size.width * 0.64, y: geo.size.height * 0.58)
                chrome
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ar-screen")
        .onAppear {
            withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        #if targetEnvironment(simulator)
        slate
        #else
        ZStack {
            DeviceARView(imageName: selected.imageName, placed: $modelPlaced)
            if !modelPlaced {
                slate.opacity(0.35)
            }
        }
        #endif
    }

    private var slate: some View {
        Image("slate-bg")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    private var companion: some View {
        Image(MenuCatalog.applePie.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: appeared ? 160 : 40, height: appeared ? 160 : 40)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.35), radius: 12, y: 8)
            .accessibilityLabel(MenuCatalog.applePie.name)
    }

    private var chrome: some View {
        VStack {
            HStack {
                BackButton {
                    withAnimation(CafeMotion.curve(reduceMotion: reduceMotion)) {
                        session.back()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            Spacer()
            Text(selected.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.55), in: Capsule())
                .padding(.bottom, 28)
        }
    }
}

private let arLogger = Logger(subsystem: "com.cafemenu.app", category: "ar")

struct DeviceARView: UIViewRepresentable {
    let imageName: String
    @Binding var placed: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(imageName: imageName, placed: $placed)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        guard ARWorldTrackingConfiguration.isSupported else {
            arLogger.error("World tracking is not supported on this device")
            return view
        }
        config.planeDetection = [.horizontal]
        view.session.delegate = context.coordinator
        context.coordinator.arView = view
        view.session.run(config)

        let coaching = ARCoachingOverlayView()
        coaching.session = view.session
        coaching.goal = .horizontalPlane
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(coaching)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    final class Coordinator: NSObject, ARSessionDelegate {
        let imageName: String
        var placed: Binding<Bool>
        weak var arView: ARView?
        private var didPlace = false

        init(imageName: String, placed: Binding<Bool>) {
            self.imageName = imageName
            self.placed = placed
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard !didPlace,
                  let plane = anchors.compactMap({ $0 as? ARPlaneAnchor }).first(where: { $0.alignment == .horizontal }),
                  let arView
            else { return }
            didPlace = true
            place(on: plane, in: arView)
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            arLogger.error("AR session failed: \(error.localizedDescription, privacy: .public)")
        }

        private func place(on plane: ARPlaneAnchor, in arView: ARView) {
            guard let image = UIImage(named: imageName),
                  let circled = image.croppedToCircle()?.cgImage
            else {
                arLogger.error("Missing food image \(self.imageName, privacy: .public)")
                return
            }
            do {
                let texture = try TextureResource.generate(
                    from: circled,
                    options: TextureResource.CreateOptions(semantic: .color)
                )
                var material = UnlitMaterial()
                material.color = .init(tint: .white, texture: .init(texture))
                let mesh = MeshResource.generatePlane(width: 0.18, depth: 0.18)
                let entity = ModelEntity(mesh: mesh, materials: [material])
                entity.scale = SIMD3(repeating: 0.05)
                let anchor = AnchorEntity(anchor: plane)
                anchor.addChild(entity)
                arView.scene.addAnchor(anchor)
                entity.move(
                    to: Transform(scale: .one),
                    relativeTo: anchor,
                    duration: 0.45,
                    timingFunction: .easeOut
                )
                DispatchQueue.main.async {
                    self.placed.wrappedValue = true
                }
            } catch {
                arLogger.error("Could not place dessert: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

private extension UIImage {
    func croppedToCircle() -> UIImage? {
        let side = min(size.width, size.height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: CGSize(width: side, height: side))).addClip()
            draw(in: CGRect(
                x: (side - size.width) / 2,
                y: (side - size.height) / 2,
                width: size.width,
                height: size.height
            ))
        }
    }
}
