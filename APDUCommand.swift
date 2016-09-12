//
//  APDUCommand.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct APDUCommand: APDUMessage {
    enum Error: ErrorType {
        case MissingHeader
        case MissingData
        case InvalidHeader
        case UnknownCommand
        case MessageTooLarge
    }
    
    var header: APDUCommandHeaderProtocol
    var data: APDUCommandDataProtocol
    
    init(data d: APDUCommandDataProtocol) throws {
        data = d
        let dSize = try data.getSize()
        
        if APDU_COMMAND_HEADER.LengthRange.contains(dSize) {
            header = try APDU_COMMAND_HEADER(data: d)
        } else if EXTENDED_APDU_COMMAND_HEADER.LengthRange.contains(dSize) {
            header = try EXTENDED_APDU_COMMAND_HEADER(data: d)
        } else {
            throw Error.MessageTooLarge
        }
    }
    
    init(raw: NSData) throws {
        var h: APDUCommandHeaderProtocol = APDU_COMMAND_HEADER(raw: raw)
        var hSize = try h.getSize()
        
        if h.length == 0 && raw.length != hSize {
            // LC1 is 0x00, but there's data. Might be extended.
            h = EXTENDED_APDU_COMMAND_HEADER(raw: raw)
        }
        
        hSize = try h.getSize()
        if raw.length - hSize != h.length {
            throw Error.InvalidHeader
        }
        
        let dataRange = NSRange(location: hSize, length: raw.length - hSize)
        let dataRaw = raw.subdataWithRange(dataRange)
        
        switch h.ins {
        case UInt8(U2F_REGISTER):
            data = U2F_REGISTER_REQ(raw: dataRaw)
        case UInt8(U2F_AUTHENTICATE):
            data = U2F_AUTHENTICATE_REQ(raw: dataRaw)
        default:
            throw Error.UnknownCommand
        }
        
        header = h
    }
    
    func getRaw() throws -> NSData {
        let hRaw = try header.getRaw()
        let dRaw = try data.getRaw()
        
        let r = NSMutableData()
        r.appendData(hRaw)
        r.appendData(dRaw)
        
        return r
    }
    
    func getSize() throws -> Int {
        let hSize = try header.getSize()
        let dSize = try data.getSize()
        return hSize + dSize
    }
}
