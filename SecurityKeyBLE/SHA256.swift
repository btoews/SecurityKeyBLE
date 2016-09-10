//
//  SHA256.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class SHA256 {
    enum Error: ErrorType {
        case BadEncoding
        case NoDigest
    }
    
    typealias TupleDigest = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    
    static var DigestLength = Int(CC_SHA256_DIGEST_LENGTH)
    
    static func digest(str: String, encoding: NSStringEncoding = NSUTF8StringEncoding) throws -> NSData {
        let h = SHA256()
        try h.update(str, encoding: encoding)
        h.final()
        guard let d = h.digest else { throw Error.NoDigest }
        return d
    }
    
    static func tupleDigest(str: String, encoding: NSStringEncoding = NSUTF8StringEncoding) throws -> TupleDigest {
        let h = SHA256()
        try h.update(str, encoding: encoding)
        h.final()
        guard let td = h.tupleDigest else { throw Error.NoDigest }
        return td
    }

    static func b64Digest(str: String, encoding: NSStringEncoding = NSUTF8StringEncoding) throws -> String {
        let h = SHA256()
        try h.update(str, encoding: encoding)
        h.final()
        guard let bd = h.b64Digest else { throw Error.NoDigest }
        return bd
    }
    
    var digest: NSData?
    
    private var ctx = CC_SHA256_CTX()
    
    var tupleDigest: TupleDigest? {
        guard let d = digest else { return nil }
        var td: TupleDigest = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        d.getBytes(&td, length: SHA256.DigestLength)
        return td
    }
    
    var b64Digest: String? {
        guard let d = digest else { return nil }
        return d.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    init() {
        CC_SHA256_Init(&ctx)
    }
    
    func update(str: String, encoding: NSStringEncoding = NSUTF8StringEncoding) throws {
        guard let d = str.dataUsingEncoding(encoding) else {
            throw Error.BadEncoding
        }
        
        update(d)
    }
    
    func update(data: NSData) {
        CC_SHA256_Update(&ctx, data.bytes, CC_LONG(data.length))
    }
    
    func final() {
        var bytes = [UInt8](count: SHA256.DigestLength, repeatedValue: 0x00)
        CC_SHA256_Final(&bytes, &ctx)
        print(bytes)
        digest = NSData(bytes: &bytes, length: SHA256.DigestLength)
    }
}