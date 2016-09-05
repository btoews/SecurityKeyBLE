//
//  Constants.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

// Bluetooth specification V4.0 Vol 3. Part F 3.2.9
let CharacteristicMaxSize = 512

// FIDO U2F Bluetooth spec v1.0 Section 6.6
let InitialFragmentMaxData = CharacteristicMaxSize - 3
let ContinuationFragmentMaxData = CharacteristicMaxSize - 1

// Bluetooth GATT UUIDs
let u2fServiceUUID = CBUUID(string: "FFFD")
let u2fControlPointCharacteristicUUID = CBUUID(string: "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fStatusCharacteristicUUID = CBUUID(string: "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fControlPointLengthCharacteristicUUID = CBUUID(string: "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fServiceRevisionCharacteristicUUID = CBUUID(string: "2A28")