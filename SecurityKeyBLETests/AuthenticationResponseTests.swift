//
//  AuthenticationResponseTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/14/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class AuthenticationResponseTests: XCTestCase {
    let userPresence = UInt8(0x01)
    let counter = UInt32(0x01020304)
    let signature = randData()
    
    func testRoundTrip() throws {
        let r1 = AuthenticationResponse(userPresence: userPresence, counter: counter, signature: signature)
        let r2 = try AuthenticationResponse(raw: r1.raw)
        
        XCTAssertEqual(r1.userPresence, r2.userPresence)
        XCTAssertEqual(r1.counter, r2.counter)
        XCTAssertEqual(r1.signature, r2.signature)
    }
    
    func testRoundTripAPDU() throws {
        let r1 = AuthenticationResponse(userPresence: userPresence, counter: counter, signature: signature)
        let a1 = try r1.apduWrapped()
        
        let a2 = try APDUResponse<AuthenticationResponse>(raw: a1.raw)
        let r2 = a2.data
        
        XCTAssertEqual(r1.userPresence, r2.userPresence)
        XCTAssertEqual(r1.counter, r2.counter)
        XCTAssertEqual(r1.signature, r2.signature)
    }
}
