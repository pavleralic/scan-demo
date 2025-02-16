//
//  TakenScanPreviewViewController.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import Foundation
import UIKit
import SceneKit

/// Handles the preview of a scanned 3D object by loading and displaying it in a SceneKit view.
/// Allows users to view, rotate, and share the 3D model.
class TakenScanPreviewViewController: UIViewController {
    
    /// SceneKit view to display the 3D model.
    @IBOutlet weak var sceneView: SCNView!
    
    /// Container view for the scene, with rounded corners for better UI presentation.
    @IBOutlet weak var sceneContainerView: UIView! {
        didSet {
            sceneContainerView.layer.cornerRadius = 12.0
            sceneContainerView.clipsToBounds = true
            sceneContainerView.layer.masksToBounds = true
        }
    }
    
    /// URL of the 3D model file to be displayed.
    var sceneURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSceneView()
    }
    
    /// Sets up the SceneKit view, loads the 3D model, and applies lighting and camera configurations.
    private func setupSceneView() {
        guard let sceneURL else {
            print("Failed to find the 3D model")
            return
        }
        
        // Load the 3D scene from the provided URL.
        let sceneSource = SCNSceneSource(url: sceneURL, options: nil)
        let scene = sceneSource?.scene(options: nil)
        sceneView.scene = scene
        
        // Configure SceneKit view settings.
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .gray.withAlphaComponent(0.2)
        
        // Add a camera to provide a user-friendly viewing experience.
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.exposureOffset = -0.8 // Adjusts brightness slightly
        cameraNode.camera?.maximumExposure = 1.2 // Allows a bit more light
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene?.rootNode.addChildNode(cameraNode)
        
        // Add a primary light source to enhance visibility.
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1200 // Slightly increased brightness
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene?.rootNode.addChildNode(lightNode)
        
        // Add ambient lighting for overall scene brightness.
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.7, alpha: 1.0) // Lighter ambient color
        ambientLightNode.light?.intensity = 500 // Increased ambient intensity
        scene?.rootNode.addChildNode(ambientLightNode)
        
        // Adjust material properties for better visual appearance.
        scene?.rootNode.enumerateChildNodes { (node, _) in
            node.geometry?.materials.forEach { material in
                material.diffuse.contents = UIColor.lightGray // Lighter base color
                material.emission.contents = UIColor(white: 0.1, alpha: 1.0) // Subtle emission effect
                material.specular.contents = UIColor(white: 0.9, alpha: 1.0) // Adds a slight shine
            }
        }
    }
    
    /// Presents a share sheet to allow users to share the scanned object.
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let url = sceneURL else { return }
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = sender
        self.present(vc, animated: true, completion: nil)
    }
}
