import UIKit

class UsernameCell: UITableViewCell {
    @IBOutlet var username: UILabel!

    func configure(with username: Username?) {
        self.username.text = username?.value
    }
}
