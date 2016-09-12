//
//  DataWriter.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class DataWriter {
    var buffer = NSMutableData()
    
    func write<T: EndianProtocol>(val:T, endian: Endian = .Big) {
        var eval: T
        
        switch endian {
        case .Big:
            eval = val.bigEndian
        case .Little:
            eval = val.littleEndian
        }
        
        buffer.appendBytes(&eval, length: sizeof(T))
    }
    
    func writeData(d: NSData) {
        buffer.appendData(d)
    }
}