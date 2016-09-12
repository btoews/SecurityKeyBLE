//
//  DataReader.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/11/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class DataReader {
    enum Error: ErrorType {
        case End
    }
    
    enum Endian {
        case Big
        case Little
    }
    
    var data: NSData
    var offset: Int

    // How many bytes are left
    var remaining: Int { return data.length - offset }
    
    // The remaining data
    var rest: NSData { return data.subdataWithRange(NSMakeRange(offset, data.length - offset)) }
    
    init(data d: NSData, offset o: Int = 0) {
        data = d
        offset = o
    }
    
    // Read a number from the data, advancing our offset into the data.
    func read<T:EndianProtocol>(endian endian: Endian = .Big) throws -> T {
        guard let val:T = peek(endian: endian) else { throw Error.End }
        offset += sizeof(T)
        return val
    }
    
    // Read a number from the data, without advancing our offset into the data.
    func peek<T:EndianProtocol>(endian endian: Endian = .Big) -> T? {
        if remaining < sizeof(T) { return nil }

        var tmp = T.init()
        data.getBytes(&tmp, range: NSMakeRange(offset, sizeof(T)))

        switch endian {
        case .Big:
            return T(bigEndian: tmp)
        case .Little:
            return T(littleEndian: tmp)
        }
    }
    
    // Read n bytes from the data, advancing our offset into the data.
    func readData(n: Int) throws -> NSData {
        guard let d = peekData(n) else { throw Error.End }
        offset += n
        return d
    }
    
    // Read n bytes from the data, without advancing our offset into the data.
    func peekData(n: Int) -> NSData? {
        if remaining < n { return nil }
        return data.subdataWithRange(NSMakeRange(offset, n))
    }
}

protocol EndianProtocol {
    init()
    init(littleEndian value: Self)
    init(bigEndian value: Self)
}

extension UInt64: EndianProtocol {}
extension UInt32: EndianProtocol {}
extension UInt16: EndianProtocol {}
extension UInt8: EndianProtocol {
    init(littleEndian value: UInt8) {
        self = value
    }

    init(bigEndian value: UInt8) {
        self = value
    }
}
