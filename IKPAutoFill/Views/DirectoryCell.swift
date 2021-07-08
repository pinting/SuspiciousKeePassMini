import UIKit

class DirectoryCell: UITableViewCell {
    @IBOutlet var directoryName: UILabel!
    @IBOutlet var userName: UILabel!
    
    func configure(with directory: Directory?) {
        guard let dir = directory else { return }

        directoryName.text = dir.domain
        userName.text = dir.username
       
    }
}
