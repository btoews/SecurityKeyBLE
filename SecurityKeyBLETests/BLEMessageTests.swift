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
    
//    func testRoundTripWithAPDU() {
//        let c1 = SHA256.tupleDigest("hello".dataUsingEncoding(NSUTF8StringEncoding)!)
//        let a1 = SHA256.tupleDigest("world".dataUsingEncoding(NSUTF8StringEncoding)!)
//        let r1 = U2F_REGISTER_REQ(chal: c1, appId: a1)
//        let m1 = BLEMessage(cmd: BLEMessage.Command.Msg, data: r1.apdu.raw!)
//        
//        let m2 = BLEMessage()
//        for fragment in m1 {
//            do {
//                try m2.readFragment(fragment)
//            } catch {
//                XCTAssert(false, "expected readFragment not to throw an exception")
//            }
//        }
//        
//        XCTAssert(m2.isComplete, "expected message to be comlete")
//        guard let r2 = APDUCommand(raw: m2.data!).registerRequest else {
//            return XCTAssert(false, "expected data to convert to register request")
//        }
//        
//        XCTAssert(tupleDigestEqual(r1.chal, r2.chal))
//        XCTAssert(tupleDigestEqual(r1.appId, r2.appId))
//        
//    }
}
