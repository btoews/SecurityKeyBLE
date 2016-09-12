//
//  DataWriterTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class DataWriterTests: XCTestCase {
    var writer = DataWriter()
    var newReader: DataReader { return DataReader(data: writer.buffer) }
    
    func setup() {
        writer = DataWriter()
    }
    
    func testWrite() throws {
        writer.write(UInt8(0x00))
        writer.write(UInt8(0xFF), endian: .Little)
        writer.write(UInt16(0x0102))
        writer.write(UInt16(0x0102), endian: .Little)
        writer.writeData("AB".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let reader = newReader
        let result:UInt64 = try reader.read()
        
        XCTAssertEqual(0x00FF010202014142, result)
    }
}
