//
//  RegisterRequestTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class RegisterRequestTests: XCTestCase {
    func testRoundTrip() throws {
        let req = try U2F_REGISTER_REQ(challenge: "hello", origin: "world")
        XCTAssertNotNil(req) // silence compiler warning
    }
}
