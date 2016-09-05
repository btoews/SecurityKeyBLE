//
//  SecurityKeyBLETests.swift
//  SecurityKeyBLETests
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class SecurityKeyBLETests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

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

    func testMessageReadFragment() {
        let frags: [NSData] = [
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41]),
            NSData(chars:[0x00, 0x41])
        ]
        
        let m = Message()
        
        for frag in frags {
            do {
                try m.readFragment(frag)
            } catch {
                XCTAssert(false, "expected readFragment not to throw an error")
            }
            
        }
        
        XCTAssert(m.isComplete, "expected message to be complete")
        XCTAssertEqual(NSData(chars:[0x41, 0x41, 0x41, 0x41]), m.data)
        XCTAssertEqual(Message.Command.Ping, m.cmd)
        XCTAssertEqual(nil, m.status)
    }
    
    func testMessageInitWithData() {
        let d = randData()
        let m = Message(status: Message.Status.Error, data: d)
        
        XCTAssert(m.isComplete, "expected message to be complete")
        XCTAssertEqual(d, m.data)
        XCTAssertEqual(Message.Status.Error, m.status)
        XCTAssertEqual(nil, m.cmd)
    }
    
    func testMessageRoundTripData() {
        for _ in 0...100 {
            let d = randData()
            let m1 = Message(cmd: Message.Command.Msg, data: d)
            let m2 = Message()
            
            for fragment in m1 {
                do {
                    try m2.readFragment(fragment)
                } catch {
                    XCTAssert(false, "expected readFragment not to throw an exception")
                }
            }
            
            XCTAssert(m2.isComplete, "expected message to be comlete")
            XCTAssertEqual(m1.data, m2.data)
            XCTAssertEqual(m1.cmd, m2.cmd)
            XCTAssertEqual(m1.status, m2.status)
        }
    }
    
    func randData(maxLen: Int = 4096) -> NSData {
        let dLen = rand() % 4096
        let d = NSMutableData()
        for _ in 1...dLen {
            d.appendByte(UInt8(rand() % 256))
        }
        return NSData(data: d)
    }
}
