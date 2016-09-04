//
//  ViewController.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    var securityKeyPeripheral: CBPeripheralManagerDelegate?

    override func viewDidLoad() {
        securityKeyPeripheral = SecurityKeyPeripheral()
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

