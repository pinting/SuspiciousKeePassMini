//
//  AttachmentListViewController.swift
//  IOSKeePass
//
//  Created by Frank Hausmann on 11.07.21.
//  Copyright © 2021 Self. All rights reserved.
//

import Foundation
import MobileCoreServices
import PDFKit
import CropViewController
import PKHUD

class attachmentCell : UITableViewCell{
   
    @IBOutlet weak var attachmentName: UILabel!
    @IBOutlet weak var attachmentImage: UIImageView!
}

class AttachmentListViewController: UITableViewController, CropViewControllerDelegate, UIImagePickerControllerDelegate,UIDocumentPickerDelegate, UINavigationControllerDelegate {
   
    @objc var entry: KPKEntry?
    @objc var fcell: TextFieldCell?
    
    @IBOutlet var attachmentTable: UITableView!
    
    //@objc var cancelPressed: ((AttachmentListViewController) -> Void)?
    
    private let imageView = UIImageView()
    
    private var image: UIImage?
    
    private var croppingStyle = CropViewCroppingStyle.default
    
    private var croppedRect = CGRect.zero
    private var croppedAngle = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        attachmentTable.dataSource = self
        attachmentTable.delegate = self
        attachmentTable.tableFooterView = UIView()
        
        HUD.registerForKeyboardNotifications()
        
