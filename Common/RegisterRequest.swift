//
//  RegisterRequest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/10/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

extension U2F_REGISTER_REQ {
    init(clientData: ClientData, apppId origin: NSData) {
        self.init()
        
        guard let challengeParam = clientData.digest else { return }
        chal = challengeParam
        appId = SHA256.tupleDigest(origin)
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