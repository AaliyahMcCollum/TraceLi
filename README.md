# TraceLi
Absolutely — here’s a starter README for your repo based on what we’ve built so far.
You can copy-paste this into README.md and modify anything you like.

⸻

📸 AR Photo Placement App

An iOS app built with SwiftUI + RealityKit that lets users place a photo in Augmented Reality, move/rotate/scale it, tilt it to lay flat like it’s on a piece of paper, and adjust transparency for reference or tracing. Includes the ability to lock the image in place while still modifying opacity.

⸻

🚀 Features

Feature	Description
📤 Import Image	Select any photo from your device to place in AR
↔️ Move & Resize	Drag to move, pinch to scale, rotate with two fingers
🎚️ Tilt Control	Slider to tilt the photo away from the user (X-axis) for desk/paper placement
🔒 Lock Position	Freeze placement so gestures are disabled; opacity still editable
🌫 Opacity Slider	Adjust transparency for tracing/drawing references
🎛 Clean UI	Controls appear only after image is selected; tool panel on bottom


⸻

🧰 Technologies Used
	•	SwiftUI
	•	RealityKit (ARView)
	•	ARKit
	•	PhotosPicker (Transferable API)
	•	MVVM-ish state separation using SwiftUI bindings

⸻

🖼 How It Works
	1.	Tap 📸 Select Photo
	2.	Choose an image from your library
	3.	Use gestures to position:
	•	One finger drag: Move
	•	Two finger rotate: Rotate
	•	Pinch: Scale
	4.	Adjust sliders:
	•	Opacity: Fade the image
	•	Tilt: Lean the image away from the camera (onto a “paper” plane)
	5.	Tap 🔒 Lock to freeze transform, but opacity remains adjustable

⸻

🧱 Project Structure

ARPhotoApp/
│
├── ContentView.swift          // Main UI + Sliders + Buttons
├── ARViewContainer.swift      // RealityKit bridge via UIViewRepresentable
├── Coordinator                // Manages AR entities & gesture state
├── Assets/                    // App icons & assets
└── Info.plist                 // Camera & photo picker permissions

Key Entities (AR Structure)

AnchorEntity (floor/plane)
└── TiltEntity (parent)   ← slider modifies rotation here
    └── PhotoEntity       ← gestures apply to this child

This separation prevents the tilt slider from resetting user placement ✔️

⸻

🔐 Permissions

This app requires access to:
NSCameraUsageDescription
NSPhotoLibraryAddUsageDescription
NSPhotoLibraryUsageDescription

Add to Info.plist if missing.

⸻

🛠 Future Improvements (Ideas)
	•	Save/load photo positions in a session
	•	Multi-photo support
	•	Line-art detection for tracing mode

⸻

📦 Installation
	1.	Clone this repository
  2. Open in XCode
  3. Run on real iPhone (ARKit does not run in the simulator)

⸻

📌 Requirements

Requirement	Version
Xcode	15+
iOS	17+
Devices	A12 chip or newer (ARKit compatible)


⸻

🎥 Demo

WIP

⸻

❤️ About

This project is being developed to help artists, students, and creators use AR as a tool for photo tracing, reference matching, and spatial alignment.

If you found this helpful or want to contribute, feel free to open an issue or PR!

