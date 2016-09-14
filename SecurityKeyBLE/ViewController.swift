//
//  ViewController.swift
//  SecurityKeyBLE
//
//  Created by Benjamin P Toews on 9/1/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, LoggerProtocol {
    @IBOutlet weak var statusLabel: UILabel!

    var server: CBPeripheralManagerDelegate?

    override func viewDidLoad() {
        server = Server(logger: self)

        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func log(msg:String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.statusLabel.text = msg
        }
    }
}

