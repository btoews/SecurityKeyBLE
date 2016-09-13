//
//  BLEMessageTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class BLEMessageTests: XCTestCase {

    
    func testMessageInitWithStatus() {
        let d = randData()
        let m = BLEMessage(status: BLEMessage.Status.Error, data: d)
        
        XCTAssertEqual(d, m.data)
        XCTAssertEqual(BLEMessage.Status.Error, m.commandOrStatus.status)
        XCTAssertNil(m.commandOrStatus.command)
    }

    func testMessageInitWithCommand() {
        let d = randData()
        let m = BLEMessage(command: BLEMessage.Command.Msg, data: d)
        
        XCTAssertEqual(d, m.data)
        XCTAssertNil(m.commandOrStatus.status)
        XCTAssertEqual(BLEMessage.Command.Msg, m.commandOrStatus.command)
    }
    
    func testMessageRoundTripData() throws {
        let m1 = BLEMessage(command: BLEMessage.Command.Msg, data: randData())
        let r = BLEFragmentReader()
        
        for fragment in m1.fragments {
            try r.readFragment(fragment)
        }
        
        XCTAssertTrue(r.isComplete)
        let m2 = r.message!

        XCTAssertEqual(m1.commandOrStatus, m2.commandOrStatus)
        XCTAssertEqual(m1.data, m2.data)
    }
    
    func testRoundTripWithRequest() throws {
        let c1 = try SHA256.digest("hello".dataUsingEncoding(NSUTF8StringEncoding)!)
        let a1 = try SHA256.digest("world".dataUsingEncoding(NSUTF8StringEncoding)!)
        let r1 = RegisterRequest(challengeParameter: c1, applicationParameter: a1)
        
        let m1 = try r1.bleWrapped()
        let reader = BLEFragmentReader()
        for frag in m1.fragments { try reader.readFragment(frag) }
        
        XCTAssertTrue(reader.isComplete)
        guard let m2 = reader.message else {
            return XCTFail("expected m2 to have a message")
        }
        
        XCTAssertEqual(m2.commandOrStatus.command, .Msg)
        let apdu:APDUCommand = try m2.unwrapAPDU()
        
        XCTAssert(apdu.commandType == RegisterRequest.self, "expected command type to be register request")
        let r2 = apdu.data as! RegisterRequest
        
        XCTAssertEqual(r1.applicationParameter, r2.applicationParameter)
        XCTAssertEqual(r1.challengeParameter, r2.challengeParameter)
    }
}
