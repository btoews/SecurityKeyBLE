//
//  ViewController.swift
//  SecurityKeyBLEClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, LoggerProtocol {
    @IBOutlet weak var statusLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let client = Client(logger: self)
        
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
    
    func log(msg:String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.statusLabel.stringValue = msg
        }
    }
}

