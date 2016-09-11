//
//  RegisterRequest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

extension U2F_REGISTER_REQ {
    init(challenge: String, origin: String) throws {
        self.init()
        
        let cd = ClientData(typ: .Register, challenge: challenge, origin: origin)
        chal = try cd.digest()
        appId = try SHA256.tupleDigest(origin)
    }
    
    var appIdData: NSData {
        var tmp = appId
        return NSData(bytes: &tmp, length: Int(U2F_APPID_SIZE))
    }
    
    var challengeData: NSData {
        var tmp = chal
        return NSData(bytes: &tmp, length: Int(U2F_CHAL_SIZE))
    }
}