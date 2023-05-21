//
//  PropertiesTableViewController.swift
//  KeePassMini
//
//  Created by Frank Hausmann on 17.04.21.
//  Copyright © 2021 Self. All rights reserved.
//

import UIKit

class PropertiesTableViewController: UITableViewController {
    @IBOutlet weak var databaseName: UITextField!
    
    @IBOutlet weak var databaseFormat: UITextField!
    
    @IBOutlet weak var compression: UISwitch!
    
    @IBOutlet weak var Encryption: UISegmentedControl!
    
    @IBOutlet weak var repeats: UITextField!
    @IBOutlet weak var threads: UITextField!
    @IBOutlet weak var rounds: UITextField!
    @IBOutlet weak var algo: UISegmentedControl!
    @IBOutlet weak var memory: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        let appDelegate = AppDelegate.getDelegate()
        let databaseDocument = appDelegate?.databaseDocument
        
        databaseName.text = databaseDocument?.kdbTree.metaData?.databaseName
        databaseFormat.text = databaseDocument?.getFileFormat();
        
        if(databaseDocument?.kdbTree.metaData?.compressionAlgorithm == 0){
            compression.isOn = false;
        }else{
            compression.isOn = true;
        }
        
        let keyDerivation = KPKKeyDerivation.init(parameters: (databaseDocument?.kdbTree.metaData?.keyDerivationParameters)!)
        
        if(keyDerivation .isMember(of: KPKAESKeyDerivation.self)){
            let aesKdf = keyDerivation as! KPKAESKeyDerivation;
            self.rounds.text = String(aesKdf.rounds);
            algo.selectedSegmentIndex=0;
            
            /* fill defaults for Argon2 */
            let argon2Kdf = KPKArgon2DKeyDerivation.init(parameters:KPKArgon2DKeyDerivation.defaultParameters());
            self.repeats.text = String(argon2Kdf.iterations);
            self.memory.text = String(argon2Kdf.memory) + " Byte";
            self.threads.text = String(argon2Kdf.threads);
            /*NSArray *ciphers = [KPKCipher availableCiphers];
            for(KPKCipher *cipher in ciphers) {
              [cipherMenu addItemWithTitle:cipher.name action:NULL keyEquivalent:@""];
              cipherMenu.itemArray.lastObject.representedObject = cipher.uuid;
            }*/
           // var idx = String();
            let cps = KPKCipher.availableCiphers();
            let uid = databaseDocument?.kdbTree.metaData?.cipherUUID;
            cps.forEach{
                cp in
                if(cp.uuid == uid){
                    switch(cp.name){
                    case "AES Rijndale":
                        Encryption.selectedSegmentIndex=0;
                        break;
                    case "ChaCha20":
                        Encryption.selectedSegmentIndex=1;
                        break;
                    case "TwoFish":
                        Encryption.selectedSegmentIndex=2;
                        break;
                        
                    default:
                        Encryption.selectedSegmentIndex=0;
                        break;
                    }
                }
                
                //print(cp.name);
                //print(cp.uuid);
                
            }
            
            
            
            
            print("%@", uid);
            
        }
        
        
    }
    

   
    @IBAction func donePressed(_ sender: UIBarItem) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
