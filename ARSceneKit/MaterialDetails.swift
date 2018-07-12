//
//  MaterialDetails.swift
//  AR Beauty
//
//  Created by Madeline Eckhart on 6/25/18.
//  Copyright © 2018 MaddGaming. All rights reserved.
//

import Foundation
import UIKit

class MaterialDetails {
    var image: UIImage
    var desc: String = ""
    
    init(newImage: UIImage, description: String ) {
        self.desc = description
        self.image = newImage
    }
}
