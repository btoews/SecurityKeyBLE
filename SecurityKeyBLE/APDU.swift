//
//  APDU.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/8/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct APDUCommand: RawDataProtocol {
    var header: APDUCommandHeaderProtocol?
    var data: APDUCommandDataProtocol?
    
    var raw: NSData? {
        guard
            let h = header?.raw,
            let d = data?.raw
        else { return nil }

        let r = NSMutableData(data: h)
        r.appendData(d)

        return NSData(data: r)
    }
    
    var registerRequest: U2F_REGISTER_REQ? {
        return data as? U2F_REGISTER_REQ ?? nil
    }
    
    var valid: Bool {
        return header != nil && data != nil
    }
    
    init() {}
    
    init(data d: APDUCommandDataProtocol) {
        data = d
        
        if APDU_COMMAND_HEADER.LengthRange.contains(d.size) {
            header = APDU_COMMAND_HEADER(data: d)
        } else if EXTENDED_APDU_COMMAND_HEADER.LengthRange.contains(d.size) {
            header = EXTENDED_APDU_COMMAND_HEADER(data: d)
        }
    }
    
    init(raw: NSData) {
        var h: APDUCommandHeaderProtocol = APDU_COMMAND_HEADER(raw: raw)

        if h.length == 0 && raw.length != h.size {
            // LC1 is 0x00, but there's data. Might be extended.
            h = EXTENDED_APDU_COMMAND_HEADER(raw: raw)
        }
        
        if raw.length - h.size != h.length {
            // Length doesn't match data length.
            return
        }
        
        let dataRange = NSRange(location: h.size, length: raw.length - h.size)
        let dataRaw = raw.subdataWithRange(dataRange)
        
        switch h.ins {
        case UInt8(U2F_REGISTER):
            data = U2F_REGISTER_REQ(raw: dataRaw)
        case UInt8(U2F_AUTHENTICATE):
            data = U2F_AUTHENTICATE_REQ(raw: dataRaw)
        default:
            return // Unknown command code
        }
        
        header = h
    }
}

protocol APDUCommandDataProtocol: RawData {
    var cmdClass: UInt8 { get }
    var cmdCode:  UInt8 { get }
    var cmdP1:    UInt8 { get }
    var cmdP2:    UInt8 { get }
}

extension APDUCommandDataProtocol {
    var apdu: APDUCommand { return APDUCommand(data: self) }
}

extension U2F_REGISTER_REQ: APDUCommandDataProtocol {
    var cmdClass: UInt8 { return 0x00 }
    var cmdCode:  UInt8 { return UInt8(U2F_REGISTER) }
    var cmdP1:    UInt8 { return 0x00 }
    var cmdP2:    UInt8 { return 0x00 }
}

extension U2F_AUTHENTICATE_REQ: APDUCommandDataProtocol {
    var cmdClass: UInt8 { return 0x00 }
    var cmdCode:  UInt8 { return UInt8(U2F_AUTHENTICATE) }
    var cmdP1:    UInt8 { return 0x00 }
    var cmdP2:    UInt8 { return 0x00 }
}

protocol APDUCommandHeaderProtocol: RawData {
    static var LengthRange: Range<Int> { get }
    
    var cla:    UInt8  { get set }
    var ins:    UInt8  { get set }
    var p1:     UInt8  { get set }
    var p2:     UInt8  { get set }
    var length: Int    { get set }
}

extension APDUCommandHeaderProtocol {
    init(data: APDUCommandDataProtocol) {
        self.init()
        cla = data.cmdClass
        ins = data.cmdCode
        p1 = data.cmdP1
        p2 = data.cmdP2
        length = data.size
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

struct APDUResponse: RawDataProtocol {
    var data: APDUResponseDataProtocol?
    var trailer: APDU_RESPONSE_TRAILER?
    
    var raw: NSData? {
        guard
            let d = data?.raw,
            let t = trailer?.raw
        else { return nil }
        
        let r = NSMutableData(data: d)
        r.appendData(t)
        
        return NSData(data: r)
    }
    
    var valid: Bool {
        return data != nil && trailer != nil
    }
    
    init() {}
    
    init(raw: NSData) {
        if raw.length < APDU_RESPONSE_TRAILER.size { return }
        
        let tSize = APDU_RESPONSE_TRAILER.size
        
        let dRange = NSRange(location: 0, length: raw.length - tSize)
        switch dRange.length {
        case U2F_REGISTER_RESP.size:
            data = U2F_REGISTER_RESP(raw: raw.subdataWithRange(dRange))
        case U2F_AUTHENTICATE_RESP.size:
            data = U2F_AUTHENTICATE_RESP(raw: raw.subdataWithRange(dRange))
        default:
            return // Unknown response type
        }
        
        let tRange = NSRange(location: raw.length - tSize, length: tSize)
        trailer = APDU_RESPONSE_TRAILER(raw: raw.subdataWithRange(tRange))
    }
}

protocol APDUResponseDataProtocol: RawData {}
extension U2F_REGISTER_RESP:     APDUResponseDataProtocol {}
extension U2F_AUTHENTICATE_RESP: APDUResponseDataProtocol {}


extension APDU_RESPONSE_TRAILER: RawData {
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

// Protocol describing type that can be serialized to binary.
protocol RawDataProtocol {
    var raw: NSData? { get }
    
    init()
    init(raw: NSData)
}

// Helpers for converting C structs to/from data.
protocol RawData: RawDataProtocol {
    static var size: Int { get }
    var size: Int { get }
}

extension RawData {
    static var size:Int {
        return sizeof(Self)
    }
    
    var size: Int {
        return sizeof(Self)
    }
    
    var raw: NSData? {
        var tmp = self
        return NSData(bytes: &tmp, length: size)
    }
    
    init(raw: NSData) {
        self.init()
        raw.getBytes(&self, length: size)
    }
}