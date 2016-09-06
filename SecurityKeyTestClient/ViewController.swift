//
//  ViewController.swift
//  SecurityKeyTestClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ClientState: NSObject {
    var client: Client
    var nextState: ClientState.Type? { return nil }
    var failState: ClientState.Type? { return InitState.self }
    
    required init(client: Client) {
        self.client = client
        super.init()
        beforeEnter()
        enter()
    }

    func beforeEnter() {
        print("entering state: \(self.className)")
    }
    
    func enter() {
    }
    
    func proceed() {
        exit()

        guard let state = nextState else {
            print("No next state. State machine finished.")
            return
        }
        
        client.state = state.init(client: client)
    }
    
    func fail() {
        exit()

        print("failing at state: \(self.className)")
        
        guard let state = failState else {
            print("No fail state. State machine finished.")
            return
        }
        
        client.state = state.init(client: client)
    }
    
    func exit() {
    }
    
    // Default event handlers
    func handleCentralStateUpdate() {
        switch client.centralManager!.state {
        case .Unknown:
            print("While in \(self.className) centralManager entered state 'Unknown'. Resetting.")
        case .Resetting:
            print("While in \(self.className) centralManager entered state 'Resetting'. Resetting.")
        case .Unsupported:
            print("While in \(self.className) centralManager entered state 'Unsupported'. Resetting.")
        case .Unauthorized:
            print("While in \(self.className) centralManager entered state 'Unauthorized'. Resetting.")
        case .PoweredOff:
            print("While in \(self.className) centralManager entered state 'PoweredOff'. Resetting.")
        case .PoweredOn:
            print("While in \(self.className) centralManager entered state 'PoweredOn'. Resetting.")
        }
        fail()
    }
    
    func handleDiscoveredPeripheral(peripheral: CBPeripheral) {
        print("Bad event 'DiscoveredPeripheral' while in \(self.className)")
        fail()
    }
    
    func handleConncetedPeripheral() {
        print("Bad event 'ConncetedPeripheral' while in \(self.className)")
        fail()
    }

    func handleDiscoveredServices(error: NSError?) {
        print("Bad event 'DiscoveredServices' while in \(self.className)")
        fail()
    }
    
    func handleDiscoveredCharacteristics(error: NSError?) {
        print("Bad event 'DiscoveredCharacteristics' while in \(self.className)")
        fail()
    }
    
    func handleUpdatedCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        print("Bad event 'UpdatedCharacteristic' while in \(self.className)")
        fail()
    }
    
    func handleNotificationStateUpdate(error: NSError?) {
        print("Bad event 'NotificationStateUpdate' while in \(self.className)")
        fail()
    }
}

class InitState: ClientState {
    override var nextState: ClientState.Type? { return ScanState.self }
    
    override func enter() {
        client.activePeripheral = nil
        client.activeService = nil
        client.controlPointCharacteristic = nil
        client.statusCharacteristic = nil
        client.controlPointLengthCharacteristic = nil
        client.serviceRevisionCharacteristic = nil
    }
    
    override func handleCentralStateUpdate() {
        if client.centralManager?.state == .PoweredOn {
            print("centralManager powered on")
            proceed()
        } else {
            super.handleCentralStateUpdate()
        }
    }
}

class ScanState: ClientState {
    override var nextState: ClientState.Type? { return ConnectState.self }
    
    override func enter() {
        client.centralManager?.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
    }
    
    override func handleDiscoveredPeripheral(peripheral: CBPeripheral) {
        print("Found peripheral: \(peripheral.name ?? "<no name>")")
        peripheral.delegate = client
        client.activePeripheral = peripheral
        proceed()
    }
    
    override func exit() {
        client.centralManager?.stopScan()
    }
}

class ConnectState: ClientState {
    override var nextState: ClientState.Type? { return DiscoverServiceState.self }
    
    override func enter() {
        if let peripheral = client.activePeripheral {
            client.centralManager?.connectPeripheral(peripheral, options: nil)
        }
    }
    
    override func handleConncetedPeripheral() {
        print("Peripheral connected")
        proceed()
    }
}

class DiscoverServiceState: ClientState {
    override var nextState: ClientState.Type? { return DiscoverCharacteristicState.self }
    
    override func enter() {
        if let peripheral = client.activePeripheral {
            peripheral.discoverServices([u2fServiceUUID])
        }
    }
    
    override func handleDiscoveredServices(error: NSError?) {
        if error != nil {
            print("error discovering services: \(error?.localizedDescription)")
            fail()
            return
        }

        guard
            let services = client.activePeripheral?.services,
            let service = services.filter({ $0.UUID == u2fServiceUUID }).first
        else {
            print("Peripheral doesn't implement U2F service")
            fail()
            return
        }
        
        print("Discovered U2F service")
        client.activeService = service
        proceed()
    }
}

