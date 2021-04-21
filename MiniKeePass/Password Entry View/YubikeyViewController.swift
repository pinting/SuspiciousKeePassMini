//
//  YubikeyViewController.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 21.04.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation


class YubiKeyViewController: UITableViewController {
    
    @IBOutlet weak var showYubikeyHardware: UIImageView!
    @IBOutlet weak var slotSelected: UISegmentedControl!
    
    @IBOutlet weak var YubikeyHardwareLabel: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }
    
    @IBAction func challengeButtonPressed(_ sender: Any) {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            // Make sure the session is started (in case it was closed by another demo).
            let data: Data? = "Test123".data(using: .utf8)
            let ccn = YKFNFCConnection()
            ccn.challengeResponseSession {
                session, error in
                guard let session = session else {
                    print(error as Any); return }
                session.sendChallenge(data!, slot: .one) {
                    response, error in
                    print(response as Any)
                }
            }
            
            
            
            // Enable state observation (see MFIKeyInteractionViewController)
            //observeAccessorySessionStateUpdates = true
        } else {
            print("This device or iOS version does not support operations with MFi accessory YubiKeys.")
        }
    }
}
