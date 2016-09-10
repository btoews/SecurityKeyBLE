//
//  SHA256Tests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class SHA256Tests: XCTestCase {
    func testDigestFormats() {
        let hash = SHA256(data: "hello world".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let expectedB64 = "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
        XCTAssertEqual(expectedB64, hash.b64Digest)
        
        let expectedTuple: SHA256.TupleDigest = (185, 77, 39, 185, 147, 77, 62, 8, 165, 46, 82, 215, 218, 125, 171, 250, 196, 132, 239, 227, 122, 83, 128, 238, 144, 136, 247, 172, 226, 239, 205, 233)
        XCTAssert(tupleDigestEqual(expectedTuple, hash.tupleDigest))
    }
}
