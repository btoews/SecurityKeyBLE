//
//  WebSafeBase64Tests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/13/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class WebSafeBase64Tests: XCTestCase {
    func testRoundTrip() {
        for length in 0...10 {
            let orig = String(count: length, repeatedValue: Character("A")).dataUsingEncoding(NSUTF8StringEncoding)!
            let encoded = WebSafeBase64.encodeData(orig)
            
            XCTAssertNil(encoded.characters.indexOf(Character("+")))
            XCTAssertNil(encoded.characters.indexOf(Character("/")))
            XCTAssertNil(encoded.characters.indexOf(Character("=")))
            
            let decoded = WebSafeBase64.decodeString(encoded)
            XCTAssertNotNil(decoded)
            XCTAssertEqual(orig, decoded)
        }
    }
}
