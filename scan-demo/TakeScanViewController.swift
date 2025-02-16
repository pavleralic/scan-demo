//
//  ViewController.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import RealityKit
import ARKit
import MetalKit

/// A view controller responsible for managing an AR scanning session.
/// This class handles starting/stopping recording, exporting scanned objects,
/// and displaying a preview of the scanned object.
class TakeScanViewController: UIViewController, ARSessionDelegate {
    
    /// The AR view responsible for rendering the AR session.
    @IBOutlet weak var arView: ARView!
    
    /// The record button used to start and stop the scanning process.
    @IBOutlet weak var recordButton: RecordButton! {
        didSet {
            recordButton.mediaType = .video
        }
    }
    
    /// Called after the view has been loaded into memory.
    /// Initializes the AR session and disables the idle timer.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Configures debugging options for the ARView.
        func setARViewOptions() {
            /// Display the depth-colored wireframe for scene understanding meshes.
            arView.debugOptions.insert(.showSceneUnderstanding)
        }
        
        // Set AR session delegate
        arView.session.delegate = self
        
        // Initializes the AR view with necessary configurations.
        setARViewOptions()
        
        // Prevent the screen from dimming while scanning
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    /// Exports the scanned object as an OBJ file and presents a preview.
    ///
    /// This function retrieves the 3D mesh data from the AR session, converts it into a
    /// Model I/O (MDLAsset) representation, applies a material, and exports it as an OBJ file.
    /// Once exported, it presents a preview of the scanned object.
    ///
    /// - Important:
    ///   - This function relies on ARKit’s `ARMeshAnchor` data, which is collected during
    ///     an AR session with scene reconstruction enabled.
    ///   - The exported file is stored in the app’s documents directory as `scanned.obj`.
    ///   - If the device does not support Metal (required for `MDLMesh` conversion),
    ///     the export process will fail.
    ///
    /// - Dependencies:
    ///   - `ARKit` for capturing mesh data.
    ///   - `ModelIO` for converting mesh data into a 3D model.
    ///   - `MetalKit` for rendering support.
    ///
    /// - Note: The function assumes that `arView` is an active `ARView` instance configured
    ///   for scene reconstruction.
    private func exportScannedObject() {
        /// Attempts to retrieve the current camera frame from the AR session.
        /// This is necessary for applying the correct model transformations during export.
        guard let camera = arView.session.currentFrame?.camera else { return }
        
        /// Converts an array of `ARMeshAnchor` objects into a `MDLAsset`.
        ///
        /// - Parameters:
        ///   - meshAnchors: An array of `ARMeshAnchor` objects captured during the AR session.
        /// - Returns: A `MDLAsset` containing the converted 3D model, or `nil` if conversion fails.
        ///
        /// - How it works:
        ///   1. Retrieves the default Metal device.
        ///   2. Iterates through each `ARMeshAnchor`, converting its geometry into an `MDLMesh`.
        ///   3. Applies a gray material to each submesh for basic visualization.
        ///   4. Adds the converted `MDLMesh` to a `MDLAsset` for export.
        ///   5. Returns the `MDLAsset` containing all processed meshes.
        func convertToAsset(meshAnchors: [ARMeshAnchor]) -> MDLAsset? {
            // Ensure that the device supports Metal, required for mesh processing
            guard let device = MTLCreateSystemDefaultDevice() else { return nil }
            
            // Initialize an empty Model I/O asset container
            let asset = MDLAsset()
            
            for anchor in meshAnchors {
                // Convert the ARMeshAnchor geometry into an MDLMesh representation
                let mdlMesh = anchor.geometry.toMDLMesh(device: device, camera: camera, modelMatrix: anchor.transform)
                
                // Define a basic gray material for visualization
                let material = MDLMaterial(name: "GrayMaterial", scatteringFunction: MDLScatteringFunction())
                material.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, float3: SIMD3(0.5, 0.5, 0.5)))
                
                // Apply the material to all submeshes
                if let submeshes = mdlMesh.submeshes as? [MDLSubmesh] {
                    for submesh in submeshes {
                        submesh.material = material
                    }
                }
                
                // Add the processed mesh to the asset
                asset.add(mdlMesh)
            }
            
