//
//  RegisterResponseTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class RegisterResponseTests: XCTestCase {
    
    func testCertLength() {
        let crt = SelfSignedCertificate()
        let crtData = NSMutableData(data: crt.toDer())
        crtData.appendData("blah blah blah".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        var size: Int = 0
        XCTAssertEqual(1, SelfSignedCertificate.parseX509(crtData, consumed: &size))
        XCTAssertEqual(crt.toDer().length, size)
    }
}
