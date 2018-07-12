//
//  ViewController.swift
//  AR Beauty
//
//  Created by Madeline Eckhart on 7/2/18.
//  Copyright © 2018 MaddGaming. All rights reserved
//
// https://blog.rocketinsights.com/how-to-arkit/

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var searchingLabel: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    
    //----------------------------------------------- Node and Scene Setup -----------------------------------------------//
    
    private var nodeModel:SCNNode?
    var planeNode: PlaneDetectionNode?
    var nodePlaced: Bool = false
    
    private var screenCenter: CGPoint!
    private var selectedNode: SCNNode?
    private var originalRotation: SCNVector3?
    private var originalSize: SCNVector3?
    let nodeName = "makeupScene"
    
    let session = ARSession()
    let sessionConfiguration: ARWorldTrackingConfiguration = {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        return config
    }()
    
   //----------------------------------------------- View Before Loading -----------------------------------------------//
    
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
        
        if let modelScene = SCNScene(named:"perfume.scn") {
            nodeModel = modelScene.rootNode.childNode(withName: nodeName, recursively: true)
            nodeModel?.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        }else{
            print("can't load model")
        }
        
        // Track taps on screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        sceneView.addGestureRecognizer(tapGesture)
        
        // Track pans on the screen
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        
        // Track rotation gestures on the screen
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewRotated))
        sceneView.addGestureRecognizer(rotationGesture)
        
        // Track pinch gestures on the screen
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(viewPinched(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Make sure that ARKit is supported
        if ARWorldTrackingConfiguration.isSupported {
            session.run(sessionConfiguration, options: [.removeExistingAnchors, .resetTracking])
        } else {
            print("Sorry, your device doesn't support ARKit")
        }
        colorLabel.isHidden = true
    }
    
   //----------------------------------------------- Product Collection View -----------------------------------------------//

    var materials: [MaterialDetails] = []
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {

        // list of materials
        setMaterials()
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return materials.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MaterialCollectionViewCell
        let image:UIImage = materials[indexPath.row].image
        cell.imageView.image = image
        cell.layer.cornerRadius = cell.imageView.frame.size.width / 2
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        
        // cell highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 3.0
        cell?.layer.borderColor = UIColor.white.cgColor
        
        let image = materials[indexPath.row].image
        nodeModel?.geometry?.firstMaterial?.diffuse.contents = image
        
        let label = materials[indexPath.row].desc
        colorLabel.isHidden = false
        colorLabel.layer.cornerRadius = 5
        colorLabel.text = label
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        // cell un-highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 0.0
    }

   //----------------------------------------------- Recognizing Gestures -----------------------------------------------//
    
    private func node(at position: CGPoint) -> SCNNode? {
        
        return sceneView.hitTest(position, options: nil)
            .first(where: { $0.node !== planeNode && $0.node !== nodeModel })?
            .node
    }
    
    @objc private func viewTapped(_ gesture: UITapGestureRecognizer) {
        
        if nodePlaced == false {
            // Make sure we've found the floor
            guard planeNode != nil else { return }
            
            // See if we tapped on a plane where a model can be placed
            let results = sceneView.hitTest(screenCenter, types: .existingPlane)
            guard let transform = results.first?.worldTransform else { return }
            
            // Find the position to place the model
            let position = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create a copy of the model set its position/rotation
            let newNode = nodeModel?.flattenedClone()
            newNode?.simdPosition = position
            
            // Add the model to the scene
            sceneView.scene.rootNode.addChildNode(newNode!)
            nodePlaced = true
        }
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
    
    @objc private func viewPinched(_ gesture: UIPinchGestureRecognizer) {
        
        let location = gesture.location(in: sceneView)
        
        guard let node = node(at: location) else { return }
        switch gesture.state {
        case .began:
            originalSize = node.scale
        case .changed:
            let action = SCNAction.scale(by: gesture.scale, duration: 0.1)
            node.runAction(action)
            gesture.scale = 1
        default:
            originalSize = nil
        }
    }
    
   //----------------------------------------------- Plane Detection -----------------------------------------------//
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard planeNode == nil else { return }
        
        // Create a new focal node
        let node = PlaneDetectionNode()
        node.addChildNode(nodeModel!)
        
        //sceneView.scene.rootNode.addChildNode(node)
        self.planeNode = node
        
        
        // Hide searching label
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5, animations: {
                self.searchingLabel.alpha = 0.0
            }, completion: { _ in
                self.searchingLabel.isHidden = true
                
            })
            self.launchAlert()
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

   //----------------------------------------------- Auxillary Functions -----------------------------------------------//
    
    func launchAlert() {
        
        let alertController = UIAlertController(title: "Floor Detected!", message: "Tap on screen to place product", preferredStyle: .alert)
        let alertText = UIAlertAction(title: "OK", style: .cancel)
        alertController.addAction(alertText)
        present(alertController, animated: true, completion: nil)
    }
    
    func setMaterials() {
        
        // add color images with details
        let color1 = MaterialDetails(newImage: UIImage(named: "Afghan Red")!, description: " Afghan Red (garnet –satin finish) ")
        let color2 = MaterialDetails(newImage: UIImage(named: "Banned Red")!, description: " Banned Red (mulled wine –satin finish) ")
        let color3 = MaterialDetails(newImage: UIImage(named: "Belle Du Jour")!, description: " Belle Du Jour (nude beige –sheer finish) ")
        let color4 = MaterialDetails(newImage: UIImage(named: "Catfight")!, description: " Catfight (nude mauve –semi nude finish) ")
        let color5 = MaterialDetails(newImage: UIImage(named: "Cruising")!, description: " Cruising (nude pink –sheer finish) ")
        let color6 = MaterialDetails(newImage: UIImage(named: "Damage")!, description: " Damage (muted grape –sheer finish) ")
        let color7 = MaterialDetails(newImage: UIImage(named: "Dolce Vita")!, description: " Dolce Vita (dusty rose –sheer finish) ")
        let color8 = MaterialDetails(newImage: UIImage(named: "Falbala")!, description: " Falbala (shimmering rose –sheer finish) ")
        let color9 = MaterialDetails(newImage: UIImage(named: "Fast Ride")!, description: " Fast Ride (mulberry –sheer finish) ")
        let color10 = MaterialDetails(newImage: UIImage(named: "Fire Down Below")!, description: " Fire Down Below (blood red –semi matte finish) ")
        let color11 = MaterialDetails(newImage: UIImage(named: "Funny Face")!, description: " Funny Face (bright fuchsia –semi matte finish) ")
        let color12 = MaterialDetails(newImage: UIImage(named: "Gipsy")!, description: " Gipsy (warm berry –sheer finish) ")
        let color13 = MaterialDetails(newImage: UIImage(named: "Heat Wave")!, description: " Heat Wave (orange red –matte finish) ")
        let color14 = MaterialDetails(newImage: UIImage(named: "Niagara")!, description: " Niagara (pinkish –satin finish) ")
        let color15 = MaterialDetails(newImage: UIImage(named: "Pigalle")!, description: " Pigalle (pink chocolate –semi matte finish) ")
        let color16 = MaterialDetails(newImage: UIImage(named: "Red Lizard")!, description: " Red Lizard (full-powered red –semi matte finish) ")
        let color17 = MaterialDetails(newImage: UIImage(named: "Roman Holiday")!, description: " Roman Holiday (delicate pastel pink –sheer finish) ")
        let color18 = MaterialDetails(newImage: UIImage(named: "Rosecliff")!, description: " Rosecliff (soft rose –satin finish) ")
        let color19 = MaterialDetails(newImage: UIImage(named: "Scarlett Empress")!, description: " Scarlett Empress (rich blue-red –semi matte finish) ")
        let color20 = MaterialDetails(newImage: UIImage(named: "Schiap")!, description: " Schiap (shocking pink –semi matte finish) ")
        let color21 = MaterialDetails(newImage: UIImage(named: "Sexual Healing")!, description: " Sexual Healing (metallic peachy rose –satin finish) ")
        let color22 = MaterialDetails(newImage: UIImage(named: "Shrinagar")!, description: " Shrinagar (metallic raspberry –sheer finish) ")
        let color23 = MaterialDetails(newImage: UIImage(named: "Tolede")!, description: " Tolede (pink rose –satin finish) ")
        
        // add colors to array
        materials.append(color1)
        materials.append(color2)
        materials.append(color3)
        materials.append(color4)
        materials.append(color5)
        materials.append(color6)
        materials.append(color7)
        materials.append(color8)
        materials.append(color9)
        materials.append(color10)
        materials.append(color11)
        materials.append(color12)
        materials.append(color13)
        materials.append(color14)
        materials.append(color15)
        materials.append(color16)
        materials.append(color17)
        materials.append(color18)
        materials.append(color19)
        materials.append(color20)
        materials.append(color21)
        materials.append(color22)
        materials.append(color23)
        
    }
    
   //----------------------------------------------- View After Loading -----------------------------------------------//
    
    override func viewWillDisappear(_ animated: Bool) {
        
        session.pause()
        super.viewWillDisappear(animated)

    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}

