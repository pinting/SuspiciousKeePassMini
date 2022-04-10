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
import KeyboardGuide
import FilesProvider
import SwiftSpinner
import OAuthSwift
import SwiftUI
//import FLEX

class FilesViewController: UITableViewController, NewDatabaseDelegate,ImportDatabaseDelegate, UIDocumentBrowserViewControllerDelegate, FileProviderDelegate {
    private let databaseReuseIdentifier = "DatabaseCell"
    private let keyFileReuseIdentifier = "KeyFileCell"
    private let trayIdentifier = "TrayCell"
    
    lazy var documentBrowser: DocumentBrowserViewController = {
      return DocumentBrowserViewController()
    }()

    private enum Section : Int {
        case databases = 0
        case keyFiles = 1
        case trayFiles = 2
        static let AllValues = [Section.databases, Section.keyFiles, Section.trayFiles]
    }
    
    
    

    var databaseFiles: [String] = []
    var keyFiles: [String] = []
    var trayFiles: [String] = []
    var webdavProvider: WebDAVFileProvider?
    var ftpProvider: FTPFileProvider?
    var localProvider: LocalFileProvider?
    var iCloudProvider: CloudFileProvider?
    var onedriveProvider: OneDriveFileProvider?
    var oauth: OAuth2Swift?
    var backupcount: Int = 0
    var singleBackup: Int = 0
    var cloudType: Int = 0
    var isFirstTime: Int = 0
    var rfc = UIRefreshControl()
    var cloudButton = UIBarButtonItem()
    override func viewDidLoad() {
        super.viewDidLoad();
        // Activate KeyboardGuide at the beginning of application life cycle.
        KeyboardGuide.shared.activate()
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        appSettings.setfileneedsBackup("")
        let username = appSettings.cloudUser()
        let password = appSettings.cloudPWD()
        cloudType = appSettings.cloudType()
        let syncena = appSettings.backupEnabled()
        let baseURL = appSettings.cloudURL()  //"https://cloud.unicomedv.de/remote.php/dav/files/"+username+"/"
        
        webdavProvider = nil
        ftpProvider = nil
        localProvider = nil
        iCloudProvider = nil
        
        
            switch cloudType{
                case 0:
                if(username != nil && password != nil && baseURL != nil && syncena == true){
                    let credential = URLCredential(user: username!, password: password!, persistence: .permanent)
                    webdavProvider = WebDAVFileProvider(baseURL: URL(string: baseURL!)!, credential: credential)
                    webdavProvider?.delegate = self as FileProviderDelegate
                }
                    break
                case 1:
                
                   DispatchQueue.global(qos: .background).async {
                        print("Init icloud on background thread")
                        self.iCloudProvider = CloudFileProvider(containerId: nil) //"iCloud.unicomedv.de.IOSKeePass")
                        DispatchQueue.main.async {
                            
                            if(self.iCloudProvider != nil){
                                print("finished Init iCloud.")
                                self.iCloudProvider?.delegate = self as FileProviderDelegate
                            }else{
                                print("iCloud not available.")
                            }
                        }
                        
                    }
                   
                    
                    break
                case 2:
                    /*DispatchQueue.global(qos: .background).async {
                        print("Init OneDrive on background thread")
                        self.onedriveProvider = OneDriveFileProvider(credential: credential)
                        
                        DispatchQueue.main.async {
                            if(self.onedriveProvider != nil){
                                print("finished Init Onedrive.")
                                self.onedriveProvider?.delegate = self as FileProviderDelegate
                            }else{
                                print("OneDrive not available.")
                            }
                        }
                    }*/
                    OneDriveRefreshToken()
                    break;
                
                default:
                    break
            }
            
            
            
            /*ftpProvider = FTPFileProvider(baseURL: URL(string: baseURL!)!, mode: FTPFileProvider.Mode.passive, credential: credential)
            ftpProvider?.securedDataConnection = true
            
            iCloudProvider = CloudFileProvider(baseURL: URL(string: baseURL!)!)
            
            localProvider = LocalFileProvider(baseURL: URL(string: baseURL!)!)
            localProvider?.credential = credential
            
            onedriveProvider = OneDriveFileProvider(credential: credential)
            
            dropboxProvider = DropboxFileProvider(credential: credential)*/
        
        self.title =  NSLocalizedString("Files", comment: "")
    
        let flexswipe = UISwipeGestureRecognizer(target : self, action : #selector(onClickedToolFlex))
        flexswipe.direction = .right
        self.view.addGestureRecognizer(flexswipe)

        
        if #available(iOS 13.0, *) {
            if (appSettings.darkEnabled()) {
                UIApplication.shared.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .dark
                    print("Dark mode")
                    self.navigationController?.overrideUserInterfaceStyle = .dark
                }
            }else{
                UIApplication.shared.windows.forEach { window in
                    window.overrideUserInterfaceStyle = .light
                    print("Light mode")
                }
            }
        }
   
        self.rfc.attributedTitle = NSAttributedString(string: "Refresh Fileview")
       // self.rfc.addTarget(self, action: "refreshFiles:", for: UIControl.Event.valueChanged)
        