            return asset
        }
        
        /// Exports the given `MDLAsset` to an OBJ file and returns its URL.
        ///
        /// - Parameter asset: The `MDLAsset` containing the 3D model.
        /// - Throws: An error if the export operation fails.
        /// - Returns: A file URL pointing to the exported `.obj` file.
        ///
        /// - How it works:
        ///   1. Retrieves the app’s documents directory.
        ///   2. Defines a file path (`scanned.obj`) for storing the exported model.
        ///   3. Checks if Model I/O supports exporting to OBJ format.
        ///   4. Attempts to export the asset to the defined path.
        ///   5. Returns the URL of the exported file.
        ///
        /// - Warning: If the export fails, the function will terminate execution using `fatalError()`.
        func export(asset: MDLAsset) throws -> URL {
            // Get the user's documents directory for file storage
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = directory.appendingPathComponent("scanned.obj")
            
            // Ensure that the OBJ format is supported before exporting
            if MDLAsset.canExportFileExtension("obj") {
                do {
                    try asset.export(to: url)
                    return url
                } catch let error {
                    // Fatal error terminates execution if export fails
                    fatalError(error.localizedDescription)
                }
            } else {
                fatalError("Can't export OBJ format")
            }
        }
        
        /// Retrieves the ARMeshAnchors from the current AR session, converts them into a 3D model,
        /// exports it as an OBJ file, and then presents a preview.
        if let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }),
           let asset = convertToAsset(meshAnchors: meshAnchors) {
            do {
                // Attempt to export the asset and obtain the file URL
                let url = try export(asset: asset)
                
                // Present a preview of the exported model
                showScanPreview(url)
            } catch {
                print("Export error")
            }
        }
    }
    
    /// Starts AR scanning by configuring and running the AR session.
    ///
    /// - Purpose:
    ///   This function initializes the AR session for scanning objects or environments.
    ///   It ensures that the AR system is set up correctly before any 3D mesh data is captured.
    ///
    /// - How it works:
    ///   1. Calls `buildConfigure()` to create an AR session configuration optimized for scanning.
    ///   2. Runs the AR session with the generated configuration.
    ///   3. Enables real-time scene reconstruction and depth capture (if supported by the device).
    private func startRecording() {
        /// Builds and returns an AR session configuration optimized for scanning.
        ///
        /// - Returns: A configured `ARWorldTrackingConfiguration` instance ready for scanning.
        ///
        /// - How it works:
        ///   1. Enables **world tracking**, allowing the device to track its position and movement in 3D space.
        ///   2. Enables **automatic environment texturing**, which enhances scene realism by generating realistic surface textures.
        ///   3. Enables **scene reconstruction with mesh processing**, allowing the device to generate a structured 3D model of the environment.
        ///   4. Checks if the device supports **scene depth** (LiDAR-based depth sensing) and enables it if available.
        ///
        /// - Why it’s needed:
        ///   - Without this configuration, the AR session would not be able to track the environment and reconstruct 3D objects.
        ///   - The depth feature improves accuracy, making object meshes more detailed.
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            
            /**
             `ARWorldTrackingConfiguration.EnvironmentTexturing`
             The mode of environment texturing to run.
             @discussion If set, texture information will be accumulated and updated. Adding an AREnvironmentProbeAnchor to the session
             will get the current environment texture available from that probe's perspective which can be used for lighting
             virtual objects in the scene. Defaults to AREnvironmentTexturingNone.
             */
            // Enable automatic texturing for scanned surfaces
            configuration.environmentTexturing = .automatic
            
            // Enable scene reconstruction to generate 3D meshes
            configuration.sceneReconstruction = .mesh
            
            // If the device supports depth sensing, enable it
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
                configuration.frameSemantics = .sceneDepth
            }
            
            return configuration
        }
        
        // Generate the configuration and start the AR session
        let configuration = buildConfigure()
        arView.session.run(configuration)
    }
    
    /// Stops the AR session, pausing tracking and scene updates.
    private func stopRecording() {
        arView.session.pause()
    }
    
    /// Presents a preview of the scanned object.
    private func showScanPreview(_ url: URL) {
        // Attempt to load the view controller from the storyboard
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TakenScanPreviewViewController") as? TakenScanPreviewViewController else {
            fatalError("Could not instantiate TakenScanPreviewViewController")
        }
        
        // Pass the exported model’s file URL to the preview controller
        vc.sceneURL = url
        
        // Navigate to the preview screen
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Handles the record button tap event.
    @IBAction func recordButtonTapped(_ sender: RecordButton) {
        if sender.isRecording {
            // Stop the recording session and export the scanned object
            stopRecording()
            exportScannedObject()
        } else {
            // Start a new recording session
            startRecording()
        }
        
        // Toggle the recording button state
        sender.toggleRecording()
    }
}
