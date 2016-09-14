//
//  AuthenticationRequestTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/14/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class AuthenticationRequestTests: XCTestCase {
    var chal:NSData?
    var app:NSData?
    var kh:NSData?
    
    override func setUp() {
        super.setUp()

        do {
            chal = try ClientData(typ: .Authenticate, origin: "https://foobar.com").digest()
            app = try SHA256.digest("https://foobar.com".dataUsingEncoding(NSUTF8StringEncoding)!)
            kh = randData(length: 32)
        } catch {
            XCTFail("couldn't initialize fixtures")
        }
    }

    func testRoundTrip() throws {
        let a1 = AuthenticationRequest(control: .CheckOnly, challengeParameter: chal!, applicationParameter: app!, keyHandle: kh!)
        let a2 = try AuthenticationRequest(raw: a1.raw)
        
        XCTAssertEqual(a1.control, a2.control)
        XCTAssertEqual(a1.challengeParameter, a2.challengeParameter)
        XCTAssertEqual(a1.applicationParameter, a2.applicationParameter)
        XCTAssertEqual(a1.keyHandle, a2.keyHandle)
    }
    
    func testAPDURoundTrip() throws {
        let a1 = AuthenticationRequest(control: .CheckOnly, challengeParameter: chal!, applicationParameter: app!, keyHandle: kh!)
        let apdu1 = try a1.apduWrapped()
        
        let apdu2 = try APDUCommand(raw: apdu1.raw)
        guard let a2 = apdu2.authenticationRequest else {
            return XCTFail("expected apdu to have an auth request")
        }
        
        XCTAssertEqual(a1.control, a2.control)
        XCTAssertEqual(a1.challengeParameter, a2.challengeParameter)
        XCTAssertEqual(a1.applicationParameter, a2.applicationParameter)
        XCTAssertEqual(a1.keyHandle, a2.keyHandle)
    }
}
