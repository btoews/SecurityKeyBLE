//
//  SecurityKeyPeripheral.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

enum ServerStatus: StatusProtocol {
    case Initializing
    case Initialized
    
    case AddingService
    case AddedService
    
    case StartingAdvertising
    case StartedAdvertising
    
    case Advertising
    case ClientSubscribed
    
    case ReceivingRequest
    case ReceivedRequest
    
    case SendingResponse
    case SentResponse
    
    case Finished
}

class ServerContext: StateMachineContext {
    let authenticator = ServerAuthenticator()

    var peripheralManager:                   CBPeripheralManager?
    var u2fService:                          CBMutableService?
    var u2fControlPointCharacteristic:       CBMutableCharacteristic?
    var u2fStatusCharacteristic:             CBMutableCharacteristic?
    var u2fControlPointLengthCharacteristic: CBMutableCharacteristic?
    var u2fServiceRevisionCharacteristic:    CBMutableCharacteristic?
    
    var activeCentral:     CBCentral?
    var activeBLERequest:  CBATTRequest?
    var activeBLEResponse: BLEMessage?
    
    required init() {}
}

class Server: StateMachine<ServerContext, ServerStatus>, CBPeripheralManagerDelegate {
    override init() {
        super.init()
        failure = ServerInitState.self
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

class ServerState: State<ServerContext, ServerStatus> {
    required init(_ m: MachineType) {
        super.init(m)
    }
}

class ServerInitState: ServerState {
    override func enter() {
        machine.statusUpdate(.Initializing)
        
        machine.reset()
        
        context.activeCentral     = nil
        context.activeBLERequest  = nil
        context.activeBLEResponse = nil
        
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
        
        handles(event: "peripheralStateUpdate", with: handlePeripheralStateUpdate)
    }
    
    func handlePeripheralStateUpdate() {
        if context.peripheralManager?.state == .PoweredOn {
            machine.statusUpdate(.Initialized)
            proceed(ServerAddServiceState)
        } else {
            fail("peripheralManager not powered on")
        }
    }
}

class ServerAddServiceState: ServerState {
    override func enter() {
        machine.statusUpdate(.AddingService)
        
        guard
            let manager = context.peripheralManager,
            let service = context.u2fService
        else { return fail("bad context") }
        
        manager.addService(service)
        
        handles(event: "serviceAdded", with: handleServiceAdded)
    }
    
    func handleServiceAdded() {
        machine.statusUpdate(.AddedService)
        proceed(ServerStartAdvertisingState)
    }
}

class ServerStartAdvertisingState: ServerState {
    override func enter() {
        machine.statusUpdate(.StartingAdvertising)

        guard
            let manager = context.peripheralManager,
            let service = context.u2fService
        else { return fail("bad context") }

        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [service.UUID]])

        handles(event: "advertistingStarted", with: handleAdvertistingStarted)
    }
    
    func handleAdvertistingStarted() {
        machine.statusUpdate(.StartedAdvertising)
        proceed(ServerAdvertisingState)
    }
}

class ServerAdvertisingState: ServerState {
    override func enter() {
        machine.statusUpdate(.Advertising)
        handles(event: "clientSubscribed", with: handleClientSubscribed)
    }
    
    override func exit() {
        guard
            let manager = context.peripheralManager
        else { return fail("bad context") }

        manager.stopAdvertising()
    }
    
    func handleClientSubscribed() {
        machine.statusUpdate(.ClientSubscribed)
        proceed(ServerRequestState)
    }
}

class ServerRequestState: ServerState {
    let bleReader = BLEFragmentReader()
    
    override func enter() {
        machine.statusUpdate(.ReceivingRequest)

        handles(event: "writeRequestReceived", with: handleWriteRequestReceived)
    }
    
    func handleWriteRequestReceived() {
        guard
            let manager  = context.peripheralManager,
            let bleReq   = context.activeBLERequest,
            let fragment = bleReq.value
        else { return fail("bad context") }
        
        do {
            try bleReader.readFragment(fragment)
        } catch {
            return bleError()
        }
        
        if bleReader.isComplete {
            guard let cmd = bleReader.message else { return bleError() }
            context.activeBLEResponse = context.authenticator.bleResponse(cmd)
            
            machine.statusUpdate(.ReceivedRequest)
            proceed(ServerResponseState)
        }
        
        manager.respondToRequest(bleReq, withResult: CBATTError.Success)
    }
    
    func bleError() {
        let code = BLEMessage.ErrorCode.BLEError
        let data = NSData(int: code.rawValue)
        context.activeBLEResponse = BLEMessage(status: .Error, data: data)
        proceed(ServerResponseState)
    }
}

class ServerResponseState: ServerState {
    var fragments: IndexingGenerator<BLEFragmentIterator>?
    var queuedFragment: NSData?
    
    override func enter() {
        machine.statusUpdate(.SendingResponse)
        
        guard
            let resp = context.activeBLEResponse
        else { return fail("bad context") }
        
        fragments = resp.fragments.generate()

        writeNextFragment()
        handles(event: "readyToUpdate", with: writeNextFragment)
    }
    
    override func exit() {
        context.activeBLEResponse = nil
    }
    
    func writeNextFragment() {
        guard
            let manager = context.peripheralManager,
            let characteristic = context.u2fStatusCharacteristic
        else { return fail("bad context") }
        
        guard
            let fragment = queuedFragment ?? fragments?.next()
        else {
            machine.statusUpdate(.SentResponse)
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
    override func enter() {
        machine.statusUpdate(.Finished)
    }
}