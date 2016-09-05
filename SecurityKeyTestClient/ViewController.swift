//
//  ViewController.swift
//  SecurityKeyTestClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa
import CoreBluetooth


class ViewController: NSViewController, CBCentralManagerDelegate {
    var centralManager: CBCentralManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func startScan() {
        if centralManager!.state == CBCentralManagerState.PoweredOn {
            centralManager!.scanForPeripheralsWithServices([u2fServiceUUID], options: nil)
        } else {
            print("Can't scan for peripherals. Central manager not powered on.")
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("centralManagerDidUpdateState: \(centralManager!.state)")
        startScan()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

