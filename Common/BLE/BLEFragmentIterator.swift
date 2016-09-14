//
//  BLEFragmentIterator.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/12/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation

class BLEFragmentIterator: CollectionType, SequenceType {
    typealias Index = Int
    
    // FIDO U2F Bluetooth spec v1.0 Section 6.6
    private let initialFragmentMaxData = CharacteristicMaxSize - 3
    private let continuationFragmentMaxData = CharacteristicMaxSize - 1

    let message:BLEMessage
    
    init(message m: BLEMessage) {
        message = m
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        if message.data.length < initialFragmentMaxData { return 1 }
        
        var end = 1
        end += (message.data.length - initialFragmentMaxData) / continuationFragmentMaxData
        if (message.data.length - initialFragmentMaxData) % continuationFragmentMaxData > 0 {
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
            dLoc = initialFragmentMaxData + (continuationFragmentMaxData * (i - 1))
        }
        
        let dLen: Int
        if first {
            if message.data.length < initialFragmentMaxData {
                dLen = message.data.length
            } else {
                dLen = initialFragmentMaxData
            }
        } else {
            if message.data.length - dLoc < continuationFragmentMaxData {
                dLen = message.data.length - dLoc
            } else {
                dLen = continuationFragmentMaxData
            }
        }
        
        let dRange = NSRange(location: dLoc, length: dLen)
        let fData = message.data.subdataWithRange(dRange)
        let frag = DataWriter()
        
        if first {
            frag.write(message.commandOrStatus.rawValue)
            frag.write(UInt16(message.data.length))
        } else {
            frag.write(UInt8(i - 1))
        }
        
        frag.writeData(fData)
        
        return frag.buffer
    }
}