        HUD.dimsBackground = false
        HUD.allowsInteraction = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (entry?.binaries.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:attachmentCell = self.attachmentTable.dequeueReusableCell(withIdentifier: "attachmentCell") as! attachmentCell
            let bf = entry?.binaries[indexPath.row]
            //NSLog(@"Binarie %@ is valid",bf.name);
            cell.attachmentName?.text = bf?.name
        
             let ext = bf?.name
        
        let url = AppDelegate.documentsDirectoryUrl()
           

        if ext!.hasSuffix("png") || ext!.hasSuffix("PNG") || ext!.hasSuffix("Png"){// true
            print("Suffix PNG exists")
            
           
            let img = UIImage(data: (bf?.data)! )
            cell.attachmentImage?.image = img
        }
        
        if ext!.hasSuffix("jpg") || ext!.hasSuffix("JPG") || ext!.hasSuffix("Jpg"){// true
            print("Suffix JPG exists")
            let img = UIImage(data: (bf?.data)! )
            cell.attachmentImage?.image = img
        }
        
        if ext!.hasSuffix("jpeg") || ext!.hasSuffix("JPEG") || ext!.hasSuffix("Jpeg"){// true
            print("Suffix JPEG exists")
            let img = UIImage(data: (bf?.data)! )
            cell.attachmentImage?.image = img
        }
        
        if ext!.hasSuffix("pdf") || ext!.hasSuffix("PDF") || ext!.hasSuffix("Pdf"){// true
            print("Suffix PDF exists")
           /* let fn = url?.appendingPathComponent(ext!)
            try? bf?.save(toLocation: fn)*/
            let img = UIImage(named: "pdffile")
            cell.attachmentImage?.image = img
            
        }
        
       
            return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let url = AppDelegate.documentsDirectoryUrl()
            
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            let bin = entry?.binaries[indexPath.row]
            let ext = bin?.name
            
                if ext!.hasSuffix("png") || ext!.hasSuffix("PNG") || ext!.hasSuffix("Png"){// true
                    //let fn = url?.appendingPathComponent("tmp.png")
                    //try? bf?.save(toLocation: fn)
                    displayImg(forKeepassEntry: bin!)
                }
                
                if ext!.hasSuffix("jpg") || ext!.hasSuffix("JPG") || ext!.hasSuffix("Jpg"){// true
                    //let fn = url?.appendingPathComponent("tmp.jpg")
                    //try? bf?.save(toLocation: fn)
                    displayImg(forKeepassEntry: bin!)
                }
                
                if ext!.hasSuffix("jpeg") || ext!.hasSuffix("JPEG") || ext!.hasSuffix("Jpeg"){// true
                    //let fn = url?.appendingPathComponent("tmp.jpg")
                    //try? bf?.save(toLocation: fn)
                    //displayImg(forKeepassEntry: bf!)
                }
                
                if ext!.hasSuffix("pdf") || ext!.hasSuffix("PDF") || ext!.hasSuffix("Pdf"){// true
                   
                    let fn = url?.appendingPathComponent("tmp.pdf")
                    try? bin?.save(toLocation: fn)
                    displayPdf(forFileUrl: fn!)
                    
                }
                
            }
            
        }
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            return .delete
        }
        
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete{
                print("Deleted Row")
                //days.remove(at: indexPath.row)
                //tableView.deleteRows(at: [indexPath], with: .left)
                HUD.show(.progress)

                    let bin = self.entry?.binaries[indexPath.row]
                
                    self.entry?.removeBinary(bin)
                    //AppDelegate.showGlobalProgressHUD(withTitle: "Saving")
                    self.attachmentTable.reloadData()
                    let appDelegate = AppDelegate.getDelegate()
                    
                    appDelegate?.databaseDocument.save()
                let tt = String(format:"%d Attachments",self.entry?.binaries.count as! CVarArg)
                self.fcell?.textField.text = tt
                HUD.flash(.success, delay: 1.0)
              
            }
   
        }

   /* override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        let binViewController = segue.destination as! BinaryViewController
        
        binViewController.binary  = entry?.binaries[indexPath.row]
        
    }*/
    
    public func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
       print("Dismiss called")
        //cancelPressed?(self)
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyyMMddTHHmmss"

        
        
        let name = UIDevice.current.name + "_" + dateFormatterGet.string(from: Date.init()) + ".png"
        
        //Add a new Image to Keepass
        let bin = KPKBinary.init(name: name, data: image.pngData())
        entry?.addBinary(bin)
        attachmentTable.reloadData()
        cropViewController.dismiss(animated: true, completion:{
            // Save the database
            let appDelegate = AppDelegate.getDelegate()
            appDelegate?.databaseDocument.save()
            HUD.flash(.success, delay: 1.0)
           
            let tt = String(format:"%d Attachments",self.entry?.binaries.count as! CVarArg)
            self.fcell?.textField.text = tt
            
        })
        //updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        self.croppedRect = cropRect
        self.croppedAngle = angle
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    public func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        imageView.image = image
        layoutImageView()
        
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        
        if cropViewController.croppingStyle != .circular {
            imageView.isHidden = true
            
            cropViewController.dismissAnimatedFrom(self, withCroppedImage: image,
                                                   toView: imageView,
                                                   toFrame: CGRect.zero,
                                                   setup: { self.layoutImageView() },
                                                   completion: {
                                                    self.imageView.isHidden = false })
        }
        else {
            self.imageView.isHidden = false
            cropViewController.dismiss(animated: true, completion:{
                
            })
        }
    }
    
  
    private func resourceUrl(forFileName fileName: String) -> URL? {
        if let resourceUrl = Bundle.main.url(forResource: fileName,
                                             withExtension: "pdf") {
            return resourceUrl
        }
        
        return nil
    }
    
    private func createPdfView(withFrame frame: CGRect) -> PDFView {
        let pdfView = PDFView(frame: frame)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        
        return pdfView
    }
    
    
    private func createPdfDocument(forFileUrl fileName: URL) -> PDFDocument? {
        if fileName != nil {
            return PDFDocument(url: fileName)
        }
        
        return nil
    }
    
    private func displayPdf(forFileUrl fileName: URL) {
        let pdfView = self.createPdfView(withFrame: self.view.bounds)
        
        if let pdfDocument = self.createPdfDocument(forFileUrl: fileName) {
            self.view.addSubview(pdfView)
            pdfView.document = pdfDocument
            let fileManager = FileManager.default
            try? fileManager.removeItem(at: fileName)
        }
    }
    
    private func displayImg(forKeepassEntry entry: KPKBinary) {
       
        let image = UIImage(data: entry.data)
        self.image = image
        self.view.addSubview(imageView)
        let cropController = CropViewController(croppingStyle: croppingStyle, image: image!)
      
        //cropController.modalPresentationStyle = .fullScreen
        cropController.delegate = self
        self.present(cropController, animated: true, completion: nil)
    }
    
    public func layoutImageView() {
        guard imageView.image != nil else { return }
        
        let padding: CGFloat = 20.0
        
        var viewFrame = self.view.bounds
        viewFrame.size.width -= (padding * 2.0)
        viewFrame.size.height -= ((padding * 2.0))
        
        var imageFrame = CGRect.zero
        imageFrame.size = imageView.image!.size;
        
        if imageView.image!.size.width > viewFrame.size.width || imageView.image!.size.height > viewFrame.size.height {
            let scale = min(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height)
            imageFrame.size.width *= scale
            imageFrame.size.height *= scale
            imageFrame.origin.x = (self.view.bounds.size.width - imageFrame.size.width) * 0.5
            imageFrame.origin.y = (self.view.bounds.size.height - imageFrame.size.height) * 0.5
            imageView.frame = imageFrame
        }
        else {
            self.imageView.frame = imageFrame;
            self.imageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        }
    }
    
    func attachDocument() {
        let types = [kUTTypePDF,
                     kUTTypePNG,
                     kUTTypeJPEG, kUTTypeText, kUTTypeRTF, kUTTypeSpreadsheet]
        let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
        if #available(iOS 11.0, *) {
            importMenu.allowsMultipleSelection = true
        }
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        present(importMenu, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        //viwmodel.attachDocuments(at: urls)
        
        urls.forEach{ url in
            let fname = url.lastPathComponent
            let dat = try? Data.init(contentsOf: url)
            let bin = KPKBinary.init(name: fname, data: dat )
            entry?.addBinary(bin)
        }
        
        attachmentTable.reloadData()
        let appDelegate = AppDelegate.getDelegate()
        appDelegate?.databaseDocument.save()
        HUD.flash(.success, delay: 1.0)
        let tt = String(format:"%d Attachments",self.entry?.binaries.count as! CVarArg)
        self.fcell?.textField.text = tt
        }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        //self.image = image
        self.view.addSubview(imageView)
        
        let cropController = CropViewController(croppingStyle: croppingStyle, image: image)
        //cropController.modalPresentationStyle = .fullScreen
        cropController.delegate = self
        
        // Uncomment this if you wish to provide extra instructions via a title label
        cropController.title = "Imageview"
    
        // -- Uncomment these if you want to test out restoring to a previous crop setting --
        //cropController.angle = 90 // The initial angle in which the image will be rotated
        //cropController.imageCropFrame = CGRect(x: 0, y: 0, width: 2848, height: 4288) //The initial frame that the crop controller will have visible.
    
        // -- Uncomment the following lines of code to test out the aspect ratio features --
        //cropController.aspectRatioPreset = .presetSquare; //Set the initial aspect ratio as a square
        //cropController.aspectRatioLockEnabled = true // The crop box is locked to the aspect ratio and can't be resized away from it
        //cropController.resetAspectRatioEnabled = false // When tapping 'reset', the aspect ratio will NOT be reset back to default
        //cropController.aspectRatioPickerButtonHidden = true
    
        // -- Uncomment this line of code to place the toolbar at the top of the view controller --
        //cropController.toolbarPosition = .top
    
        //cropController.rotateButtonsHidden = true
        //cropController.rotateClockwiseButtonHidden = true
    
        cropController.doneButtonTitle = NSLocalizedString("Save", comment: "")
        //cropController.cancelButtonTitle = "Title"
        
        //cropController.toolbar.doneButtonHidden = true
        //cropController.toolbar.cancelButtonHidden = true
        //cropController.toolbar.clampButtonHidden = true

        // Set toolbar action button colors
        // cropController.doneButtonColor = UIColor.red
        // cropController.cancelButtonColor = UIColor.green

        self.image = image
        
        //If profile picture, push onto the same navigation stack
        if croppingStyle == .circular {
            if picker.sourceType == .camera {
                picker.dismiss(animated: true, completion: {
                    self.present(cropController, animated: true, completion: nil)
                })
            } else {
                picker.pushViewController(cropController, animated: true)
            }
        }
        else { //otherwise dismiss, and then present from the main controller
            picker.dismiss(animated: true, completion: {
                self.present(cropController, animated: true, completion: nil)
                //self.navigationController!.pushViewController(cropController, animated: true)
            })
        }
    }
    
    @IBAction func AddFile(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "Add a File", style: .default) { (action) in
            //self.croppingStyle = .default
            self.attachDocument()
           /* let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)*/
        }
        
        let profileAction = UIAlertAction(title: "Image from Album", style: .default) { (action) in
            //self.croppingStyle = .circular
            
            let imagePicker = UIImagePickerController()
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
            imagePicker.preferredContentSize = CGSize(width: 320, height: 568)
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        let cameraAction = UIAlertAction(title: "Image from Camera", style: .default) { (action) in
            //self.croppingStyle = .circular
            
            let imagePicker = UIImagePickerController()
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
            imagePicker.preferredContentSize = CGSize(width: 320, height: 568)
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        alertController.addAction(defaultAction)
        alertController.addAction(profileAction)
        alertController.addAction(cameraAction)
        alertController.modalPresentationStyle = .popover
        
        let presentationController = alertController.popoverPresentationController
        presentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(alertController, animated: true, completion: nil)
    }
    
    
}
