//
//  RegisterResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

extension U2F_REGISTER_RESP {
    enum Error: ErrorType {
        case BadCert
    }
    
    init(publicKey pk: NSData, keyHandle kh: NSData, certificate cert: NSData, signature sig: NSData) {
        self.init()

        registerId = 0x05 // legacy reserved byte
        pubKey = U2F_EC_POINT(raw: pk)
        keyHandleLen = UInt8(kh.length)
        
        let kcs = NSMutableData()
        kcs.appendData(kh)
        kcs.appendData(cert)
        kcs.appendData(sig)
        keyHandleCertSigData = kcs
    }
    
    func getKeyHandle() -> NSData {
        let khRange = NSRange(location: 0, length: Int(keyHandleLen))
        return keyHandleCertSigData.subdataWithRange(khRange)
    }
    
    func getCert() throws -> NSData {
        let offset = Int(keyHandleLen)
        let dataRange = NSRange(location: offset, length: keyHandleCertSigData.length - offset)
        let data = keyHandleCertSigData.subdataWithRange(dataRange)
        
        let certLen = try certLength(fromData: data)
        let certRange = NSRange(location: 0, length: certLen)
        
        return data.subdataWithRange(certRange)
    }

    func getSig() throws -> NSData {
        let certLen = try getCert().length
        let offset = Int(keyHandleLen) + certLen

        let sigRange = NSRange(location: offset, length: keyHandleCertSigData.length - offset)
        return keyHandleCertSigData.subdataWithRange(sigRange)
    }
    
    private var keyHandleCertSigData: NSData {
        get {
            var tmp = keyHandleCertSig
            return NSData(bytes: &tmp, length: sizeofValue(tmp))
        }
        
        set(newValue) {
            newValue.getBytes(&keyHandleCertSig, length: sizeofValue(keyHandleCertSig))
        }
    }
    
    private func certLength(fromData d: NSData) throws -> Int {
        var size: Int = 0
        if SelfSignedCertificate.parseX509(d, consumed: &size) == 1 {
            return size
        } else {
            throw Error.BadCert
        }
    }
}

extension U2F_EC_POINT: RawData {}



