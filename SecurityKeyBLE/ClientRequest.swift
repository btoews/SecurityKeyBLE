//
//  ClientRequest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

enum ClientRequestCommand: UInt8 {
    case Ping = 0x81
    case Msg = 0x83
}

class ClientRequest: Framable {
    var cmd: ClientRequestCommand
    
    init(rawData: NSData) {
        var cmdInt: UInt8 = 0
        rawData.getBytes(&cmdInt, range: NSRange(location: 0, length: 1))
        cmd = ClientRequestCommand(rawValue: cmdInt)!
        
        super.init()
        
        self.rawData = rawData
        
        rawData.getBytes(&hLen, range: NSRange(location: 1, length: 1))
        rawData.getBytes(&lLen, range: NSRange(location: 2, length: 1))
        
        let dataRange = NSRange(location: 3, length: rawData.length - 3)
        data = NSMutableData(data: rawData.subdataWithRange(dataRange))
    }
}