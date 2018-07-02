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
    
    var nodeModel:SCNNode!
    let nodeName = "SketchUp"
    
    override func viewDidLoad() {
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
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        
        
        // Start the view's AR session with a configuration that uses the rear camera,device position and orientation tracking, and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.planeDetection = [.horizontal, .vertical]
        } else {
            // Fallback on earlier versions
        }
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self as ARSessionDelegate
        
        // Prevent the screen from being dimmed after a while
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true

    }
    
    
    
    
    
    // Product Collection View
    var products: [ProductList] = []
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // list of products
        let mac: ProductList = ProductList(newName: "mac", newImage: UIImage(named: "mac_palette_material")!)
        let spray: ProductList = ProductList(newName: "fountation", newImage: UIImage(named: "mac_fix_material")!)
        products.append(mac)
        products.append(spray)

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
        if products[indexPath.row].name == "mac" {
            if let modelScene = SCNScene(named:"mac_palette.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
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
        viewDidLoad()
    }
    
    
    
    
    
    // Plane Detection
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
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
        
    }
    
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
 
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
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
    
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    
    @IBAction func chooseModel(sender: AnyObject) {
        
        /*
         
         If models ever crash or don't load check
            - is the target membersship button checked?
            - is the folder blue or yellow? if yellow you can use model name only, if blue use absolute path
        
        */ 
        
        let alert = UIAlertController(title: "Choose Model", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "MAC Palette", style: .default , handler:{ (UIAlertAction)in
            if let modelScene = SCNScene(named:"mac_palette.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
            }
            else {
                print("can't load model")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "MAC Fix Spray", style: .default , handler:{ (UIAlertAction)in
            if let modelScene = SCNScene(named:"mac_fix.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
            }
            else {
                print("can't load model")
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Urban Palette", style: .default , handler:{ (UIAlertAction)in
            if let modelScene = SCNScene(named:"urban.scn") {
                self.nodeModel =  modelScene.rootNode.childNode(withName: self.nodeName, recursively: true)
            }
            else {
                print("can't load model")
            }
        }))

        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }


}




