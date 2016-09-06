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
    
    required init(client: Client) {
        self.client = client
        super.init()
        enter()
    }
    
    func enter() {
        print("entering state: \(self.className)")
    }
    
    func proceed() {
        beforeExit()

        guard let state = nextState else {
            print("State machine finished.")
            return
        }
        
        client.state = state.init(client: client)
    }
    
    func beforeExit() {
        print("exiting state: \(self.className)")
    }
}

class InitState: ClientState {
    override var nextState: ClientState.Type? { return ScanState.self }
}

class ScanState: ClientState {
    override var nextState: ClientState.Type? { return DiscoverServiceState.self }
}

class DiscoverServiceState: ClientState {
    override var nextState: ClientState.Type? { return DiscoverCharacteristicState.self }
}

class DiscoverCharacteristicState: ClientState {
    override var nextState: ClientState.Type? { return nil }
}

class Client {
    var centralManager: CBCentralManager?
    var activePeripheral: CBPeripheral?
    var activeService: CBService?
    var controlPointCharacteristic: CBCharacteristic?
    var statusCharacteristic: CBCharacteristic?
    var controlPointLengthCharacteristic: CBCharacteristic?
    var serviceRevisionCharacteristic: CBCharacteristic?
    
    var state: ClientState?
    
    init() {
        state = InitState(client: self)
    }
}

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var activePeripheral: CBPeripheral?
    private var activeService: CBService?
    private var controlPointCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?
    private var controlPointLengthCharacteristic: CBCharacteristic?
    private var serviceRevisionCharacteristic: CBCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if centralManager!.state == CBCentralManagerState.PoweredOn {
            reset()
        } else {
            print("Can't scan for peripherals. Central manager not powered on.")
            centralManager!.stopScan()
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        activePeripheral = peripheral
        print("Found peripheral: \(activePeripheral?.name ?? "<no name>")")
        
        print("Stopping scan")
        centralManager!.stopScan()
        
        print("Connecting...")
        activePeripheral!.delegate = self
        centralManager!.connectPeripheral(activePeripheral!, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connected peripheral: \(activePeripheral?.name ?? "<no name>")")
        
        print("Discovering services...")
        activePeripheral?.discoverServices([u2fServiceUUID])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral) {
        print("didFailToConnectPeripheral")
        reset()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral")
        reset()
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        
        guard
            let services = peripheral.services,
            let service = services.filter({ $0.UUID == u2fServiceUUID }).first
        else {
            print("Didn't find u2fService")
            return
        }
        
        print("Discovering characteristics...")
        peripheral.discoverCharacteristics([
            u2fControlPointCharacteristicUUID,
            u2fStatusCharacteristicUUID,
            u2fControlPointLengthCharacteristicUUID,
            u2fServiceRevisionCharacteristicUUID
        ], forService: service)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if error != nil {
            print("Error discovering characteristics")
            print(error!.localizedDescription)
        }

        guard let chars = service.characteristics else {
            print("Error discovering characteristics")
            return
        }
        
        for char in chars {
            switch char.UUID {
            case u2fControlPointCharacteristicUUID:
                controlPointCharacteristic = char
            case u2fStatusCharacteristicUUID:
                statusCharacteristic = char
                activePeripheral?.setNotifyValue(true, forCharacteristic: char)
            case u2fControlPointLengthCharacteristicUUID:
                controlPointLengthCharacteristic = char
                activePeripheral!.readValueForCharacteristic(char)
            case u2fServiceRevisionCharacteristicUUID:
                serviceRevisionCharacteristic = char
                activePeripheral!.readValueForCharacteristic(char)
            default:
                2
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            print("Error getting characteristic value: \(error?.localizedDescription)")
            return
        }
        
        var i: UInt16 = 0
        characteristic.value?.getBytes(&i, length: 2)
        print("\(characteristic.UUID): \(i)")
    }
    
    func reset() {
        print("Resetting everything and starting to scan.")
        activePeripheral = nil
        activeService = nil
        controlPointCharacteristic = nil
        statusCharacteristic = nil
        controlPointLengthCharacteristic = nil
        serviceRevisionCharacteristic = nil
        
        centralManager?.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
    }
    

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

