//
//  BLEMessageTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class BLEMessageTests: XCTestCase {
    func testMessageReadFragment() {
        let frags: [NSData] = [
            NSData(chars:[0x81, 0x00, 0x04, 0x41, 0x41, 0x41]),
            NSData(chars:[0x00, 0x41])
        ]
        
        let m = BLEMessage()
        
        for frag in frags {
            do {
                try m.readFragment(frag)
            } catch {
                XCTAssert(false, "expected readFragment not to throw an error")
            }
            
        }
        
        XCTAssert(m.isComplete, "expected message to be complete")
        XCTAssertEqual(NSData(chars:[0x41, 0x41, 0x41, 0x41]), m.data)
        XCTAssertEqual(BLEMessage.Command.Ping, m.cmd)
        XCTAssertEqual(nil, m.status)
    }
    
    func testMessageInitWithData() {
        let d = randData()
        let m = BLEMessage(status: BLEMessage.Status.Error, data: d)
        
        XCTAssert(m.isComplete, "expected message to be complete")
        XCTAssertEqual(d, m.data)
        XCTAssertEqual(BLEMessage.Status.Error, m.status)
        XCTAssertEqual(nil, m.cmd)
    }
    
    func testMessageRoundTripData() {
        for _ in 0...100 {
            let d = randData()
            let m1 = BLEMessage(cmd: BLEMessage.Command.Msg, data: d)
            let m2 = BLEMessage()
            
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
