//
//  Framable.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/4/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class BLEMessage: CollectionType, SequenceType {
    enum Error: ErrorType {
        case InvalidSequence
        case InvalidMessage
        case MessageComplete
    }

    // Possible statuses for Authenticator Response messages.
    enum Status: UInt8 {
        case KeepAlive = 0x82
        case Error = 0xBF
    }
    
    // Possible commands for Client Request messages.
    enum Command: UInt8 {
        case Ping = 0x81
        case Msg = 0x83
    }
    
    var data: NSData?

    private var cmdOrStatus:  UInt8?
    private var partialData:  NSMutableData?
    private var totalLength: Int?
    private var lastSequence: UInt8?

    // Do we have the entire message?
    var isComplete:   Bool {
        return data != nil
    }
    
    // What command, if any, is this?
    var cmd: Command? {
        if cmdOrStatus == nil { return nil }
        guard let c = Command(rawValue: cmdOrStatus!) else { return nil }
        return c
    }
    
    // What is the status, if any?
    var status: Status? {
        if cmdOrStatus == nil { return nil }
        guard let s = Status(rawValue: cmdOrStatus!) else { return nil }
        return s
    }
    
    // Create a message for reading fragments into.
    init() {}
    
    // Create a new authenticator response.
    init(status: Status, data: NSData) {
        self.cmdOrStatus = status.rawValue
        self.data = data
    }
    
    // Create a new client request.
    init(cmd: Command, data: NSData) {
        self.cmdOrStatus = cmd.rawValue
        self.data = data
    }
    
    // Read a fragment into this message.
    func readFragment(frag: NSData) throws {
        if isComplete {
            // We've already got the whole message.
            throw Error.MessageComplete
        }

        if isInitialFragment(frag) {
            try readInitialFragment(frag)
        } else {
            try readContinuationFragment(frag)
        }
    }
    
    // Read the first fragment of the message.
    private func readInitialFragment(frag: NSData) throws {
        cmdOrStatus = frag.getByte(0)

        guard
            let hLen = frag.getByte(1),
            let lLen = frag.getByte(2)
        else {
            throw Error.InvalidMessage
        }

        totalLength = (Int(hLen) << 8) | Int(lLen)
        
        // Check that we don't exceed the total length.
        if frag.length > totalLength! + 3 {
            throw Error.InvalidMessage
        }

        let dataRange = NSRange(location: 3, length: frag.length - 3)
        partialData = NSMutableData(data: frag.subdataWithRange(dataRange))
        
        // See if this was the last fragment.
        if partialData!.length == totalLength {
            data = NSData(data: partialData!)
            partialData = nil
            lastSequence = nil
        } else {
            lastSequence = 0xFF // -1. Next fragment will be seq 0
        }
    }
    
    // Read a subsequent fragment of the message.
    private func readContinuationFragment(frag: NSData) throws {
        // Should have been set to -1 (0xFF) in readInitialFragment.
        if lastSequence == nil {
            throw Error.InvalidSequence
        }
        
        // Check that we didn't miss a fragment.
        guard let seq = frag.getByte(0) else {
            throw Error.InvalidMessage
        }
        
        if lastSequence! == 0xFF && seq == 0 {
            // ok
        } else if seq == lastSequence! + 1 {
            // ok
        } else {
            throw Error.InvalidSequence
        }

        lastSequence = seq
        
        // Check that we don't exceed the expected message length
        if partialData!.length + frag.length - 1 > totalLength {
            throw Error.InvalidMessage
        }
        
        let dataRange = NSRange(location: 1, length: frag.length - 1)
        partialData!.appendData(frag.subdataWithRange(dataRange))
        
        // See if this was the last fragment.
        if partialData!.length == totalLength {
            data = NSData(data: partialData!)
            partialData = nil
            lastSequence = nil
        }
    }
    
    // Is this the first fragment?
    // Statuses and commands are all >0x80. Sequence numbers are <=0x7F.
    private func isInitialFragment(frag: NSData) -> Bool {
        var firstByte: UInt8 = 0
        frag.getBytes(&firstByte, range: NSRange(location: 0, length: 1))
        return firstByte & 0x80 > 0
    }
    
    // The following methods implement the CollectionType protocol over the fragments of the message.
    typealias Index = Int
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        if !isComplete { return 0 }
        if data!.length < InitialFragmentMaxData { return 1 }
        
        var end = 1
        end += (data!.length - InitialFragmentMaxData) / ContinuationFragmentMaxData
        if (data!.length - InitialFragmentMaxData) % ContinuationFragmentMaxData > 0 {
            end += 1
        }

        return end
    }
    
    subscript(i: Int) -> NSData {
        let first = i == 0
        
        let dLoc: Int
        if first {
            dLoc = 0
        } else {
            dLoc = InitialFragmentMaxData + (ContinuationFragmentMaxData * (i - 1))
        }
        
        let dLen: Int
        if first {
            if data!.length < InitialFragmentMaxData {
                dLen = data!.length
            } else {
                dLen = InitialFragmentMaxData
            }
        } else {
            if data!.length - dLoc < ContinuationFragmentMaxData {
                dLen = data!.length - dLoc
            } else {
                dLen = ContinuationFragmentMaxData
            }
        }
        
        let dRange = NSRange(location: dLoc, length: dLen)
        let fData = data!.subdataWithRange(dRange)
        let frag = NSMutableData()
        
        if first {
            frag.appendByte(cmdOrStatus!)
            frag.appendInt(data!.length, size: 2)
        } else {
            frag.appendInt(i - 1, size: 1)
        }
        
        frag.appendData(fData)
        
        return NSData(data: frag)
    }
}