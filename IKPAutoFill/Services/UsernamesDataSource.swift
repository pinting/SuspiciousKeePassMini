import UIKit

class UsernamesDataSource: NSObject, UITableViewDataSource {
    let directory: Directory
    var usernames: [Username]

    init(directory: Directory, usernames: [Username] = []) {
        self.directory = directory
        self.usernames = usernames
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "username", for: indexPath) as! UsernameCell
        let username = usernames[indexPath.row]
        cell.configure(with: username)

        return cell
    }
}
