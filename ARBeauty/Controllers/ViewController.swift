//
//  ViewController.swift
//  Maddie
//
//  Created by Madeline Eckhart on 7/13/18.
//  Copyright © 2018 MaddGaming. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    /*
     Delete me:
     
     Maddie - hope you don't think i'm ruining your project (or overstepping), I really just want to be helpful. I am truly excited about this project. My goal is to show you how to be a better developer, and the only real way I know how to do that is with code, and by instruction. I also get excited about technical challenges so helping you solve some things has been rewarding.
     
     This should be enough to get you to the finish line, let me know when you're ready to take the video. I'll be checking in on you Friday to see where you're at. I also think this project will be a great visual thing you can show in future interviews, and your website – AR is super popular right now.
     
     Things left for Maddie to do:

     - check product scale, it should be close to reality
     - finalize particle effect, either make better or remove :P
     
    */
    
    
    //Outlets
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var swatchDrawerConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var alertView_label: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    //Properties
    var nodeModel:SCNNode!
    var planeNode:SCNNode!
    var originalRotation: Float?
    var materials: [SwatchDetails] = []
    var nodePlaced = false

    //----------------------------------------- Lifecycle -----------------------------------------//
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Default Data
        nodeModel = SCNNode()
        swatchDrawerConstraint.constant = -110.0
        
        //Add gestures
        addTapGestureToSceneView()
        addLongPressGestureToSceneView()
        addPanGestureToSceneView()
        
        //Inits
        configureLighting()
        initAlertView()
        preloadModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
        colorLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showAlertView(status: 0)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    
    
    
    //----------------------------------------- Scene Setup -----------------------------------------//

    func setUpSceneView() {

        //Config the Scene
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func configureLighting() {
        
        let directionalNode = SCNNode()
        let constraint = SCNLookAtConstraint(target:nodeModel)
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.light?.color = UIColor.white
        directionalNode.light?.castsShadow = true
        directionalNode.light?.intensity = 2000
        directionalNode.light?.shadowRadius = 16
        directionalNode.light?.shadowMode = .deferred
        directionalNode.eulerAngles = SCNVector3(Float.pi/2,0,0)
        directionalNode.light?.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        directionalNode.position = SCNVector3((nodeModel.position.x) + 10,(nodeModel.position.y) + 30,(nodeModel.position.z)+30)
        directionalNode.constraints = [constraint]

        self.sceneView.scene.rootNode.addChildNode(directionalNode)
    }
    
    func preloadModel() {
        //Preload model so there isn't a delay on tap
        guard let shipScene = SCNScene(named: "nars.scn"),
            let node = shipScene.rootNode.childNode(withName: "Nars", recursively: false)
            else { return }
        
        nodeModel = node
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        
        let fire = SCNParticleSystem(named: "smoke.scnp", inDirectory: nil)
        //fire?.birthLocation = .surface
        fire?.particleSize = 0.08
        
        nodeModel.addParticleSystem(fire!)
    }
    
    @objc func showVariantDrawer() {
        
        swatchDrawerConstraint.constant = 0

        UIView.animate(withDuration:1.0, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: {
            (value: Bool) in
        })
    }
    
    
    
    
    //----------------------------------------- Collection View (Delegate & Datasource) -----------------------------------------//
    
    // MARK: UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        setMaterials()
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return materials.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        // Configure the cell
        let shade = materials[indexPath.row]
        cell.layer.cornerRadius = cell.frame.size.width / 2
        cell.clipsToBounds = true
        cell.backgroundColor = hexStringToUIColor(hex: shade.hex)
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // cell highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 3.0
        cell?.layer.borderColor = UIColor.white.cgColor
        
//        var newFrame: CGRect = (cell?.frame)!
//        newFrame.size = CGSize(width: (cell?.intrinsicContentSize.height)!*2, height: (cell?.intrinsicContentSize.width)!*2)
//        cell?.frame = newFrame
        
        
        let shade = materials[indexPath.row]
        colorLabel.layer.cornerRadius = 5
        colorLabel.text = shade.desc
        colorLabel.isHidden = false
        
        //This is how you edit an the existing material defined in scn
        let lipstick_bullet = self.nodeModel.childNode(withName: "Bullet", recursively: true)!
        lipstick_bullet.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: shade.hex)

        //Replay the animation
        //If you look at the scn file, select the "lipstick" bullet node, you'll see an animation section, that's where the "ID12" comes from
        lipstick_bullet.animationPlayer(forKey: "ID12")?.play()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        // cell un-highlight when selected
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 0.0
    }
    
    
    

    
    //----------------------------------------- Gestures -----------------------------------------//
    
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.viewTapped(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    func addLongPressGestureToSceneView() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.viewLongPress(_:)))
        sceneView.addGestureRecognizer(longPressGestureRecognizer)
    }
 
    func addPanGestureToSceneView() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.viewPan(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    // get gesture position
    private func node(at position: CGPoint) -> SCNNode? {
        return sceneView.hitTest(position, options: nil)
            .first(where: { $0.node !== planeNode && $0.node !== nodeModel })?
            .node
    }

    // place object at tap
    @objc func viewTapped(_ gesture: UIGestureRecognizer) {
        if nodePlaced == false {
            let tapLocation = gesture.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
            guard let hitTestResult = hitTestResults.first else { return }
            let translation = hitTestResult.worldTransform.translation
            let x = translation.x
            let y = translation.y
            let z = translation.z
        
        
            //"Remove" the plane - we don't really remove, we need a plane to cast shadows
            planeNode.geometry?.materials.first?.diffuse.contents = UIColor.transparentWhite
            sceneView.debugOptions = []
        
            //Set the size and position of 3d object (easier to set in code vs in IB editor)
            nodeModel.scale = SCNVector3(0.007, 0.007, 0.007)
        
            //Do some math, boundingBox = orinigal size of object, so we need to scale it down based on scale vector above
            //Also if you posistion the model in scn file onto the grid, you won't need this math
            //let (min, max) = nodeModel.boundingBox
            //let height = (max.y - min.y) * 0.0002
        
            //nodeModel.position = SCNVector3(x,y+height,z) //depending on where the model center is, you have to offset the y sometimes
            nodeModel.position = SCNVector3(x,y,z)
        
            //Add 3D object to scene
            sceneView.scene.rootNode.addChildNode(nodeModel)
        
            /*
            //Show Explosion
            let base = self.nodeModel.childNode(withName: "Matte_Base", recursively: true)!
            createExplosion(geometry: base.geometry!, position: nodeModel.position, rotation: nodeModel.rotation)
            */
        
            //Show the variant drawer, but use a small delay for performace and visual
            perform(#selector(showVariantDrawer), with: self, afterDelay: 0.5)
            nodePlaced = true
        }
    }
    
    // move object on long press
    @objc func viewLongPress(_ gesture: UILongPressGestureRecognizer) {
        
        // Find the location in the view
        let location = gesture.location(in: sceneView)
        
        switch gesture.state {
            case .changed:
                // Move the node based on the real world translation
                guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
                
                let transform = result.worldTransform
                let newPosition = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                //selectedNode?.simdPosition = newPosition
                nodeModel.simdPosition = newPosition

            default:
                print("nothin")
        }
    }
    
    // roate object with swipe
    @objc func viewPan(_ gesture: UIPanGestureRecognizer) {
        
        print("panning")
        let location = gesture.location(in: sceneView)
        
        guard let node = node(at: location) else { return }
        originalRotation = node.eulerAngles.y
        let translation = gesture.translation(in: gesture.view)
        var newY = (Float)(translation.x) * (Float)(Double.pi)/180
        newY += originalRotation!
        
        node.eulerAngles.y = newY
        
        if(gesture.state == .ended) {
            originalRotation = newY
        }

    }
    
    
    
    
    
    //----------------------------------------- Auxilary Functions -----------------------------------------//

    func initAlertView() {
        alertView.isHidden = true
        alertView.layer.cornerRadius = 10.0
        alertView.clipsToBounds = true
    }
    
    func showAlertView (status:Int) {
        if(status == 0)
        {
            alertView_label.text = "Searching for ground plane…"
            alertView.isHidden = false
            activityView.startAnimating()
        }
        else
        {
            alertView_label.text = "Ground plane found! Tap to add object."
            perform(#selector(hideAlertView), with: self, afterDelay: 0.5)
        }
    }
    
    @objc func hideAlertView() {
        
        UIView.animate(withDuration: 0.5 , delay: 2.0, options: .curveEaseOut, animations: {
            self.alertView.alpha = 0.0
        }, completion: { _ in
            self.alertView.isHidden = true
        })
    }
    
    @IBAction func addToCart(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: "Added to Cart", preferredStyle: .alert)
        let alertText = UIAlertAction(title: "OK", style: .cancel)
        alertController.addAction(alertText)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func close(_sender : AnyObject){
        dismiss(animated: true, completion: nil)
    }
    
    
    func setMaterials() {
        
        // add color images with details
        let color1 = SwatchDetails(hexValue: "#B9405D", description: " Afghan Red (garnet –satin finish) ")
        let color2 = SwatchDetails(hexValue: "#A85854", description: " Banned Red (mulled wine –satin finish) ")
        let color3 = SwatchDetails(hexValue: "#CB9D8D", description: " Belle Du Jour (nude beige –sheer finish) ")
        let color4 = SwatchDetails(hexValue: "#AC787A", description: " Catfight (nude mauve –semi nude finish) ")
        let color5 = SwatchDetails(hexValue: "#BE7A75", description: " Cruising (nude pink –sheer finish) ")
        let color6 = SwatchDetails(hexValue: "#AC7983", description: " Damage (muted grape –sheer finish) ")
        let color7 = SwatchDetails(hexValue: "#C5908E", description: " Dolce Vita (dusty rose –sheer finish) ")
        let color8 = SwatchDetails(hexValue: "#7F3A2C", description: " Falbala (shimmering rose –sheer finish) ")
        let color9 = SwatchDetails(hexValue: "#885766", description: " Fast Ride (mulberry –sheer finish) ")
        let color10 = SwatchDetails(hexValue: "#881728", description: " Fire Down Below (blood red –semi matte finish) ")
        let color11 = SwatchDetails(hexValue: "#F9509D", description: " Funny Face (bright fuchsia –semi matte finish) ")
        let color12 = SwatchDetails(hexValue: "#AC2F53", description: " Gipsy (warm berry –sheer finish) ")
        let color13 = SwatchDetails(hexValue: "#F92F43", description: " Heat Wave (orange red –matte finish) ")
        let color14 = SwatchDetails(hexValue: "#BE6157", description: " Niagara (pinkish –satin finish) ")
        let color15 = SwatchDetails(hexValue: "#D99399", description: " Pigalle (pink chocolate –semi matte finish) ")
        let color16 = SwatchDetails(hexValue: "#B91647", description: " Red Lizard (full-powered red –semi matte finish) ")
        let color17 = SwatchDetails(hexValue: "#C16F7F", description: " Roman Holiday (delicate pastel pink –sheer finish) ")
        let color18 = SwatchDetails(hexValue: "#C48C82", description: " Rosecliff (soft rose –satin finish) ")
        let color19 = SwatchDetails(hexValue: "#9F1747", description: " Scarlett Empress (rich blue-red –semi matte finish) ")
        let color20 = SwatchDetails(hexValue: "#F24CA4", description: " Schiap (shocking pink –semi matte finish) ")
        let color21 = SwatchDetails(hexValue: "#C88B88", description: " Sexual Healing (metallic peachy rose –satin finish) ")
        let color22 = SwatchDetails(hexValue: "#8D374F", description: " Shrinagar (metallic raspberry –sheer finish) ")
        let color23 = SwatchDetails(hexValue: "#B36368", description: " Tolede (pink rose –satin finish) ")
        
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
    
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}



//----------------------------------------- Extensions -----------------------------------------//

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.30)
    }
    
    open class var transparentWhite: UIColor {
        return UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.01)
    }
}


//----------------------------------------- ARRKit Delegate Protcol -----------------------------------------//
extension ViewController: ARSCNViewDelegate {
    
    //method for plane discovery and visualization
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
        
        planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
        
        DispatchQueue.main.async {
            self.showAlertView(status: 1)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }
}
