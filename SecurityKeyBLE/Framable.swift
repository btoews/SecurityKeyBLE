//
//  Framable.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class Framable {
    var cmdOrStatus: UInt8 = 0
    var hLen:        UInt8 = 0
    var lLen:        UInt8 = 0
    var data:        NSMutableData = NSMutableData()
    var rawData:     NSData = NSData()
}