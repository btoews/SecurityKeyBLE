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
    var centralManager:                   CBCentralManager?
    var activePeripheral:                 CBPeripheral?
    var activeService:                    CBService?
    var activeCharacteristic:             CBCharacteristic?
    var controlPointCharacteristic:       CBCharacteristic?
    var statusCharacteristic:             CBCharacteristic?
    var controlPointLengthCharacteristic: CBCharacteristic?
    var serviceRevisionCharacteristic:    CBCharacteristic?
    
    required init() {}
}

class Client: StateMachine<ClientContext>, CBCentralManagerDelegate, CBPeripheralDelegate {
    override init() {
        super.init()
        
        context.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        failure = ClientInitialState.self
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
            print("centralManager powered on")
            proceed(ClientScanState)
        } else {
            fail("centralManager not powered on")
        }
    }
}

class ClientScanState: ClientState {
    override func enter() {
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
        
        print("Found peripheral: \(peripheral.name ?? "<no name>")")
        
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
        guard
            let peripheral = context.activePeripheral,
            let manager = context.centralManager
            else { return fail("bad context") }
        
        manager.connectPeripheral(peripheral, options: nil)
        handle(event: "connectedPeripheral", with: handleConncetedPeripheral)
    }
    
    func handleConncetedPeripheral() {
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
    
    func handleDiscoveredServices() {
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
    
    func handleDiscoveredCharacteristics() {
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
    
    func handleUpdatedCharacteristic() {
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
    
    func handleUpdatedCharacteristic() {
        guard
            let characteristic = context.controlPointLengthCharacteristic,
            let value = characteristic.value
            else { return fail("bad context") }
        
        if value.getInt(2) != CharacteristicMaxSize {
            return fail("expected control point size to be \(CharacteristicMaxSize)")
        }
        
        print("valid control point length")
        proceed(ClientSubscribeToServerState)
    }
}

class ClientSubscribeToServerState: ClientState {
    override func enter() {
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
    var fragments = BLEMessage(cmd: .Msg, data: "We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty, and the pursuit of Happiness. That to secure these rights, Governments are instituted among Men, deriving their just powers from the consent of the governed, That whenever any Form of Government becomes destructive of these ends, it is the Right of the People to alter or to abolish it, and to institute new Government, laying its foundation on such principles and organizing its powers in such form, as to them shall seem most likely to effect their Safety and Happiness.  Prudence, indeed, will dictate that Governments long established should not be changed for light and transient causes; and accordingly all experience hath shown, that mankind are more disposed to suffer, while evils are sufferable, than to right themselves by abolishing the forms to which they are accustomed.  But when a long train of abuses and usurpations, pursuing invariably the same Object evinces a design to reduce them under absolute Despotism, it is their right, it is their duty, to throw off such Government, and to provide new Guards for their future security. --Such has been the patient sufferance of these Colonies; and such is now the necessity which constrains them to alter their former Systems of Government. The history of the present King of Great Britain is a history of repeated injuries and usurpations, all having in direct object the establishment of an absolute Tyranny over these States.  To prove this, let Facts be submitted to a candid world.".dataUsingEncoding(NSUTF8StringEncoding)!).generate()
    
    var nextFragment: NSData?

    override func enter() {
        writeNextFragment()
        handle(event: "wroteCharacteristic", with: writeNextFragment)
    }
    
    func writeNextFragment() {
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.controlPointCharacteristic
        else { return fail("bad context") }

        guard
            let fragment = nextFragment ?? fragments.next()
        else {
            return proceed(ClientResponseState)
        }
        
        peripheral.writeValue(fragment, forCharacteristic: characteristic, type: .WithResponse)
        
        nextFragment = fragments.next()
        if nextFragment == nil {
            // Don't wait for the server's ACK. We need to get to the response-state
            // quickly so we don't miss a fragment.
            return proceed(ClientResponseState)
        }
    }
}

class ClientResponseState: ClientState {
    var u2fResp = BLEMessage()
    
    override func enter() {
        guard
            let peripheral = context.activePeripheral,
            let characteristic = context.statusCharacteristic
            else { return fail("bad context") }
        
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
        
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
            try u2fResp.readFragment(fragment)
        } catch {
            return fail("error receiving fragment")
        }
        
        if u2fResp.isComplete {
            guard
                let data   = u2fResp.data,
                let strMsg = String(data: data, encoding: NSUTF8StringEncoding)
                else { return fail("error receiving message") }
            
            print("message from client: \(strMsg)")
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
        handle(event: "notificationStateUpdate", with: handleNotificationStateUpdate)
    }

    func handleNotificationStateUpdate() {
    }
}