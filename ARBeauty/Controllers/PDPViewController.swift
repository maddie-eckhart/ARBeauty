//
//  PDPViewController.swift
//  Maddie
//
//  Created by Eby, Nicholas on 7/18/18.
//

import UIKit

class PDPViewController: UIViewController {

    @IBOutlet weak var animation_imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        initAnimation()
    }
    
    func initAnimation() {
        
        let imagesListArray:NSMutableArray = []
        
        //use for loop
        for position in 0...114
        {
            
            let strImageName : String = "animation\(position).jpg"
            let image  = UIImage(named:strImageName)
            imagesListArray.add(image!)
        }
        
        animation_imageView.animationImages = imagesListArray as? [UIImage]
        animation_imageView.animationDuration = 4.0
        animation_imageView.startAnimating()
    }

}