class DiscoverCharacteristicState: ClientState {
    override var nextState: ClientState.Type? { return ReadServiceRevisionState.self }
    
    override func enter() {
        if let peripheral = client.activePeripheral, let service = client.activeService {
            peripheral.discoverCharacteristics(
                [
                    u2fControlPointCharacteristicUUID,
                    u2fStatusCharacteristicUUID,
                    u2fControlPointLengthCharacteristicUUID,
                    u2fServiceRevisionCharacteristicUUID
                ], forService: service
            )
        }
    }
    
    override func handleDiscoveredCharacteristics(error: NSError?) {
        if error != nil {
            print("Error discovering characteristics: \(error!.localizedDescription)")
            fail()
            return
        }
        
        guard
            let service = client.activeService,
            let characteristics = service.characteristics
        else {
            print("Error discovering characteristics")
            fail()
            return
        }
        
        print("Discovered characteristics")
        
        for characteristic in characteristics {
            switch characteristic.UUID {
            case u2fControlPointCharacteristicUUID:
                client.controlPointCharacteristic = characteristic
            case u2fStatusCharacteristicUUID:
                client.statusCharacteristic = characteristic
            case u2fControlPointLengthCharacteristicUUID:
                client.controlPointLengthCharacteristic = characteristic
            case u2fServiceRevisionCharacteristicUUID:
                client.serviceRevisionCharacteristic = characteristic
            default: ()
            }
        }
        
        let chars = [
            client.controlPointCharacteristic,
            client.statusCharacteristic,
            client.controlPointLengthCharacteristic,
            client.serviceRevisionCharacteristic
        ]
        
        if chars.contains({ $0 == nil }) {
            print("Error: services doesn't define all characteristics")
            fail()
            return
        }
        
        proceed()
    }
}

class ReadServiceRevisionState: ClientState {
    override var nextState: ClientState.Type? { return ReadControlPointLengthState.self }
    
    override func enter() {
        if let peripheral = client.activePeripheral, let characteristic = client.serviceRevisionCharacteristic {
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    override func handleUpdatedCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            print("Error reading serviceRevisionCharacteristic: \(error?.localizedDescription)")
            fail()
            return
        }
        
        if characteristic != client.serviceRevisionCharacteristic! {
            print("Read wrong characteristic")
            fail()
            return
        }
        
        let strValue = String(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        if strValue != "1.0" {
            print("Unknown service revision")
            fail()
            return
        }
        
        proceed()
    }
}

class ReadControlPointLengthState: ClientState {
    override var nextState: ClientState.Type? { return ReadMessageState.self }
    
    override func enter() {
        if let peripheral = client.activePeripheral, let characteristic = client.controlPointLengthCharacteristic {
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    override func handleUpdatedCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            print("Error reading controlPointLengthCharacteristic: \(error?.localizedDescription)")
            fail()
            return
        }
        
        if characteristic != client.controlPointLengthCharacteristic! {
            print("Read wrong characteristic")
            fail()
            return
        }
        
        let intValue = characteristic.value!.getInt(2)
        if intValue != 512 {
            print("Expected control point size to be 512. Bailing...")
            fail()
            return
        }
        
        proceed()
    }
}

class ReadMessageState: ClientState {
    override func enter() {
        client.activePeripheral!.setNotifyValue(true, forCharacteristic: client.statusCharacteristic!)
    }
    
    override func handleUpdatedCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            print("Error reading statusCharacteristic: \(error?.localizedDescription)")
            fail()
            return
        }
        
        if characteristic != client.statusCharacteristic! {
            print("Read wrong characteristic")
            fail()
            return
        }
        
        let strValue = String(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        print("Read packet: '\(strValue)'")
    }
    
    override func handleNotificationStateUpdate(error: NSError?) {
        print("notification state updated: notifying=\(client.statusCharacteristic!.isNotifying)")
    }
}

class Client: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var activePeripheral: CBPeripheral?
    var activeService: CBService?
    var controlPointCharacteristic: CBCharacteristic?
    var statusCharacteristic: CBCharacteristic?
    var controlPointLengthCharacteristic: CBCharacteristic?
    var serviceRevisionCharacteristic: CBCharacteristic?
    
    var state: ClientState?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        state = InitState(client: self)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        state!.handleCentralStateUpdate()
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        state!.handleDiscoveredPeripheral(peripheral)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        state!.handleConncetedPeripheral()
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        state!.handleDiscoveredServices(error)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        state!.handleDiscoveredCharacteristics(error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        state!.handleUpdatedCharacteristic(characteristic, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        state!.handleNotificationStateUpdate(error)
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

