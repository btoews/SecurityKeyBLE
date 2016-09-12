//
//  SecurityKeyPeripheral.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

class ServerContext: ContextProtocol {
    var peripheralManager:                   CBPeripheralManager?
    var u2fService:                          CBMutableService?
    var u2fControlPointCharacteristic:       CBMutableCharacteristic?
    var u2fStatusCharacteristic:             CBMutableCharacteristic?
    var u2fControlPointLengthCharacteristic: CBMutableCharacteristic?
    var u2fServiceRevisionCharacteristic:    CBMutableCharacteristic?
    
    var activeCentral:    CBCentral?
    var activeBLERequest: CBATTRequest?
    var activeU2FRequest: BLEMessage?
    
    required init() {}
}

class Server: StateMachine<ServerContext>, CBPeripheralManagerDelegate {
    override init() {
        super.init()
        
        failure = ServerInitState.self
        proceed(ServerInitState.self)
    }
    
    // Reset the peripheral manager
    override func reset() {
        context.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        handle(event: "peripheralStateUpdate")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        handle(event: "serviceAdded")
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        handle(event: "advertistingStarted")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        context.activeCentral = central
        handle(event: "clientSubscribed")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        context.activeCentral = nil
        handle(event: "clientUnsubscribed")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        context.activeBLERequest = request
        handle(event: "unexpectedReadRequestReceived")
        context.activeBLERequest = nil
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        for request in requests {
            context.activeBLERequest = request
            handle(event: "writeRequestReceived")
            context.activeBLERequest = nil
        }
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        handle(event: "readyToUpdate")
    }
}

class ServerState: State<ServerContext> {
    required init(_ m: StateMachine<ServerContext>) {
        super.init(m)
    }
}

class ServerInitState: ServerState {
    override func enter() {
        machine.reset()
        
        context.u2fControlPointCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointCharacteristicUUID,
            properties: .Write,
            value: nil,
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Writeable.rawValue | CBAttributePermissions.WriteEncryptionRequired.rawValue)
        )
        
        context.u2fStatusCharacteristic = CBMutableCharacteristic(
            type: u2fStatusCharacteristicUUID,
            properties: CBCharacteristicProperties(rawValue:CBCharacteristicProperties.Notify.rawValue | CBCharacteristicProperties.NotifyEncryptionRequired.rawValue),
            value: nil,
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        context.u2fControlPointLengthCharacteristic = CBMutableCharacteristic(
            type: u2fControlPointLengthCharacteristicUUID,
            properties: .Read,
            // Max BLE characteristic size for ctrl pt len.
            value: NSData(int: UInt16(CharacteristicMaxSize)),
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        context.u2fServiceRevisionCharacteristic = CBMutableCharacteristic(
            type: u2fServiceRevisionCharacteristicUUID,
            properties: .Read,
            value: "1.0".dataUsingEncoding(NSUTF8StringEncoding),
            permissions: CBAttributePermissions(rawValue: CBAttributePermissions.Readable.rawValue | CBAttributePermissions.ReadEncryptionRequired.rawValue)
        )
        
        let service = CBMutableService(
            type: u2fServiceUUID,
            primary: true
        )
        
        service.characteristics = [
            context.u2fControlPointCharacteristic!,
            context.u2fStatusCharacteristic!,
            context.u2fControlPointLengthCharacteristic!,
            context.u2fServiceRevisionCharacteristic!
        ]
        
        context.u2fService = service
        
        handle(event: "peripheralStateUpdate", with: handlePeripheralStateUpdate)
    }
    
    func handlePeripheralStateUpdate() {
        if context.peripheralManager?.state == .PoweredOn {
            print("peripheralManager powered on")
            proceed(ServerAddServiceState)
        } else {
            fail("peripheralManager not powered on")
        }
    }
}

