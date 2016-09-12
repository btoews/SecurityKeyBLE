//
//  RegisterResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

protocol APDUResponseDataProtocol {
    init(raw: NSData) throws
    var raw: NSData { get }
}

struct RegisterResponse: APDUResponseDataProtocol {
    enum Error: ErrorType {
        case BadSize
    }
    
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
        var range: NSRange

        range = NSMakeRange(offset, 1)
        let reserved = raw.subdataWithRange(range)
        if reserved.length != range.length { throw Error.BadSize }
        offset += range.length
        
        range = NSMakeRange(offset, sizeof(U2F_EC_POINT))
        publicKey = raw.subdataWithRange(range)
        if publicKey.length != range.length { throw Error.BadSize }
        offset += range.length
        
        range = NSMakeRange(offset, 1)
        var khLen: UInt8 = 0
        raw.getBytes(&khLen, range: range)
        if khLen == 0 { throw Error.BadSize }
        offset += range.length
        
        range = NSMakeRange(offset, Int(khLen))
        keyHandle = raw.subdataWithRange(range)
        if keyHandle.length != range.length { throw Error.BadSize }
        offset += range.length

        // peek at cert to figure out its length
        range = NSMakeRange(offset, raw.length - offset)
        let rest = raw.subdataWithRange(range)
        let certLen = try Util.certLength(fromData: rest)

        range = NSMakeRange(offset, certLen)
        certificate = raw.subdataWithRange(range)
        if certificate.length != range.length { throw Error.BadSize }
        offset += range.length
        
        range = NSMakeRange(offset, raw.length - offset)
        signature = raw.subdataWithRange(range)
        if signature.length != range.length { throw Error.BadSize }
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