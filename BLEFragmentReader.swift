//
//  BLEMessageReader.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class BLEFragmentReader {
    enum Error: ErrorType {
        case InvalidSequence
        case InvalidMessage
        case MessageComplete
        case InvalidHeader
    }
    
    var message: BLEMessage?
    
    var isComplete: Bool { return message != nil }
    
    private var cmdOrStatus: BLEMessage.CommandOrStatus?
    private var partialData = CappedDataWriter(max: 0)
    private var lastSequence: UInt8 = 0xFF
    
    func readFragment(frag: NSData) throws {
        if isComplete {
            // We've already got the whole message.
            throw Error.MessageComplete
        }
        
        if try isInitialFragment(frag) {
            try readInitialFragment(frag)
        } else {
            try readContinuationFragment(frag)
        }
    }
    
    // Read the first fragment of the message.
    private func readInitialFragment(frag: NSData) throws {
        let cs:BLEMessage.CommandOrStatus

        do {
            let reader = DataReader(data: frag)
            
            cs = try reader.read()
            cmdOrStatus = cs
            
            let totalLength:UInt16 = try reader.read()
            partialData.max = Int(totalLength)
            
            try partialData.writeData(reader.rest)
        } catch is DataReader.Error {
            throw Error.InvalidHeader
        } catch is CappedDataWriter.Error {
            throw Error.InvalidMessage
        }
        
        if partialData.isFinished {
            message = BLEMessage(commandOrStatus: cs, data: partialData.buffer)
        }
    }
    
    // Read a subsequent fragment of the message.
    private func readContinuationFragment(frag: NSData) throws {
        let reader = DataReader(data: frag)
        
        let seq:UInt8 = try reader.read()
        
        // Check that we didn't miss a fragment.
        if lastSequence == 0xFF {
            if seq == 0x00 {
                lastSequence = seq
            } else {
                throw Error.InvalidSequence
            }
        } else {
            if seq == lastSequence + 1 {
                lastSequence = seq
            } else {
                throw Error.InvalidSequence
            }
        }
        
        try partialData.writeData(reader.rest)
        
        if partialData.isFinished {
            guard let cs = cmdOrStatus else { throw Error.InvalidMessage }
            message = BLEMessage(commandOrStatus: cs, data: partialData.buffer)
        }
    }
    
    // Is this the first fragment?
    // Statuses and commands are all >0x80. Sequence numbers are <=0x7F.
    private func isInitialFragment(frag: NSData) throws -> Bool {
        let reader = DataReader(data: frag)
        let firstByte: UInt8 = try reader.read()
        return firstByte & 0x80 > 0
    }
}