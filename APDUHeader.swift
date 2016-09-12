//
//  APDUCommandHeader.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct APDUHeader {
    enum CommandClass: UInt8 {
        case Reserved = 0x00
    }
    
    enum CommandCode: UInt8 {
        case Register          = 0x01
        case Authenticate      = 0x02
        case Version           = 0x03
        case CheckRegister     = 0x04
        case AuthenticateBatch = 0x05
    }
    
    var cla: CommandClass
    var ins: CommandCode
    var p1:  UInt8 = 0x00
    var p2:  UInt8 = 0x00
    var dataLength: Int
    
    init(cmdData: APDUCommandDataProtocol) throws {
        cla = cmdData.cmdClass
        ins = cmdData.cmdCode
        dataLength = cmdData.raw.length
        if dataLength > 0xFFFF { throw APDUError.BadSize }
    }
    
    init(raw: NSData) throws {
        var offset = 0
        var range: NSRange
        var byte: UInt8 = 0
        
        var lc0: UInt8 = 0
        var lc1: UInt8 = 0
        var lc2: UInt8 = 0
        
        range = NSMakeRange(offset, 1)
        if raw.length < range.location + range.length { throw APDUError.BadSize }
        raw.getBytes(&byte, range: range)
        guard let tmpCla = CommandClass(rawValue: byte) else { throw APDUError.BadClass }
        cla = tmpCla
        offset += range.length
        
        range = NSMakeRange(offset, 1)
        if raw.length < range.location + range.length { throw APDUError.BadSize }
        raw.getBytes(&byte, range: range)
        guard let tmpIns = CommandCode(rawValue: byte) else { throw APDUError.BadCode }
        ins = tmpIns
        offset += range.length
        
        range = NSMakeRange(offset, 1)
        if raw.length < range.location + range.length { throw APDUError.BadSize }
        raw.getBytes(&byte, range: range)
        p1 = byte
        offset += range.length
        
        range = NSMakeRange(offset, 1)
        if raw.length < range.location + range.length { throw APDUError.BadSize }
        raw.getBytes(&byte, range: range)
        p2 = byte
        offset += range.length

        range = NSMakeRange(offset, 1)
        if raw.length < range.location + range.length { throw APDUError.BadSize }
        raw.getBytes(&lc0, range: range)
        offset += range.length
        
        if lc0 == 0 {
            range = NSMakeRange(offset, 1)
            if raw.length < range.location + range.length { throw APDUError.BadSize }
            raw.getBytes(&lc1, range: range)
            offset += range.length
            
            range = NSMakeRange(offset, 1)
            if raw.length < range.location + range.length { throw APDUError.BadSize }
            raw.getBytes(&lc2, range: range)
            offset += range.length
            
            dataLength = (Int(lc1) << 8) & Int(lc2)
        } else {
            dataLength = Int(lc0)
        }
    }
    
    var raw: NSData {
        let m = NSMutableData()
        m.appendByte(cla.rawValue)
        m.appendByte(ins.rawValue)
        m.appendByte(p1)
        m.appendByte(p2)
        
        if dataLength <= 0xFF {
            m.appendByte(UInt8(dataLength))
        } else {
            m.appendByte(0x00)
            m.appendInt(dataLength, size: 2)
        }
        
        return m
    }
}