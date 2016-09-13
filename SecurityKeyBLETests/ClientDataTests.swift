//
//  ClientDataTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class ClientDataTests: XCTestCase {
    func testSerialize() throws {
        let cd = ClientData(typ: .Register, origin: "zxcv")
        
        let expectedJSON = "{\"challenge\":\"\(cd.challenge)\",\"typ\":\"navigator.id.finishEnrollment\",\"origin\":\"zxcv\"}".dataUsingEncoding(NSUTF8StringEncoding)
        let actualJSON = try cd.toJSON()
        XCTAssertEqual(expectedJSON, actualJSON)
    }
}
