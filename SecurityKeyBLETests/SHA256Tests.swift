//
//  SHA256Tests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class SHA256Tests: XCTestCase {
    func testB64() throws {
        let expected = "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
        let actual = try SHA256.b64Digest("hello world")
        XCTAssertEqual(expected, actual)
    }
    
    func testTuple() throws {
        let expected: SHA256.TupleDigest = (185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233)
        let actual = try SHA256.tupleDigest("hello world", encoding: NSASCIIStringEncoding)
        XCTAssert(tupleDigestEqual(expected, actual), "expected \(actual) to equal \(expected)")
    }
    
    func testMultipleUpdates() throws {
        let h = SHA256()
        try h.update("hello ")
        try h.update("world")
        h.final()
        
        let expected: SHA256.TupleDigest = (185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233)
        let actual = h.tupleDigest!
        
        XCTAssert(tupleDigestEqual(expected, actual), "expected \(actual) to equal \(expected)")
    }
    
    func tupleDigestEqual(a: SHA256.TupleDigest, _ b: SHA256.TupleDigest) -> Bool {
        return
            a.0 == b.0 &&
            a.1 == b.1 &&
            a.2 == b.2 &&
            a.3 == b.3 &&
            a.4 == b.4 &&
            a.5 == b.5 &&
            a.6 == b.6 &&
            a.7 == b.7 &&
            a.8 == b.8 &&
            a.9 == b.9 &&
            a.10 == b.10 &&
            a.11 == b.11 &&
            a.12 == b.12 &&
            a.13 == b.13 &&
            a.14 == b.14 &&
            a.15 == b.15 &&
            a.16 == b.16 &&
            a.17 == b.17 &&
            a.18 == b.18 &&
            a.19 == b.19 &&
            a.20 == b.20 &&
            a.21 == b.21 &&
            a.22 == b.22 &&
            a.23 == b.23 &&
            a.24 == b.24 &&
            a.25 == b.25 &&
            a.26 == b.26 &&
            a.27 == b.27 &&
            a.28 == b.28 &&
            a.29 == b.29 &&
            a.30 == b.30 &&
            a.31 == b.31
    }
}
