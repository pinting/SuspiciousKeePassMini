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

import UIKit


class RenameDatabaseViewController: UITableViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var correntPwdTextFiled: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    @IBOutlet weak var confirmPwdTextField: UITextField!
    
    var donePressed: ((RenameDatabaseViewController, _ originalUrl: URL, _ newUrl: URL, _ cuurentPassword: String, _ newPassword: String) -> Void)?
    var originalUrl: URL!
    var renameOnly: Bool!
    var showPWDButton: UIImageView!
    var showConfirmButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.isEnabled = true
        
        if(renameOnly == false){
            nameTextField.isEnabled = false
            var createPWDButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            createPWDButton.setTitle("...", for: .normal)
            createPWDButton.addTarget(self,
                                      action: #selector(createPassword),
                                      for: .touchUpInside)
            
            pwdTextField.rightViewMode = UITextField.ViewMode.always
            pwdTextField.rightView = createPWDButton
            
            showPWDButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            showPWDButton.image = UIImage(named: "eye") //setTitle("...", for: .normal)
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showPasswords))
            showPWDButton.isUserInteractionEnabled = true
            showPWDButton.addGestureRecognizer(singleTap)
            
            correntPwdTextFiled.rightViewMode = UITextField.ViewMode.always
            correntPwdTextFiled.rightView = showPWDButton
            
            showConfirmButton = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            showConfirmButton.image = UIImage(named: "eye") //setTitle("...", for: .normal)
            let singleConfTap = UITapGestureRecognizer(target: self, action: #selector(showConfirmPasswords))
            showConfirmButton.isUserInteractionEnabled = true
            showConfirmButton.addGestureRecognizer(singleConfTap)
            
            correntPwdTextFiled.rightViewMode = UITextField.ViewMode.always
            confirmPwdTextField.rightView = showConfirmButton
            
            let appSettings = AppSettings.sharedInstance() as AppSettings
            let filename = originalUrl.lastPathComponent
            // Check if we should move the saved passwords to the new filename
            if (appSettings.rememberPasswordsEnabled() == true) {
                // Load the password and keyfile from the keychain under the old filename
                
                let currentpwd = KeychainUtils.string(forKey: filename, andServiceName: "KEYCHAIN_PASSWORDS_SERVICE")
                correntPwdTextFiled.text = currentpwd;
                
            }
            
            if(appSettings.touchIdEnabled() == true){
                let databaseManager = DatabaseManager.sharedInstance()
                
                
                let cpwd =  databaseManager?.getKeyChainPWDWithBioMetrics(forFile: filename)
                if(cpwd != nil){
                    if(!cpwd!.isEmpty){
                        correntPwdTextFiled.text = cpwd;
                    }
                }
                
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameTextField.text = originalUrl.deletingPathExtension().lastPathComponent
    }
    
    @objc func showPasswords(){
        if (!correntPwdTextFiled.isSecureTextEntry) {
            // Clear the password first, since you can't edit a secure text entry once set
            //correntPwdTextFiled.text = ""
            correntPwdTextFiled.isSecureTextEntry = true
            
            // Change the image
            showPWDButton.image = UIImage(named: "eye")
        } else {
            correntPwdTextFiled.isSecureTextEntry = false
            
            // Change the image
            showPWDButton.image = UIImage(named: "eye-slash")
        }
    }
    
    @objc func showConfirmPasswords(){
        if (!pwdTextField.isSecureTextEntry) {
            // Clear the password first, since you can't edit a secure text entry once set
            //correntPwdTextFiled.text = ""
            pwdTextField.isSecureTextEntry = true
            confirmPwdTextField.isSecureTextEntry = true
            // Change the image
            showConfirmButton.image = UIImage(named: "eye")
        } else {
            pwdTextField.isSecureTextEntry = false
            confirmPwdTextField.isSecureTextEntry = false
            // Change the image
            showConfirmButton.image = UIImage(named: "eye-slash")
        }
    }
    
    @objc
    func createPassword() {
        print("CreatePassword")
        let storyboard = UIStoryboard(name: "PasswordGenerator", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        
       /* let passwordGeneratorViewController = navigationController.topViewController as! PasswordGeneratorViewController*/
        let viewController = navigationController.topViewController as! PasswordGeneratorViewController
        viewController.donePressed = { (passwordGeneratorViewController: PasswordGeneratorViewController, password: String) in//try is current master pwd right
            
            self.pwdTextField.text = password
            self.confirmPwdTextField.text = password
            
            self.dismiss(animated: true, completion: nil)
        }
        
        viewController.cancelPressed = { (passwordGeneratorViewController: PasswordGeneratorViewController) in
        
            
            self.dismiss(animated: true, completion: nil)
        }

        present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        donePressedAction(nil)
        return true
    }
    
    // MARK: - Actions
    
    @IBAction func donePressedAction(_ sender: UIBarButtonItem?) {
        let name = nameTextField.text
        pwdTextField.isSecureTextEntry  = false
        let newPwd = pwdTextField.text
        correntPwdTextFiled.isSecureTextEntry = false
        let currentPwd = correntPwdTextFiled.text
        
        let confirm = confirmPwdTextField.text
       
        
        if (name == nil || name!.isEmpty) {
            self.presentAlertWithTitle(NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Filename is invalid", comment: ""))
            return
        }
        
        if(renameOnly == false){
            //Check is pwd, conform and current valid
            if(newPwd == nil || newPwd!.isEmpty || confirm == nil || confirm!.isEmpty || currentPwd == nil || currentPwd!.isEmpty){
                
                self.presentAlertWithTitle(NSLocalizedString("Warning", comment: ""), message: NSLocalizedString("Anything is wrong with your Masterkey", comment: "Please correct Password, Confirm, or New Password"))
                return
            }
        }
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = Date()
        let calendar = Calendar.current
        let hourm = calendar.component(.hour, from: date)*60*60*1000
        let minutem = calendar.component(.minute, from: date)*60*1000
        let secondm = calendar.component(.second, from: date)*1000
        let millis = calendar.component(.nanosecond, from: date)
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let filename =  nameTextField.text!// + "." + dateFormatter.string(from: date)+".\(hourm+minutem+secondm+millis)"
        
        // Create the new URL
       
        
        //newUrl = newUrl.appendingPathExtension("bck")
    
        
       // if(renameonly == true){
       //     donePressed?(self, originalUrl, newUrl, "", "")
        //}else{
        if(renameOnly == true){
            var newUrl = originalUrl.deletingLastPathComponent()
            newUrl = newUrl.appendingPathComponent(filename)
            newUrl = newUrl.appendingPathExtension(originalUrl.pathExtension)
            donePressed?(self, originalUrl, newUrl, currentPwd!, "")
        }else{
            var backurl = originalUrl.deletingLastPathComponent()
            backurl = backurl.appendingPathComponent(filename)
            backurl = backurl.appendingPathExtension(originalUrl.pathExtension)
          
            donePressed?(self, originalUrl, backurl, currentPwd!, newPwd!)
        }
        //}
    }
    
    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
