//
//  ViewController.swift
//  SecurityKeyTestClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ClientContext: ContextProtocol {
    var centralManager:                   CBCentralManager? = nil
    var activePeripheral:                 CBPeripheral?     = nil
    var activeService:                    CBService?        = nil
    var activeCharacteristic:             CBCharacteristic? = nil
    var controlPointCharacteristic:       CBCharacteristic? = nil
    var statusCharacteristic:             CBCharacteristic? = nil
    var controlPointLengthCharacteristic: CBCharacteristic? = nil
    var serviceRevisionCharacteristic:    CBCharacteristic? = nil
    
    required init() {}
}

class Client: StateMachine<ClientContext>, CBCentralManagerDelegate, CBPeripheralDelegate {
    override init() {
        super.init()
        
        context.centralManager = CBCentralManager(delegate: self, queue: nil)

        failure = ClientInitialState.self
        proceed(ClientInitialState.self)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        handle(event: "centralStateUpdate")
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        context.activePeripheral = peripheral
        handle(event: "discoveredPeripheral")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        handle(event: "connectedPeripheral")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        handle(event: "discoveredServices", error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        handle(event: "discoveredCharacteristics", error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        context.activeCharacteristic = characteristic
        defer { context.activeCharacteristic = nil }
        handle(event: "updatedCharacteristic", error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        context.activeCharacteristic = characteristic
        defer { context.activeCharacteristic = nil }
        handle(event: "notificationStateUpdate", error: error)
    }
}

class ClientState: State<ClientContext> {
    required init(_ m: StateMachine<ClientContext>) {
        super.init(m)
    }
}

class ClientInitialState: ClientState {
    override func enter() {
        context.activePeripheral = nil
        context.activeService = nil
        context.controlPointCharacteristic = nil
        context.statusCharacteristic = nil
        context.controlPointLengthCharacteristic = nil
        context.serviceRevisionCharacteristic = nil
        
        if context.centralManager?.state == .PoweredOn {
            proceed(ClientScanState)
        }
        
        handle(event: "centralStateUpdate", with: handleCentralStateUpdate)
    }
    
    func handleCentralStateUpdate(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }

        if context.centralManager?.state == .PoweredOn {
            print("centralManager powered on")
            proceed(ClientScanState)
        } else {
            fail("centralManager not powered on")
        }
    }
}

class ClientScanState: ClientState {
    override func enter() {
        context.centralManager?.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
        
        handle(event: "discoveredPeripheral", with: handleDiscoveredPeripheral)
    }
    
    func handleDiscoveredPeripheral(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }

        guard
            let peripheral = context.activePeripheral
        else { return fail("bad context") }
        
        guard
            let delegate = machine as? CBPeripheralDelegate
        else { return fail("couldn't cast machine as CBPeripheralDelegate") }
        
        print("Found peripheral: \(peripheral.name ?? "<no name>")")
        
        peripheral.delegate = delegate
        proceed(ClientConnectState)
    }
    
    override func exit() {
        context.centralManager?.stopScan()
    }
}

class ClientConnectState: ClientState {
    override func enter() {
        guard
            let peripheral = context.activePeripheral
        else { return fail("bad context") }

        context.centralManager?.connectPeripheral(peripheral, options: nil)
        handle(event: "connectedPeripheral", with: handleConncetedPeripheral)
    }
    
    func handleConncetedPeripheral(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }

        print("Peripheral connected")
        proceed(ClientDiscoverServiceState)
    }
}

class ClientDiscoverServiceState: ClientState {
    override func enter() {
        guard
            let peripheral = context.activePeripheral
        else { return fail("bad context") }
        
        peripheral.discoverServices([u2fServiceUUID])
        
        handle(event: "discoveredServices", with: handleDiscoveredServices)
    }
    
    func handleDiscoveredServices(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }

        guard
            let services = context.activePeripheral?.services,
            let service = services.filter({ $0.UUID == u2fServiceUUID }).first
        else {
            return fail("peripheral doesn't implement U2F service")
        }
        
        print("Discovered U2F service")
        context.activeService = service
        proceed(ClientDiscoverCharacteristicState)
    }
}

class ClientDiscoverCharacteristicState: ClientState {
    override func enter() {
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
    
    func handleDiscoveredCharacteristics(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        
        guard
            let service = context.activeService,
            let characteristics = service.characteristics
        else { return fail("bad context") }
        
        print("Discovered characteristics")
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
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.serviceRevisionCharacteristic
        else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handle(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        
        guard
            let characteristic = context.serviceRevisionCharacteristic,
            let value = characteristic.value
        else { return fail("bad context") }
        
        if String(data: value, encoding: NSUTF8StringEncoding) != "1.0" {
            return fail("unknown service revision")
        }
        
        print("valid service revision")
        proceed(ClientReadControlPointLengthState)
    }
}

class ClientReadControlPointLengthState: ClientState {
    override func enter() {
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.controlPointLengthCharacteristic
        else { return fail("bad context") }
        
        peripheral.readValueForCharacteristic(characteristic)
        
        handle(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
    }
    
    func handleUpdatedCharacteristic(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        
        guard
            let characteristic = context.controlPointLengthCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if value.getInt(2) != 512 {
            return fail("expected control point size to be 512")
        }
        
        print("valid control point length")
        proceed(ClientReadMessageState)
    }
}

class ClientReadMessageState: ClientState {
    override func enter() {
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }

        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        
        handle(event: "updatedCharacteristic", with: handleUpdatedCharacteristic)
        handle(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
    }
    
    func handleUpdatedCharacteristic(error: NSError?) {
        if let e = error { return fail(e.localizedDescription) }
        
        guard
            let characteristic = context.statusCharacteristic,
            let value = characteristic.value
        else { return fail("bad context") }
        
        let strValue = String(data: value, encoding: NSUTF8StringEncoding)
        print("Read packet: '\(strValue)'")
    }
    
    func handleNotificationStateUpdate(error: NSError?) {
        guard
            let characteristic = context.statusCharacteristic
        else { return fail("bad context") }

        print("notification state updated: notifying=\(characteristic.isNotifying)")
    }
}

class ViewController: NSViewController {
    var u2fClient: Client?

    override func viewDidLoad() {
        super.viewDidLoad()
        u2fClient = Client()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

