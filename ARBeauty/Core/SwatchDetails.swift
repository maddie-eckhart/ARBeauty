//
//  SwatchDetails.swift
//  Maddie
//
//  Created by Madeline Eckhart on 7/19/18.
//  Copyright © 2018 MaddGaming. All rights reserved.
//

import Foundation
import UIKit

class SwatchDetails {
    var desc: String = ""
    var hex: String = ""
    
    init(hexValue: String, description: String ) {
        self.desc = description
        self.hex = hexValue
    }
}
