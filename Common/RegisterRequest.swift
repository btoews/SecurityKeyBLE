//
//  RegisterRequest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

protocol APDUCommandDataProtocol {
    var cmdClass: APDUHeader.CommandClass { get }
    var cmdCode:  APDUHeader.CommandCode  { get }

    init(raw: NSData) throws
    var raw: NSData { get }
}

struct RegisterRequest: APDUCommandDataProtocol {
    enum Error: ErrorType {
        case BadSize
    }
    
    var cmdClass = APDUHeader.CommandClass.Reserved
    var cmdCode  = APDUHeader.CommandCode.Register

    var challengeParameter: NSData
    var applicationParameter: NSData
    
    init(challengeParameter c: NSData, applicationParameter a: NSData) {
        challengeParameter = c
        applicationParameter = a
    }
    
    init(raw: NSData) throws {
        if raw.length != sizeof(U2F_REGISTER_REQ) {
            throw Error.BadSize
        }
        
        var offset = 0
        var range: NSRange
        
        range = NSMakeRange(offset, Int(U2F_CHAL_SIZE))
        challengeParameter = raw.subdataWithRange(range)
        offset += range.length
        
        range = NSMakeRange(offset, Int(U2F_APPID_SIZE))
        applicationParameter = raw.subdataWithRange(range)
    }
    
    var raw: NSData {
        let m = NSMutableData()
        m.appendData(challengeParameter)
        m.appendData(applicationParameter)
        return m
    }
}