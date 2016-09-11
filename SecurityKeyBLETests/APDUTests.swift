//
//  APDUTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/9/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class APDUTests: XCTestCase {
    func testU2FRegisterRequest() {
        let challenge = SHA256(data: "hello".dataUsingEncoding(NSUTF8StringEncoding)!)
        let appId = SHA256(data: "world".dataUsingEncoding(NSUTF8StringEncoding)!)
        let req = U2F_REGISTER_REQ(chal: challenge.tupleDigest, appId: appId.tupleDigest)
        
        // check data
        var expected = NSMutableData()
        expected.appendData(challenge.digest)
        expected.appendData(appId.digest)
        XCTAssertEqual(NSData(data: expected), req.raw)
        
        // check header
        guard let header = req.apdu.header else { return XCTFail("expected header not to be nil") }
        XCTAssertEqual(0x00, header.cla)
        XCTAssertEqual(0x01, header.ins)
        XCTAssertEqual(0x00, header.p1)
        XCTAssertEqual(0x00, header.p2)
        XCTAssertEqual(64, header.length)
        
        // check apdu
        expected = NSMutableData()
        expected.appendData(header.raw)
        expected.appendData(req.raw)
        XCTAssertEqual(NSData(data: expected), req.apdu.raw)
    }
    
    func testU2FRegisterRequestRoundTrip() {
        let challenge = SHA256.tupleDigest("hello".dataUsingEncoding(NSUTF8StringEncoding)!)
        let appId = SHA256.tupleDigest("world".dataUsingEncoding(NSUTF8StringEncoding)!)
        let expected = U2F_REGISTER_REQ(chal: challenge, appId: appId).apdu
        let actual = APDUCommand(raw: expected.raw!)
        
        let ar = actual.raw
        let er = expected.raw
        
        XCTAssertEqual(er, ar)
        XCTAssertEqual(expected.header?.raw, actual.header?.raw)
        XCTAssertEqual(expected.data?.raw, actual.data?.raw)
    }
    
    func testU2FRegisterResponse() {}
    
    func testExtendedHeaderLength() {
        var eh = EXTENDED_APDU_COMMAND_HEADER()
        
        eh.length = 0x1234
        XCTAssertEqual(0x1234, eh.length)
        XCTAssertEqual(0x00, eh.lc.0)
        XCTAssertEqual(0x12, eh.lc.1)
        XCTAssertEqual(0x34, eh.lc.2)
    }
}
