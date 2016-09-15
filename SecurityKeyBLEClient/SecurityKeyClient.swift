//
//  SecurityKeyClient.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/7/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

enum ClientStatus: StatusProtocol {
    case Initializing
    case Initialized

    case Scanning
    case DeviceFound

    case Connecting
    case Connected
    
    case DiscoveringServices
    case DiscoveredServices
    
    case DiscoveringCharacteristics
    case DiscoveredCharacteristics
    
    case ReadingServiceRevision
    case ReadServiceRevision
    
    case ReadingControlPointLength
    case ReadControlPointLength
    
    case Subscribing
    case Subscribed
    
    case SendingRequest
    case SentRequest
    
    case ReceivingResponse
    case ReceivedResponse
    
    case Finished
}

class ClientContext: StateMachineContext {
    var centralManager:                   CBCentralManager?
    var activePeripheral:                 CBPeripheral?
    var activeService:                    CBService?
    var activeCharacteristic:             CBCharacteristic?
    var controlPointCharacteristic:       CBCharacteristic?
    var statusCharacteristic:             CBCharacteristic?
    var controlPointLengthCharacteristic: CBCharacteristic?
    var serviceRevisionCharacteristic:    CBCharacteristic?
    
    var activeRequest: BLEMessage?
    var responseCallback: ((response: BLEMessage ) -> Void)?
    
    required init() {}
}

class Client: StateMachine<ClientContext, ClientStatus>, CBCentralManagerDelegate, CBPeripheralDelegate {
    override init() {
        super.init()
        context.centralManager = CBCentralManager(delegate: self, queue: nil)
        failure = ClientInitialState.self
    }
    
    func request(message: BLEMessage, cb: ((response: BLEMessage ) -> Void)) {
        context.activeRequest = message
        context.responseCallback = cb
        proceed(ClientInitialState)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        handle(event: "centralStateUpdate")
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        context.activePeripheral = peripheral
        handle(event: "discoveredPeripheral")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        if peripheral != context.activePeripheral { return fail("wrong peripheral") }
        handle(event: "connectedPeripheral")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if peripheral != context.activePeripheral { return fail("wrong peripheral") }
        handle(event: "discoveredServices")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        if peripheral != context.activePeripheral { return fail("wrong peripheral") }
        handle(event: "discoveredCharacteristics")
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        context.activeCharacteristic = characteristic
        handle(event: "updatedCharacteristic")
        context.activeCharacteristic = nil
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        context.activeCharacteristic = characteristic
        handle(event: "notificationStateUpdate")
        context.activeCharacteristic = nil
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        if peripheral != context.activePeripheral { return fail("wrong peripheral") }
        handle(event: "wroteCharacteristic")
    }
}

class ClientState: State<ClientContext, ClientStatus> {
    required init(_ m: MachineType) {
        super.init(m)
    }
}

class ClientInitialState: ClientState {
    override func enter() {
        machine.statusUpdate(.Initializing)
        
        guard
            let manager = context.centralManager
            else { return fail("bad context") }
        
        context.activePeripheral = nil
        context.activeService = nil
        context.controlPointCharacteristic = nil
        context.statusCharacteristic = nil
        context.controlPointLengthCharacteristic = nil
        context.serviceRevisionCharacteristic = nil
        
        if manager.state == .PoweredOn {
            machine.statusUpdate(.Initialized)
            return proceed(ClientScanState)
        }
        
        handles(event: "centralStateUpdate", with: handleCentralStateUpdate)
    }
    
    func handleCentralStateUpdate() {
        guard
            let manager = context.centralManager
            else { return fail("bad context") }

        if manager.state == .PoweredOn {
            machine.statusUpdate(.Initialized)
            proceed(ClientScanState)
        } else {
            fail("centralManager not powered on")
        }
    }
}

