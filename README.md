## Scan Demo App

### Overview
Scan Demo is an AR-based application that allows users to scan objects using ARKit and view them in a 3D preview. The app provides an intuitive workflow where users can start scanning, stop scanning, and preview the captured object. Additionally, users can share the scanned object using the built-in share functionality.

### Features
- **Start/Stop Scanning**: Users can start scanning with a single tap and stop with another tap.
- **3D Object Preview**: The scanned object is displayed in an interactive SceneKit view.
- **Sharing**: Users can easily share the scanned object via the system's share sheet.

## Installation

1. Clone this repository:
   ```sh
   git clone https://github.com/pavleralic/scan-demo.git
   ```
2. Open the project in Xcode.
3. Ensure your development device supports ARKit (iOS devices with LiDAR only).
4. Run the project on a real device (ARKit does not work on the simulator).

## How to Use

### 1. Start Scanning
- Tap the **Record** button to start scanning.
- The app will begin tracking the environment and reconstructing a 3D model.

### 2. Stop Scanning
- Tap the **Record** button again to stop scanning.
- The captured object will be saved automatically.

### 3. Preview the Scanned Object
- Once scanning stops, the 3D object will be displayed in the preview screen.
- You can **rotate, zoom, and interact** with the 3D model.

### 4. Share the Scanned Object
- In the preview screen, tap the **Share** button located in the **top-right corner**.
- The system **share sheet** will appear, allowing you to share the model via **AirDrop, Messages, Email, or other apps**.

## Requirements
- **ARKit-compatible device**

## Notes
- Ensure you have **good lighting conditions** for optimal scanning results.
- **Large or highly reflective surfaces** may affect the quality of the scan.
