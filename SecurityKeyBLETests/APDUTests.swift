//
//  APDUTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/9/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class APDUTests: XCTestCase {
    func testU2FRegisterRequest() throws {
        let challenge = try SHA256.tupleDigest("hello")
        let appId = try SHA256.tupleDigest("world")
        let req = U2F_REGISTER_REQ(chal: challenge, appId: appId)

        var expected = NSMutableData()
        expected.appendData(try SHA256.digest("hello"))
        expected.appendData(try SHA256.digest("world"))
        XCTAssertEqual(NSData(data: expected), req.raw)
        
        guard let header = req.apdu.header else {
            return XCTFail("expected header not to be nil")
        }
        
        XCTAssertEqual(0x00, header.cla)
        XCTAssertEqual(0x01, header.ins)
        XCTAssertEqual(0x00, header.p1)
        XCTAssertEqual(0x00, header.p2)
        XCTAssertEqual(64, header.length)
        
        expected = NSMutableData()
        expected.appendByte(0x00)
        expected.appendByte(0x01)
        expected.appendByte(0x00)
        expected.appendByte(0x00)
        expected.appendByte(0x40)
        XCTAssertEqual(NSData(data: expected), header.raw)
        
        guard let realHeader = header as? APDU_COMMAND_HEADER else {
            return XCTFail("expected header to be APDU_COMMAND_HEADER")
        }

        XCTAssertEqual(64, realHeader.lc)
        
        expected = NSMutableData()
        expected.appendData(header.raw!)
        expected.appendData(req.raw!)
        XCTAssertEqual(NSData(data: expected), req.apdu.raw)
    }
    
    func testRoundTrip() throws {
        let challenge = try SHA256.tupleDigest("hello")
        let appId = try SHA256.tupleDigest("world")
        let expected = U2F_REGISTER_REQ(chal: challenge, appId: appId).apdu
        let actual = APDUCommand(raw: expected.raw!)
        
        XCTAssertEqual(expected.raw, actual.raw)
        XCTAssertEqual(expected.header!.raw, actual.header!.raw)
        XCTAssertEqual(expected.data!.raw, actual.data!.raw)
    }
    
    func testExtendedHeaderLength() {
        var eh = EXTENDED_APDU_COMMAND_HEADER()
        
        eh.length = 0x1234
        XCTAssertEqual(0x1234, eh.length)
        XCTAssertEqual(0x00, eh.lc.0)
        XCTAssertEqual(0x12, eh.lc.1)
        XCTAssertEqual(0x34, eh.lc.2)
    }
}
