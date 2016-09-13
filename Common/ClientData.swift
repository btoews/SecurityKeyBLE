//
//  ClientData.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct ClientData {
    enum Type: String {
        case Register = "navigator.id.finishEnrollment"
        case Authenticate = "navigator.id.getAssertion"
    }
    
    let typ: Type
    let challenge: String
    let origin: String
    
    var dict: [String:String] {
        return [
            "typ":       typ.rawValue,
            "challenge": challenge,
            "origin":    origin
        ]
    }
    
    init(typ t: Type, origin o: String) {
        typ = t
        origin = o
        challenge = ClientData.makeChallenge()
    }
    
    func toJSON() throws -> NSData {
        return try NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }
    
    func digest() throws -> NSData {
        let j = try toJSON()
        return try SHA256.digest(j)
    }
    
    static func makeChallenge(size:Int = 32) -> String {
        var bytes = [UInt8](count: size, repeatedValue: 0x00)
        SecRandomCopyBytes(kSecRandomDefault, size, &bytes)
        let data = NSData(bytes: &bytes, length: size)
        return WebSafeBase64.encodeData(data)
    }
}