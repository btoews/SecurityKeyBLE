//
//  SecurityKeyBLETests.swift
//  SecurityKeyBLETests
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class SecurityKeyBLETests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUnpackClientRequest() {
        var packedString: [UInt8] = [0x81, 0x12, 0x34, 0x41, 0x41, 0x41, 0x41]
        let packedData = NSData(bytes: &packedString, length: packedString.count)
        let cr = ClientRequest(rawData: packedData)

        XCTAssertEqual(ClientRequestCommand.Ping, cr.cmd)
        XCTAssertEqual(0x12, cr.hLen)
        XCTAssertEqual(0x34, cr.lLen)
        XCTAssertEqual("AAAA", String(data: cr.data, encoding: NSASCIIStringEncoding))
    }
    
    func testPackAuthenticatorResponse() {
        let ar = AuthenticatorResponse(stat: .KeepAlive, data: "AAAA".dataUsingEncoding(NSASCIIStringEncoding)!)
        
        var expectedString: [UInt8] = [0x82, 0x00, 0x04, 0x41, 0x41, 0x41, 0x41]
        let expected = NSData(bytes: &expectedString, length: expectedString.count)
        
        XCTAssertEqual(expected, ar.rawData)
    }
}
