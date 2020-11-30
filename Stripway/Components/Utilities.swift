//
//  Utility.swift
//  Stripway
//
//  Created by iOS Dev on 2/11/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import Foundation
import UIKit

class Utilities : NSObject {
    class func isIphoneX() -> Bool {
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 1136:
                print("iPhone 5 or 5S or 5C")
                return false
            case 1334:
                print("iPhone 6/6S/7/8")
                return false
            case 1920, 2208:
                print("iPhone 6+/6S+/7+/8+")
                return false
            case 2436:
                print("iPhone X, XS")
                return true
            case 2688:
                print("iPhone XS Max")
                return true
            case 1792:
                print("iPhone XR")
                return true
            default:
                print("Unknown")
                return false
            }
        }
        return false
    }
}

