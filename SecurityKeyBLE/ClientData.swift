//
//  ClientData.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct ClientData {
    var typ: String
    var challenge: String
    var origin: String
    
    var dict: [String:String] {
        return [
            "typ":       typ,
            "challenge": challenge,
            "origin":    origin
        ]
    }
    
    var json: NSData? {
        do {
            return try NSJSONSerialization.dataWithJSONObject(dict, options: [])
        } catch {
            return nil
        }
    }
    
    var digest: SHA256.TupleDigest? {
        guard let j = json else { return nil }
        return SHA256.tupleDigest(j)
    }
}