class ClientScanState: ClientState {
    override func enter() {
        machine.statusUpdate(.Scanning)
        
        guard
            let manager = context.centralManager
            else { return fail("bad context") }

        manager.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
        
        handles(event: "discoveredPeripheral", with: handleDiscoveredPeripheral)
    }
    
    func handleDiscoveredPeripheral() {
        guard
            let peripheral = context.activePeripheral
            else { return fail("bad context") }
        
        guard
            let delegate = machine as? CBPeripheralDelegate
            else { return fail("couldn't cast machine as CBPeripheralDelegate") }
        
        peripheral.delegate = delegate
        
        machine.statusUpdate(.DeviceFound)
        proceed(ClientConnectState)
    }
    
    override func exit() {
        guard
            let manager = context.centralManager
            else { return fail("bad context") }

        manager.stopScan()
    }
}

class ClientConnectState: ClientState {
    override func enter() {
        machine.statusUpdate(.Connecting)
        
        guard
            let peripheral = context.activePeripheral,
            let manager = context.centralManager
        else { return fail("bad context") }
        
        manager.connectPeripheral(peripheral, options: nil)
        handles(event: "connectedPeripheral", with: handleConncetedPeripheral)
    }
    
    func handleConncetedPeripheral() {
        machine.statusUpdate(.Connected)
        proceed(ClientDiscoverServiceState)
    }
}

class ClientDiscoverServiceState: ClientState {
    override func enter() {
        machine.statusUpdate(.DiscoveringServices)
        
        guard
            let peripheral = context.activePeripheral
            else { return fail("bad context") }
        
        peripheral.discoverServices([u2fServiceUUID])
        
        handles(event: "discoveredServices", with: handleDiscoveredServices)
    }
    
    func handleDiscoveredServices() {
        guard
            let services = context.activePeripheral?.services,
            let service = services.filter({ $0.UUID == u2fServiceUUID }).first
            else {
                return fail("peripheral doesn't implement U2F service")
        }
        
        context.activeService = service
        
        machine.statusUpdate(.DiscoveredServices)
        proceed(ClientDiscoverCharacteristicState)
    }
}

class ClientDiscoverCharacteristicState: ClientState {
    override func enter() {
        machine.statusUpdate(.DiscoveringCharacteristics)

        guard
            let peripheral = context.activePeripheral,
            let service = context.activeService
            else { return fail("bad context") }
        
        peripheral.discoverCharacteristics(
            [
                u2fControlPointCharacteristicUUID,
                u2fStatusCharacteristicUUID,
                u2fControlPointLengthCharacteristicUUID,
                u2fServiceRevisionCharacteristicUUID
            ], forService: service
        )
        
        handles(event: "discoveredCharacteristics", with: handleDiscoveredCharacteristics)
    }
    
    func handleDiscoveredCharacteristics() {
        guard
            let service = context.activeService,
            let characteristics = service.characteristics
            else { return fail("bad context") }

        for characteristic in characteristics {
            switch characteristic.UUID {
            case u2fControlPointCharacteristicUUID:
                context.controlPointCharacteristic = characteristic
            case u2fStatusCharacteristicUUID:
                context.statusCharacteristic = characteristic
            case u2fControlPointLengthCharacteristicUUID:
                context.controlPointLengthCharacteristic = characteristic
            case u2fServiceRevisionCharacteristicUUID:
                context.serviceRevisionCharacteristic = characteristic
            default: ()
            }
        }
        
        let chars = [
            context.controlPointCharacteristic,
            context.statusCharacteristic,
            context.controlPointLengthCharacteristic,
            context.serviceRevisionCharacteristic
        ]
        
        if chars.contains({ $0 == nil }) {
            return fail("services doesn't define all characteristics")
        }
        
        machine.statusUpdate(.DiscoveredCharacteristics)
        proceed(ClientReadServiceRevisionState)
    }
}

