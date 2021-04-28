//
//  YubikeyViewController.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 21.04.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation
//import XCTest

class YubiKeyViewController: UITableViewController {
    
    var pwdcontroller:PasswordEntryViewController?
    
    @IBOutlet weak var showYubikeyHardware: UIImageView!
    @IBOutlet weak var slotSelected: UISegmentedControl!
    
    lazy var conn: YubiKeyConnection = {
      return YubiKeyConnection()
    }()
    
    @objc var pwdstr: String!
    @objc var challengeData: NSData!
    
    @IBOutlet weak var YubikeyHardwareLabel: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            
            conn = YubiKeyConnection()
            
            conn.connection(completion: {_ in
                           ///
                print("Connection cimpletion")
                self.conn.readconfig(completion: {_ in
                 
                })
                
            })
            
        
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            YubiKitManager.shared.stopAccessoryConnection()
            
            if(challengeData != nil){
                self.pwdcontroller?.retrieveChallengaData(data:self.challengeData)
            }
        }
        
    }

    @objc var challengePressed: ((YubiKeyViewController) -> Void)?
    
    @IBAction func challengeButtonPressed(_ sender: Any) {
        if YubiKitDeviceCapabilities.supportsMFIAccessoryKey {
            //conn = YubiKeyConnection()
            
            conn.connection(completion: {_ in
                           ///
                
                print("Try an challenge Response ")
                self.conn.pwdData = self.pwdstr;
                self.conn.selectedIndex = 1 //self.slotSelected.selectedSegmentIndex
                
                self.conn.challengeResponse(completion: {_ in
                    self.challengeData = self.conn.challengeData
                    //print(self.conn.challengeData)
                    
                    //
                })
                
               
            })
            //
            //self.dismiss(animated: true, completion: nil)
        } else {
            print("This device or iOS version does not support operations with MFi accessory YubiKeys.")
        
            
        }
        
    }
}
