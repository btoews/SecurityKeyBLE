//
//  Util.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class Util {
    enum Error: ErrorType {
        case BadCert
    }
    
    // Parse a DER formatted X509 certificate from the beginning of a datum and return its length.
    static func certLength(fromData d: NSData) throws -> Int {
        var size: Int = 0
        if SelfSignedCertificate.parseX509(d, consumed: &size) == 1 {
            return size
        } else {
            throw Error.BadCert
        }
    }
}