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
        let reader = DataReader(data: raw)
        
        do {
            // reserved byte
            let _:UInt8 = try reader.read()
            
            publicKey = try reader.readData(sizeof(U2F_EC_POINT))
            
            let khLen:UInt8 = try reader.read()
            keyHandle = try reader.readData(Int(khLen))
            
            // peek at cert to figure out its length
            let certLen = try Util.certLength(fromData: reader.rest)
            certificate = try reader.readData(certLen)
            
            signature = reader.rest
        } catch DataReader.Error.End {
            throw APDUError.BadSize
        }
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