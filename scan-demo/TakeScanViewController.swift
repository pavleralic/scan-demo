//
//  ViewController.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import RealityKit
import ARKit
import MetalKit

class TakeScanViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var arView: ARView!
    
    @IBOutlet weak var recordButton: RecordButton! {
        didSet {
            recordButton.mediaType = .video
        }
    }
    
    deinit {
        print("TakeScanViewController deinited")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        func setARViewOptions() {
            arView.debugOptions.insert(.showSceneUnderstanding)
        }
        
        func initARView() {
            setARViewOptions()
        }
        
        arView.session.delegate = self
        super.viewDidLoad()
        initARView()
        
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    private func exportScannedObject() {
        guard
            let camera = arView.session.currentFrame?.camera
        else { return }
        
        func convertToAsset(meshAnchors: [ARMeshAnchor]) -> MDLAsset? {
            guard let device = MTLCreateSystemDefaultDevice() else {return nil}
            
            let asset = MDLAsset()
            
            for anchor in meshAnchors {
                let mdlMesh = anchor.geometry.toMDLMesh(device: device, camera: camera, modelMatrix: anchor.transform)
                
                // Apply a gray material to the mesh
                let material = MDLMaterial(name: "GrayMaterial", scatteringFunction: MDLScatteringFunction())
                material.setProperty(MDLMaterialProperty(name: "baseColor", semantic: .baseColor, float3: SIMD3(0.5, 0.5, 0.5))) // Gray color
                if let submeshes = mdlMesh.submeshes as? [MDLSubmesh] {
                    for submesh in submeshes {
                        submesh.material = material
                    }
                }
                
                asset.add(mdlMesh)
            }
            
            return asset
        }
        
        func export(asset: MDLAsset) throws -> URL {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = directory.appendingPathComponent("scaned.obj")
            
            if MDLAsset.canExportFileExtension("obj") {
                do {
                    try asset.export(to: url)
                    
                    return url
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            } else {
                fatalError("Can't export USD")
            }
        }
        
        func share(url: URL) {
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = recordButton
            self.present(vc, animated: true, completion: nil)
        }
        
        if let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }),
           let asset = convertToAsset(meshAnchors: meshAnchors) {
            do {
                let url = try export(asset: asset)
                showScanPreview(url)
                //                share(url: url)
            } catch {
                print("export error")
            }
        }
    }
    
    private func showScanPreview(_ url: URL) {
        guard
            let vc = storyboard?.instantiateViewController(withIdentifier: "TakenScanPreviewViewController") as? TakenScanPreviewViewController
        else { fatalError() }
        
        vc.sceneURL = url
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func startRecording() {
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            
            configuration.environmentTexturing = .automatic
            configuration.sceneReconstruction = .mesh
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
                configuration.frameSemantics = .sceneDepth
            }
            
            return configuration
        }
        let configuration = buildConfigure()
        arView.session.run(configuration)
    }
    
    private func stopRecording() {
        arView.session.pause()
    }
    
    @IBAction func recordButtonTapped(_ sender: RecordButton) {
        if sender.isRecording {
            stopRecording()
            exportScannedObject()
        } else {
            startRecording()
        }
        sender.toggleRecording()
    }
}
