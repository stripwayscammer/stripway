//
//  TrendingHeaderImagesViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 12/10/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Photos
import FMPhotoPicker

/// This is the view that allows the admin to add/remove header images that will show on the trending screen
class TrendingHeaderImagesViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    var headerImageURLs = [(snapshotKey: String, urlString: String, index: Int)]()
    var newHeaderImageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadHeaderImages()
        // Do any additional setup after loading the view.
    }
    
    /// This pulls the actual images from the database
    func loadHeaderImages() {
        API.Trending.loadHeaderImages { (resultTuple, shouldClear, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let shouldClear = shouldClear, shouldClear {
                self.headerImageURLs.removeAll()
            }
            if let resultTuple = resultTuple {
                self.headerImageURLs.append(resultTuple)
                self.tableview.reloadData()
            }
        }
    }
    
    /// Admin can upload a new header image for this
    @IBAction func addButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "New Header Image", message: "Would you like to add a new header image?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "New Photo", style: .default, handler: { (action) in
            self.newHeaderImage()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Presents the picker controller for the admin to choose the new header photo
    func newHeaderImage() {
        checkPermissions {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            self.present(pickerController, animated: true, completion: nil)
        }
    }
    
    

}

/// Populates and formats the tableViewController for the header images
extension TrendingHeaderImagesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headerImageURLs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        headerImageURLs = headerImageURLs.sorted(by: { $0.index < $1.index })
        let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderImageTableViewCell", for: indexPath) as! HeaderImageTableViewCell
        cell.headerInfo = headerImageURLs[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let tuple = headerImageURLs[indexPath.row]
        API.Trending.deleteHeaderImage(tuple: tuple) { (error) in
            print("Some sort of error: \(error.localizedDescription)")
        }
    }
    
    /// Admin can change the index of a header image to make it show up earlier/later in the slideshow
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alertController = UIAlertController(title: "Change Tag Index", message: "Lower index shows up higher in trending page.", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.keyboardType = .numberPad
            textField.placeholder = String(self.headerImageURLs[indexPath.row].index)
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            guard let newIndex = firstTextField.text, !newIndex.isEmpty, let numIndex = Int(newIndex) else { return }
            print("Updated index to \(numIndex)")
            API.Trending.updateIndexForHeaderImage(headerImageKey: self.headerImageURLs[indexPath.row].snapshotKey, toIndex: numIndex)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}

/// The cell the header is displayed in
class HeaderImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var indexLabel: UILabel!
    
    /// Has the url of the photo and the index for the header, not sure the snapshotKey is necessary
    var headerInfo: (snapshotKey: String, urlString: String, index: Int)? {
        didSet {
            headerImageView.sd_setImage(with: URL(string: headerInfo!.urlString), completed: nil)
            indexLabel.text = String(headerInfo!.index)
        }
    }
    
}

/// This does all the cropViewController stuff for the header so it's the right aspect ratio and the admin can move it around and stuff
extension TrendingHeaderImagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, FMImageEditorViewControllerDelegate {

    // Once an image has been successfully picked from the library, pass it to the cropViewController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        print("Did finish picking media")
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            print("Something went wrong with the image picker")
            dismiss(animated: true, completion: nil)
            return
        }
        
        dismiss(animated: true) {
            var config = FMPhotoPickerConfig()
            config.selectMode = .single
            config.maxImage = 1
            config.mediaTypes = [.image]
            
            let picker = FMImageEditorViewController(config: config, sourceImage: image)
            picker.delegate = self
            self.present(picker, animated: true)
        }
    }
    func fmImageEditorViewController(_ editor: FMImageEditorViewController, didFinishEdittingPhotoWith photo: UIImage) {
        dismiss(animated: true, completion: nil)
        let image = photo
        newHeaderImageData = image.jpegData(compressionQuality: 0.1)
        API.Trending.uploadNewHeaderImage(imageData: newHeaderImageData!) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }

    
    /// This helper method makes sure we actually have permission to view the user's photo library
    func checkPermissions(completion: @escaping ()->()) {
        print("Checking permissions")
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            // Access already granted
            print("access has already been granted by user")
            completion()
        case .notDetermined:
            // Access not granted, so we must request it
            PHPhotoLibrary.requestAuthorization { (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    // access granted by user
                    print("access granted by user")
                    completion()
                }
            }
        default:
            print("Error: no access to photo album")
            let alert = UIAlertController(title: "Error", message: "No access to photo album. Please allow Stripway to access your photos in settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}


