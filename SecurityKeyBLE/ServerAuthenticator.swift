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

    private let cert        = SelfSignedCertificate()
    private let UserPresent = UInt8(U2F_AUTH_FLAG_TUP)
    private let Counter     = UInt32(0x00000000)

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
        do {
            if let req = cmd.registerRequest {
                return try register(req).bleWrapped()
            }
            
            if let req = cmd.authenticationRequest {
                return try authenticate(req).bleWrapped()
            }
        } catch {}
        
        return bleErrorResponse(.APDUError)
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
        
        let toSign = DataWriter()
        toSign.write(UInt8(0x00)) // reserved
        toSign.writeData(request.applicationParameter)
        toSign.writeData(request.challengeParameter)
        toSign.writeData(kh)
        toSign.writeData(k)
        
        let s = signWithCert(toSign.buffer)
        let c = cert.toDer()
        
        return RegisterResponse(publicKey: k, keyHandle: kh, certificate: c, signature: s)
    }
    
    // auth request -> auth response
    func authenticate(request: AuthenticationRequest) throws -> AuthenticationResponse {
        let toSign = DataWriter()
        toSign.writeData(request.applicationParameter)
        toSign.write(UserPresent)
        toSign.write(Counter)
        toSign.writeData(request.challengeParameter)
        
        let sig = try signWithKey(request.keyHandle, message: toSign.buffer)
        
        return AuthenticationResponse(userPresence: UserPresent, counter: Counter, signature: sig)
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