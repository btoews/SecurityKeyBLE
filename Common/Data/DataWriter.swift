//
//  DataWriter.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

protocol DataWriterProtocol {
    var buffer: NSMutableData { get }

    func write<T: EndianProtocol>(val:T, endian: Endian) throws
    func writeData(d: NSData) throws
}

class DataWriter: DataWriterProtocol {
    let buffer = NSMutableData()
    
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

class CappedDataWriter: DataWriterProtocol {
    enum Error: ErrorType {
        case MaxExceeded
    }
    
    var max: Int
    var buffer: NSMutableData { return writer.buffer }
    var isFinished: Bool { return buffer.length == max }
    
    private let writer = DataWriter()
    
    init(max m:Int) {
        max = m
    }
    
    func write<T: EndianProtocol>(val:T, endian: Endian = .Big) throws {
        if buffer.length + sizeof(T) > max {
            throw Error.MaxExceeded
        }
        
        writer.write(val, endian: endian)
    }
    
    func writeData(d: NSData) throws {
        if buffer.length + d.length > max {
            throw Error.MaxExceeded
        }
        
        writer.writeData(d)
    }
}