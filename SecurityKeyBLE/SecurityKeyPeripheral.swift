//
//  SecurityKeyPeripheral.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

let u2fServiceUUID = CBUUID(string: "FFFD")
let u2fControlPointCharacteristicUUID = CBUUID(string: "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fStatusCharacteristicUUID = CBUUID(string: "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fControlPointLengthCharacteristicUUID = CBUUID(string: "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB")
let u2fServiceRevisionCharacteristicUUID = CBUUID(string: "2A28")

var ControlPointLengthMaxInt = 512
let ControlPointLengthMax = NSData(bytes: &ControlPointLengthMaxInt, length: 2)

class SecurityKeyPeripheral: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    
    private var u2fControlPointCharacteristic: CBMutableCharacteristic?
    private var u2fStatusCharacteristic: CBMutableCharacteristic?
    private var u2fControlPointLengthCharacteristic: CBMutableCharacteristic?
    private var u2fServiceRevisionCharacteristic: CBMutableCharacteristic?
    
    override init() {
        super.init()

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if (peripheralManager!.state != CBPeripheralManagerState.PoweredOn) {
            return
        }
        
        print("peripheralManager powered on.")
        
        u2fControlPointCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointCharacteristicUUID,
            properties: CBCharacteristicProperties.Write,
            value: nil,
            permissions: CBAttributePermissions.Writeable
        )
        
        u2fStatusCharacteristic = CBMutableCharacteristic(
            type: u2fStatusCharacteristicUUID,
            properties: CBCharacteristicProperties.Notify,
            value: nil,
            permissions: CBAttributePermissions.Readable
        )
        
        u2fControlPointLengthCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointLengthCharacteristicUUID,
            properties: CBCharacteristicProperties.Read,
            value: ControlPointLengthMax,
            permissions: CBAttributePermissions.Readable
        )
        
        u2fServiceRevisionCharacteristic = CBMutableCharacteristic(
            type: u2fServiceRevisionCharacteristicUUID,
            properties: CBCharacteristicProperties.Read,
            value: nil,
            permissions: CBAttributePermissions.Readable
        )
        
        let u2fService = CBMutableService(
            type: u2fServiceUUID,
            primary: true
        )
        
        u2fService.characteristics = [
            u2fControlPointCharacteristic!,
            u2fStatusCharacteristic!,
            u2fControlPointLengthCharacteristic!,
            u2fServiceRevisionCharacteristic!
        ]
        
        peripheralManager!.addService(u2fService)
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if (error != nil) {
            print("error adding service: \(error!.localizedDescription)")
            print("Providing the reason for failure: \(error!.localizedFailureReason)")
        }
        else {
            print("added service")
            peripheralManager!.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [service.UUID]])
        }
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if (error != nil) {
            print("error starting advertising: \(error!.localizedDescription)")
            print("Providing the reason for failure: \(error!.localizedFailureReason)")
        } else {
            print("started advertising")
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        print("A new CBCentral has subscribed to this device's CBServices")
        print(central.description)
        
        print("Updating subbed char")
        peripheralManager!.updateValue("shit".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: u2fStatusCharacteristic!, onSubscribedCentrals: nil)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("\(central.description) has unsubbed from this device's CBServices")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        var char: CBMutableCharacteristic
        
        switch request.characteristic.UUID {
        case u2fControlPointLengthCharacteristicUUID:
            print("read request: u2fControlPointLengthCharacteristic")
            char = u2fControlPointCharacteristic!
        default:
            print("read request for bad characteristic: \(request.characteristic.UUID)")
            peripheralManager!.respondToRequest(request, withResult: CBATTError.ReadNotPermitted)
            return
        }
        
        if (request.offset > char.value!.length) {
            peripheralManager?.respondToRequest(request, withResult: CBATTError.InvalidOffset)
            return
        }
        
        let cRange = NSRange(location: request.offset, length: char.value!.length - request.offset)
        request.value = char.value?.subdataWithRange(cRange)

        peripheralManager!.respondToRequest(request, withResult: CBATTError.Success)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        var char: CBMutableCharacteristic

        for request in requests {
            switch request.characteristic {
            case u2fControlPointCharacteristicUUID:
                print("write request: u2fControlPointCharacteristic, \(request.value)")
                char = u2fControlPointCharacteristic!
            default:
                print("write request for bad characteristic: \(request.characteristic.UUID)")
                peripheralManager!.respondToRequest(request, withResult: CBATTError.WriteNotPermitted)
                return
            }
            
            // Take write offset into account? How does that work?
            char.value = request.value
        }
        
        peripheralManager!.respondToRequest(requests.first!, withResult: CBATTError.Success)
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        print("Updating subscribed devices")
    }
}