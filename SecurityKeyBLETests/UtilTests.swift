//
//  UtilTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class UtilTests: XCTestCase {
    func testCertLength() throws {
        let crt = SelfSignedCertificate()
        let crtData = NSMutableData(data: crt.toDer())
        crtData.appendData("blah blah blah".dataUsingEncoding(NSUTF8StringEncoding)!)

        let expected = crt.toDer().length
        let actual = try Util.certLength(fromData: crtData)
        XCTAssertEqual(expected, actual)
    }
}
