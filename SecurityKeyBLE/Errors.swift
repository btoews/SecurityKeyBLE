//
//  Errors.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

enum SecurityKeyError: ErrorType {
    case InvalidSequence
    case InvalidMessage
    case MessageComplete
}