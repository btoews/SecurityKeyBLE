//
//  APDUCommand.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

var CommandTypeForCode:[APDUHeader.CommandCode:APDUCommandDataProtocol.Type] = [
    .Register: RegisterRequest.self
]

struct APDUCommand {
    var header: APDUHeader
    var data: APDUCommandDataProtocol
    
    init(data d: APDUCommandDataProtocol) throws {
        header = try APDUHeader(cmdData: d)
        data = d
    }
    
    init(raw: NSData) throws {
        header = try APDUHeader(raw: raw)
        
        let dOffset = header.raw.length
        let dRange = NSMakeRange(dOffset, raw.length - dOffset)
        let dData = raw.subdataWithRange(dRange)
        
        guard let cmdType = CommandTypeForCode[header.ins] else {
            throw APDUError.BadCode
        }
        
        data = try cmdType.init(raw: dData)
    }
    
    var raw: NSData {
        let m = NSMutableData()
        m.appendData(header.raw)
        m.appendData(data.raw)
        return m
    }
}
