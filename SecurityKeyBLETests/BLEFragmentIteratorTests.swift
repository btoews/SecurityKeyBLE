//
//  BLEFragmentIteratorTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class BLEFragmentIteratorTests: XCTestCase {
    func testFragments() {
        let dlen = (CharacteristicMaxSize - 3) + (CharacteristicMaxSize - 1) + 1
        let data = NSData(chars: [UInt8](count: dlen, repeatedValue: 0xF0))
        let message = BLEMessage(command: .Msg, data: data)
        var frags = message.fragments.generate()
        
        var expected = DataWriter()
        expected.write(BLEMessage.Command.Msg.rawValue)
        expected.write(UInt16(dlen))
        expected.writeData(NSData(chars: [UInt8](count: CharacteristicMaxSize - 3, repeatedValue: 0xF0)))
        XCTAssertEqual(expected.buffer, frags.next())
        
        expected = DataWriter()
        expected.write(UInt8(0x00))
        expected.writeData(NSData(chars: [UInt8](count: CharacteristicMaxSize - 1, repeatedValue: 0xF0)))
        XCTAssertEqual(expected.buffer, frags.next())
        
        expected = DataWriter()
        expected.write(UInt8(0x01))
        expected.write(UInt8(0xF0))
        XCTAssertEqual(expected.buffer, frags.next())
    }
}
