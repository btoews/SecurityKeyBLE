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
    @IBOutlet weak var statusLabel: UILabel!

    override func viewDidLoad() {
        let server = Server()
        
        server.subscribe(statusUpdated)

        server.proceed(ServerInitState.self)

        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func statusUpdated(status:ServerStatus) {
        var msg:String? = nil
        
        switch status {
        case .Initializing:
            msg = "Initializing…"
        case .Advertising:
            msg = "Advertising U2F service…"
        case .ClientSubscribed:
            msg = "Device connected…"
        case .ReceivingRequest:
            msg = "Sending request…"
        case .SendingResponse:
            msg = "Receiving response…"
        case .Finished:
            msg = "All done…"
        default:
            break
        }
        
        if let m = msg {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusLabel.text = m
            }
        }
    }
}

