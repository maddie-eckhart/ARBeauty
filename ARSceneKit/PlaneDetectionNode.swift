//
//  PlaneDetectionNode.swift
//  ARSceneKit
//
//  Created by Madeline Eckhart on 7/3/18.
//  Copyright © 2018 MaddGaming. All rights reserved.
//

import Foundation
import SceneKit

class PlaneDetectionNode: SCNNode {
    
    let size: CGFloat = 0.1
    let segmentWidth: CGFloat = 0.004
    
    private let colorMaterial: SCNMaterial = {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        return material
    }()
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func createSegment(width: CGFloat, height: CGFloat) -> SCNNode {
        let segment = SCNPlane(width: width, height: height)
        segment.materials = [colorMaterial]
        
        return SCNNode(geometry: segment)
    }
    
    private func addHorizontalSegment(dx: Float) {
        let segmentNode = createSegment(width: segmentWidth, height: size)
        segmentNode.position.x += dx
        
        addChildNode(segmentNode)
    }
    
    private func addVerticalSegment(dy: Float) {
        let segmentNode = createSegment(width: size, height: segmentWidth)
        segmentNode.position.y += dy
        
        addChildNode(segmentNode)
    }
    
    private func setup() {
        let dist = Float(size) / 2.0
        addHorizontalSegment(dx: dist)
        addHorizontalSegment(dx: -dist)
        addVerticalSegment(dy: dist)
        addVerticalSegment(dy: -dist)
        
        // Rotate the node so the square is flat against the floor
        transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
    }
    
}
