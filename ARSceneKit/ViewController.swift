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
    
    var nodeModel:SCNNode!
    var planeNode: PlaneDetectionNode?
    private var screenCenter: CGPoint!
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
        let modelScene = SCNScene(named: "perfume")!
        
        // Get the model from the root node of the scene
        nodeModel = modelScene.rootNode
        
        // Scale down the model to fit the real world better
        nodeModel.scale = SCNVector3(0.001, 0.001, 0.001)
        
        // Rotate the model 90 degrees so it sits even to the floor
        nodeModel.transform = SCNMatrix4Rotate(nodeModel.transform, Float.pi / 2.0, 1.0, 0.0, 0.0)
        
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
        
        /* ORIGINAL PLANE DETECTION
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
 */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /* ORIGINAL PLANE DETECTION
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            //configuration.planeDetection = [.horizontal, .vertical]
            configuration.planeDetection = [.horizontal]
        } else {
            configuration.planeDetection = [.horizontal]
        }
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self as ARSessionDelegate
        
        // Prevent the screen from being dimmed after a while
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.showsStatistics = true
        */
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
        
        // drop product
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
            }
            else {
                print("can't load model")
            }
        }
        if products[indexPath.row].name == "perfume" {
            if let modelScene = SCNScene(named:"perfume.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
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

    // Plane Detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard planeNode == nil else { return }
        
        // Create a new focal node
        let node = PlaneDetectionNode()
        
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
        
        /* ORIGINAL PLANE DETECTION
        // Place content only for anchors found by plane detection.
        
        if !anchor.isKind(of: ARPlaneAnchor.self) {
            DispatchQueue.main.async {
                let modelClone = self.nodeModel.clone()
                modelClone.position = SCNVector3Zero
                
                // Add model as a child of the node
                node.addChildNode(modelClone)
            }
        }
       
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        let planeNode = SCNNode(geometry: plane)
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        
        // adding color to plane
        plane.materials.first?.diffuse.contents = UIColor.purple
        planeNode.opacity = 0.25
        
        // `SCNPlane` is vertically oriented in its local coordinate space, so
        // rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        
        node.addChildNode(planeNode)
        */
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
    
    /* ORIGINAL PLANE DETECTION
    // UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        planeNode.position = SCNVector3(x, y, z)
        
    }

    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {}
 
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {}
 
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {}
 
    // MARK: - ARSessionObserver
 
    func sessionWasInterrupted(_ session: ARSession) {}
 
    func sessionInterruptionEnded(_ session: ARSession) {
        resetTracking()
    }
 
    func session(_ session: ARSession, didFailWithError error: Error) {
        resetTracking()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: sceneView)
        
        // Let's test if a 3D Object was touch
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = sceneView.hitTest(location, options: hitTestOptions)
        
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                node.removeFromParentNode()
                return
            }
        }
        
        // No object was touch? Try feature points
        let hitResultsFeaturePoints: [ARHitTestResult]  = sceneView.hitTest(location, types: .featurePoint)
        
        if let hit = hitResultsFeaturePoints.first {
            
            // Get the rotation matrix of the camera
            let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
            
            // Combine the matrices
            let finalTransform = simd_mul(hit.worldTransform, rotate)
            sceneView.session.add(anchor: ARAnchor(transform: finalTransform))
            //sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
        }
        
    }

    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }

    // MARK: - ARSCNViewDelegate
    */
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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

