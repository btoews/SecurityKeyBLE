//
//  RegisterResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

// Variable length fields make the C struct hard to use with swift.
struct RegisterResponse {
    var publicKey:   NSData
    var keyHandle:   NSData
    var certificate: NSData
    var signature:   NSData
    
    init(publicKey pk: NSData, keyHandle kh: NSData, certificate cert: NSData, signature sig: NSData) {
        publicKey = pk
        keyHandle = kh
        certificate = cert
        signature = sig
    }
    
    init(raw: NSData) throws {
        var offset = 0

        let reservedRange = NSMakeRange(offset, 1)
        // let reserved = raw.subdataWithRange(reservedRange)
        offset += reservedRange.length
        
        let pkRange = NSMakeRange(offset, sizeof(U2F_EC_POINT))
        publicKey = raw.subdataWithRange(pkRange)
        offset += pkRange.length
        
        let khLenRange = NSMakeRange(offset, 1)
        var khLen: UInt8 = 0
        raw.getBytes(&khLen, range: khLenRange)
        offset += khLenRange.length
        
        let khRange = NSMakeRange(offset, Int(khLen))
        keyHandle = raw.subdataWithRange(khRange)
        offset += khRange.length

        // peek at cert to figure out its length
        let restRange = NSMakeRange(offset, raw.length - offset)
        let rest = raw.subdataWithRange(restRange)
        let certLen = try Util.certLength(fromData: rest)

        let certRange = NSMakeRange(offset, certLen)
        certificate = raw.subdataWithRange(certRange)
        offset += certRange.length
        
        let sigRange = NSMakeRange(offset, raw.length - offset)
        signature = raw.subdataWithRange(sigRange)
    }
    
    var raw: NSData {
        let r = NSMutableData()
        
        var reserved: UInt8 = 0x05
        r.appendBytes(&reserved, length: 1)
        
        r.appendData(publicKey)

        var khLen = UInt8(keyHandle.length)
        r.appendBytes(&khLen, length: 1)
        
        r.appendData(keyHandle)
        r.appendData(certificate)
        r.appendData(signature)
        
        return r
    }
}