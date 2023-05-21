import UIKit

class ViewPasswordDirectoriesViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!

    @IBOutlet weak var CancelBtn: UIBarButtonItem!
    var dataSource: DirectoriesTableViewDataSource!
    weak var navigator: Navigator?
    
    override func viewDidLoad() {
        searchBar.delegate = self
        tableView.delegate = self
        dataSource.delegate = self
        
        tableView.dataSource = dataSource
        
        let buttonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.OnCancel(_:)))
                navigationItem.rightBarButtonItem = buttonItem
        
    }
    
    @objc func OnCancel(_ sender: UIBarButtonItem) {
        
        self.navigator?.navigateCancel()
    }

    
    func showResultsMatching(_ string: String?) {
        guard let s = string else { return }

        searchBar.text = s
        searchBar(searchBar, textDidChange: s)
    }
}

extension ViewPasswordDirectoriesViewController: MyForwardCellDelegate {
    func forwarddidTapButtonInCell(_ cell: DirectoryCell) {
       //Do whatever you want to do when the button is tapped here
        let decrypturl = cell.dir.otpurl.cryptoSwiftAESDecryptForUrl(key: "xxxxxxxxxxxxxxxx", iv:"xxxxxxxxxxxxxxxx" )
        let url = URL(string: decrypturl!)
        do{
            let tok =  try Token(url: url!) //[[Token alloc] initWithUrl:url secret:nil error:nil];
            
            //OTP.text = tok.currentPasswordmoreReadable;
            //cell.dir.otp = tok.currentPasswordmoreReadable!
            
            let tt = String(format:"You Want using this OTP:%@", doOntimeRefresh(tok: tok))
            let alertController = UIAlertController(title: "Calculate OTP", message: tt, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            }
            let usingAction = UIAlertAction(title: "Copy to clipboard", style: .default) { (action) in
                cell.dir.otp = tok.currentPasswordmoreReadable!
                UIPasteboard.general.string = tok.currentPasswordmoreReadable!.replacingOccurrences(of: " ", with: "")
                self.navigator?.navigateToContentsOf(domain: cell.dir)
                
            }
            alertController.addAction(usingAction)
            alertController.addAction(cancelAction)
            
            alertController.modalPresentationStyle = .popover
            let popover = alertController.popoverPresentationController
            popover?.sourceView = view
            popover?.sourceRect = CGRect(x: 32, y: 32, width: 64, height: 64)
            
            present(alertController, animated: true, completion: nil)
        } catch {
            print(error)
        }
    }
    
    func doOntimeRefresh(tok: Token)->String {
        let dateFormatter = DateFormatter()

        // Set Date Format
        dateFormatter.dateFormat = "ss"
        
        let dat = Date()
        let sec = Int(dateFormatter.string(from: dat))//[[dateFormatter stringFromDate:[NSDate date]] integerValue];
       
             
        if(sec! >= 30){
            //NSString *tt = [[NSString alloc] initWithFormat:@"%@ (%ldsec)",tok.currentPasswordmoreReadable,60-sec];
            return String(format:"%@ %ds",tok.currentPasswordmoreReadable!, (60-sec!))
            //OTP.text = tt;// tok.currentPassword;
                //NSLog(@"OTP %d valid",60-sec);
             }else{
                 return String(format:"%@ %ds",tok.currentPasswordmoreReadable!, (30-sec!))
                //  OTP.text = tt;// tok.currentPassword;
             }
        
    }
}

extension ViewPasswordDirectoriesViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = dataSource.filteredSections[indexPath.section]
        let directory = section.constituents[indexPath.row]
        
        navigator?.navigateToContentsOf(domain: directory)
    }
    
   
}
    

extension ViewPasswordDirectoriesViewController: UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange searchText: String) {
        dataSource.showDirectories(matching: searchText)
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_: UISearchBar) {
        dataSource.showDirectories(matching: "")
        tableView.reloadData()
    }
}
