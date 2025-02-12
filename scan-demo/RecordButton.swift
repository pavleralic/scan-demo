//
//  RecordButton.swift
//  scan-demo
//
//  Created by Pavle Ralic on 12.2.25..
//

import UIKit

class RecordButton: UIButton {
    
    enum MediaType {
        case image, video
    }
    
    // States for the button
    private let viewSize: CGFloat = 68.0
    private let redCircleDiameter: CGFloat = 57.0
    private let redRectangleSize: CGSize = CGSize(width: 25, height: 25)
    private let borderWidth: CGFloat = 3.0
    
    var isRecording = false
    
    private var shrinkTimer: Timer?
    
    var mediaType: MediaType = .image {
        didSet {
            guard let redCircle = viewWithTag(100) else { return }
            
            switch mediaType {
            case .image:
                redCircle.backgroundColor = .white
            case .video:
                redCircle.backgroundColor = UIColor(hex: "EB4E3D")
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Set up the white outer circle
        self.layer.cornerRadius = viewSize / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = borderWidth
        self.backgroundColor = .clear
        
        // Set up the inner red circle
        let redCircle = UIView()
        redCircle.backgroundColor = UIColor(hex: "EB4E3D")
        redCircle.frame = CGRect(
            x: (viewSize - redCircleDiameter) / 2,
            y: (viewSize - redCircleDiameter) / 2,
            width: redCircleDiameter,
            height: redCircleDiameter
        )
        redCircle.layer.cornerRadius = redCircleDiameter / 2
        redCircle.isUserInteractionEnabled = false
        redCircle.tag = 100 // Identifier for the red circle
        self.addSubview(redCircle)
        
        // Add touch events
        addTarget(self, action: #selector(startShrinking), for: [
            .touchDown, .touchDragInside, .touchDragEnter])
        addTarget(self, action: #selector(stopShrinking), for: [
            .touchUpInside, .touchCancel, .touchDragExit, .touchDragOutside])
    }
    
    @objc private func startShrinking() {
        updateCircleSize(diameter: redCircleDiameter * 0.9, addOverlay: true)
    }
    
    @objc private func stopShrinking() {
        updateCircleSize(diameter: redCircleDiameter)
    }
    
    private func updateCircleSize(diameter: CGFloat, addOverlay: Bool = false) {
        guard !isRecording else { return }
        
        shrinkTimer?.invalidate()
        shrinkTimer = nil
        
        guard let redCircle = self.viewWithTag(100) else { return }
        shrinkTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            guard let self = self else { return }
                        
            // Apply the new size
            UIView.animate(withDuration: 0.1) {
                redCircle.frame = CGRect(
                    x: (self.viewSize - diameter) / 2,
                    y: (self.viewSize - diameter) / 2,
                    width: diameter,
                    height: diameter
                )
                redCircle.alpha = addOverlay ? 0.8 : 1.0
                redCircle.layer.cornerRadius = diameter / 2
            }
        }
    }
    
    func toggleRecording() {
        shrinkTimer?.invalidate()
        shrinkTimer = nil
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        switch mediaType {
        case .image:
            stopShrinking()
        case .video:
            isRecording.toggle()
            guard let redCircle = self.viewWithTag(100) else { return }
            
            UIView.animate(withDuration: 0.2, animations: {
                redCircle.alpha = 1.0
                if self.isRecording {
                    // Transform to rounded rectangle
                    redCircle.frame = CGRect(
                        x: (self.viewSize - self.redRectangleSize.width) / 2,
                        y: (self.viewSize - self.redRectangleSize.height) / 2,
                        width: self.redRectangleSize.width,
                        height: self.redRectangleSize.height
                    )
                    redCircle.layer.cornerRadius = 6 // Rounded rectangle edges
                } else {
                    // Transform back to circle
                    redCircle.frame = CGRect(
                        x: (self.viewSize - self.redCircleDiameter) / 2,
                        y: (self.viewSize - self.redCircleDiameter) / 2,
                        width: self.redCircleDiameter,
                        height: self.redCircleDiameter
                    )
                    redCircle.layer.cornerRadius = self.redCircleDiameter / 2
                }
            })
        }
    }
}