class ServerAddServiceState: ServerState {
    override func enter() {
        guard
            let manager = context.peripheralManager,
            let service = context.u2fService
        else { return fail("bad context") }
        
        manager.addService(service)
        
        handle(event: "serviceAdded", with: handleServiceAdded)
    }
    
    func handleServiceAdded() {
         proceed(ServerStartAdvertisingState)
    }
}

class ServerStartAdvertisingState: ServerState {
    override func enter() {
        guard
            let manager = context.peripheralManager,
            let service = context.u2fService
        else { return fail("bad context") }

        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [service.UUID]])

        handle(event: "advertistingStarted", with: handleAdvertistingStarted)
    }
    
    func handleAdvertistingStarted() {
        proceed(ServerAdvertisingState)
    }
}

class ServerAdvertisingState: ServerState {
    override func enter() {
        handle(event: "clientSubscribed", with: handleClientSubscribed)
    }
    
    override func exit() {
        guard
            let manager = context.peripheralManager
        else { return fail("bad context") }

        manager.stopAdvertising()
    }
    
    func handleClientSubscribed() {
        proceed(ServerRequestState)
    }
}

class ServerRequestState: ServerState {
    override func enter() {
        context.activeU2FRequest = BLEMessage()
        handle(event: "writeRequestReceived", with: handleWriteRequestReceived)
    }
    
    func handleWriteRequestReceived() {
        guard
            let u2fReq  = context.activeU2FRequest,
            let manager = context.peripheralManager,
            let bleReq  = context.activeBLERequest,
            let fragment   = bleReq.value
        else { return fail("bad context") }
        
        do {
            try u2fReq.readFragment(fragment)
        } catch {
            return fail("error reading fragment")
        }
        
        if u2fReq.isComplete {
            guard
                let data   = u2fReq.data,
                let strMsg = String(data: data, encoding: NSUTF8StringEncoding)
            else { return fail("error receiving message") }

            print("message from client: \(strMsg)")
            proceed(ServerResponseState)
        }
        
        manager.respondToRequest(bleReq, withResult: CBATTError.Success)
    }
}

class ServerResponseState: ServerState {
    var fragments: IndexingGenerator<BLEMessage>?
    var queuedFragment: NSData?
    
    override func enter() {
        guard
            let u2fReq = context.activeU2FRequest,
            let reqCmd = u2fReq.cmd
        else { return fail("bad context") }
        
        if !u2fReq.isComplete {
            return fail("incomplete request")
        }
        
        let u2fResp = BLEMessage(cmd: reqCmd, data: "We, therefore, the Representatives of the United States of America, in General Congress, Assembled, appealing to the Supreme Judge of the world for the rectitude of our intentions, do, in the Name, and by the Authority of the good People of these Colonies, solemnly publish and declare, That these United Colonies are, and of Right ought to be Free and Independent States; that they are Absolved from all Allegiance to the British Crown, and that all political connection between them and the State of Great Britain, is and ought to be totally dissolved; and that as Free and Independent States, they have full Power to levy War, conclude Peace, contract Alliances, establish Commerce, and to do all other Acts and Things which Independent States may of right do.  And for the support of this Declaration, with a firm reliance on the Protection of Divine Providence, we mutually pledge to each other our Lives, our Fortunes and our sacred Honor.".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        fragments = u2fResp.generate()

        writeNextFragment()
        handle(event: "readyToUpdate", with: writeNextFragment)
    }
    
    func writeNextFragment() {
        guard
            let manager = context.peripheralManager,
            let characteristic = context.u2fStatusCharacteristic
        else { return fail("bad context") }
        
        guard
            let fragment = queuedFragment ?? fragments?.next()
        else {
            return proceed(ServerFinishedState)
        }

        let wrote = manager.updateValue(fragment, forCharacteristic: characteristic, onSubscribedCentrals: nil)

        if wrote {
            queuedFragment = nil
            writeNextFragment()
        } else {
            // wait for the characteristic to be free for writing
            queuedFragment = fragment
        }
    }
}

class ServerFinishedState: ServerState {
}