        self.rfc.addTarget(self, action: #selector(FilesViewController.refreshFiles), for: UIControl.Event.valueChanged)


        self.tableView?.addSubview(rfc)
        //create a new button
        let barButton = UIButton(type: UIButton.ButtonType.custom)
        //set image for button
        barButton.setImage(UIImage(named:"cloudsync"), for: UIControl.State.normal)
        //add function for button
        barButton.addTarget(self, action: #selector(FilesViewController.checkConnection), for: UIControl.Event.touchUpInside)
        //set frame
        //button.frame = CGRectMake(0, 0, 53, 31)
        //let button = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.refresh, target: self, action: Selector("someAction"))
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        cloudButton = UIBarButtonItem(customView: barButton)
        
        if(appSettings.backupEnabled() == true){
            self.navigationItem.leftBarButtonItem = cloudButton
        }

      
        print("HomePath:\(NSHomeDirectory())")
        
    }
    
   
    
    override func viewWillAppear(_ animated: Bool) {
        updateFiles();
        super.viewWillAppear(animated)
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        
        cloudType = appSettings.cloudType()
      /*  switch cloudType{
            case 0:
                copyDocumentsToWebDav()
                break
            case 1:
                copyDocumentsToiCloud()
                break
            case 2:
                copyDocumentsToOneDrive()
                break;
            default:
                copyDocumentsToWebDav()
        }*/
        
        
        let fnb = appSettings.fileneedsBackup()
        if(fnb != "" && appSettings.backupEnabled() == true){
            switch cloudType{
                case 0:
                    needBackupToWebDav()
                    break
                case 1:
                    needBackupToiCloud()
                    break
                case 2:
                    needBackupToOneDrive()
                    break;
               
                default:
                    needBackupToWebDav()
            }
            
        }
        
        
    }
    
     override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if(self.isFirstTime == 0){
           
            let appSettings = AppSettings.sharedInstance() as AppSettings
            //self.databaseFiles[indexPath.row]
            let defname = appSettings.defaultDB()
            if(defname != nil){
                if(defname != "" ){
                    let databaseManager = DatabaseManager.sharedInstance()
                    
                    databaseManager?.openDatabaseDocument(defname, animated: true)
                    let appDelegate = AppDelegate.getDelegate()
                    let document = appDelegate?.getOpenDataBase()
                    if(document != nil){
                        performSegue(withIdentifier: "fileOpened", sender: nil)
                    }
                }
            }
            
            if(databaseFiles.count == 0){
                let notiData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title: NSLocalizedString("Your Files Folder is empty 📂", comment: ""),
                            message: NSLocalizedString("Please use + Button for create a new empty KeePassDB or using Import Button to get your actual KeePass DB from your Sharepoints ⚙️", comment:""),
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: notiData, secounds: 12.0, onTap: nil, onDidDismiss: nil)
            }
            self.isFirstTime = 1
        }
        
     }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "newDatabase"?:
            guard let navigationController = segue.destination as? UINavigationController,
                let newDatabaseViewController = navigationController.topViewController as? NewDatabaseViewController else {
                    return
            }

            newDatabaseViewController.delegate = self
        case "fileOpened"?:
            
            guard let groupViewController = segue.destination as? GroupViewController else {
                return
            }
            
            
            let appDelegate = AppDelegate.getDelegate()
            let document = appDelegate?.getOpenDataBase()//appDelegate?.databaseDocument
            //Check if file is available on cloud connection
             switch cloudType{
                  case 0:
                     if(checkFileVersionOnWebDav(document: document!) == true){
                          //neuere Version gefunden we should handle it
                     }
                      break
                  case 1:
                    DispatchQueue.global(qos: .background).async {
                        if(self.checkFileVersionOniCloud(document: document!) == true){
                              //neuere Version gefunden we should handle it
                         }
                    }
                      break
                  case 2:
                      
                      break;
                  default:
                     if(checkFileVersionOnWebDav(document: document!) == true){
                          //neuere Version gefunden we should handle it
                     }
              }
              
            
            let adb = AutoFillDB()
            let dname = URL(fileURLWithPath: document!.filename).lastPathComponent
            if(!adb.IsKeePassInAutoFill(dbname: dname)){
                
            
            
                let group = DispatchGroup()
                    group.enter()

                    // avoid deadlocks by not using .main queue here
                DispatchQueue.global(qos: .default).async {
                    appDelegate?.buildAutoFillIfNeeded(dname)
                    
                        group.leave()
                    }

                // wait ...
                group.wait()
            }
            
           
            
            groupViewController.parentGroup = document?.kdbTree.root
            groupViewController.title = URL(fileURLWithPath: document!.filename).lastPathComponent
            groupViewController.tagid = 1
            
            
           
        case "importDatabase"?:
           displayDocumentBrowser()
            


        default:
            break
        }
    }
    
    @objc func refreshFiles(sender:AnyObject) {
      self.updateFiles()
      self.tableView.reloadData()
        self.rfc.endRefreshing()
    }

    @objc func checkConnection(sender:AnyObject){
       
    }
    
   func copyDocumentsToFTP()
   {
        
   }
    
    func copyDocumentsToLOCAL()
    {
         
    }
    
    func checkFileVersionOnWebDav(document: DatabaseDocument)->Bool
    {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        var isChecked: Bool = false
        if document == nil {
            return false
        }
        
        if(appSettings.backupEnabled()  == false){
            self.navigationItem.leftBarButtonItem = nil
            return false
        }
        
        if(self.webdavProvider == nil){ //Mainthread problems
            self.navigationItem.leftBarButtonItem = nil
            DispatchQueue.main.async {
                let notiData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                            message: NSLocalizedString("Sorry WebDav temporarily not available", comment: ""),
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
                return false
        }
        
        
        self.webdavProvider?.isReachable(completionHandler:{success,error in
            if(error != nil)
            {
                print("Isreachable Error:\(error?.localizedDescription)")
            }
            if(success == false){
                self.navigationItem.leftBarButtonItem = nil
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry Cloud temporarily not reachable:", comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
               
            }else{
                self.navigationItem.leftBarButtonItem = self.cloudButton
                let localurl = URL(fileURLWithPath: document.filename)
                let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                let localattrib = try? FileManager.default.attributesOfItem(atPath: document.filename)
                self.webdavProvider?.attributesOfItem(path: remotePath, completionHandler:{ attrib, error in
                    if(error == nil){
                        let localdate = localattrib?[FileAttributeKey.modificationDate] as? Date
                        var clouddate:Date = (attrib?.modifiedDate)!
                        let cds = clouddate.timeIntervalSinceReferenceDate //we add 180 secs because the modified date is different between local and cloud
                        let lds = localdate!.timeIntervalSinceReferenceDate+90
                                //return attr[FileAttributeKey.modificationDate] as? Date
                        print("Modify Date:\(attrib?.modifiedDate) local:\(localattrib?[FileAttributeKey.modificationDate]) md5-Base64:\(document.md5Base64)")
                        
                        if(cds > lds){
                            DispatchQueue.main.async {
                                let notiData = HDNotificationData(
                                            iconImage: UIImage(named: "AppIcon"),
                                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                            title: NSLocalizedString("Newer KeePass File ℹ️",comment:""),
                                            message: NSLocalizedString("Newer Keepass file found on your Cloud Storage, please use Cloud sync procedure to syncing to newest content",comment:""),
                                            time:NSLocalizedString("now", comment: ""))
                                        
                                HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                            }
                            isChecked=true
                        }
                    }
                })
                
            }
        })
       return isChecked
    }
    
    func checkFileVersionOniCloud(document: DatabaseDocument)->Bool
    {
        let appSettings = AppSettings.sharedInstance() as AppSettings
        var isChecked: Bool = false
        if document == nil {
            return false
        }
        
        if(appSettings.backupEnabled()  == false){
            self.navigationItem.leftBarButtonItem = nil
            return false
        }
        
        if(self.iCloudProvider == nil){ //Mainthread problems
            self.navigationItem.leftBarButtonItem = nil
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need iCloud Backup ⚠️", comment: ""),
                        message: NSLocalizedString("Sorry iCloud temporarily not available", comment: ""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return false
        }
        
        
        self.iCloudProvider?.isReachable(completionHandler:{success,error in
            if(error != nil)
            {
                print("Isreachable Error:\(error?.localizedDescription)")
            }
            if(success == false){
                self.navigationItem.leftBarButtonItem = nil
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry Cloud temporarily not reachable:", comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
               
            }else{
                self.navigationItem.leftBarButtonItem = self.cloudButton
                let localurl = URL(fileURLWithPath: document.filename)
                let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                let localattrib = try? FileManager.default.attributesOfItem(atPath: document.filename)
               
                
                self.iCloudProvider?.attributesOfItem(path: remotePath, completionHandler:{ attrib, error in
                    if(error == nil && attrib != nil){
                        let localdate = localattrib?[FileAttributeKey.modificationDate] as? Date
                       
                        var clouddate:Date = (attrib?.modifiedDate)!
                        let cds = clouddate.timeIntervalSinceReferenceDate //we add 180 secs because the modified date is different between local and cloud
                        let lds = localdate!.timeIntervalSinceReferenceDate+90
                                //return attr[FileAttributeKey.modificationDate] as? Date
                        print("Modify Date:\(attrib?.modifiedDate) local:\(localattrib?[FileAttributeKey.modificationDate]) md5-Base64:\(document.md5Base64)")
                        
                        if(cds > lds){
                            DispatchQueue.main.async {
                                let notiData = HDNotificationData(
                                            iconImage: UIImage(named: "AppIcon"),
                                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                            title: NSLocalizedString("Newer KeePass File ℹ️",comment:""),
                                            message: NSLocalizedString("Newer Keepass file found on your Cloud Storage, please use Cloud sync procedure to syncing to newest content",comment:""),
                                            time:NSLocalizedString("now", comment: ""))
                                        
                                HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                            }
                            isChecked=true
                        }
                    }
                })
                
            }
        })
       return isChecked
    }
    func needBackupToWebDav(){
        /*let appSettings = AppSettings.sharedInstance() as AppSettings
        let username = appSettings.cloudUser()
        let password = appSettings.cloudPWD()
        let baseURL = appSettings.cloudURL()  //"https://cloud.unicomedv.de/remote.php/dav/files/"+username+"/"
        let credential = URLCredential(user: username!, password: password!, persistence: .permanent)
        
        self.webdavProvider = WebDAVFileProvider(baseURL: URL(string: baseURL!)!, credential: credential)*/
       
            
        if(self.webdavProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: NSLocalizedString("Sorry Cloud temporarily not reachable:", comment:""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
                return
        }
        
        self.webdavProvider?.isReachable(completionHandler:{success,error in
            if(success == false){
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry Cloud connection temporarily not reachable:",comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
            }else{
                DispatchQueue.main.async {
                    let appSettings = AppSettings.sharedInstance() as AppSettings
                    self.singleBackup = 1
                    if (appSettings.backupEnabled() && self.webdavProvider != nil) {
                        // Setup iCloud Nexcloud
                        let fnb = appSettings.fileneedsBackup()
                        
                       // let dir = FileManager.default //urls(for: .documentDirectory, in: .userDomainMask).first
                        let localurl = URL(fileURLWithPath: fnb!)
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        let icloudKeePassPath = "/IOSKeePass"
                        let icloudBackupPath =  "/IOSKeePass/Backups"
                        //Check is IOSKeePass on Cloud
                        self.webdavProvider?.attributesOfItem(path: icloudKeePassPath, completionHandler:{ attribute, error in
                            
                            if(attribute == nil){
                                
                                print("Error on webDav Direcrory:\(icloudKeePassPath) not exists")
                                self.webdavProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                                    print("Error can´t Create Directory IOSKeePass:\(err)")
                                })
                            }else{
                                print("Directory IOSKeePass Exists")
                            }
                            
                            self.webdavProvider?.attributesOfItem(path: icloudBackupPath, completionHandler:{ attribute, error in
                                
                                if(attribute == nil){
                                    DispatchQueue.main.async {
                                        let notiData = HDNotificationData(
                                                    iconImage: UIImage(named: "AppIcon"),
                                                    appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                                    title:  NSLocalizedString("Create Cloud Infrastructure ⚠️", comment: ""),
                                                    message: NSLocalizedString("Createing Directorys on Cloud please try it again ✅",comment:""),
                                                    time: NSLocalizedString("now", comment: ""))
                                                
                                        HDNotificationView.show(data: notiData,secounds:9.0, onTap: nil, onDidDismiss: nil)
                                    }
                                    print("Error on webdav contents of Direcrory:\(icloudBackupPath)")
                                    self.webdavProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                                        print("Error can´t Create Directory Backups:\(err)")
                                        
                                    })
                                    
                                    
                                }else{
                                    print("Directory IOSKeePass Exists")
                                }
                            
                            })
                       
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                                  SwiftSpinner.hide()
                                })
                                self.webdavProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                                    if(err != nil){
                                        self.backupcount = self.backupcount - 1
                                        print("Status:\(err)")
                                    }
                                })
                                appSettings.setfileneedsBackup("")
                            }
                            
                        })
                        
                        
                    }
                }
            }
        })
        
        
           
    }
    
    
    func needBackupToOneDrive(){
        
        if(self.onedriveProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: "Sorry OneDrive temporarily not available",
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        let appSettings = AppSettings.sharedInstance() as AppSettings
        let savedToken =  appSettings.refreshToken()
        
        if savedToken!.isEmpty{
            DispatchQueue.main.async {
                let nData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                            message: "Sorry OneDrive temporarily not reachable:",
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: nData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
        }else{
                self.singleBackup = 1
                if (appSettings.backupEnabled() && self.onedriveProvider != nil) {
                    // Setup iCloud Nexcloud
                    let fnb = appSettings.fileneedsBackup()
                    
                   // let dir = FileManager.default //urls(for: .documentDirectory, in: .userDomainMask).first
                    let localurl = URL(fileURLWithPath: fnb!)
                    let remotePath = "/IOSKeePass/Backups"
                    let remotefile = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                    
                    self.onedriveProvider?.contentsOfDirectory(path: remotePath, completionHandler:{ files, error in
                        
                        if(error != nil){
                            
                            print("Error on webDav contents of Direcrory:\(error)")
                            self.onedriveProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                                print("Create Directory IOSKeePass:\(err)")
                                self.onedriveProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                                    print("Create Directory Backup:\(err)")
                                })
                            })
                            
                            
                        }
                        DispatchQueue.main.async {
                            SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                              SwiftSpinner.hide()
                            })
                            self.onedriveProvider?.copyItem(localFile: localurl, to: remotefile, overwrite: true, completionHandler: { err in
                                if(err != nil){
                                    self.backupcount = self.backupcount - 1
                                    print("Status:\(err)")
                                }
                            })
                            appSettings.setfileneedsBackup("")
                        }
                        
                    })
                    
                    
                }
            }
        
        
       /* self.onedriveProvider?.isReachable(completionHandler:{success,error in
            if(success == false){
                DispatchQueue.main.async {
                    let nData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: "Sorry OneDrive temporarily not reachable:",
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: nData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
            }else{
                DispatchQueue.main.async {
                    let appSettings = AppSettings.sharedInstance() as AppSettings
                    self.singleBackup = 1
                    if (appSettings.backupEnabled() && self.onedriveProvider != nil) {
                        // Setup iCloud Nexcloud
                        let fnb = appSettings.fileneedsBackup()
                        
                       // let dir = FileManager.default //urls(for: .documentDirectory, in: .userDomainMask).first
                        let localurl = URL(fileURLWithPath: fnb!)
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        
                        self.onedriveProvider?.contentsOfDirectory(path: remotePath, completionHandler:{ files, error in
                            
                            if(error != nil){
                                
                                print("Error on webDav contents of Direcrory:\(error)")
                                self.onedriveProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                                    print("Create Directory IOSKeePass:\(err)")
                                    self.onedriveProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                                        print("Create Directory Backup:\(err)")
                                    })
                                })
                                
                                
                            }
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                                  SwiftSpinner.hide()
                                })
                                self.onedriveProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                                    if(err != nil){
                                        self.backupcount = self.backupcount - 1
                                        print("Status:\(err)")
                                    }
                                })
                                appSettings.setfileneedsBackup("")
                            }
                            
                        })
                        
                        
                    }
                }
            }
        })*/
        
        
           /* let appSettings = AppSettings.sharedInstance() as AppSettings
            self.singleBackup = 1
            if (appSettings.backupEnabled() && self.onedriveProvider != nil) {
                // Setup iCloud Nexcloud
                let fnb = appSettings.fileneedsBackup()
                SwiftSpinner.show("OneDrive Backup \nTap to stop").addTapHandler({
                  SwiftSpinner.hide()
                })
               // let dir = FileManager.default //urls(for: .documentDirectory, in: .userDomainMask).first
                let localurl = URL(fileURLWithPath: fnb!)
                let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                //check is Backup Location exist
                self.onedriveProvider?.contentsOfDirectory(path: remotePath, completionHandler:{ files, error in
                    
                    if(error != nil){
                        print("Error on webDav contents of Direcrory:\(error)")
                    }
                    if(files.count == 0){ //vermutlich nicht vorhanden oder leer
                        self.copyDocumentsToWebDav()
                    }
                    
                })
                self.onedriveProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                    if(err != nil){
                        self.backupcount = self.backupcount - 1
                        print("Status:\(err)")
                    }
                })
                appSettings.setfileneedsBackup("")
            }*/
        
    }
    
    func needBackupToiCloud(){
        if(self.iCloudProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: "Sorry iCloud temporarily not available",
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        self.iCloudProvider?.isReachable(completionHandler:{success,error in
            if(success == false){
                DispatchQueue.main.async {
                    let nData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: "Sorry iCloud temporarily not reachable:",
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: nData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
            }else{
                DispatchQueue.main.async {
                    let appSettings = AppSettings.sharedInstance() as AppSettings
                    self.singleBackup = 1
                    if (appSettings.backupEnabled() && self.iCloudProvider != nil) {
                        // Setup iCloud Nexcloud
                        let fnb = appSettings.fileneedsBackup()
                        
                       // let dir = FileManager.default //urls(for: .documentDirectory, in: .userDomainMask).first
                        let localurl = URL(fileURLWithPath: fnb!)
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        let icloudKeePassPath = "/IOSKeePass"
                        let icloudBackupPath =  "/IOSKeePass/Backups"
                        //Check is IOSKeePass on Cloud
                        self.iCloudProvider?.attributesOfItem(path: icloudKeePassPath, completionHandler:{ attribute, error in
                            
                            if(attribute == nil){
                                
                                print("Error on iCloud Direcrory:\(icloudKeePassPath) not exists")
                                self.iCloudProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                                    print("Error can´t Create Directory IOSKeePass:\(err)")
                                })
                            }else{
                                print("Directory IOSKeePass Exists")
                            }
                        })
                            
                        self.iCloudProvider?.attributesOfItem(path: icloudBackupPath, completionHandler:{ attribute, error in
                            
                            if(attribute == nil){
                                
                                print("Error on iCloud contents of Direcrory:\(icloudBackupPath)")
                                self.iCloudProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                                    print("Error can´t Create Directory Backups:\(err)")
                                    
                                })
                                
                                
                            }
                            
                            
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                                  SwiftSpinner.hide()
                                })
                                self.iCloudProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                                    if(err != nil){
                                        self.backupcount = self.backupcount - 1
                                        print("Status:\(err)")
                                    }
                                })
                                appSettings.setfileneedsBackup("")
                            }
                            
                        })
                        
                        
                    }
                }
            }
        })
        
        
           
    }
    
    
    func copyDocumentsToWebDav(){
        
        if(webdavProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title: NSLocalizedString("Copy WebDav Backup ⚠️",comment: ""),
                        message: NSLocalizedString("Sorry WebDav temporarily not available", comment: ""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        onedriveProvider?.isReachable(completionHandler:{success,error in
            if(success == false){
                DispatchQueue.main.async {
                let notiData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                            message: "Sorry OneDrive temporarily not reachable:",
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
                return
            }else{
                let appSettings = AppSettings.sharedInstance() as AppSettings
                
                if (appSettings.backupEnabled() && !appSettings.backupFirstTime() && self.webdavProvider != nil) {
                    // Setup iCloud Nexcloud
                   
                    
                    self.webdavProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                        print("Status:\(err)")
                    })
                    
                    self.webdavProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                        print("Status:\(err)")
                    })
                    
                    guard let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last else { return }
                    
                    do {
                        let fileURLs = try FileManager.default.contentsOfDirectory(at: localDocumentsURL, includingPropertiesForKeys: nil)
                        // process files
                        SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                          SwiftSpinner.hide()
                        })
                       
                        self.backupcount = fileURLs.count
                        
                            fileURLs.forEach { localurl in
                                print("Backup:\(localurl)")
                                
                                let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                                self.webdavProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                                    if(err != nil){
                                        self.backupcount = self.backupcount - 1
                                        print("Status:\(err)")
                                    }
                                })
                                
                               
                            }
                        
                        
                    } catch {
                        print("Error while enumerating files \(localDocumentsURL.path): \(error.localizedDescription)")
                    }
                }
            }
        })
        
        /*let appSettings = AppSettings.sharedInstance() as AppSettings
        
        if (appSettings.backupEnabled() && !appSettings.backupFirstTime() && webdavProvider != nil) {
            // Setup iCloud Nexcloud
           
            
            webdavProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                print("Status:\(err)")
            })
            
            webdavProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                print("Status:\(err)")
            })
            
            guard let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: localDocumentsURL, includingPropertiesForKeys: nil)
                // process files
                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                  SwiftSpinner.hide()
                })
               
                backupcount = fileURLs.count
                
                    fileURLs.forEach { localurl in
                        print("Backup:\(localurl)")
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        webdavProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                            if(err != nil){
                                self.backupcount = self.backupcount - 1
                                print("Status:\(err)")
                            }
                        })
                        
                       
                    }
                
                
            } catch {
                print("Error while enumerating files \(localDocumentsURL.path): \(error.localizedDescription)")
            }
        }*/
    }
    
    func copyDocumentsToOneDrive(){
        
        if(onedriveProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title: "Copy OneDrive Backup ⚠️",
                        message: "Sorry OneDrive temporarily not available",
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        if (appSettings.backupEnabled() && !appSettings.backupFirstTime() && onedriveProvider != nil) {
            // Setup iCloud Nexcloud
           
            
            onedriveProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                print("Status:\(err)")
            })
            
            onedriveProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                print("Status:\(err)")
            })
            
            guard let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: localDocumentsURL, includingPropertiesForKeys: nil)
                // process files
                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                  SwiftSpinner.hide()
                })
               
                backupcount = fileURLs.count
                
                    fileURLs.forEach { localurl in
                        print("Backup:\(localurl)")
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        webdavProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                            if(err != nil){
                                self.backupcount = self.backupcount - 1
                                print("Status:\(err)")
                            }
                        })
                        
                       
                    }
                
                
            } catch {
                print("Error while enumerating files \(localDocumentsURL.path): \(error.localizedDescription)")
            }
        }
    }
    
    func copyDocumentsToiCloud(){
        
        if(iCloudProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: "Sorry iCloud temporarily not available",
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        if (appSettings.backupEnabled() && !appSettings.backupFirstTime() && webdavProvider != nil) {
            // Setup iCloud Nexcloud
           
            
            iCloudProvider?.create(folder: "IOSKeePass", at: "/", completionHandler: { err in
                print("Status:\(err)")
            })
            
            iCloudProvider?.create(folder: "Backups", at: "/IOSKeePass", completionHandler: { err in
                print("Status:\(err)")
            })
            
            guard let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: localDocumentsURL, includingPropertiesForKeys: nil)
                // process files
                SwiftSpinner.show("Cloud Backup \nTap to stop").addTapHandler({
                  SwiftSpinner.hide()
                })
               
                backupcount = fileURLs.count
                
                    fileURLs.forEach { localurl in
                        print("Backup:\(localurl)")
                        
                        let remotePath = "/IOSKeePass/Backups/"+localurl.lastPathComponent
                        iCloudProvider?.copyItem(localFile: localurl, to: remotePath, overwrite: true, completionHandler: { err in
                            if(err != nil){
                                self.backupcount = self.backupcount - 1
                                print("Status:\(err)")
                            }
                        })
                        
                       
                    }
                
                
            } catch {
                print("Error while enumerating files \(localDocumentsURL.path): \(error.localizedDescription)")
            }
        }
    }
    

    
    func fileproviderSucceed(_ fileProvider: FileProviderOperations, operation: FileOperationType) {
            switch operation {
            case .copy(source: let source, destination: let dest):
                
                backupcount = backupcount-1
                print("\(source) copied to \(dest). count:\(backupcount)")
            case .remove(path: let path):
                print("\(path) has been deleted.")
            default:
                if let destination = operation.destination {
                    print("\(operation.actionDescription) from \(operation.source) to \(destination) succeed.")
                } else {
                    print("\(operation.actionDescription) on \(operation.source) succeed.")
                }
            }
        
            singleBackup = 0
            if(backupcount <= 0){
                let appSettings = AppSettings.sharedInstance() as AppSettings
                SwiftSpinner.hide()
                appSettings.setBackupFirstTime(true)
            }
        
            updateFiles()
            self.tableView.reloadData()
        }
        
        func fileproviderFailed(_ fileProvider: FileProviderOperations, operation: FileOperationType, error: Error) {
            switch operation {
            case .copy(source: let source, destination: let dest):
                print("copying \(source) to \(dest) has been failed.")
                backupcount = backupcount-1
            case .remove:
                print("file can't be deleted.")
            default:
                if let destination = operation.destination {
                    print("\(operation.actionDescription) from \(operation.source) to \(destination) failed.")
                } else {
                    print("\(operation.actionDescription) on \(operation.source) failed.")
                }
            }
            if(backupcount <= 0){
                let appSettings = AppSettings.sharedInstance() as AppSettings
                
                appSettings.setBackupFirstTime(true)
            }
            
            SwiftSpinner.hide()
            
        }
        
        func fileproviderProgress(_ fileProvider: FileProviderOperations, operation: FileOperationType, progress: Float) {
            switch operation {
            case .copy(source: let source, destination: let dest) where dest.hasPrefix("file://"):
                print("Downloading \(source) to \((dest as NSString).lastPathComponent): \(progress * 100) completed.")
                SwiftSpinner.show(progress: Double(progress), title: "Cloud Sync: \(Int(progress * 100))% completed")
                if progress >= 1 {
                    
                    SwiftSpinner.show( duration: 2.0, title: "Complete!", animated: false)
                    SwiftSpinner.hide()
                }
            case .copy(source: let source, destination: let dest) where source.hasPrefix("file://"):
                
                print("Uploading \((source as NSString).lastPathComponent) to \(dest): \(progress * 100) completed.")
                if(singleBackup == 1){
                   
                        SwiftSpinner.show(progress: Double(progress), title: "Cloud Backup: \(Int(progress * 100))% completed")
                        
                    
                    if progress >= 1 {
                        
                        SwiftSpinner.show( duration: 2.0, title: "Complete!", animated: false)
                        SwiftSpinner.hide()
                        singleBackup = 0
                        
                    }
                }
            case .copy(source: let source, destination: let dest):
                print("Copy \(source) to \(dest): \(progress * 100) completed.")
            default:
                break
            }
        }
    
    func copyDocumentsToiCloudDirectory() {
        guard let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last else { return }
        
        guard let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents").appendingPathComponent("Backups") else { return }
        
        var isDir:ObjCBool = false
        
        if FileManager.default.fileExists(atPath: iCloudDocumentsURL.path, isDirectory: &isDir) {
            do {
                try FileManager.default.removeItem(at: iCloudDocumentsURL)
                print("Removing old Backus: \(iCloudDocumentsURL)")
            }
            catch {
                //Error handling
                print("Error in remove item")
            }
        }
        
        do {
            try FileManager.default.copyItem(at: localDocumentsURL, to: iCloudDocumentsURL)
            print("Copy DBs from:\(localDocumentsURL) to: \(iCloudDocumentsURL)")
        }
        catch {
            //Error handling
            print("Error in copy item")
        }
    }

    func OneDriveRefreshToken()
    {
        let appScheme = "IOSKeePass"
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        let username = appSettings.cloudUser()
        let savedToken =  appSettings.refreshToken()
        let kClientID = "137e1fe9-5666-4eb1-9a36-168fa28d4dea"
        let kRedirectUri = "msauth.de.unicomedv.IOSKeePass://auth"
        let kAuthority = "https://login.microsoftonline.com/common"
        let kGraphEndpoint = "https://graph.microsoft.com/"
        self.oauth = OAuth2Swift(consumerKey: "137e1fe9-5666-4eb1-9a36-168fa28d4dea",
                                 consumerSecret: "",
                                 authorizeUrl: "https://login.microsoftonline.com/fe4e6494-0017-40df-a25b-dfeaf494e286/oauth2/v2.0/authorize",
                                 accessTokenUrl: "https://login.microsoftonline.com/fe4e6494-0017-40df-a25b-dfeaf494e286/oauth2/v2.0/token",
                                 responseType: "code")
        
        self.oauth!.authorizeURLHandler = SafariURLHandler(viewController: self, oauthSwift: self.oauth!)
        
        if !savedToken!.isEmpty {
            self.oauth!.renewAccessToken(withRefreshToken: savedToken!, completionHandler: { result in
                switch result {
                    case .success(let (credential, response, parameters)):
                      print(credential.oauthToken)
                    let urlcredential = URLCredential(user: username!, password: credential.oauthToken, persistence: .permanent)
                    let refreshToken = credential.oauthRefreshToken
                    // TODO: Save refreshToken in keychain
                    appSettings.setRefreshToken(refreshToken)
                    // TODO: Save credential in keychain
                    // TODO: Create OneDrive provider using urlcredential
                        if(self.onedriveProvider == nil){
                            self.onedriveProvider = OneDriveFileProvider(credential: urlcredential)
                            print("finished Init Onedrive.")
                            self.onedriveProvider?.delegate = self as FileProviderDelegate
                        }else{
                            print("OneDrive already init ")
                        }
                    
                      // Do your request
                    case .failure(let error):
                      print(error.localizedDescription)
                    appSettings.setRefreshToken("")
                    }
            })
        }else{
            _ = self.oauth!.authorize(
                withCallbackURL: URL(string: kRedirectUri),//"\(appScheme)://oauth-callback/onedrive")!,
                    scope: "offline_access User.Read Files.ReadWrite.All", state: "ONEDRIVE", completionHandler: { result in
                        switch result {
                            case .success(let (credential, response, parameters)):
                              print(credential.oauthToken)
                            let urlcredential = URLCredential(user: username!, password: credential.oauthToken, persistence: .permanent)
                            // TODO: Save refreshToken in keychain
                            appSettings.setRefreshToken(credential.oauthRefreshToken)
                            // TODO: Save credential in keychain
                            // TODO: Create OneDrive provider using credential
                            if(self.onedriveProvider == nil){
                                self.onedriveProvider = OneDriveFileProvider(credential: urlcredential)
                                print("finished Init Onedrive.")
                                self.onedriveProvider?.delegate = self as FileProviderDelegate
                            }else{
                                print("OneDrive already init.")
                            }
                              // Do your request
                            case .failure(let error):
                              print(error.localizedDescription)
                            appSettings.setRefreshToken("")
                            }
                    })
        }
        
    }
    
    
    func displayDocumentBrowser(inboundURL: URL? = nil, importIfNeeded: Bool = true) {
      //if presentationContext == .launched {
        documentBrowser.impDBdelegate = self;
        present(documentBrowser, animated: false)
      //}
      //presentationContext = .browsing
    }

    @objc func updateFiles() {
        if let databaseManager = DatabaseManager.sharedInstance() {
            databaseFiles = databaseManager.getDatabases() as! [String]
            keyFiles = databaseManager.getKeyFiles() as! [String]
            trayFiles = databaseManager.getTrayFiles() as! [String]
        }
    }
    
    // MARK: - Empty State

    func toggleEmptyState() {
        if (databaseFiles.count == 0 && keyFiles.count == 0) {
            let emptyStateLabel = UILabel()
            emptyStateLabel.text = NSLocalizedString("Tap the + button to add a new KeePass file.", comment: "")
            emptyStateLabel.textAlignment = .center
            emptyStateLabel.textColor = UIColor.gray
            emptyStateLabel.numberOfLines = 0
            emptyStateLabel.lineBreakMode = .byWordWrapping

            tableView.backgroundView = emptyStateLabel
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }

    // MARK: - UITableView data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.AllValues.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section.AllValues[section] {
        case .databases:
            return NSLocalizedString("Databases", comment: "")
        case .keyFiles:
            return NSLocalizedString("Key Files", comment: "")
        case .trayFiles:
            return NSLocalizedString("Recycle bin", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Hide the section titles if there are no files in a section
        switch Section.AllValues[section] {
        case .databases:
            if (databaseFiles.count == 0) {
                return 0
            }
        case .keyFiles:
            if (keyFiles.count == 0) {
                return 0
            }
            
        case .trayFiles:
            if (trayFiles.count == 0) {
                return 0
            }
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        toggleEmptyState()

        switch Section.AllValues[section] {
        case .databases:
            return databaseFiles.count
        case .keyFiles:
            return keyFiles.count
        case .trayFiles:
            return trayFiles.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let filename: String

        // Get the cell and filename
        switch Section.AllValues[indexPath.section] {
        case .databases:
            cell = tableView.dequeueReusableCell(withIdentifier: databaseReuseIdentifier, for: indexPath)
            filename = databaseFiles[indexPath.row]
            let appSettings = AppSettings.sharedInstance() as AppSettings
            let defname = appSettings.defaultDB()
            if(defname != nil){
                if(defname == filename){
                    print("Default DB found")
                    cell.textLabel?.textColor = UIColor.systemGreen
                }
            }
        case .keyFiles:
            cell = tableView.dequeueReusableCell(withIdentifier: keyFileReuseIdentifier, for: indexPath)
            filename = keyFiles[indexPath.row]
        case .trayFiles:
            cell = tableView.dequeueReusableCell(withIdentifier: trayIdentifier, for: indexPath)
            filename = trayFiles[indexPath.row]
        }

        cell.textLabel!.text = filename

        // Get the file's last modification time
        let databaseManager = DatabaseManager.sharedInstance()
        let url = databaseManager?.getFileUrl(filename)
        let size = databaseManager?.getFileSize(url)
        let date = databaseManager?.getFileLastModificationDate(url)
        let nowdate = Date()
        var sstr = String(format:"%@ Bytes", size!)
        
        if(Int64(truncating: size!) > 1024){
            sstr = String(format:"%d KB", Int64(truncating: size!)/1024)
        }
        
        if(Int64(truncating: size!) > (1024*1024)){
            sstr = String(format:"%d MB", Int64(truncating: size!)/1024/1024)
        }
        
        if(Int64(truncating: size!) > (1024*1024*1024)){
            sstr = String(format:"%d GB", Int64(truncating: size!)/1024/1024/1024)
        }
        
        // Format the last modified time as the subtitle of the cell
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        cell.detailTextLabel!.text = NSLocalizedString("Last Modified", comment: "") + ": " + dateFormatter.string(from: date ?? nowdate) + " Size:" + sstr

        
        return cell
    }

    // MARK: - UITableView delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Load the database
        
        let databaseManager = DatabaseManager.sharedInstance()
        // Move to a background thread to do some long running work
        //AppDelegate.showGlobalProgressHUD(withTitle:"loading..")
        //DispatchQueue.global(qos: .userInitiated).async {
            databaseManager?.openDatabaseDocument(self.databaseFiles[indexPath.row], animated: true)
            
            /*DispatchQueue.main.async {
                AppDelegate.dismissGlobalHUD()
            }
        }*/
        
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.deleteRowAtIndexPath(indexPath)
        }
        
        let shareAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Shareing", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.shareRowAtIndexPath(indexPath)
        }
        
        let renameAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Rename", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.renameRowAtIndexPath(indexPath)
        }
        
        let defaultAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Default", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.defaultRowAtIndexPath(indexPath)
        }
        
        let removeAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Remove", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.removeRowAtIndexPath(indexPath)
        }
        
        let recoverAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Recover", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            self.recoverRowAtIndexPath(indexPath)
        }
        
        let syncAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Sync", comment: "")) { (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            DispatchQueue.global(qos: .background).async {
                self.syncRowAtIndexPath(indexPath)
            }
        }
        
        shareAction.backgroundColor = UIColor.systemPurple
        renameAction.backgroundColor = UIColor.systemBlue
        defaultAction.backgroundColor = UIColor.systemGreen
        recoverAction.backgroundColor = UIColor.systemPurple
        syncAction.backgroundColor = UIColor.systemOrange
        
        switch Section.AllValues[indexPath.section] {
        case .databases:
            let appSettings = AppSettings.sharedInstance() as AppSettings
            if(appSettings.backupEnabled() == true){
                return [syncAction,shareAction,deleteAction, renameAction, defaultAction]
            }else{
                return [shareAction,deleteAction, renameAction, defaultAction]
            }
           
        case .keyFiles:
            return [shareAction,deleteAction]
        case .trayFiles:
            return [removeAction,recoverAction]
        }
    }
    
    func syncFromWebDav(_ indexPath: IndexPath)
    {
        if(self.webdavProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: NSLocalizedString("Sorry WebDav temporarily not available", comment: ""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
       
        let databaseManager = DatabaseManager.sharedInstance()
        
        let keepassURL = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
        let appDelegate = AppDelegate.getDelegate()
        self.webdavProvider?.isReachable(completionHandler:{success,error in
            if(error != nil)
            {
                print("Isreachable Error:\(error?.localizedDescription)")
            }
            if(success == false){
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry Cloud temporarily not reachable:", comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
                
            }else{
                let remotePath = "/IOSKeePass/Backups/"+keepassURL!.lastPathComponent
                let localattrib = try? FileManager.default.attributesOfItem(atPath: keepassURL!.path)
                self.singleBackup = 1
                self.webdavProvider?.attributesOfItem(path: remotePath, completionHandler:{ attrib, error in
                    if(error == nil){
                        let localdate = localattrib?[FileAttributeKey.modificationDate] as? Date
                        var clouddate:Date = (attrib?.modifiedDate)!
                        let cds = 1; //clouddate.timeIntervalSinceReferenceDate+180 //we add 180 secs because the modified date is different between local and cloud
                        let lds = 0;//localdate!.timeIntervalSinceReferenceDate
                                //return attr[FileAttributeKey.modificationDate] as? Date
                        print("Modify Date:\(attrib?.modifiedDate) local:\(localattrib?[FileAttributeKey.modificationDate])")
                        
                        if(cds > lds){
                            
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Cloud Sync \nTap to stop").addTapHandler({
                                  SwiftSpinner.hide()
                                })
                                var count: Int = 0
                                let filename = keepassURL?.lastPathComponent
                                let template = NSPredicate(format: "self BEGINSWITH $letter")
                                let beginsWithFilename = ["letter": filename]
                                let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

                                let beginsWithFilenames = self.trayFiles.filter { beginsWithF.evaluate(with: $0) }
                                count = beginsWithFilenames.count
                                
                                var movefile = filename! + ".bck"
                                if(count > 0){
                                    movefile = filename! + "_"+String(count)+".bck"
                                }
                                
                                // Delete the file
                              
                                databaseManager?.moveFile(filename, moveTo: movefile)
                                self.webdavProvider?.copyItem(path: remotePath, toLocalURL: keepassURL!, completionHandler: { err in
                                    if(err != nil){
                                       
                                        print("Status:\(err)")
                                    }
                                    
                                })
                                appSettings.setfileneedsBackup("")
                            }
                            
                        }else{
                           
                        }
                    }
                })
                
            }
        })
    }
    
    
    func syncFromiCloud(_ indexPath: IndexPath)
    {
        if(self.iCloudProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: NSLocalizedString("Sorry iCloud temporarily not available", comment: ""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
       
        let databaseManager = DatabaseManager.sharedInstance()
        
        let keepassURL = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
        let appDelegate = AppDelegate.getDelegate()
        self.iCloudProvider?.isReachable(completionHandler:{success,error in
            if(error != nil)
            {
                print("Isreachable Error:\(error?.localizedDescription)")
            }
            if(success == false){
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry Cloud temporarily not reachable:", comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
                
            }else{
                let remotePath = "/IOSKeePass/Backups/"+keepassURL!.lastPathComponent
                let localattrib = try? FileManager.default.attributesOfItem(atPath: keepassURL!.path)
                self.singleBackup = 1
               
                self.iCloudProvider?.contentsOfDirectory(path: "/IOSKeePass/Backups/", completionHandler:{ files, error in
                    if(error == nil){
                        //print("files:\(files.)")
                        var found = false
                        files.forEach { file in
                            print("File:\(file.name)")
                            if(file.name == keepassURL!.lastPathComponent){
                                found = true;
                            }
                        }
                        DispatchQueue.main.async {
                            SwiftSpinner.show("Cloud Sync \nTap to stop").addTapHandler({
                              SwiftSpinner.hide()
                            })
                        if(found == true){
                            var count: Int = 0
                            let filename = keepassURL!.lastPathComponent
                            let template = NSPredicate(format: "self BEGINSWITH $letter")
                            let beginsWithFilename = ["letter": filename]
                            let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

                            let beginsWithFilenames = self.trayFiles.filter { beginsWithF.evaluate(with: $0) }
                            count = beginsWithFilenames.count
                            
                            var movefile = filename + ".bck"
                            if(count > 0){
                                movefile = filename + "_"+String(count)+".bck"
                            }
                            databaseManager?.moveFile(filename, moveTo: movefile)
                            self.iCloudProvider?.copyItem(path: remotePath, toLocalURL: keepassURL!, completionHandler: { err in
                                if(err != nil){
                                   
                                    print("Status:\(err)")
                                }
                                
                            })
                        }else{
                            self.iCloudProvider?.copyItem(localFile: keepassURL!, to: remotePath, completionHandler: { err in
                                if(err != nil){
                                   
                                    print("Status:\(err)")
                                }
                                
                            })
                        }
                            appSettings.setfileneedsBackup("")
                    }
                    }else{
                        print("Error:\(error)")
                    }
                })
                
                
                /*self.iCloudProvider?.attributesOfItem(path: remotePath, completionHandler:{ attrib, error in
                    if(error == nil){
                        let localdate = localattrib?[FileAttributeKey.modificationDate] as? Date
                        //var clouddate:Date = (attrib?.modifiedDate)!
                        let cds = 1//clouddate.timeIntervalSinceReferenceDate+180 //we add 180 secs because the modified date is different between local and cloud
                        let lds = 0//localdate!.timeIntervalSinceReferenceDate
                                //return attr[FileAttributeKey.modificationDate] as? Date
                        print("Modify Date:Not Supported at the moment local:\(localattrib?[FileAttributeKey.modificationDate])")
                        
                        if(cds > lds){
                            
                            DispatchQueue.main.async {
                                SwiftSpinner.show("Cloud Sync \nTap to stop").addTapHandler({
                                  SwiftSpinner.hide()
                                })
                                var count: Int = 0
                                let filename = keepassURL?.lastPathComponent
                                let template = NSPredicate(format: "self BEGINSWITH $letter")
                                let beginsWithFilename = ["letter": filename]
                                let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

                                let beginsWithFilenames = self.trayFiles.filter { beginsWithF.evaluate(with: $0) }
                                count = beginsWithFilenames.count
                                
                                var movefile = filename! + ".bck"
                                if(count > 0){
                                    movefile = filename! + "_"+String(count)+".bck"
                                }
                                
                                //check if file exist
                                
                                // Delete the file
                              
                                databaseManager?.moveFile(filename, moveTo: movefile)
                                self.iCloudProvider?.copyItem(path: remotePath, toLocalURL: keepassURL!, completionHandler: { err in
                                    if(err != nil){
                                       
                                        print("Status:\(err)")
                                    }
                                    
                                })
                                appSettings.setfileneedsBackup("")
                            }
                            
                        }else{
                           
                        }
                    }
                })*/
                
            }
        })
    }
    
    func syncFromOneDrive(_ indexPath: IndexPath)
    {
        if(self.onedriveProvider == nil){ //Mainthread problems
            DispatchQueue.main.async {
            let notiData = HDNotificationData(
                        iconImage: UIImage(named: "AppIcon"),
                        appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                        title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                        message: NSLocalizedString("Sorry onedrive temporarily not available", comment: ""),
                        time: NSLocalizedString("now", comment: ""))
                    
            HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
            return
        }
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        let savedToken =  appSettings.refreshToken()
        let databaseManager = DatabaseManager.sharedInstance()
        
        let keepassURL = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
        let appDelegate = AppDelegate.getDelegate()
        if savedToken!.isEmpty {
            DispatchQueue.main.async {
                let notiData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                            message: NSLocalizedString("Sorry onedrive temporarily not reachable:", comment:""),
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
            }
        }else{
            let remotePath = "/IOSKeePass/Backups/"+keepassURL!.lastPathComponent
            let localattrib = try? FileManager.default.attributesOfItem(atPath: keepassURL!.path)
            self.singleBackup = 1
            
            self.onedriveProvider?.contentsOfDirectory(path: "/IOSKeePass/Backups/", completionHandler:{ files, error in
                if(error == nil){
                    //print("files:\(files.)")
                    var found = false
                    files.forEach { file in
                        print("File:\(file.name)")
                        if(file.name == keepassURL!.lastPathComponent){
                            found = true;
                        }
                    }
                    DispatchQueue.main.async {
                        SwiftSpinner.show("Cloud Sync \nTap to stop").addTapHandler({
                          SwiftSpinner.hide()
                        })
                    if(found == true){
                        var count: Int = 0
                        let filename = keepassURL!.lastPathComponent
                        let template = NSPredicate(format: "self BEGINSWITH $letter")
                        let beginsWithFilename = ["letter": filename]
                        let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

                        let beginsWithFilenames = self.trayFiles.filter { beginsWithF.evaluate(with: $0) }
                        count = beginsWithFilenames.count
                        
                        var movefile = filename + ".bck"
                        if(count > 0){
                            movefile = filename + "_"+String(count)+".bck"
                        }
                        databaseManager?.moveFile(filename, moveTo: movefile)
                        self.onedriveProvider?.copyItem(path: remotePath, toLocalURL: keepassURL!, completionHandler: { err in
                            if(err != nil){
                               
                                print("Status:\(err)")
                            }
                            
                        })
                    }else{
                        self.onedriveProvider?.copyItem(localFile: keepassURL!, to: remotePath, completionHandler: { err in
                            if(err != nil){
                               
                                print("Status:\(err)")
                            }
                            
                        })
                    }
                        appSettings.setfileneedsBackup("")
                }
                }else{
                    print("Error:\(error)")
                }
            })
        }
        /*self.onedriveProvider?.isReachable(completionHandler:{success,error in
            if(error != nil)
            {
                print("Isreachable Error:\(error?.localizedDescription)")
            }
            if(success == false){
                DispatchQueue.main.async {
                    let notiData = HDNotificationData(
                                iconImage: UIImage(named: "AppIcon"),
                                appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                                title:  NSLocalizedString("Need Cloud Backup ⚠️", comment: ""),
                                message: NSLocalizedString("Sorry onedrive temporarily not reachable:", comment:""),
                                time: NSLocalizedString("now", comment: ""))
                            
                    HDNotificationView.show(data: notiData,secounds:5.0, onTap: nil, onDidDismiss: nil)
                }
                
            }else{
                let remotePath = "/IOSKeePass/Backups/"+keepassURL!.lastPathComponent
                let localattrib = try? FileManager.default.attributesOfItem(atPath: keepassURL!.path)
                self.singleBackup = 1
               
                self.onedriveProvider?.contentsOfDirectory(path: "/IOSKeePass/Backups/", completionHandler:{ files, error in
                    if(error == nil){
                        //print("files:\(files.)")
                        var found = false
                        files.forEach { file in
                            print("File:\(file.name)")
                            if(file.name == keepassURL!.lastPathComponent){
                                found = true;
                            }
                        }
                        DispatchQueue.main.async {
                            SwiftSpinner.show("Cloud Sync \nTap to stop").addTapHandler({
                              SwiftSpinner.hide()
                            })
                        if(found == true){
                            var count: Int = 0
                            let filename = keepassURL!.lastPathComponent
                            let template = NSPredicate(format: "self BEGINSWITH $letter")
                            let beginsWithFilename = ["letter": filename]
                            let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

                            let beginsWithFilenames = self.trayFiles.filter { beginsWithF.evaluate(with: $0) }
                            count = beginsWithFilenames.count
                            
                            var movefile = filename + ".bck"
                            if(count > 0){
                                movefile = filename + "_"+String(count)+".bck"
                            }
                            databaseManager?.moveFile(filename, moveTo: movefile)
                            self.onedriveProvider?.copyItem(path: remotePath, toLocalURL: keepassURL!, completionHandler: { err in
                                if(err != nil){
                                   
                                    print("Status:\(err)")
                                }
                                
                            })
                        }else{
                            self.onedriveProvider?.copyItem(localFile: keepassURL!, to: remotePath, completionHandler: { err in
                                if(err != nil){
                                   
                                    print("Status:\(err)")
                                }
                                
                            })
                        }
                            appSettings.setfileneedsBackup("")
                    }
                    }else{
                        print("Error:\(error)")
                    }
                })
            }
        })*/
                
    }
    
    func syncRowAtIndexPath(_ indexPath: IndexPath) {
        switch cloudType{
            case 0:
                syncFromWebDav(indexPath)
                break
            case 1:
                syncFromiCloud(indexPath)
                break
            case 2:
                syncFromOneDrive(indexPath)
                break;
           
            default:
                syncFromWebDav(indexPath)
        }
        
    }
    
    func shareRowAtIndexPath(_ indexPath: IndexPath) {
        
       // do {
            let databaseManager = DatabaseManager.sharedInstance()
            let keepassURL = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
            let tex = String("Share KeePass File:")+databaseFiles[indexPath.row];
            //let keepassData = try NSData(contentsOf: keepassURL!, options: NSData.ReadingOptions())
        let activityViewController = UIActivityViewController(activityItems: [tex, keepassURL!], applicationActivities: nil)
            present(activityViewController, animated: true, completion: nil)
         /*   } catch {
                    print(error)
            }*/

        
        
    }
    
    func defaultRowAtIndexPath(_ indexPath: IndexPath) {
        // Get the filename to default
        
        let filename: String
        filename = databaseFiles[indexPath.row]
        let appSettings = AppSettings.sharedInstance() as AppSettings
        let of = appSettings.defaultDB()
       
            if(filename == of){
                appSettings.setDefaultDB("")
              
            }else{
                
                appSettings.setDefaultDB(filename)
                DispatchQueue.main.async {
                let notiData = HDNotificationData(
                            iconImage: UIImage(named: "AppIcon"),
                            appTitle: NSLocalizedString("Notify from IOSKeePass", comment: "").uppercased(),
                            title: NSLocalizedString("New Default DB is selected Name:", comment: "")+self.databaseFiles[indexPath.row],
                            message: NSLocalizedString("This Database is", comment: ""),
                            time: NSLocalizedString("now", comment: ""))
                        
                HDNotificationView.show(data: notiData, secounds: 10.0, onTap: nil, onDidDismiss: nil)
                }
                
            }
       
       
        self.tableView.reloadRows(at: [indexPath],
                                  with: .fade)
        
    }
    
    func recoverRowAtIndexPath(_ indexPath: IndexPath) {
        // Get the filename to delete
        let filename: String
       
        filename = trayFiles.remove(at: indexPath.row)
        let movefile = filename.dropLast(4)
        
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.recoverFile(filename)
        
        // Update the table
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        let index = self.databaseFiles.insertionIndexOf(String(movefile)) {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        self.databaseFiles.insert(String(movefile), at: index)
        
        // Notify the table of the new row
        if (self.databaseFiles.count == 1) {
            // Reload the section if it was previously empty
            let indexSet = IndexSet(integer: Section.databases.rawValue)
            self.tableView.reloadSections(indexSet, with: .right)
        } else {
            let indexPath = IndexPath(row: index, section: Section.databases.rawValue)
            self.tableView.insertRows(at: [indexPath], with: .right)
        }
    }
    
    func renameRowAtIndexPath(_ indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "RenameDatabase", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let viewController = navigationController.topViewController as! RenameDatabaseViewController
        viewController.donePressed = { (renameDatabaseViewController: RenameDatabaseViewController, originalUrl: URL, newUrl: URL) in
            let databaseManager = DatabaseManager.sharedInstance()
            databaseManager?.renameDatabase(originalUrl, newUrl: newUrl)
            
            // Update the filename in the files list
            self.databaseFiles[indexPath.row] = newUrl.lastPathComponent
            self.tableView.reloadRows(at: [indexPath], with: .fade)
            
            self.dismiss(animated: true, completion: nil)
        }
        
        let databaseManager = DatabaseManager.sharedInstance()
        viewController.originalUrl = databaseManager?.getFileUrl(databaseFiles[indexPath.row])
        
        present(navigationController, animated: true, completion: nil)
    }
    
    func removeRowAtIndexPath(_ indexPath: IndexPath) {
        
        let alertController = UIAlertController(title: "Remove KeePass", message: "If you select remove you don`t recover thie KeePass File anyone", preferredStyle: .actionSheet)
        
        let removetAction = UIAlertAction(title: "Remove", style: .default) { (action) in
            let filename = self.trayFiles.remove(at: indexPath.row)
            
            // Delete the file
            let databaseManager = DatabaseManager.sharedInstance()
            databaseManager?.removeFile(filename)
            
            // Update the table
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
        }
       
        alertController.addAction(removetAction)
        alertController.addAction(cancelAction)
        
        alertController.modalPresentationStyle = .popover
        let popover = alertController.popoverPresentationController
        popover?.sourceView = view
        popover?.sourceRect = CGRect(x: 32, y: 32, width: 64, height: 64)


        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteRowAtIndexPath(_ indexPath: IndexPath) {
        // Get the filename to delete
        let filename: String
        var count: Int = 0
        switch Section.AllValues[indexPath.section] {
        case .databases:
            filename = databaseFiles.remove(at: indexPath.row)
        case .keyFiles:
            filename = keyFiles.remove(at: indexPath.row)
        case .trayFiles:
            filename = trayFiles.remove(at: indexPath.row)
            
        }
        
        let template = NSPredicate(format: "self BEGINSWITH $letter")
        let beginsWithFilename = ["letter": filename]
        let beginsWithF = template.withSubstitutionVariables(beginsWithFilename)

        let beginsWithFilenames = trayFiles.filter { beginsWithF.evaluate(with: $0) }
        count = beginsWithFilenames.count
        
        var movefile = filename + ".bck"
        if(count > 0){
            movefile = filename + "_"+String(count)+".bck"
        }
        
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.moveFile(filename, moveTo: movefile)
        
        // Update the table
        /*tableView.deleteRows(at: [indexPath], with: .fade)
        
        let index = self.trayFiles.insertionIndexOf(String(movefile)) {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        self.trayFiles.insert(String(movefile), at: index)
        
        // Notify the table of the new row
        if (self.trayFiles.count == 1) {
            // Reload the section if it was previously empty
            let indexSet = IndexSet(integer: Section.trayFiles.rawValue)
            self.tableView.reloadSections(indexSet, with: .right)
        } else {
            let indexPath = IndexPath(row: index, section: Section.trayFiles.rawValue)
            self.tableView.insertRows(at: [indexPath], with: .right)
        }*/
        self.updateFiles()
        self.tableView.reloadData()
    }
    
    func newDatabaseCreated(filename: String) {
        let index = self.databaseFiles.insertionIndexOf(filename) {
            $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
        self.databaseFiles.insert(filename, at: index)
        
        // Notify the table of the new row
        if (self.databaseFiles.count == 1) {
            // Reload the section if it was previously empty
            let indexSet = IndexSet(integer: Section.databases.rawValue)
            self.tableView.reloadSections(indexSet, with: .right)
        } else {
            let indexPath = IndexPath(row: index, section: Section.databases.rawValue)
            self.tableView.insertRows(at: [indexPath], with: .right)
        }
    }
    
    func importDatabaseCreated(fileURL: URL) {
      
       
        // Move database file from bundle to documents folder
            
            let fileManager = FileManager.default
            
            let documentsUrl = fileManager.urls(for: .documentDirectory,
                                                        in: .userDomainMask)
            
            guard documentsUrl.count != 0 else {
                return // Could not find documents URL
            }
            
            let finalDatabaseURL = documentsUrl.first!.appendingPathComponent(fileURL.lastPathComponent)
        
            if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
                print("DB does not exist in documents folder")
                
               // let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("SQL.sqlite")
                
                do {
                    let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                       defer {
                         if didStartAccessing {
                           fileURL.stopAccessingSecurityScopedResource()
                         }
                       }
                    try fileManager.copyItem(atPath: (fileURL.path), toPath: finalDatabaseURL.path)
                      if(fileManager.fileExists(atPath: finalDatabaseURL.path)){
                      
                           let index = self.databaseFiles.insertionIndexOf(fileURL.lastPathComponent) {
                               $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                           }
                           self.databaseFiles.insert(fileURL.lastPathComponent, at: index)
                           
                           // Notify the table of the new row
                           if (self.databaseFiles.count == 1) {
                               // Reload the section if it was previously empty
                               let indexSet = IndexSet(integer: Section.databases.rawValue)
                               self.tableView.reloadSections(indexSet, with: .right)
                           } else {
                               let indexPath = IndexPath(row: index, section: Section.databases.rawValue)
                               self.tableView.insertRows(at: [indexPath], with: .right)
                           }
                    }
                    } catch let error as NSError {
                        print("Couldn't copy file to final location! Error:\(error.description)")
                }
 
            } else {
                print("Database file found at path: \(finalDatabaseURL.path)")
            }
       /* let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documentsPath+"/"+fileURL.lastPathComponent
        //let ori = fileURL.path
         let fileManager = FileManager.default
        if(!fileManager.fileExists(atPath: ori)){
            print(ori)
        }
        do{
         try fileManager.copyItem(at: URL, to: path)
        
            if(fileManager.fileExists(atPath: path)){
           
                let index = self.databaseFiles.insertionIndexOf(fileURL.lastPathComponent) {
                    $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending
                }
                self.databaseFiles.insert(fileURL.lastPathComponent, at: index)
                
                // Notify the table of the new row
                if (self.databaseFiles.count == 1) {
                    // Reload the section if it was previously empty
                    let indexSet = IndexSet(integer: Section.databases.rawValue)
                    self.tableView.reloadSections(indexSet, with: .right)
                } else {
                    let indexPath = IndexPath(row: index, section: Section.databases.rawValue)
                    self.tableView.insertRows(at: [indexPath], with: .right)
                }
            }
        }catch {
            print("Copy operation failed . Abort with error: \(error.localizedDescription)")
        }*/
        
       }
  
    @objc public func onClickedToolFlex() {
        #if DEBUG
            //FLEXManager.shared.showExplorer()
        #endif
    }
    
}

