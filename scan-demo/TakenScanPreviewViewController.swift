//
//  TakenScanPreviewViewController.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import Foundation
import UIKit
import SceneKit

class TakenScanPreviewViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    
    @IBOutlet weak var sceneContainerView: UIView! {
        didSet {
            sceneContainerView.layer.cornerRadius = 12.0
            sceneContainerView.clipsToBounds = true
            sceneContainerView.layer.masksToBounds = true
        }
    }
    
    var sceneURL: URL?
    var thumbnailURL: URL?
    
    deinit {
        print("TakenScanPreviewViewController deinited")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        setupSceneView()
    }
    
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendButtonTapped() {
//        guard
//            let sceneURL,
//            let thumbnailURL,
//            let attributes = geoTraceController?.getLocationMediaUploadRequestData(
//                locationId: locationId, comment: commentTextView.currentText)
//        else { return }
//        showLoadingIndicator()
//        DigitalTweenAPI.shared.createScan(
//            scanUrl: sceneURL,
//            thumbnailUrl: thumbnailURL,
//            attributes: attributes) { [weak self] scan in
//                self?.hideLoadingIndicator()
//                guard
//                    let self,
//                    let scan
//                else {
//                    self?.showSelfDismissingBanner(message: COStrings.generalErrorMessage)
//                    return
//                }
//                
//                self.delegate?.didFinishAddingScan(scan)
//                self.popBack(2)
//            }
    }
    
    private func setupSceneView() {
        guard let sceneURL else {
            print("Failed to find the 3D model")
            return
        }
    
//        func share(url: URL) {
//            let vc = UIActivityViewController(activityItems: [sceneURL], applicationActivities: nil)
//            vc.popoverPresentationController?.sourceView = self.sceneView
//            self.present(vc, animated: true, completion: nil)
//        }
//
//        share(url: sceneURL)
        
        // Load the scene
        let sceneSource = SCNSceneSource(url: sceneURL, options: nil)
        let scene = sceneSource?.scene(options: nil)
        sceneView.scene = scene

        // Configure SCNView
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = .gray.withAlphaComponent(0.2)

        // Add a camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.exposureOffset = -0.8 // Slightly brighter than before
        cameraNode.camera?.maximumExposure = 1.2 // Allow a bit more light
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scene?.rootNode.addChildNode(cameraNode)

        // Add lights
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.light?.intensity = 1200 // Slightly brighter light
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene?.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.7, alpha: 1.0) // Lighter ambient color
        ambientLightNode.light?.intensity = 500 // Increase ambient light intensity
        scene?.rootNode.addChildNode(ambientLightNode)

        // Adjust model materials
        scene?.rootNode.enumerateChildNodes { (node, _) in
            node.geometry?.materials.forEach { material in
                material.diffuse.contents = UIColor.lightGray // Lighter base color
                material.emission.contents = UIColor(white: 0.1, alpha: 1.0) // Subtle light emission
                material.specular.contents = UIColor(white: 0.9, alpha: 1.0) // Slightly shinier effect
            }
        }
                
        // Generate thumbnail after rendering the initial scene
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        let thumbnailImage = sceneView.snapshot()
        
        // Save or use the thumbnail as needed
        saveThumbnailImage(thumbnailImage)
    }
    
    private func saveThumbnailImage(_ image: UIImage) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let thumbnailURL = directory.appendingPathComponent("thumbnail.png")
        
//        func share(url: URL) {
//            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//            vc.popoverPresentationController?.sourceView = self.sceneView
//            self.present(vc, animated: true, completion: nil)
//        }
        
        if let pngData = image.pngData() {
            do {
                try pngData.write(to: thumbnailURL)
                print("Thumbnail saved to: \(thumbnailURL)")
                self.thumbnailURL = thumbnailURL
                //                share(url: thumbnailURL)
            } catch {
                print("Error saving thumbnail: \(error)")
            }
        }
    }
}
