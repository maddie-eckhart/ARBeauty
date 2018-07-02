//
//  ProductList.swift
//  AR Beauty
//
//  Created by Madeline Eckhart on 6/25/18.
//  Copyright © 2018 MaddGaming. All rights reserved.
//

import Foundation
import UIKit
// maybe add in a .scn as an attribute too??????

class ProductList {
    var name: String = ""
    var image: UIImage
    
    init(newName: String, newImage: UIImage) {
        self.name = newName
        self.image = newImage
    }
    
    func getName() -> String {
        return name
    }
    
    func getImage() -> UIImage {
        return image
    }
}
