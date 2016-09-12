//
//  BLEFragmentReaderTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class BLEFragmentReaderTests: XCTestCase {
    func testReadMultipleFragments() throws {
        let frags = (
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41]),
            NSData(chars:[0x00, 0x41])
        )
        
        let r = BLEFragmentReader()
        
        try r.readFragment(frags.0)
        XCTAssertFalse(r.isComplete)
        XCTAssertNil(r.message)
        
        try r.readFragment(frags.1)
        XCTAssertTrue(r.isComplete)

        guard let message = r.message else {
            return XCTFail("expected reader to have a message")
        }

        XCTAssertEqual(NSData(chars:[0x41, 0x41, 0x41, 0x41]), message.data)
        XCTAssertEqual(BLEMessage.Command.Ping, message.commandOrStatus.command)
        
        XCTAssertThrowsError(try r.readFragment(frags.1)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .MessageComplete)
        }
    }
    
    func testReadOneShotFragment() throws {
        let frag = NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41, 0x41])
        
        let r = BLEFragmentReader()
        try r.readFragment(frag)
        
        XCTAssertTrue(r.isComplete)
        
        guard let message = r.message else {
            return XCTFail("expected reader to have a message")
        }
        
        XCTAssertEqual(NSData(chars:[0x41, 0x41, 0x41, 0x41]), message.data)
        XCTAssertEqual(BLEMessage.Command.Ping, message.commandOrStatus.command)
    }
    
    func testBadCmd() throws {
        let frag = NSData(chars:[0x99, 0x00, 0x04, 0x41, 0x41, 0x41])
        
        let r = BLEFragmentReader()
        
        XCTAssertThrowsError(try r.readFragment(frag)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidHeader)
        }
        
        XCTAssertFalse(r.isComplete)
        XCTAssertNil(r.message)
    }
    
    func testMsgTooLong() throws {
        let frag = NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41, 0x41, 0xFF])
        
        let r = BLEFragmentReader()
        
        XCTAssertThrowsError(try r.readFragment(frag)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidMessage)
        }
        
        XCTAssertFalse(r.isComplete)
        XCTAssertNil(r.message)
    }
    
    func testMsgTooShort() throws {
        let frag = NSData(chars:[0x81])
        
        let r = BLEFragmentReader()
        
        XCTAssertThrowsError(try r.readFragment(frag)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidHeader)
        }
        
        XCTAssertFalse(r.isComplete)
        XCTAssertNil(r.message)
    }
    
    func testBadFirstSequence() throws {
        let frags = (
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41]),
            NSData(chars:[0x01, 0x41])
        )
        
        let r = BLEFragmentReader()
        try r.readFragment(frags.0)
        
        XCTAssertThrowsError(try r.readFragment(frags.1)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidSequence)
        }
    }
    
    func testBadSecondSequence() throws {
        let frags = (
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41]),
            NSData(chars:[0x00, 0x41]),
            NSData(chars:[0x02, 0x41])
        )
        
        let r = BLEFragmentReader()
        try r.readFragment(frags.0)
        try r.readFragment(frags.1)
        
        XCTAssertThrowsError(try r.readFragment(frags.2)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidSequence)
        }
    }

    func testBadOrder() throws {
        let frags = (
            NSData(chars:[0x01, 0x41]),
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41])
        )
        
        let r = BLEFragmentReader()
        
        XCTAssertThrowsError(try r.readFragment(frags.0)) { error in
            XCTAssertEqual(error as? BLEFragmentReader.Error, .InvalidSequence)
        }
    }
}
