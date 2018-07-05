//
//  ViewController.swift
//  AR Beauty
//
//  Created by Madeline Eckhart on 7/2/18.
//  Copyright © 2018 MaddGaming. All rights reserved
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var searchingLabel: UILabel!
    
    private var nodeModel:SCNNode!
    var planeNode: PlaneDetectionNode?
    private var screenCenter: CGPoint!
    private var selectedNode: SCNNode?
    private var originalRotation: SCNVector3?
    let nodeName = "makeupScene"
    let session = ARSession()
    let sessionConfiguration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        return config
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session = session
        
        // Lighting
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        
        // Update at 60 frames per second (recommended by Apple)
        sceneView.preferredFramesPerSecond = 60
        
        screenCenter = view.center
        
        // Get the scene the model is stored in
        //let modelScene = SCNScene(named: "mac_fix.scn")!
        
        if let modelScene = SCNScene(named:"mac_palette.scn") {
            //nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
            nodeModel = modelScene.rootNode
        }else{
            print("can't load model")
        }
        // Get the model from the root node of the scene
        //nodeModel = modelScene.rootNode
        
        // Scale down the model to fit the real world better
        //nodeModel.scale = SCNVector3(0.001, 0.001, 0.001)
        
        // Rotate the model 90 degrees so it sits even to the floor
        //nodeModel.transform = SCNMatrix4Rotate(nodeModel.transform, Float.pi / 2.0, 1.0, 0.0, 0.0)
        
        // Track taps on screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Tracks pans on the screen
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        
        // Tracks rotation gestures on the screen
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewRotated))
        sceneView.addGestureRecognizer(rotationGesture)
        
        
        
        
        
        /* ORIGINAL PLANE DETECTION
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        //sceneView.antialiasingMode = .multisampling4X
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
       
        if let modelScene = SCNScene(named:"mac_palette.scn") {
            nodeModel =  modelScene.rootNode.childNode(withName: nodeName, recursively: true)
        }else{
            print("can't load model")
        }
 */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            session.run(sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        } else {
            print("Sorry, your device doesn't support ARKit")
        }
    }
    
    //////////////////////////////// Product Collection View
    var products: [ProductList] = []
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // list of products
        let mac: ProductList = ProductList(newName: "mac", newImage: UIImage(named: "mac_palette_material")!)
        let foundation: ProductList = ProductList(newName: "foundation", newImage: UIImage(named: "mac_fix_material")!)
        let perfume: ProductList = ProductList(newName: "perfume", newImage: UIImage(named: "front")!)
        products.append(mac)
        products.append(foundation)
        products.append(perfume)
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ProductCollectionViewCell
        let image = products[indexPath.row].image
        cell.imageView.image = image
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // cell highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 2.0
        cell?.layer.borderColor = UIColor.red.cgColor
        
        // choose product
        if products[indexPath.row].name == "mac" {
            if let modelScene = SCNScene(named:"mac_palette.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                print("got product")
            }
            else {
                print("can't load model")
            }
        }
        if products[indexPath.row].name == "foundation" {
            if let modelScene = SCNScene(named:"mac_fix.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                print("got product")
            }
            else {
                print("can't load model")
            }
        }
        if products[indexPath.row].name == "perfume" {
            if let modelScene = SCNScene(named:"perfume.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
                print("got product")
            }
            else {
                print("can't load model")
            }
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // cell un-highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 0.0
    }

    // Recognizing Gestures
    private func node(at position: CGPoint) -> SCNNode? {
        return sceneView.hitTest(position, options: nil)
            .first(where: { $0.node !== planeNode && $0.node !== nodeModel })?
            .node
    }
    
    @objc private func viewTapped(_ gesture: UITapGestureRecognizer) {
        // Make sure we've found the floor
        guard planeNode != nil else { return }
        
        // See if we tapped on a plane where a model can be placed
        let results = sceneView.hitTest(screenCenter, types: .existingPlane)
        guard let transform = results.first?.worldTransform else { return }
        
        // Find the position to place the model
        let position = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        // Create a copy of the model set its position/rotation
        let newNode = nodeModel.flattenedClone()
        newNode.simdPosition = position
        
        // Add the model to the scene
        sceneView.scene.rootNode.addChildNode(newNode)
        
        //nodes.append(newNode)
    }
    
    @objc private func viewPanned(_ gesture: UIPanGestureRecognizer) {
        // Find the location in the view
        let location = gesture.location(in: sceneView)
        
        switch gesture.state {
        case .began:
            // Choose the node to move
            selectedNode = node(at: location)
        case .changed:
            // Move the node based on the real world translation
            guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
            
            let transform = result.worldTransform
            let newPosition = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
        default:
            // Remove the reference to the node
            selectedNode = nil
        }
    }
    
    @objc private func viewRotated(_ gesture: UIRotationGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        
        guard let node = node(at: location) else { return }
        
        switch gesture.state {
        case .began:
            originalRotation = node.eulerAngles
        case .changed:
            guard var originalRotation = originalRotation else { return }
            originalRotation.y -= Float(gesture.rotation)
            node.eulerAngles = originalRotation
        default:
            originalRotation = nil
        }
    }
    
    // Plane Detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard planeNode == nil else { return }
        
        // Create a new focal node
        let node = PlaneDetectionNode()
        node.addChildNode(nodeModel)
        
        sceneView.scene.rootNode.addChildNode(node)
        self.planeNode = node
        
        
        // Hide searching label
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.searchingLabel.alpha = 0.0
            }, completion: { _ in
                self.searchingLabel.isHidden = true
            })
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // If we haven't established a focal node yet do not update
        guard let planeNode = planeNode else { return }
        
        // Determine if we hit a plane in the scene
        let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
        
        // Find the position of the first plane we hit
        guard let positionColumn = hit.first?.worldTransform.columns.3 else { return }
        
        // Update the position of the node
        planeNode.position = SCNVector3(x: positionColumn.x, y: positionColumn.y, z: positionColumn.z)
    }
    
   
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
        override func viewWillDisappear(_ animated: Bool) {
            // Pause ARKit while the view is gone
            session.pause()
            
            super.viewWillDisappear(animated)
            
            /* ORIGINAL PLANE DETECTION
            super.viewWillDisappear(animated)
    
            // Pause the view's session
            sceneView.session.pause()
            */
        }

        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Release any cached data, images, etc that aren't in use.
        }

}

