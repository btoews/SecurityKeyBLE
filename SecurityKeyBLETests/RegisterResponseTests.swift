//
//  RegisterResponseTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class RegisterResponseTests: XCTestCase {
    let pk  = randData(length: sizeof(U2F_EC_POINT))
    let kh  = randData(length: 50)
    let crt = SelfSignedCertificate().toDer()
    let sig = randData(length: 20)
    
    func testRoundTrip() throws {
        let r1 = RegisterResponse(publicKey: pk, keyHandle: kh, certificate: crt, signature: sig)
        let r2 = try RegisterResponse(raw: r1.raw)
        
        XCTAssertEqual(r1.publicKey, r2.publicKey)
        XCTAssertEqual(r1.keyHandle, r2.keyHandle)
        XCTAssertEqual(r1.certificate, r2.certificate)
        XCTAssertEqual(r1.signature, r2.signature)
    }
    
    func testAPDURoundTrip() throws {
        let r1 = RegisterResponse(publicKey: pk, keyHandle: kh, certificate: crt, signature: sig)
        let apdu1 = try r1.apduWrapped()
        
        let apdu2 = try APDUResponse<RegisterResponse>(raw: apdu1.raw)
        let r2 = apdu2.data
        
        XCTAssertEqual(r1.publicKey, r2.publicKey)
        XCTAssertEqual(r1.keyHandle, r2.keyHandle)
        XCTAssertEqual(r1.certificate, r2.certificate)
        XCTAssertEqual(r1.signature, r2.signature)
    }
    
    func testCertLength() throws {
        let crt = SelfSignedCertificate()
        let crtData = NSMutableData(data: crt.toDer())
        crtData.appendData("blah blah blah".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let expected = crt.toDer().length
        let actual = try RegisterResponse.certLength(fromData: crtData)
        XCTAssertEqual(expected, actual)
    }
}
