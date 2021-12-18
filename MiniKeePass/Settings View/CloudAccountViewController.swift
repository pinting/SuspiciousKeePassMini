//
//  CloudAccountView.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 13.10.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation

class CloudAccountViewController: UITableViewController, UITextFieldDelegate {
    

    
    @IBOutlet weak var accountText: UITextField!
    @IBOutlet weak var urlText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    @IBOutlet weak var cloudType: UISegmentedControl!
    
    @IBOutlet weak var showImageView: UIImageView!
    
    public var user: String = ""
    public var pwd: String = ""
    public var url: String = ""
    public var selindex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordText.delegate = self
        urlText.delegate = self
        accountText.delegate = self
        accountText.text = user
        urlText.text = url
        passwordText.text = pwd
        cloudType.selectedSegmentIndex = selindex
    }
    
  
    @IBAction func accountChange(_ sender: UITextField) {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        user = sender.text!
        appSettings.setCloudUser(user)
    }
    
    @IBAction func cloudTypeChanged(_ sender: UISegmentedControl) {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        appSettings.setCloudType(sender.selectedSegmentIndex)
    }
    
    @IBAction func urlChange(_ sender: UITextField) {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        url = sender.text!
        appSettings.setCloudURL(url)
    }
    
    @IBAction func pwdCange(_ sender: UITextField) {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        pwd = sender.text!
        appSettings.setCloudPWD(pwd)
    }
    
    @IBAction func showPressed(_ sender: UITapGestureRecognizer) {
        if (!passwordText.isSecureTextEntry) {
            // Clear the password first, since you can't edit a secure text entry once set
            passwordText.text = ""
            passwordText.isSecureTextEntry = true
            
            // Change the image
            showImageView.image = UIImage(named: "eye")
        } else {
            passwordText.isSecureTextEntry = false
            
            // Change the image
            showImageView.image = UIImage(named: "eye-slash")
        }
    }

}
