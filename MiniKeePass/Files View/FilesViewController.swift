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
    var backupcount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Activate KeyboardGuide at the beginning of application life cycle.
        KeyboardGuide.shared.activate()
        
    
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
        let username = appSettings.cloudUser()
        let password = appSettings.cloudPWD()
        
        let baseURL = appSettings.cloudURL()  //"https://cloud.unicomedv.de/remote.php/dav/files/"+username+"/"
        
        if(username != nil && password != nil && baseURL != nil){
            let credential = URLCredential(user: username!, password: password!, persistence: .permanent)
            webdavProvider = WebDAVFileProvider(baseURL: URL(string: baseURL!)!, credential: credential)
            webdavProvider?.delegate = self as FileProviderDelegate
        }else{
            webdavProvider = nil
        }
    
       
        
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
   
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
      
        
    }
    
   
    
    override func viewWillAppear(_ animated: Bool) {
        updateFiles();
        super.viewWillAppear(animated)
        copyDocumentsToWebDav()
        
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
            groupViewController.tagid = 1;
            
           
        case "importDatabase"?:
           displayDocumentBrowser()
            


        default:
            break
        }
    }
   
    func copyDocumentsToWebDav(){
        
        let appSettings = AppSettings.sharedInstance() as AppSettings
        
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
                SwiftSpinner.show("Backup \nTap to stop").addTapHandler({
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
               // SwiftSpinner.hide()
                
                
            } catch {
                print("Error while enumerating files \(localDocumentsURL.path): \(error.localizedDescription)")
            }
            
            /*webdavProvider?.contentsOfDirectory(path: "/", completionHandler: {
                contents, error in
                for file in contents {
                    print("Name: \(file.name)")
                    print("Size: \(file.size)")
                    print("Creation Date: \(file.creationDate)")
                    print("Modification Date: \(file.modifiedDate)")
                }
            })*/
            
            //let iCloudToken = FileManager.default.ubiquityIdentityToken
            
                //is iCloud working?
                /*if  iCloudToken != nil {
                    print("iCloud available")
                    if let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
                        print(iCloudDocumentsURL.path)
                        
                        if (!FileManager.default.fileExists(atPath: iCloudDocumentsURL.path, isDirectory: nil)) {
                                    do {
                                        try FileManager.default.createDirectory(at: iCloudDocumentsURL, withIntermediateDirectories: true, attributes: nil)
                                    }
                                    catch {
                                        //Error handling
                                        print("Error in creating doc")
                                    }
                        }else{
                            print("iCloud URL already exist")
                        }
                    }
                    
                    copyDocumentsToNextCloudDirectory()
                    
                } else {
                    print("iCloud is NOT working!")
                    //  return
                }*/


           
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
        
            if(backupcount <= 0){
                let appSettings = AppSettings.sharedInstance() as AppSettings
                SwiftSpinner.hide()
                appSettings.setBackupFirstTime(true)
            }
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
                SwiftSpinner.hide()
                appSettings.setBackupFirstTime(true)
            }
        }
        
        func fileproviderProgress(_ fileProvider: FileProviderOperations, operation: FileOperationType, progress: Float) {
            switch operation {
            case .copy(source: let source, destination: let dest) where dest.hasPrefix("file://"):
                print("Downloading \(source) to \((dest as NSString).lastPathComponent): \(progress * 100) completed.")
            case .copy(source: let source, destination: let dest) where source.hasPrefix("file://"):
                
                print("Uploading \((source as NSString).lastPathComponent) to \(dest): \(progress * 100) completed.")
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
            if(defname == filename){
                print("Default DB found")
                cell.textLabel?.textColor = UIColor.cyan
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
        
        renameAction.backgroundColor = UIColor.systemGreen
        defaultAction.backgroundColor = UIColor.systemBlue
        recoverAction.backgroundColor = UIColor.systemPurple
        
        switch Section.AllValues[indexPath.section] {
        case .databases:
            return [deleteAction, renameAction, defaultAction]
        case .keyFiles:
            return [deleteAction]
        case .trayFiles:
            return [removeAction,recoverAction]
        }
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
        // Get the filename to delete
        let filename: String
       
        filename = trayFiles.remove(at: indexPath.row)
        
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.removeFile(filename)
        
        // Update the table
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func deleteRowAtIndexPath(_ indexPath: IndexPath) {
        // Get the filename to delete
        let filename: String
        switch Section.AllValues[indexPath.section] {
        case .databases:
            filename = databaseFiles.remove(at: indexPath.row)
        case .keyFiles:
            filename = keyFiles.remove(at: indexPath.row)
        case .trayFiles:
            filename = trayFiles.remove(at: indexPath.row)
        }
        
        let movefile = filename + ".bck"
        // Delete the file
        let databaseManager = DatabaseManager.sharedInstance()
        databaseManager?.deleteFile(filename)
        
        // Update the table
        tableView.deleteRows(at: [indexPath], with: .fade)
        
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
        }
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
    
}

