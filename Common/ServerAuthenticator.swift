//
//  Authenticator.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct ServerAuthenticator {
    enum Error: ErrorType {
        case DuplicateKeyHandle
        case NoSuchKey
        case KeyGenerationFailure
        case SigningError
    }
    
    // TODO: Store this somewhere and reuse it?
    private var cert = SelfSignedCertificate()

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
        let kh = newKeyHandle()
        let k = try generateKey(kh)
        
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
    private func signWithKey(kh: NSData, message: NSData) throws -> NSData {
        if !KeyInterface.publicKeyExists(kh) {
            throw Error.NoSuchKey
        }
    
        let res = KeyInterface.generateSignatureForData(message, withKeyName: kh)

        if res.error != nil {
            throw Error.SigningError
        } else {
            return res.signature
        }
    }
    
    // Generate a key with the given key handle.
    private func generateKey(kh: NSData) throws -> NSData {
        if KeyInterface.publicKeyExists(kh) {
            throw Error.DuplicateKeyHandle
        }
        
        if !KeyInterface.generateTouchIDKeyPair(kh) {
            throw Error.KeyGenerationFailure
        }
        
        return KeyInterface.publicKeyBits(kh)
    }

    private func newKeyHandle() -> NSData {
        var bytes = [UInt8](count: 32, repeatedValue: 0x00)
        SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)
        return NSData(bytes: &bytes, length: 32)
    }
}