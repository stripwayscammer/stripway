//
//  EditProfileViewController.swift
//
//
//  Created by Drew Dennistoun on 1/17/19.
//

import UIKit
import Photos
import FMPhotoPicker
import Segmentio
import Closures
import DropDown

class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var segmentView: Segmentio!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    var dropDown = DropDown()
    var newProfileImage: UIImage?
    var newHeaderImage: UIImage?
    
    var card: UserCard?
    
    @IBOutlet weak var profileImageButton: UIButton!
    
    @IBOutlet weak var topTabsBackgroundView: UIView!
    var userInfo = [String: String]()
    var userInfoCell: EditProfileTableViewCell?
    var cardCell: EditCardTableViewCell?
    var showCard: Bool?
    var currentTab = 0
    
    var strips = [StripwayStrip]()
    var removedStripIDs = [String]()
    var stripPosts: [String: [StripwayPost]] = [:]
    var newStripNames: [String: (String, StripwayStrip)] = [:]
    
    var profileOwner: StripwayUser!
    
    @IBOutlet weak var tableView: UITableView!
    
    var deletedStrips = [StripwayStrip]()
    var deletedPosts = [StripwayPost]()
    
    var stripsOrPostsHaveBeenDeleted = false
    
    var imagePicked: NewImageType = .other
    
    @IBOutlet weak var loadingView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        setupUI()
        loadProfileInfo()
    }
    func setupSegment() {
        
        let strips = SegmentioItem(title: "Info", image: nil)
        let reposts = SegmentioItem(title: "Strips", image: nil)
        let card = SegmentioItem(title: "Card", image: nil)
        let content = [strips, reposts, card]
        
        let state = SegmentioStates(
                    defaultState: SegmentioState(
                        backgroundColor: .clear,
                        titleFont: UIFont(name: "Avenir Next", size: 16) ?? .systemFont(ofSize: 16),
                        titleTextColor: .darkGray
                    ),
                    selectedState: SegmentioState(
                        backgroundColor: .clear,
                        titleFont: UIFont(name: "Avenir Next Bold", size: 16) ?? .systemFont(ofSize: 15, weight: .bold),
                        titleTextColor: .black
                    ),
                    highlightedState: SegmentioState(
                        backgroundColor: .clear,
                        titleFont: UIFont(name: "Avenir Next Bold", size: 16) ?? .systemFont(ofSize: 16),
                        titleTextColor: .black
                    )
        )

        let option = SegmentioOptions(backgroundColor: .white,
                                      segmentPosition: .fixed(maxVisibleItems: 3),
                                      scrollEnabled: false,
                                      indicatorOptions: .init(type: .bottom, ratio: 1, height: 3, color: .darkText),
                                      horizontalSeparatorOptions: .init(type: .bottom, height: 0, color: .white),
                                      verticalSeparatorOptions: nil,
                                      imageContentMode: .scaleAspectFit,
                                      labelTextAlignment: .center,
                                      labelTextNumberOfLines: 1,
                                      segmentStates: state,
                                      animationDuration: 0.25)
        
        segmentView.setup(content: content, style: .onlyLabel, options: option)

        segmentView.selectedSegmentioIndex = 0

        segmentView.valueDidChange = { segmentio, segmentIndex in
            self.currentTab = segmentIndex
            self.tabChanged()
        }
    }
    
    func setupUI() {
        
        saveButton.layer.cornerRadius = 15
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = UIColor.black.cgColor
        
        cancelButton.layer.cornerRadius = 15
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor.black.cgColor
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        
        profileImageButton.layer.masksToBounds = true
        profileImageButton.layer.cornerRadius = profileImageButton.bounds.width / 2
        
        let bottomBorder = UIView(frame: CGRect.zero)
        topTabsBackgroundView.addSubview(bottomBorder)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.bottomAnchor.constraint(equalTo: topTabsBackgroundView.bottomAnchor).isActive = true
        bottomBorder.leadingAnchor.constraint(equalTo: topTabsBackgroundView.leadingAnchor).isActive = true
        bottomBorder.trailingAnchor.constraint(equalTo: topTabsBackgroundView.trailingAnchor).isActive = true
        bottomBorder.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
        bottomBorder.backgroundColor = UIColor.lightGray
        
        setupSegment()

    }
    
    func loadProfileInfo() {
        if let profileImageURL = profileOwner.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            profileImageView.sd_setImage(with: profileURL)
        }
        if let headerImageURL = profileOwner.headerImageURL {
            let headerURL = URL(string: headerImageURL)
            headerImageView.sd_setImage(with: headerURL)
        }
        loadStrips()
        loadCard()
    }
    func loadCard() {
        API.UserCard.getCard(userID: profileOwner.uid) { (card) in
            self.card = card
            self.tableView.reloadData()
        }
    }
    
    func loadStrips() {
        API.Strip.fetchStripIDs(forUserID: profileOwner.uid) { (key) in
            API.Strip.observeStrip(withID: key, completion: { (strip) in
                if self.removedStripIDs.contains(key) || self.deletedStrips.contains(where: { $0.stripID == key }) {
                    return
                }
                self.strips.append(strip)
                API.Strip.observePostsForStrip(atDatabaseReference: strip.postsReference!, completion: { (post, error, shouldClear) in
                    if let shouldClear = shouldClear, shouldClear {
                        self.stripPosts[strip.stripID] = []
                        return
                    }
                    if let error = error {
                        print(error.localizedDescription)
                    } else if let post = post {
                        if self.deletedPosts.contains(where: { $0.postID == post.postID}) {
                            return
                        }
                        var postsForStrip = self.stripPosts[strip.stripID] ?? []
                        postsForStrip.append(post)
                        self.stripPosts[strip.stripID] = postsForStrip
                        self.tableView.reloadData()
                    }
                })
            })
        }
        
        API.Strip.observeStripIDsRemoved(forUserID: profileOwner.uid) { (key) in
            self.strips = self.strips.filter{ $0.stripID != key }
            self.removedStripIDs.append(key)
            self.tableView.reloadData()
        }
    }
    
    @IBAction func headerImageButtonPressed(_ sender: Any) {
        checkPermissions {
            DispatchQueue.main.async {
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                self.present(pickerController, animated: true, completion: nil)
                self.imagePicked = .headerImage
            }
        }
    }
    
    @IBAction func profileImageButtonPressed(_ sender: Any) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        self.present(pickerController, animated: true, completion: nil)
        self.imagePicked = .profileImage
        
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.resignFirstResponder()
        if stripsOrPostsHaveBeenDeleted {
            let alert = UIAlertController(title: "Cancel Changes?", message: "Are you sure you want to cancel? If you cancel, your deleted posts/strips won't be deleted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Back", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        self.resignFirstResponder()
        updateUserInfoDictionary()
        if let newUsername = userInfo["username"], newUsername != profileOwner.username {
            let alert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
            if !usernameIsFormattedCorrectly(username: newUsername) {
                alert.message = "Username is incorrectly formatted. It can only contain numbers, lowercase letters, and underscores. It also must contain between 3 and 24 characters."
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in }))
                self.present(alert, animated: true, completion: nil)
                return
            }
            checkUsernameUniqueness(username: newUsername) { (isUnique) in
                if !isUnique {
                    alert.message = "This username is already in use. Please try another username."
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in }))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    self.saveChanges()
                }
            }
        } else {
            saveChanges()
        }
    }
    
    func saveChanges() {
        print("SAVE CHANGES RUNNING")
        if stripsOrPostsHaveBeenDeleted {
            let alert = UIAlertController(title: "Save Changes?", message: "Are you sure you want to save changes? All deleted posts and strips will be permanent.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { (action) in
                self.updateIndices()
                self.renameStrips()
                self.deletePosts()
                self.deleteStrips()
                self.loadingView.isHidden = false
                self.updateUserInfo {
                    self.dismiss(animated: true, completion: nil)
                    self.loadingView.isHidden = true
                }
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            updateIndices()
            renameStrips()
            self.loadingView.isHidden = false
            updateUserInfo {
                self.dismiss(animated: true, completion: nil)
                self.loadingView.isHidden = true
            }
        }
    }
    
    func renameStrips() {
        for (_, newStripTuple) in newStripNames {
            API.Strip.updateName(forStrip: newStripTuple.1, withName: newStripTuple.0) { (_) in }
        }
    }
    
    func deletePosts() {
        for post in deletedPosts {
            API.Post.deletePost(post: post)
        }
    }
    
    func deleteStrips() {
        for strip in deletedStrips {
            API.Strip.deleteStrip(strip: strip)
        }
    }
    
    func updateUserInfo(completion: @escaping ()->()) {
        let newUsername = userInfo["username"]
        let newName = userInfo["name"]
        let newLink = userInfo["link"]
        let newBio = userInfo["bio"]
        
        if let cardCell = cardCell {
            if let yt = cardCell.txtYoutube.text {
                if card == nil {
                    card = UserCard()
                }
                card?.youtube = yt
            }
            if let category = cardCell.txtCategory.text {
                if card == nil {
                    card = UserCard()
                }
                card?.category = category
            }
            if let tw = cardCell.txtTwitter.text {
                if card == nil {
                    card = UserCard()
                }
                card?.twitter = tw
            }
            if let insta = cardCell.txtInsta.text {
                if card == nil {
                    card = UserCard()
                }
                card?.instagram = insta
            }
            card?.name = profileOwner.name
            card?.profilePicture = profileOwner.profileImageURL
        }
                
        if let card = card {
            API.UserCard.addCard(card: card, toUserID: profileOwner.uid) { (err) in
                API.User.updateUserInfo(forUser: self.profileOwner, newUsername: newUsername, newName: newName, newBio: newBio, newBioLink: newLink, newProfileImage: self.newProfileImage, newHeaderImage: self.newHeaderImage, showCard: self.showCard) {
                    completion()
                }
            }
        } else {
            API.User.updateUserInfo(forUser: profileOwner, newUsername: newUsername, newName: newName, newBio: newBio, newBioLink: newLink, newProfileImage: newProfileImage, newHeaderImage: newHeaderImage, showCard: self.showCard) {
                completion()
            }
        }
    }
    
    func usernameIsFormattedCorrectly(username: String?) -> Bool {
        guard let username = username else { return false }
        return username.range(of: "[^a-z0-9_]", options: .regularExpression) == nil && (username.count > 2 && username.count < 24)
    }
    
    func checkUsernameUniqueness(username: String?, completion: @escaping(Bool)->()) {
        guard let username = username else {
            completion(false)
            return
        }
        API.User.usernamesReference.child(username).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print("THIS USERNAME ALREADY EXISTS")
                completion(false)
            } else {
                print("USERNAME IS AVAILABLE")
                completion(true)
            }
        }
    }
    
    // Helper method for moving strips, just updates their Firebase index to match their index in strips array
    func updateIndices() {
        for (index, strip) in strips.enumerated() {
            API.Strip.setIndex(index: index + 1, forStrip: strip)
            print("Updating index of \(strip.name) to \(index + 1)")
        }
    }
    
     func tabChanged() {
        if currentTab == 0 || currentTab == 2{
            tableView.isEditing = false
        } else {
            updateUserInfoDictionary()
            tableView.isEditing = true
        }
        self.tableView.reloadData()
    }
    
    
    func updateUserInfoDictionary() {
        if let userInfoCell = userInfoCell {
            self.userInfo["name"] = userInfoCell.nameTextField.getTrimmedText() ?? ""
            self.userInfo["username"] = userInfoCell.usernameTextField.getTrimmedText() ?? ""
            self.userInfo["link"] = userInfoCell.linkTextField.getTrimmedText() ?? ""
            
            // Need to make sure we don't save bio placeholder text in dictionary
            if userInfoCell.bioTextView.tag == 1 {
                self.userInfo["bio"] = ""
            } else {
                self.userInfo["bio"] = userInfoCell.bioTextView.getTrimmedText() ?? ""
            }
        }
    }

}

