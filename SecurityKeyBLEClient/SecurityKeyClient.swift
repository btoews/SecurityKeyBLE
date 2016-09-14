//
//  SecurityKeyClient.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/7/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Foundation
import CoreBluetooth

class ClientContext: ContextProtocol {
    var logger: LoggerProtocol?
    
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

class Client: StateMachine<ClientContext>, CBCentralManagerDelegate, CBPeripheralDelegate {
    override init(logger:LoggerProtocol? = nil) {
        super.init(logger: logger)
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

class ClientState: State<ClientContext> {
    required init(_ m: StateMachine<ClientContext>) {
        super.init(m)
    }
}

class ClientInitialState: ClientState {
    override func enter() {
        context.log("Initializing…")
        
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
            return proceed(ClientScanState)
        }
        
        handle(event: "centralStateUpdate", with: handleCentralStateUpdate)
    }
    
    func handleCentralStateUpdate() {
        guard
            let manager = context.centralManager
            else { return fail("bad context") }

        if manager.state == .PoweredOn {
            context.debug("centralManager powered on")
            proceed(ClientScanState)
        } else {
            fail("centralManager not powered on")
        }
    }
}

class ClientScanState: ClientState {
    override func enter() {
        context.log("Scanning for devices…")
        
        guard
            let manager = context.centralManager
            else { return fail("bad context") }

        manager.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
        
        handle(event: "discoveredPeripheral", with: handleDiscoveredPeripheral)
    }
    
    func handleDiscoveredPeripheral() {
        guard
            let peripheral = context.activePeripheral
            else { return fail("bad context") }
        
        guard
            let delegate = machine as? CBPeripheralDelegate
            else { return fail("couldn't cast machine as CBPeripheralDelegate") }
        
        context.debug("Found peripheral: \(peripheral.name ?? "<no name>")")
        
        peripheral.delegate = delegate
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
        context.log("Connecting to device…")
        
        guard
            let peripheral = context.activePeripheral,
            let manager = context.centralManager
        else { return fail("bad context") }
        
        manager.connectPeripheral(peripheral, options: nil)
        handle(event: "connectedPeripheral", with: handleConncetedPeripheral)
    }
    
    func handleConncetedPeripheral() {
        context.debug("Peripheral connected")
        proceed(ClientDiscoverServiceState)
    }
}

class ClientDiscoverServiceState: ClientState {
    override func enter() {
        context.log("Discovering services…")
        
        guard
            let peripheral = context.activePeripheral
            else { return fail("bad context") }
        
        peripheral.discoverServices([u2fServiceUUID])
        
        handle(event: "discoveredServices", with: handleDiscoveredServices)
    }
    
    func handleDiscoveredServices() {
        guard
            let services = context.activePeripheral?.services,
            let service = services.filter({ $0.UUID == u2fServiceUUID }).first
            else {
                return fail("peripheral doesn't implement U2F service")
        }
        
        context.debug("Discovered U2F service")
        context.activeService = service
        proceed(ClientDiscoverCharacteristicState)
    }
}

class ClientDiscoverCharacteristicState: ClientState {
    override func enter() {
        context.log("Discovering characteristics…")

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
        
        handle(event: "discoveredCharacteristics", with: handleDiscoveredCharacteristics)
    }
    
    func handleDiscoveredCharacteristics() {
        guard
            let service = context.activeService,
            let characteristics = service.characteristics
            else { return fail("bad context") }
        
        context.debug("Discovered characteristics")
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
        
        proceed(ClientReadServiceRevisionState)
    }
}

class ClientReadServiceRevisionState: ClientState {
    override func enter() {
        context.log("Checking service revision…")
        
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.serviceRevisionCharacteristic
            else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handle(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.serviceRevisionCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if String(data: value, encoding: NSUTF8StringEncoding) != "1.0" {
            return fail("unknown service revision")
        }
        
        context.debug("valid service revision")
        proceed(ClientReadControlPointLengthState)
    }
}

class ClientReadControlPointLengthState: ClientState {
    override func enter() {
        context.log("Checking control-point length…")
        
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.controlPointLengthCharacteristic
            else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handle(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.controlPointLengthCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if value.getInt(2) != CharacteristicMaxSize {
            return fail("expected control point size to be \(CharacteristicMaxSize)")
        }
        
        context.debug("valid control point length")
        proceed(ClientSubscribeToServerState)
    }
}

class ClientSubscribeToServerState: ClientState {
    override func enter() {
        context.log("Subscribing…")

        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }
        
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)

        handle(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
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
        
        proceed(ClientRequestState)
    }
}

class ClientRequestState: ClientState {
    var fragments: IndexingGenerator<BLEFragmentIterator>?
    var nextFragment: NSData?

    override func enter() {
        context.log("Sending request…")

        guard
            let msg = context.activeRequest
        else { return fail("bad context") }
    
        fragments = msg.fragments.generate()
        
        writeNextFragment()
        handle(event: "wroteCharacteristic", with: writeNextFragment)
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
            return proceed(ClientResponseState)
        }
    }
}

class ClientResponseState: ClientState {
    let reader = BLEFragmentReader()
    
    override func enter() {
        context.log("Waiting for response…")

        handle(event: "updatedCharacteristic",   with: handleUpdatedCharacteristic)
        handle(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
        handle(event: "wroteCharacteristic",     with: handleWroteCharacteristic)
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
        context.log("Received response…")

        handle(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
    }

    func handleNotificationStateUpdate() {
    }
}