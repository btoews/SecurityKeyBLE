//
//  WebSafeBase64.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/13/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class WebSafeBase64 {
    static func encodeData(data: NSData) -> String {
        return data.base64EncodedStringWithOptions([])
            .stringByReplacingOccurrencesOfString("+", withString: "-")
            .stringByReplacingOccurrencesOfString("/", withString: "_")
            .stringByReplacingOccurrencesOfString("=", withString: "")
    }
    
    static func decodeString(string: String) -> NSData? {
        var b64 = string
            .stringByReplacingOccurrencesOfString("-", withString: "+")
            .stringByReplacingOccurrencesOfString("_", withString: "/")
        
        let padding: Int
        
        switch b64.characters.count % 4 {
        case 0:
            padding = 0
        case 2:
            padding = 2
        case 3:
            padding = 1
        default:
            return nil
        }
        
        b64 += String(count: padding, repeatedValue: Character("="))
        
        return NSData(base64EncodedString: b64, options: [])
    }
    
    static func random(size:Int = 32) -> String {
        var bytes = [UInt8](count: size, repeatedValue: 0x00)
        SecRandomCopyBytes(kSecRandomDefault, size, &bytes)
        let data = NSData(bytes: &bytes, length: size)
        return encodeData(data)
    }
}
