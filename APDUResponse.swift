//
//  APDUResponse.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

struct APDUResponse: APDUMessage {
    enum Error: ErrorType {
        case MissingData
        case MissingTrailer
        case InvalidSize
    }
    
    var data: APDUResponseDataProtocol
    var trailer: APDU_RESPONSE_TRAILER
    
    init(raw: NSData) throws {
        if raw.length < sizeof(APDU_RESPONSE_TRAILER) { throw Error.InvalidSize }
        
        let tSize = sizeof(APDU_RESPONSE_TRAILER)
        let dRange = NSRange(location: 0, length: raw.length - tSize)
        
        switch dRange.length {
        case sizeof(U2F_REGISTER_RESP):
            data = U2F_REGISTER_RESP(raw: raw.subdataWithRange(dRange))
        case sizeof(U2F_AUTHENTICATE_RESP):
            data = U2F_AUTHENTICATE_RESP(raw: raw.subdataWithRange(dRange))
        default:
            throw Error.InvalidSize
        }
        
        let tRange = NSRange(location: raw.length - tSize, length: tSize)
        trailer = APDU_RESPONSE_TRAILER(raw: raw.subdataWithRange(tRange))
    }
    
    func getRaw() throws -> NSData {
        let dRaw = try data.getRaw()
        let tRaw = try trailer.getRaw()
        
        let r = NSMutableData()
        r.appendData(dRaw)
        r.appendData(tRaw)
        
        return r
    }
    
    
    func getSize() throws -> Int {
        let dSize = try data.getSize()
        let tSize = try trailer.getSize()
        return dSize + tSize
    }
}