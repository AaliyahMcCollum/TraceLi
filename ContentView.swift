import SwiftUI
import RealityKit
import ARKit
import PhotosUI

struct ContentView : View {
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var imageOpacity: Float = 1.0
    @State private var rotationAngle: Float = 0.0
    @State private var isLocked: Bool = false
    var body : some View {
        ZStack {
            ARViewContainer(selectedImage: $selectedImage,
                            imageOpacity: $imageOpacity,
                            rotationAngle: $rotationAngle,
                            isLocked: $isLocked)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Top bar with photo picker button
                HStack {
                    Button(action: {
                        showPhotoPicker.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Select Photo")
                        }
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)

                    Spacer()
                }
                .padding([.top, .horizontal])

                Spacer()

                // Bottom control panel: only show once a photo has been picked
                if selectedImage != nil {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Opacity")
                            Slider(
                                value: Binding(
                                    get: { Double(imageOpacity) },
                                    set: { imageOpacity = Float($0) }
                                ),
                                in: 0...1
                            )
                        }

                        HStack {
                            Text("Tilt")
                            Slider(
                                value: Binding(
                                    get: { Double(rotationAngle) },
                                    set: { rotationAngle = Float($0) }
                                ),
                                in: 0...(Double.pi / 2)
                            )
                        }
                        .disabled(isLocked)

                        Button(action: {
                            isLocked.toggle()
                        }) {
                            HStack {
                                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                Text(isLocked ? "Locked" : "Lock")
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: Binding(
            get: { nil },
            set: { newValue in
                if let newValue = newValue {
                    Task {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
            }
        ))
    }
}

//Bridge bewtween SwiftUI framework and RealityKit framework
struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var imageOpacity: Float
    @Binding var rotationAngle: Float
    @Binding var isLocked: Bool

    class Coordinator {
        weak var arView: ARView?
        var photoAnchor: AnchorEntity?
        var photoEntity: ModelEntity?
        var tiltEntity: Entity?
        var lastImageID: ObjectIdentifier?
        var lockedTransform: Transform?
        var gestureRecognizers: [EntityGestureRecognizer] = []
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = true
        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // If there's no selected image, clear the scene and reset coordinator state.
        guard let image = selectedImage else {
            uiView.scene.anchors.removeAll()
            context.coordinator.photoAnchor = nil
            context.coordinator.photoEntity = nil
            context.coordinator.tiltEntity = nil
            context.coordinator.lastImageID = nil
            context.coordinator.lockedTransform = nil
            context.coordinator.gestureRecognizers = []
            return
        }

        let currentID = ObjectIdentifier(image)

        // If we don't have an entity yet, or the image changed, rebuild the plane.
        if context.coordinator.photoEntity == nil || context.coordinator.lastImageID != currentID {
            uiView.scene.anchors.removeAll()
            context.coordinator.lockedTransform = nil

            guard let cgImage = image.cgImage,
                  let texture = try? TextureResource(image: cgImage, options: .init(semantic: .color)) else {
                return
            }

            var material = UnlitMaterial()
            // Use tint alpha + transparent blending to control opacity.
            material.color = .init(
                tint: .white.withAlphaComponent(CGFloat(imageOpacity)),
                texture: .init(texture)
            )
            material.blending = .transparent(opacity: .init(scale: Float(Double(imageOpacity))))

            let mesh = MeshResource.generatePlane(width: 0.3, height: 0.3)
            let planeEntity = ModelEntity(mesh: mesh, materials: [material])

            // Parent entity used for tilt; child for gestures (move/rotate/scale)
            let tiltEntity = Entity()

            // Apply initial tilt based on slider (around X axis) on the parent
            var tiltTransform = tiltEntity.transform
            let tiltQuat = simd_quatf(angle: -rotationAngle, axis: SIMD3<Float>(1, 0, 0))
            tiltTransform.rotation = tiltQuat
            tiltEntity.transform = tiltTransform

            // Attach the plane to the tilt entity
            tiltEntity.addChild(planeEntity)

            if isLocked {
                context.coordinator.lockedTransform = tiltEntity.transform
            }

            // Enable gestures (move, rotate, scale) on the plane itself
            planeEntity.generateCollisionShapes(recursive: true)

            let anchor = AnchorEntity(plane: .horizontal)
            anchor.addChild(tiltEntity)

            uiView.scene.anchors.append(anchor)
            context.coordinator.gestureRecognizers = uiView.installGestures([.translation, .rotation, .scale], for: planeEntity)

            context.coordinator.photoAnchor = anchor
            context.coordinator.photoEntity = planeEntity
            context.coordinator.tiltEntity = tiltEntity
            context.coordinator.lastImageID = currentID
        } else {
            // Same image: just update opacity on the existing material.
            guard let entity = context.coordinator.photoEntity,
                  var material = entity.model?.materials.first as? UnlitMaterial else {
                return
            }

            material.color = .init(
                tint: .white.withAlphaComponent(CGFloat(imageOpacity)),
                texture: material.color.texture
            )
            material.blending = .transparent(opacity: .init(scale: Float(Double(imageOpacity))))

            // Update transform based on lock state and sliders, using the tilt parent
            if let tiltEntity = context.coordinator.tiltEntity {
                if isLocked {
                    // Disable gestures while locked
                    for recognizer in context.coordinator.gestureRecognizers {
                        recognizer.isEnabled = false
                    }

                    // Freeze transform at the locked one, if available
                    if let locked = context.coordinator.lockedTransform {
                        tiltEntity.transform = locked
                    } else {
                        // If we just locked, capture the current transform of the tilt parent
                        context.coordinator.lockedTransform = tiltEntity.transform
                    }
                } else {
                    // Re-enable gestures when unlocked
                    for recognizer in context.coordinator.gestureRecognizers {
                        recognizer.isEnabled = true
                    }

                    // Unlocked: clear any stored locked transform and apply tilt,
                    // without disturbing the child plane's local transform (gestures)
                    context.coordinator.lockedTransform = nil

                    var updatedTransform = tiltEntity.transform
                    let translation = updatedTransform.translation
                    let scale = updatedTransform.scale

                    let tiltQuat = simd_quatf(angle: -rotationAngle, axis: SIMD3<Float>(1, 0, 0))

                    updatedTransform.rotation = tiltQuat
                    updatedTransform.translation = translation
                    updatedTransform.scale = scale

                    tiltEntity.transform = updatedTransform
                }
            }

            entity.model?.materials = [material]
        }
    }
}

#Preview {
    ContentView()
}
