//
//  AuthenticatorResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

enum AuthenticatorResponseStatus: UInt8 {
    case KeepAlive = 0x82
    case Error = 0xBF
}

class AuthenticatorResponse: Framable {
    var stat: AuthenticatorResponseStatus
    
    init(stat: AuthenticatorResponseStatus, data: NSData) {
        self.stat = stat
        super.init()
        
        self.data = NSMutableData(data: data)
        
        cmdOrStatus = stat.rawValue
        
        hLen = UInt8((data.length >> 8) & 0xFF)
        lLen = UInt8(data.length & 0xFF)
        
        let mutableRawData = NSMutableData(capacity: data.length + 3)!
        mutableRawData.appendBytes(&cmdOrStatus, length: 1)
        mutableRawData.appendBytes(&hLen, length: 1)
        mutableRawData.appendBytes(&lLen, length: 1)
        mutableRawData.appendData(data)
        
        rawData = NSData(data: mutableRawData)
    }
}