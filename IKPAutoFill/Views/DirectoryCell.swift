import UIKit
import CryptoSwift

protocol MyCellDelegate: AnyObject {
        func didTapButtonInCell(_ cell: DirectoryCell)
    }


class DirectoryCell: UITableViewCell {
    
    @IBOutlet var directoryName: UILabel!
    @IBOutlet var userName: UILabel!
   
    @IBOutlet weak var OTPbtn: UIButton!
    weak var delegate: MyCellDelegate?
    
    weak var navigator: Navigator?
    var dir: Directory!
    
    
    func configure(with directory: Directory?) {
        dir = directory

        if(dir == nil){
            return;
        }
        directoryName.text = dir.domain
        userName.text = dir.username
        
        if(dir.otpurl == ""){
            OTPbtn.isEnabled = false
            OTPbtn.isHidden = true
        }else{
            OTPbtn.isEnabled = true
            OTPbtn.isHidden = false
            
            
        }
       
    }
    
    /*@IBAction func getOTP(_ sender: UIButton) {
       
        
        subscribeButtonAction?()
    }*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
            
        // Add action to perform when the button is tapped
        self.OTPbtn.addTarget(self, action: #selector(subscribeButtonTapped(_:)), for: .touchUpInside)
      }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
      }

    
    @IBAction func subscribeButtonTapped(_ sender: UIButton){
        delegate?.didTapButtonInCell(self)
      }
    
    
}


extension String {

    func cryptoSwiftAESDecryptForUrl(key: String, iv: String) -> String? {
       
        
        let d = Data(base64Encoded: self,options: .ignoreUnknownCharacters)
        //print("decodedData: \(d)")
        let encrypted: [UInt8] = Array(d!.bytes)


        guard let dec = try? AES(key: key, iv: iv, padding: .pkcs7).decrypt(encrypted) else {    return nil    }
        let decData = String(bytes: dec, encoding: .utf8)
        //print("decryptedString: \(decData)")
        //let decData = Data(bytes: dec, count: Int(dec.count)) //.base64EncodedString(options: .lineLength64Characters)
        return decData
    }
}

/*extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}*/


