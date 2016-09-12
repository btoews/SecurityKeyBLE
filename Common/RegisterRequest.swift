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
        let reader = DataReader(data: raw)
        
        do {
            challengeParameter = try reader.readData(Int(U2F_CHAL_SIZE))
            applicationParameter = try reader.readData(Int(U2F_APPID_SIZE))
        } catch DataReader.Error.End {
            throw APDUError.BadSize
        }

        if reader.remaining > 0 { throw APDUError.BadSize }
    }
    
    var raw: NSData {
        let m = NSMutableData()
        m.appendData(challengeParameter)
        m.appendData(applicationParameter)
        return m
    }
}