extension EditProfileViewController: UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentTab != 1 { return 1 }
        return strips.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if currentTab == 0 {
            return 370
        }
        if currentTab == 2 {
            return 280
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentTab == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileInfoCell") as! EditProfileTableViewCell
            cell.nameTextField.text = userInfo["name"]
            cell.usernameTextField.text = userInfo["username"]
            cell.linkTextField.text = userInfo["link"]
            cell.bioTextView.text = userInfo["bio"]
            self.userInfoCell = cell
            if let userInfoCell = userInfoCell {
                self.textViewDidEndEditing(userInfoCell.bioTextView)
            }
            return cell
        } else if currentTab == 1 {
            strips = strips.sorted(by: { $0.index < $1.index })
            let cell = tableView.dequeueReusableCell(withIdentifier: "StripTableViewCell") as! StripTableViewCell
            let strip = strips[indexPath.row]
            let posts = stripPosts[strip.stripID]
            cell.strip = strip
            cell.countView.isHidden = true
            cell.arrowImg.isHidden = true
            cell.posts = posts
            cell.isCurrentlyEditing = true
            cell.delegate = self
            cell.index = indexPath.row
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditCardCell") as! EditCardTableViewCell
            cell.txtCategory.delegate = self
            cell.bind(card: card, showCard: profileOwner.showCard ?? false)
            cell.showCardSwitch.on(.valueChanged) { (control, event) in
                self.showCard = cell.showCardSwitch.isOn
            }
            
            dropDown.dataSource = UserCardAPI.categories
            dropDown.anchorView = cell
            dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
                let category = UserCardAPI.categories[index]
                card?.category = category
                cell.txtCategory.text = category
            }
            self.cardCell = cell
            return cell
        }
    }
    @objc func action() {
        
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // Lets you move strips, moves them on the database too
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedStrip = self.strips[sourceIndexPath.row]
        strips.remove(at: sourceIndexPath.row)
        strips.insert(movedStrip, at: destinationIndexPath.row)
        print("moved a strip, looks like this now:")
        for strip in strips {
            print(strip.name)
            strip.index = destinationIndexPath.row
        }
        print("====================================")
//        updateIndices()
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == cardCell?.txtCategory {
            dropDown.show()
            return false
        }
        return true
    }
    
}


