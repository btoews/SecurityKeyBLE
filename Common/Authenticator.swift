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

    // Get a BLE level response for a BLE level message.
    func bleResponse(msg: BLEMessage) -> BLEMessage {
        do {
            let cmd:APDUCommand = try msg.unwrapAPDU()
            return bleCommandResponse(cmd)
        } catch is BLEMessage.Error {
            return bleErrorResponse(.BLEError)
        } catch is APDUError {
            return bleErrorResponse(.APDUError)
        } catch {
            return bleErrorResponse(.Unknown)
        }
    }

    // Get a BLE level response for a BLE level command.
    func bleCommandResponse(cmd: APDUCommand) -> BLEMessage {
        if let req = cmd.data as? RegisterRequest {
            return bleRegisterResponse(req)
        } else {
            return bleErrorResponse(.U2FError)
        }
    }
    
    // Get a BLE level response for a U2F level register request.
    func bleRegisterResponse(req: RegisterRequest) -> BLEMessage {
        do {
            let resp = try(register(req))
            let msg = try resp.bleWrapped()
            return msg
        } catch {
            return bleErrorResponse(.U2FError)
        }
    }
    
    // Get a BLE level error response with the given code.
    func bleErrorResponse(code: BLEMessage.ErrorCode) -> BLEMessage {
        let data = NSData(int: code.rawValue)
        return BLEMessage(status: .Error, data: data)
    }

    // register request -> register response
    func register(request: RegisterRequest) throws -> RegisterResponse {
        let kh = keyHandle(request.applicationParameter)
        let k = try keyData(forKeyHandle: kh)
        
        let toSign = NSMutableData()
        toSign.appendByte(0x00) // reserved
        toSign.appendData(request.applicationParameter)
        toSign.appendData(request.challengeParameter)
        toSign.appendData(kh)
        toSign.appendData(k)
        
        let s = signWithCert(toSign)
        let c = cert.toDer()
        
        return RegisterResponse(publicKey: k, keyHandle: kh, certificate: c, signature: s)
    }

    // Sign a message with our X509 certificate.
    private func signWithCert(message: NSData) -> NSData {
        return cert.signData(message)
    }
    
    // Sign a message with the appropriate key.
    private func signWithKey(applicationParameter: NSData, message: NSData) throws -> NSData {
        let kh = keyHandle(applicationParameter)
        let res = KeyInterface.generateSignatureForData(message, withKeyName: kh)

        if res.error != nil {
            throw Error.SigningError
        } else {
            return res.signature
        }
    }
    
    // Get the appropriate key for the given key handle.
    private func keyData(forKeyHandle kh: NSData) throws -> NSData {
        if !KeyInterface.publicKeyExists(kh) && !KeyInterface.generateTouchIDKeyPair(kh){
            throw Error.KeyGenerationFailure
        }
        
        return KeyInterface.publicKeyBits(kh)
    }
    
    // Get the appropriate key handle for a given application parameter.
    private func keyHandle(applicationParameter: NSData) -> NSData {
        let data = NSMutableData(data: keyHandleBase)
        data.appendData(applicationParameter)
        return SHA256.b64Digest(data)
    }
}