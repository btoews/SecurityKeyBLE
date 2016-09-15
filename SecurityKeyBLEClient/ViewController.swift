//
//  ViewController.swift
//  SecurityKeyBLEClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let client = Client()
        
        client.subscribe(statusUpdated)
        
        guard let msg = bleRegisterRequest() else {
            print("couldn't generate register request")
            return
        }

        client.request(msg) { response in
            do {
                let apdu:APDUResponse<RegisterResponse> = try response.unwrapAPDU()
                let regResp = apdu.data
                print("key handle: \(regResp.keyHandle)")
            } catch {
                print("something else blew up")
            }
        }
    }
    
    func bleRegisterRequest() -> BLEMessage? {
        do {
            let origin = "https://github.com"
            let cd = ClientData(typ: .Register, origin: origin)
            let chal = try cd.digest()
            let app = try SHA256.digest(origin.dataUsingEncoding(NSUTF8StringEncoding)!)
            let req = RegisterRequest(challengeParameter: chal, applicationParameter: app)
            return try req.bleWrapped()
        } catch {
            print("something blew up")
            return nil
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func statusUpdated(status:ClientStatus) {
        var msg:String? = nil
        
        switch status {
        case .Initializing:
            msg = "Initializing…"
        case .Scanning:
            msg = "Scanning for U2F devices…"
        case .Connecting:
            msg = "Connecting to device…"
        case .SendingRequest:
            msg = "Sending request…"
        case .ReceivingResponse:
            msg = "Receiving response…"
        case .Finished:
            msg = "All done…"
        default:
            break
        }
        
        if let m = msg {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusLabel.stringValue = m
            }
        }
    }
}

