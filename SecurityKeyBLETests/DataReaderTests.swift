//
//  DataReaderTests.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import XCTest

class DataReaderTests: XCTestCase {
    func testUInt8() throws {
        var raw:[UInt8] = [0x00, 0x01, 0x02]
        let data = NSData(bytes: &raw, length: raw.count)
        let reader = DataReader(data: data, offset: 1)
        var ores:UInt8?
        var res:UInt8
        
        XCTAssertEqual(2, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x01)
        XCTAssertEqual(2, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x01)
        
        XCTAssertEqual(1, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x02)
        XCTAssertEqual(1, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x02)
        
        XCTAssertEqual(0, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, nil)
        XCTAssertEqual(0, reader.remaining)
        
        do {
            res = try reader.read()
            XCTAssert(false, "expected exception")
        } catch DataReader.Error.End {
            // pass
        }
        
        XCTAssertEqual(0, reader.remaining)
    }
    
    func testUInt16() throws {
        var raw:[UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04]
        let data = NSData(bytes: &raw, length: raw.count)
        let reader = DataReader(data: data, offset: 0)
        var ores:UInt16?
        var res:UInt16
        
        XCTAssertEqual(5, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, 0x0001)
        XCTAssertEqual(5, reader.remaining)
        res = try reader.read()
        XCTAssertEqual(res, 0x0001)
        
        XCTAssertEqual(3, reader.remaining)
        ores = reader.peek(endian: .Little)
        XCTAssertEqual(ores, 0x0302)
        XCTAssertEqual(3, reader.remaining)
        res = try reader.read(endian: .Little)
        XCTAssertEqual(res, 0x0302)
        
        XCTAssertEqual(1, reader.remaining)
        ores = reader.peek()
        XCTAssertEqual(ores, nil)
        
        do {
            res = try reader.read()
            XCTAssert(false, "expected exception")
        } catch DataReader.Error.End {
            // pass
        }
        
        XCTAssertEqual(1, reader.remaining)
    }
    
    func testReadBytes() throws {
        var raw:[UInt8] = [0x00, 0x01, 0x02, 0x03, 0x04]
        let data = NSData(bytes: &raw, length: raw.count)
        let reader = DataReader(data: data, offset: 0)
        var ores: NSData?
        var res: NSData
        
        let expected = data.subdataWithRange(NSMakeRange(0, 2))
        XCTAssertEqual(5, reader.remaining)
        ores = reader.peekData(2)
        XCTAssertEqual(ores, expected)
        XCTAssertEqual(5, reader.remaining)
        res = try reader.readData(2)
        XCTAssertEqual(res, expected)
        
        XCTAssertEqual(3, reader.remaining)
        ores = reader.peekData(4)
        XCTAssertEqual(ores, nil)
        XCTAssertEqual(3, reader.remaining)
        
        do {
            res = try reader.readData(4)
            XCTAssert(false, "expected exception")
        } catch DataReader.Error.End {
            // pass
        }
        
        XCTAssertEqual(3, reader.remaining)
    }
}
