//
//  AuthenticationRequest.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

extension U2F_AUTHENTICATE_REQ: APDUCommandDataProtocol {
    var cmdClass: UInt8 { return 0x00 }
    var cmdCode:  UInt8 { return UInt8(U2F_AUTHENTICATE) }
    var cmdP1:    UInt8 { return 0x00 }
    var cmdP2:    UInt8 { return 0x00 }
}