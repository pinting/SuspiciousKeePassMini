/*
 * Copyright 2016 Jason Rush and John Flanagan. All rights reserved.
 * Mdified by Frank Hausmann 2020-2021
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

protocol NewDatabaseDelegate {
    func newDatabaseCreated(filename: String)
    func newKeyfileCreated(filename: String)
}

class NewDatabaseViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var versionSegmentedControl: UISegmentedControl!

    @IBOutlet weak var generateKeyFile: UIButton!
    var delegate: NewDatabaseDelegate?
    var keyfilename: String?
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        generateKeyFile.isEnabled = false
        keyfilename = "";
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
       // view.tintColor = UIColor.red
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        if #available(iOS 13.0, *) {
            if (appSettings.darkEnabled()) {
                let header = view as! UITableViewHeaderFooterView
                header.textLabel?.textColor = UIColor.white
                    
               
            }else{
                let header = view as! UITableViewHeaderFooterView
                header.textLabel?.textColor = UIColor.black
               
            }
        }
        
    }
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == nameTextField) {
            passwordTextField.becomeFirstResponder()
        } else if (textField == passwordTextField) {
            confirmPasswordTextField.becomeFirstResponder()
        } else if (textField == confirmPasswordTextField) {
            donePressedAction(nil)
        }
        return true
    }
    
    @IBAction func OnGenerateKeyFile(_ sender: UIButton) {
        if(sender.isEnabled == true){
            var keydata = String()
            for _ in 0...31 {
                let val = UInt8.random(in: 32..<254)
                let uc = UnicodeScalar(val)
                keydata += String(Character(uc))
            }
            //let str = String(data: data, encoding: .ascii)
    
            keyfilename = nameTextField.text! + String(".keyx")
            var url = AppDelegate.documentsDirectoryUrl()
            url = url?.appendingPathComponent(keyfilename!)
            
            if url == nil {
                presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Could not create file path", comment: ""))
                return
            }
            
            do {
                try keydata.write(to: url!, atomically: false, encoding: .utf8)
                presentAlertWithTitle("Success", message: "We hav create a Keyfile, please hold this file secure, if you lost, no recover is possible")
                }
                catch let error as NSError {
                        print(error)
                    
                }
            
         
        
        }
    }
    
    @IBAction func changeDBtype(_ sender: UISegmentedControl) {
        if(sender.selectedSegmentIndex == 0){
            generateKeyFile.isEnabled = false
        }else{
            generateKeyFile.isEnabled = true
        }
        
        if(nameTextField.text?.isEmpty == true){
            generateKeyFile.isEnabled = false
        }
    }
    // MARK: - Actions

    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        // Check to make sure the name was supplied
        guard let name = nameTextField.text, !(name.isEmpty) else {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Database name is required", comment: ""))
            return
        }

        // Check the passwords
        guard let password1 = passwordTextField.text, !(password1.isEmpty),
            let password2 = confirmPasswordTextField.text, !(password2.isEmpty) else {
                presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Password is required", comment: ""))
                return
        }

        if (password1 != password2) {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Passwords do not match", comment: ""))
            return
        }

        var version: Int
        var extention: String

        switch(versionSegmentedControl.selectedSegmentIndex)
        {
        case 0:
            version = 1
            extention = "kdb"
            break
            
        case 1:
            version = 2
            extention = "kdbx"
            break;
            
        case 2:
            version = 3
            extention = "kdbx"
            break;
        default:
            version = 3
            extention = "kdbx"
            break;
        }
        
        /*if (versionSegmentedControl.selectedSegmentIndex == 0) {
            version = 1
            extention = "kdb"
        } else {
            version = 2
            extention = "kdbx3"
        }*/
        
        // Create a URL to the file
        var url = AppDelegate.documentsDirectoryUrl()
        url = url?.appendingPathComponent("\(name).\(extention)")
        
        if url == nil {
            presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Could not create file path", comment: ""))
            return
        }

        // Check if the file already exists
        do {
            if try url!.checkResourceIsReachable() {
                presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("A file already exists with this name", comment: ""))
                return
            }
        } catch {
        }

        // Create the new database
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.newDatabase(url, password: password1, version: version, keyfile: keyfilename)
        
        delegate?.newDatabaseCreated(filename: url!.lastPathComponent)
        if(!keyfilename!.isEmpty)
        {
            var keyurl = AppDelegate.documentsDirectoryUrl()
            keyurl = keyurl?.appendingPathComponent(keyfilename!)
            delegate?.newKeyfileCreated(filename: keyurl!.lastPathComponent)
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
