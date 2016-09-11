//
//  SHA256.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class SHA256 {
    typealias TupleDigest = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    static var DigestLength = Int(CC_SHA256_DIGEST_LENGTH)
    
    static func digest(data: NSData) throws -> NSData {
        return SHA256(data: data).digest
    }
    
    static func tupleDigest(data: NSData) -> TupleDigest {
        return SHA256(data: data).tupleDigest
    }

    static func b64Digest(data: NSData) -> NSData {
        return SHA256(data: data).b64Digest
    }
    
    var digest: NSData
    
    var tupleDigest: TupleDigest {
        var td: TupleDigest = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        digest.getBytes(&td, length: SHA256.DigestLength)
        return td
    }
    
    var b64Digest: NSData {
        return digest.base64EncodedDataWithOptions([])
    }
    
    init(data: NSData) {
        var bytes = [UInt8](count: SHA256.DigestLength, repeatedValue: 0x00)
        CC_SHA256(data.bytes, CC_LONG(data.length), &bytes)
        digest = NSData(bytes: &bytes, length: SHA256.DigestLength)
    }
}