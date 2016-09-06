//
//  CoreExtensions.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

enum Endian {
    case Big
    case Little
}

extension NSMutableData {
    func appendInt(int: Int, size: Int, endian: Endian = .Big) {
        appendData(NSData(int: int, size: size, endian: endian))
    }
    
    func appendByte(byte: UInt8) {
        var tmp = byte
        appendBytes(&tmp, length: 1)
    }
}

extension NSData {
    convenience init(int: Int, size: Int, endian: Endian = .Big) {
        var vBytes = [UInt8]()

        for i in 0..<size {
            let byte = UInt8((int >> ((size - i - 1) * 8)) & 0xFF)

            switch endian {
            case .Big:
                vBytes.append(byte)
            case .Little:
                vBytes.insert(byte, atIndex: 0)
            }
        }
        
        self.init(bytes: &vBytes, length: size)
    }
    
    convenience init(chars: [UInt8]) {
        var vChars = chars
        self.init(bytes: &vChars, length: vChars.count)
    }

    func getByte(index: Int) -> UInt8? {
        if index > length { return nil }
        var byte: UInt8 = 0
        let range = NSRange(location: index, length: 1)
        getBytes(&byte, range: range)
        return byte
    }
    
    func getInt(size: Int, endian: Endian = .Big) -> Int {
        var int = 0
        var byte: UInt8 = 0
    
        for i in 0..<size {
            getBytes(&byte, range: NSRange(location: i, length: 1))

            switch endian {
            case .Big:
                int += Int(byte) << ((size - i - 1) * 8)
            case .Little: ()
                int += Int(byte) << i * 8
            }
        }
        
        return int
    }
}