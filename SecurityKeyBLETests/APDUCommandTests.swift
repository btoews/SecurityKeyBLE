//
//  APDUCommandTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class APDUCommandTests: XCTestCase {
    func testRoundTrip() throws {
        let c = try SHA256.digest("world".dataUsingEncoding(NSUTF8StringEncoding)!)
        let a = try SHA256.digest("hello".dataUsingEncoding(NSUTF8StringEncoding)!)
        let r = RegisterRequest(challengeParameter: c, applicationParameter: a)
        
        let cmd1 = try APDUCommand(data: r)
        let cmd2 = try APDUCommand(raw: cmd1.raw)
        
        XCTAssertEqual(cmd1.header.raw, cmd2.header.raw)
        XCTAssertEqual(cmd1.data.raw, cmd2.data.raw)
    }
    
    func testCommandTypeForCode() {
        XCTAssert(APDUCommand.commandTypeForCode(.Register)          == RegisterRequest.self)
        XCTAssert(APDUCommand.commandTypeForCode(.Authenticate)      == AuthenticationRequest.self)
        XCTAssert(APDUCommand.commandTypeForCode(.Version)           == nil)
        XCTAssert(APDUCommand.commandTypeForCode(.CheckRegister)     == nil)
        XCTAssert(APDUCommand.commandTypeForCode(.AuthenticateBatch) == nil)
    }
}