class ClientReadServiceRevisionState: ClientState {
    override func enter() {
        machine.statusUpdate(.ReadingServiceRevision)
        
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.serviceRevisionCharacteristic
            else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handles(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.serviceRevisionCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if String(data: value, encoding: NSUTF8StringEncoding) != "1.0" {
            return fail("unknown service revision")
        }
        
        machine.statusUpdate(.ReadServiceRevision)
        proceed(ClientReadControlPointLengthState)
    }
}

class ClientReadControlPointLengthState: ClientState {
    override func enter() {
        machine.statusUpdate(.ReadingControlPointLength)
        
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.controlPointLengthCharacteristic
            else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handles(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.controlPointLengthCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if value.getInt(2) != CharacteristicMaxSize {
            return fail("expected control point size to be \(CharacteristicMaxSize)")
        }

        machine.statusUpdate(.ReadControlPointLength)
        proceed(ClientSubscribeToServerState)
    }
}

class ClientSubscribeToServerState: ClientState {
    override func enter() {
        machine.statusUpdate(.Subscribing)

        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }
        
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)

        handles(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
    }
    
    func handleNotificationStateUpdate() {
        guard
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }
        
        if context.activeCharacteristic != characteristic {
            return fail("subscribed to wrong characteristic")
        }
        
        if !characteristic.isNotifying {
            return fail("couldn't subscribe to characteristic")
        }
        
        machine.statusUpdate(.Subscribed)
        proceed(ClientRequestState)
    }
}

class ClientRequestState: ClientState {
    var fragments: IndexingGenerator<BLEFragmentIterator>?
    var nextFragment: NSData?

    override func enter() {
        machine.statusUpdate(.SendingRequest)

        guard
            let msg = context.activeRequest
        else { return fail("bad context") }
    
        fragments = msg.fragments.generate()
        
        writeNextFragment()
        handles(event: "wroteCharacteristic", with: writeNextFragment)
    }
    
    func writeNextFragment() {
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.controlPointCharacteristic
        else { return fail("bad context") }

        guard
            let fragment = nextFragment ?? fragments?.next()
        else {
            return proceed(ClientResponseState)
        }
        
        peripheral.writeValue(fragment, forCharacteristic: characteristic, type: .WithResponse)
        
        nextFragment = fragments?.next()
        if nextFragment == nil {
            // Don't wait for the server's ACK. We need to get to the response-state
            // quickly so we don't miss a fragment.
            machine.statusUpdate(.SentRequest)
            return proceed(ClientResponseState)
        }
    }
}

class ClientResponseState: ClientState {
    let reader = BLEFragmentReader()
    
    override func enter() {
        machine.statusUpdate(.ReceivingResponse)

        handles(event: "updatedCharacteristic",   with: handleUpdatedCharacteristic)
        handles(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
        handles(event: "wroteCharacteristic",     with: handleWroteCharacteristic)
    }
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.statusCharacteristic,
            let fragment = characteristic.value
        else { return fail("bad context") }
        
        do {
            try reader.readFragment(fragment)
        } catch {
            return fail("error receiving fragment")
        }
        
        if reader.isComplete {
            guard
                let cb = context.responseCallback
            else { return fail("bad context") }
            
            guard
                let msg = reader.message
            else { return fail("error receiving message") }
            
            cb(response: msg)
            
            machine.statusUpdate(.ReceivedResponse)
            proceed(ClientFinishedState)
        }
    }
    
    func handleNotificationStateUpdate() {
        guard
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }
        
        if context.activeCharacteristic != characteristic {
            return fail("subscribed to wrong characteristic")
        }
        
        if !characteristic.isNotifying {
            return fail("couldn't subscribe to characteristic")
        }
    }
    
    func handleWroteCharacteristic () {
        // An ACK from the server for our last request packed. Don't care...
    }
}

class ClientFinishedState: ClientState {
    override func enter() {
        machine.statusUpdate(.Finished)

        handles(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
    }

    func handleNotificationStateUpdate() {
    }
}