extension EditProfileViewController: StripCellDelegate {
    func deletePost(post: StripwayPost, fromStrip strip: StripwayStrip) {
        print("DELETING POST WITH ID: \(post.postID)")
        stripsOrPostsHaveBeenDeleted = true
        deletedPosts.append(post)
        stripPosts[strip.stripID]?.removeAll(where: { $0.postID == post.postID })
        tableView.reloadData()
    }
    
    func loadMore(index: Int) {
    }
    
    func accessoryPressedForPost(post: StripwayPost, forTrendtag trendtag: Trendtag) {}
    
    func deleteStrip(strip: StripwayStrip, atIndex: Int) {
        print("Deleting strip: \(strip.name)")
        
        stripsOrPostsHaveBeenDeleted = true
        deletedStrips.append(strip)
        strips.removeAll(where: { $0.stripID == strip.stripID })
        tableView.reloadData()
    }
    
//    func goToPostVC(post: StripwayPost) {}
    
    func goToPostVC(post: StripwayPost, posts: [StripwayPost]) {}
    
    func goToStripVC(strip: StripwayStrip) {}
    
    func goToTrendtagVC(trendtag: Trendtag) {}
    
    func didEditStripName(newName: String, forStrip strip: StripwayStrip) {
        newStripNames[strip.stripID] = (newName, strip)
    }
    
}

