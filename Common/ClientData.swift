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
    
    var typ: Type
    var challenge: String
    var origin: String
    
    var dict: [String:String] {
        return [
            "typ":       typ.rawValue,
            "challenge": challenge,
            "origin":    origin
        ]
    }
    
    func toJSON() throws -> NSData {
        return try NSJSONSerialization.dataWithJSONObject(dict, options: [])
    }
    
    func digest() throws -> SHA256.TupleDigest {
        let j = try toJSON()
        return SHA256.tupleDigest(j)
    }
}