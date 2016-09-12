////
////  BLEMessageReader.swift
////  SecurityKeyBLE
////
////  Created by Benjamin P Toews on 9/12/16.
////  Copyright © 2016 GitHub. All rights reserved.
////
//
//import Foundation
//
//class BLEMessageReader {
//    enum Error: ErrorType {
//        case InvalidSequence
//        case InvalidMessage
//        case MessageComplete
//    }
//    
//    var message: BLEMessage?
//    
//    var isComplete: Bool { return message != nil }
//    
//    private var cmdOrStatus: UInt8?
//    private var partialData: BLEMessage.CommandOrStatus?
//    
//    func readFragment(frag: NSData) throws {
//        if isComplete {
//            // We've already got the whole message.
//            throw Error.MessageComplete
//        }
//        
//        if try isInitialFragment(frag) {
//            try readInitialFragment(frag)
//        } else {
//            try readContinuationFragment(frag)
//        }
//    }
//    
//    // Read the first fragment of the message.
//    private func readInitialFragment(frag: NSData) throws {
//        let reader = DataReader(data: frag)
//
//        let csByte:UInt8 = try reader.read()
//        guard let cs = BLEMessage.CommandOrStatus(rawValue: csByte) else { throw Error.InvalidMessage }
//        
//        guard
//            let hLen = frag.getByte(1),
//            let lLen = frag.getByte(2)
//            else {
//                throw Error.InvalidMessage
//        }
//        
//        totalLength = (Int(hLen) << 8) | Int(lLen)
//        
//        // Check that we don't exceed the total length.
//        if frag.length > totalLength! + 3 {
//            throw Error.InvalidMessage
//        }
//        
//        let dataRange = NSRange(location: 3, length: frag.length - 3)
//        partialData = NSMutableData(data: frag.subdataWithRange(dataRange))
//        
//        // See if this was the last fragment.
//        if partialData!.length == totalLength {
//            data = NSData(data: partialData!)
//            partialData = nil
//            lastSequence = nil
//        } else {
//            lastSequence = 0xFF // -1. Next fragment will be seq 0
//        }
//    }
//    
//    // Is this the first fragment?
//    // Statuses and commands are all >0x80. Sequence numbers are <=0x7F.
//    private func isInitialFragment(frag: NSData) throws -> Bool {
//        let reader = DataReader(data: frag)
//        let firstByte: UInt8 = try reader.read()
//        return firstByte & 0x80 > 0
//    }
//}