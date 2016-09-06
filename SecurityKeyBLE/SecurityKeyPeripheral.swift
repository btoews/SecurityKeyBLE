//
//  SecurityKeyPeripheral.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

class SecurityKeyPeripheral: NSObject, CBPeripheralManagerDelegate {
    private var peripheralManager: CBPeripheralManager?
    private var u2fService: CBMutableService?
    private var u2fControlPointCharacteristic: CBMutableCharacteristic?
    private var u2fStatusCharacteristic: CBMutableCharacteristic?
    private var u2fControlPointLengthCharacteristic: CBMutableCharacteristic?
    private var u2fServiceRevisionCharacteristic: CBMutableCharacteristic?
    
    override init() {
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        
        u2fControlPointCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointCharacteristicUUID,
            properties: .Write,
            value: nil,
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Writeable.rawValue | CBAttributePermissions.WriteEncryptionRequired.rawValue)
        )
        
        u2fStatusCharacteristic = CBMutableCharacteristic(
            type: u2fStatusCharacteristicUUID,
            properties: CBCharacteristicProperties(rawValue:CBCharacteristicProperties.Notify.rawValue | CBCharacteristicProperties.NotifyEncryptionRequired.rawValue),
            value: nil,
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        u2fControlPointLengthCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointLengthCharacteristicUUID,
            properties: .Read,
            // Max BLE characteristic size for ctrl pt len.
            value: NSData(int: CharacteristicMaxSize, size: 2),
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        u2fServiceRevisionCharacteristic = CBMutableCharacteristic(
            type: u2fServiceRevisionCharacteristicUUID,
            properties: .Read,
            value: "1.0".dataUsingEncoding(NSUTF8StringEncoding),
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        u2fService = CBMutableService(
            type: u2fServiceUUID,
            primary: true
        )
        
        u2fService!.characteristics = [
            u2fControlPointCharacteristic!,
            u2fStatusCharacteristic!,
            u2fControlPointLengthCharacteristic!,
            u2fServiceRevisionCharacteristic!
        ]
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        switch peripheralManager!.state {
        case .Unknown:
            print("peripheralManager state: Unknown")
        case .Resetting:
            print("peripheralManager state: Resetting")
        case .Unsupported:
            print("peripheralManager state: Unsupported")
        case .Unauthorized:
            print("peripheralManager state: Unauthorized")
        case .PoweredOff:
            print("peripheralManager state: PoweredOff")
        case .PoweredOn:
            print("peripheralManager state: PoweredOn")
        }

        if (peripheralManager!.state == CBPeripheralManagerState.PoweredOn) {
            print("Adding service")
            peripheralManager!.addService(u2fService!)
        } else {
            print("Stopping advertising")
            peripheralManager!.stopAdvertising()
            
            print("Removing service")
            peripheralManager!.removeService(u2fService!)
        }
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
        print("A new CBCentral has subscribed to this service's characteristic")
        print(central.description)
        
        print("Updating subbed char")
        // these calls return boolean false if the queue is blocked. peripheralManagerIsReadyToUpdateSubscribers is called
        // when it's free again.
        peripheralManager!.updateValue("shit".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: u2fStatusCharacteristic!, onSubscribedCentrals: nil)
        peripheralManager!.updateValue("shit2".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: u2fStatusCharacteristic!, onSubscribedCentrals: nil)
        peripheralManager!.updateValue("shit3".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: u2fStatusCharacteristic!, onSubscribedCentrals: nil)
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        print("\(central.description) has unsubbed from this device's characteristic")
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
        peripheralManager!.updateValue("shit123".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: u2fStatusCharacteristic!, onSubscribedCentrals: nil)
    }
}
