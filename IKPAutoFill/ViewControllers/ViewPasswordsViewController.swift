import UIKit

extension UIStoryboard {
    static var viewPasswordsVC: ViewPasswordsViewController {
        return UIStoryboard(name: "FindPasswordFlow", bundle: nil).instantiateViewController(withIdentifier: "viewPasswords") as! ViewPasswordsViewController
    }
}

class ViewPasswordsViewController: UIViewController {
    @IBOutlet var directoryName: UILabel!
    @IBOutlet var usernamesTable: UITableView!
    @IBOutlet var passwordField: UITextField!

    
    weak var selectionDelegate: PasswordSelectionDelegate?
    var directory: Directory!
    var unameDataSource: UsernamesDataSource!

    override func viewDidLoad() {
        usernamesTable.delegate = self
        usernamesTable.dataSource = unameDataSource

        directoryName.text = directory.domain
    }
}

extension ViewPasswordsViewController: UITableViewDelegate {
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let domain = unameDataSource.directory
        let uname = unameDataSource.usernames[indexPath.row].value

        selectionDelegate?.selectedPassword(for: domain)
    }
}
