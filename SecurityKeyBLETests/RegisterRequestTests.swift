//
//  RegisterRequestTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class RegisterRequestTests: XCTestCase {
    var c:NSData?
    var a:NSData?
    
    override func setUp() {
        super.setUp()

        do {
            c = try SHA256.digest("world".dataUsingEncoding(NSUTF8StringEncoding)!)
            a = try SHA256.digest("hello".dataUsingEncoding(NSUTF8StringEncoding)!)
        } catch {
            XCTFail("couldn't initialize fixtures")
        }
    }
    
    func testRoundTrip() throws {
        let r1 = RegisterRequest(challengeParameter: c!, applicationParameter: a!)
        let r2 = try RegisterRequest(raw: r1.raw)
        
        XCTAssertEqual(r1.challengeParameter, r2.challengeParameter)
        XCTAssertEqual(r1.applicationParameter, r2.applicationParameter)
    }
    
    func testAPDURoundTrip() throws {
        let r1 = RegisterRequest(challengeParameter: c!, applicationParameter: a!)
        let apdu1 = try r1.apduWrapped()
        
        let apdu2 = try APDUCommand(raw: apdu1.raw)
        
        guard let r2 = apdu2.registerRequest else {
            return XCTFail("expected apdu to have a register request")
        }
        
        XCTAssertEqual(r1.challengeParameter, r2.challengeParameter)
        XCTAssertEqual(r1.applicationParameter, r2.applicationParameter)
    }
}
