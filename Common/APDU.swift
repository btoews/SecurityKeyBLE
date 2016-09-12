//
//  APDU.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/8/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct APDUHeader {
    var cmdClass: UInt8
}

protocol APDUMessage {
    init(raw: NSData) throws
    func getRaw() throws -> NSData
    func getSize() throws -> Int
}

protocol APDUCommandDataProtocol: RawStruct {
    var cmdClass: UInt8 { get }
    var cmdCode:  UInt8 { get }
    var cmdP1:    UInt8 { get }
    var cmdP2:    UInt8 { get }
}

extension APDUCommandDataProtocol {
    func buildAPDU() throws -> APDUCommand {
        let apdu = try APDUCommand(data: self)
        return apdu
    }
}

protocol APDUCommandHeaderProtocol: RawStruct {
    static var LengthRange: Range<Int> { get }
    
    var cla:    UInt8  { get set }
    var ins:    UInt8  { get set }
    var p1:     UInt8  { get set }
    var p2:     UInt8  { get set }
    var length: Int    { get set }
}

extension APDUCommandHeaderProtocol {
    init(data: APDUCommandDataProtocol) throws {
        self.init()
        cla = data.cmdClass
        ins = data.cmdCode
        p1 = data.cmdP1
        p2 = data.cmdP2
        length = try data.getSize()
    }
}

extension APDU_COMMAND_HEADER: APDUCommandHeaderProtocol {
    static var LengthRange = 1...255

    var length: Int {
        get {
            return Int(lc)
        }
        
        set(newValue) {
            lc = UInt8(newValue)
        }
    }
}

extension EXTENDED_APDU_COMMAND_HEADER: APDUCommandHeaderProtocol {
    static var LengthRange = 1...65535
    
    var length: Int {
        get {
            return (Int(lc.1) << 8) | Int(lc.2)
        }
        
        set(newValue) {
            lc.0 = 0x00
            lc.1 = UInt8((newValue >> 8) & 0xFF)
            lc.2 = UInt8(newValue & 0xFF)
        }
    }
}

protocol APDUResponseDataProtocol: RawData {}
extension U2F_REGISTER_RESP:     RawStruct, APDUResponseDataProtocol {}
extension U2F_AUTHENTICATE_RESP: RawStruct, APDUResponseDataProtocol {}


extension APDU_RESPONSE_TRAILER: RawStruct {
    var status: Int {
        get {
            return (Int(sw1) << 8) & Int(sw2)
        }
        set(newValue) {
            sw1 = UInt8((newValue >> 8) & 0xFF)
            sw2 = UInt8(newValue & 0xFF)
        }
    }
}

// Helpers for converting C structs to/from data.
protocol RawData {
    init(raw: NSData) throws
    func getRaw() throws -> NSData
    func getSize() throws -> Int
}

protocol RawStruct: RawData {}
extension RawStruct {
    init() {
        self.init()
    }
    
    init(raw r: NSData) {
        self.init()
        r.getBytes(&self, length: sizeof(Self))
    }
    
    func getRaw() throws -> NSData {
        var tmp = self
        return NSData(bytes: &tmp, length: sizeof(Self))
    }
    
    func getSize() throws -> Int {
        return sizeof(Self)
    }
}