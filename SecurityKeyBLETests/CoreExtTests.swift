//
//  CoreExtTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class CoreExtTests: XCTestCase {
    func testCoreExtInitNSDataWithInt() {
        let input = 0x123456
        var expected: NSData
        var actual: NSData
        
        expected = NSData(chars: [0x12, 0x34, 0x56])
        actual = NSData(int: input, size: 3)
        XCTAssertEqual(expected, actual)
        
        expected = NSData(chars: [0x34, 0x56])
        actual = NSData(int: input, size: 2)
        XCTAssertEqual(expected, actual)
        
        expected = NSData(chars: [0x56, 0x34, 0x12])
        actual = NSData(int: input, size: 3, endian: .Little)
        XCTAssertEqual(expected, actual)
        
        expected = NSData(chars: [0x56, 0x34])
        actual = NSData(int: input, size: 2, endian: .Little)
        XCTAssertEqual(expected, actual)
    }
}
