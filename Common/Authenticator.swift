//
//  Authenticator.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct Authenticator {
    enum Error: ErrorType {
        case KeyGenerationFailure
        case SigningError
    }
    
    // TODO: Store this somewhere and reuse it?
    private var cert = SelfSignedCertificate()
    
    // TODO: use something unique to the device.
    private var keyHandleBase = "iOS Security Key:".dataUsingEncoding(NSUTF8StringEncoding)!
    
    // register request -> register response
    func register(request: U2F_REGISTER_REQ) throws -> U2F_REGISTER_RESP {
        let kh = keyHandle(request.appIdData)
        let k = try keyData(forKeyHandle: kh)
        
        let toSign = NSMutableData()
        toSign.appendByte(0x00) // reserved
        toSign.appendData(request.appIdData)
        toSign.appendData(request.challengeData)
        toSign.appendData(kh)
        toSign.appendData(k)
        
        let s = signWithCert(toSign)
        let c = cert.toDer()
        
        return U2F_REGISTER_RESP(publicKey: k, keyHandle: kh, certificate: c, signature: s)
    }
    
    private func signWithCert(message: NSData) -> NSData {
        return cert.signData(message)
    }
    
    private func signWithKey(applicationParameter: NSData, message: NSData) throws -> NSData {
        let kh = keyHandle(applicationParameter)
        let res = KeyInterface.generateSignatureForData(message, withKeyName: kh)

        if res.error != nil {
            throw Error.SigningError
        } else {
            return res.signature
        }
    }
    
    private func keyData(forKeyHandle kh: NSData) throws -> NSData {
        if !KeyInterface.publicKeyExists(kh) && !KeyInterface.generateTouchIDKeyPair(kh){
            throw Error.KeyGenerationFailure
        }
        
        return KeyInterface.publicKeyBits(kh)
    }
    
    private func keyHandle(applicationParameter: NSData) -> NSData {
        let data = NSMutableData(data: keyHandleBase)
        data.appendData(applicationParameter)
        return SHA256.b64Digest(data)
    }
}