class EditProfileTableViewCell: UITableViewCell {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var bioTextView: UITextView!
    
    
    
    override func layoutSubviews() {
        
        let nameBottomBorder = UIView(frame: CGRect.zero)
        self.contentView.addSubview(nameBottomBorder)
        nameBottomBorder.translatesAutoresizingMaskIntoConstraints = false
        nameBottomBorder.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10).isActive = true
        nameBottomBorder.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        nameBottomBorder.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        nameBottomBorder.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        nameBottomBorder.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 192/255, alpha: 0.03)
        
        let usernameBottomBorder = UIView(frame: CGRect.zero)
        self.contentView.addSubview(usernameBottomBorder)
        usernameBottomBorder.translatesAutoresizingMaskIntoConstraints = false
        usernameBottomBorder.bottomAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 10).isActive = true
        usernameBottomBorder.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        usernameBottomBorder.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        usernameBottomBorder.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        usernameBottomBorder.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 192/255, alpha: 0.03)
        
        let linkBottomBorder = UIView(frame: CGRect.zero)
        self.contentView.addSubview(linkBottomBorder)
        linkBottomBorder.translatesAutoresizingMaskIntoConstraints = false
        linkBottomBorder.bottomAnchor.constraint(equalTo: linkTextField.bottomAnchor, constant: 10).isActive = true
        linkBottomBorder.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        linkBottomBorder.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        linkBottomBorder.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        linkBottomBorder.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 192/255, alpha: 0.03)
        
        let bioBottomBorder = UIView(frame: CGRect.zero)
        self.contentView.addSubview(bioBottomBorder)
        bioBottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bioBottomBorder.bottomAnchor.constraint(equalTo: bioTextView.bottomAnchor, constant: 8).isActive = true
        bioBottomBorder.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        bioBottomBorder.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        bioBottomBorder.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        bioBottomBorder.backgroundColor = UIColor(red: 187/255, green: 187/255, blue: 192/255, alpha: 0.03)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, FMImageEditorViewControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Local variable inserted by Swift 4.2 migrator.
        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        
        print("Did finish picking media")
        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            print("Something went wrong with the image picker")
            dismiss(animated: true, completion: nil)
            return
        }
        
        dismiss(animated: false) {
            self.presentCropViewController(withImage: image)
        }
    }

    func presentCropViewController(withImage image: UIImage) {
        
        var config = FMPhotoPickerConfig()
        config.selectMode = .single
        config.maxImage = 1
        config.mediaTypes = [.image]
        config.useCropFirst = true
        // Depends on which image user is changing
        switch imagePicked {
        case .profileImage:
            config.eclipsePreviewEnabled = true
            config.availableCrops = [FMCrop.ratioSquare]
            config.forceCropEnabled = true
        case .headerImage:
            // If it's the header image, then it must have a 3:1 width:height ratio
            config.availableCrops = [StripCrop.ratio3x1]
            config.forceCropEnabled = true
        default:
            print("Didn't work")
            return
        }
        let picker = FMImageEditorViewController(config: config, sourceImage: image)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func fmImageEditorViewController(_ editor: FMImageEditorViewController, didFinishEdittingPhotoWith photo: UIImage) {
        let image = photo
        dismiss(animated: false)
        
        switch imagePicked {
        case .profileImage:
            profileImageView.image = image
            newProfileImage = image
      
        case .headerImage:
            headerImageView.image = image
            newHeaderImage = image
        default:
            print("no new image")
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

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 1 {
            textView.tag = 0
            textView.text = ""
            textView.textColor = UIColor.black
            textView.textAlignment = .left
        }
        textView.contentInset = .zero
        textView.clipsToBounds = true
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        // Tag of 1 means it has a placeholder, tag of 0 means it doesnt
        if textView.text == "" {
            textView.tag = 1
            textView.text = "Add a bio to your profile"
            textView.textColor = UIColor(red: 187/255, green: 187/255, blue: 192/255, alpha: 0.9)
            textView.textAlignment = .center
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
