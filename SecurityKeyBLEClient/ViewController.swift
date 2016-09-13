//
//  ViewController.swift
//  SecurityKeyBLEClient
//
//  Created by Benjamin P Toews on 9/5/16.
//  Copyright © 2016 GitHub. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    var client = Client()

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
}

