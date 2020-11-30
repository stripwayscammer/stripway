//
//  NewPostViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/15/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase

class NewPostViewController: UIViewController {
    
    var imageToPost: UIImage? = nil
    var imageAspectRatio: CGFloat! = 0.0
    var postAuthor: StripwayUser!
    var postCaption: String!
    var postCaptionBackGroundColorCode: String!
    var postCaptionTextColorCode: String!
    var postHashTags: [String]!
    var newHashFlag: Bool = false
    var newHashTags: [String]!
    var selectedUsers: [StripwayUser] = []
    var taggedUsers: [TaggedUser] = []
    
    @IBOutlet weak var captionView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageToPostView: UIImageView!
    @IBOutlet weak var viewContnrImg: UIView!
    @IBOutlet weak var colorCaption_CV: UICollectionView!
    @IBOutlet weak var postimageHeigt: NSLayoutConstraint!
    @IBOutlet weak var captionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var captionTextView: MyTextView!
    
    var strips: [StripwayStrip] = []
    
    var selectedStrip: StripwayStrip?
    
    @IBOutlet weak var postButton: UIButton!
    
    @IBOutlet weak var newStripLabel: UILabel!
    @IBOutlet weak var lblStripNotFound: UILabel!
    @IBOutlet weak var newStripTextField: UITextField!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var isAddingToNewStrip = false
    

    
    var isTextPost = false
    var mentionedUIDs = [String]()
    
    var customTabBarController: CustomTabBarController!
   
    let colorArray: [UIColor] = [UIColor.black, UIColor.white]
    var isCaptionColorSelected = false
    var tagSelected:Int?
    var backroundColorCode:String?
    var textColorCode:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captionView.isUserInteractionEnabled = false
        if isTextPost {
            captionTextView.isHidden = false
            self.imageToPostView.isHidden = true
            captionTextView.text = postCaption
            if postCaptionBackGroundColorCode == "#000000" {
                captionView.backgroundColor = .black
                captionTextView.textColor = .white
            } else {
                captionView.backgroundColor = .white
                captionTextView.textColor = .black
            }
            captionViewHeight.constant = UIScreen.main.bounds.size.width / self.imageAspectRatio
            captionView.layoutIfNeeded()
            captionTextView.fitTextToBounds()
            captionTextView.alignTextVerticallyInContainer()
        } else {
            captionTextView.isHidden = true
        }
        
        self.modification()
        scrollView.contentOffset.x = 0
        scrollView.bounces = false
        
        self.lblStripNotFound.isHidden = true
    }
    
    override func viewWillLayoutSubviews() {
        self.postimageHeigt.constant = UIScreen.main.bounds.size.width / self.imageAspectRatio
        self.imageToPostView.layoutIfNeeded()
    }
    
    func modification() {
       
        newStripTextField.setBottomBorder()
        if self.navigationController == nil {
            print("Adding a fake navigation bar")
        }
        
        if let newImage = imageToPost {
            imageToPostView.image = newImage
        } else {
            print("The image didn't pass through for some reaosn.")
        }
        loadStrips()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("NewPostViewController")
    }
    
    // This load the entire strip just to get the name, not good
    func loadStrips() {
        print("loading strips")
        
        API.Strip.fetchStripIDs(forUserID: postAuthor.uid) { (key) in
            API.Strip.observeStrip(withID: key, completion: { (strip) in
                self.strips.append(strip)
                print("Rohit stripe---\(strip.name)")
                self.collectionView.reloadData()
                self.lblStripNotFound.isHidden = true
            })
            print("Rohit stripe--->>")
        }
    }
    
    @IBOutlet weak var topTabSuperview: UIView!
    @IBOutlet weak var tuLeadingConstraint1: NSLayoutConstraint!
    @IBOutlet weak var tuTrailingConstraint1: NSLayoutConstraint!
    @IBOutlet weak var tuLeadingConstraint2: NSLayoutConstraint!
    @IBOutlet weak var tuTrailingConstraint2: NSLayoutConstraint!
    
    
    @IBAction func chooseStripButtonPressed(_ sender: Any) {
        print("real chooseStripButtonPressed")
        tuLeadingConstraint2.isActive = false
        tuTrailingConstraint2.isActive = false
        tuLeadingConstraint1.isActive = true
        tuTrailingConstraint1.isActive = true
        UIView.animate(withDuration: 0.3) {
            self.topTabSuperview.layoutIfNeeded()
        }
        isAddingToNewStrip = false
        toggleTabs()
    }
    
    @IBAction func chooseTagPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AddTagViewController") as? AddTagViewController{
            vc.selectedUsers = selectedUsers
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func createStripButtonPressed(_ sender: Any) {
        tuLeadingConstraint1.isActive = false
        tuTrailingConstraint1.isActive = false
        tuLeadingConstraint2.isActive = true
        tuTrailingConstraint2.isActive = true
        UIView.animate(withDuration: 0.3) {
            self.topTabSuperview.layoutIfNeeded()
        }
        isAddingToNewStrip = true
        toggleTabs()
    }
    

    
    func toggleTabs() {
        if isAddingToNewStrip {
            collectionView.isHidden = true
            newStripTextField.isHidden = false
            newStripLabel.isHidden = false
            lblStripNotFound.isHidden = true

        } else {
          
            newStripTextField.isHidden = true
            newStripLabel.isHidden = true
            collectionView.isHidden = false
        }
    }
    
    @objc func keyboardWillShow() {
        if newStripTextField.isEditing { return }
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 150
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
//        self.cancelPosting()
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        postButton.isEnabled = false
        print("Post button pressed")
        
        guard let image = imageToPost else { return }

        
        if tagSelected == 0 {
            backroundColorCode = "#000000"
            textColorCode = "#FFFFFF"
        }else if tagSelected == 1 {
            backroundColorCode = "#FFFFFF"
            textColorCode = "#000000"
        }
        
        if newHashFlag {
            API.Hashtag.postHashtags(withUserUID: postAuthor.uid, tags: newHashTags)
        }
        
        var tags = [String:Any]()
        
        for tagged in taggedUsers{
            var dict = [String:Any]()
            dict["username"] = tagged.user.username
            dict["x"] = tagged.view.frame.origin.x
            dict["y"] = tagged.view.frame.origin.y - self.scrollView.frame.origin.y
            tags[tagged.user.uid] = dict
        }
        
        if isAddingToNewStrip {
            if let newStripName = newStripTextField.text, !newStripName.isEmpty {
                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                let newPostID = API.Post.postsDatabaseReference.childByAutoId().key!
                let timestamp = Int(Date().timeIntervalSince1970)
                let newStripeID = API.Strip.stripsDatabaseReference.childByAutoId().key!
                
                let post = StripwayPost(postID: newPostID, postImage: image, authorUID: postAuthor.uid, caption: postCaption ,captionBgColorCode: postCaptionBackGroundColorCode ?? "",captionTxtColorCode: postCaptionTextColorCode ?? "", hashTags: postHashTags,timestamp:timestamp, stripName: newStripName, stripID: newStripeID, imageAspectRatio: imageAspectRatio, withMentions: mentionedUIDs, width:Int(image.size.width*0.5), height:Int(image.size.height*0.5), tags: tags)
                
                self.startPosting(post, postAuthor)
                API.Strip.addPostToNewStrip(postID:newPostID, stripName: newStripName, newStripID: newStripeID, authorUID: self.postAuthor.uid, postImage: image, caption: postCaption, captionBgColorCode: postCaptionBackGroundColorCode ?? "", captionTxtColorCode: postCaptionTextColorCode ?? "", hashTags: postHashTags, timestamp:timestamp, imageAspectRatio: imageAspectRatio, withMentions: self.mentionedUIDs, tags: tags) { (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    //                    NotificationCenter.default.post(name: NEW_POSTING_FINISHED, object: nil, userInfo:nil)
                    //                    self.dismiss(animated: true, completion: nil)
                    //                    self.finishPosting()
                }
                
            } else {
                let alert = UIAlertController(title: "Enter Strip Name", message: "You must enter the name for the new strip, or choose an existing strip to add this post to.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                postButton.isEnabled = true
            }
        } else {
            //            if selectedStrip == nil && !strips.isEmpty {
            //                self.selectedStrip = strips.first!
            //            }
             if selectedStrip == nil {
                let alert = UIAlertController(title: "Choose a Strip", message: "You must choose a strip to add this post to, or create a new strip.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self.postButton.isEnabled = true
                    return
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                
                
                let newPostID = API.Post.postsDatabaseReference.childByAutoId().key!
                let timestamp = Int(Date().timeIntervalSince1970)
                
                let post = StripwayPost(postID: newPostID, postImage: image, authorUID: postAuthor.uid, caption: postCaption, captionBgColorCode: postCaptionBackGroundColorCode ?? "", captionTxtColorCode: postCaptionTextColorCode ?? "", hashTags: postHashTags, timestamp:timestamp, stripName: selectedStrip!.name, stripID: selectedStrip!.stripID, imageAspectRatio: imageAspectRatio, withMentions: mentionedUIDs, width:Int(image.size.width*0.5), height:Int(image.size.height*0.5), tags: tags)
                
                self.startPosting(post, postAuthor)
                
                API.Post.createPost(postID:newPostID, postImage: image, authorUID: postAuthor.uid, caption: postCaption, captionBgColorCode: postCaptionBackGroundColorCode ?? "", captionTxtColorCode: postCaptionTextColorCode ?? "", hashTags: postHashTags, timestamp:timestamp, stripName: selectedStrip!.name, stripID: selectedStrip!.stripID, imageAspectRatio: imageAspectRatio, withMentions: mentionedUIDs, tags: tags) { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    
                    // this post might need a snapshot of some sort
                    guard let post = post else { return }
                    print("Here's the post that should have successfully uploaded: \(post.toAnyObject())")
                    if let strip = self.selectedStrip {
                        API.Strip.addPostToStrip(withID: strip.stripID, post: post)
                        //                        NotificationCenter.default.post(name: NEW_POSTING_FINISHED, object: nil, userInfo:nil)
                    }
                    else {
                        print("This post wasn't added to a strip")
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SuggestionsContainerSegue" {

        }
    }
    
    func startPosting(_ post:StripwayPost, _ postAuthor:StripwayUser) {
        print("Running finish posting")
        API.Post.newPost = post
        API.Post.newAuthor = postAuthor
        API.Post.wasNewPostPosted = true
        
        customTabBarController.newPostPosted()
        self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func cancelPosting() {
        customTabBarController.cancelPosted()
    }
    
    func alertValidation() {
        let alert = UIAlertController(title: "", message: "Please select background color.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension NewPostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        
    }
    func textViewDidChange(_ textView: UITextView) {
        
        
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
       
        return true
    }
    
    
}


extension NewPostViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == colorCaption_CV //MARK: -: ColorCaption_CV :-
        { return colorArray.count }
        else {
            print("Should have this many collectionView cells: \(strips.count)")
            if strips.count == 0 {
                self.lblStripNotFound.isHidden = false
                self.lblStripNotFound.text = "No stripe found, click create stripe  to create new stripe"
                return 0
            }
            self.lblStripNotFound.isHidden = true
            return strips.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == colorCaption_CV { //MARK: -: ColorCaption_CV :-
            let colorCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCaptionCell", for: indexPath) as! ColorCaptionCell
            colorCell.colorView.backgroundColor = colorArray[indexPath.row]
            colorCell.modifyView()
            return colorCell
        }
        else {
            strips = strips.sorted(by: { $0.index < $1.index })
            print("Should be creating a collectionView cell for strip: \(strips[indexPath.row].name)")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChooseStripCell", for: indexPath) as! ChooseStripCollectionViewCell
            cell.stripNameLabel.text = strips[indexPath.row].name
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         self.selectedStrip = strips[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == colorCaption_CV //MARK: -: ColorCaption_CV :-
        { return CGSize(width: colorCaption_CV.bounds.height - 10, height: colorCaption_CV.bounds.height - 10) }
        else
        { return CGSize(width: colorCaption_CV.bounds.width/2.5, height: colorCaption_CV.bounds.height) }
    }
}

class ChooseStripCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var stripNameLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectCell()
            } else {
                deselectCell()
            }
        }
    }
    
    override func layoutSubviews() {
        print("Running layoutSubviews()")
        super.layoutSubviews()
        if isSelected {
            selectCell()
        } else {
            deselectCell()
        }
        self.layer.cornerRadius = 10.0
    }
    
    func selectCell() {
        self.layer.borderWidth = 3.0
        self.layer.borderColor = UIColor.black.cgColor
        stripNameLabel.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    func deselectCell() {
        self.layer.borderWidth = 2.0
        //        self.layer.borderColor = UIColor.lightGray.cgColor
        stripNameLabel.font = UIFont.systemFont(ofSize: 17)
    }
    
}

extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UITextView{
    func centerText() {
        self.textAlignment = .center
        let fittingSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let size = sizeThatFits(fittingSize)
        let topOffset = (bounds.size.height - size.height * zoomScale) / 2
        let positiveTopOffset = max(1, topOffset)
        contentOffset.y = -positiveTopOffset
    }
}


extension NewPostViewController:AddTagViewControllerDelegate{
    func cellWithUserTapped(user: StripwayUser, fromVC vc: AddTagViewController) {
        
    }
    
    func addThisUser(_ user: StripwayUser) {
        selectedUsers.append(user)
        if let rect = getRect(){
            
            let myText = user.username
            
            let mRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            let labelSize = myText.boundingRect(with: mRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:  UIFont.systemFont(ofSize: 14)], context: nil)
            
            let button = UIButton(frame: rect)
            button.frame.size.width = labelSize.width + 30
            button.setTitle("@" + user.username, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.backgroundColor = UIColor.black
            button.alpha = 0.7
            button.layer.cornerRadius = 14
            button.clipsToBounds = true
            var panGesture  = UIPanGestureRecognizer()
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_: )))
            button.isUserInteractionEnabled = true
            button.addGestureRecognizer(panGesture)

            if isTextPost {
                self.captionView.isUserInteractionEnabled = true
                self.captionView.addSubview(button)
                self.captionView.bringSubviewToFront(button)
            } else {
                self.imageToPostView.isUserInteractionEnabled = true
                self.imageToPostView.addSubview(button)
                
            }
            
            let taggedUser = TaggedUser(user: user, view: button)
            self.taggedUsers.append(taggedUser)}
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        print("draggedView")
        let button = sender.view as! UIButton
        isTextPost ? self.imageToPostView.bringSubviewToFront(button) : self.captionView.bringSubviewToFront(button)
        let translation = sender.translation(in: self.imageToPostView)
        
        if getVaildBounds(center: CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)) {
            button.center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: isTextPost ? self.captionView : self.imageToPostView)
        }
    }
    
    func removeThisUser(_ user: StripwayUser) {
        if let index = selectedUsers.firstIndex(where: {$0.uid == user.uid}){
            selectedUsers.remove(at: index)
        }
        
        if let taggedIndex = taggedUsers.firstIndex(where: {$0.user.uid == user.uid}){
            self.taggedUsers[taggedIndex].view.removeFromSuperview()
            self.taggedUsers.remove(at: taggedIndex)
        }
    }
    
    func getRect()->CGRect?{
        
        var tries = 0
        var rect:CGRect? = nil
        while rect == nil && tries < 10{
            let testingRect = getRectBounds()
            if taggedUsers.contains(where: {$0.view.frame.intersects(testingRect)}){
                tries += 1
            }else{
                rect = testingRect
            }
            
        }
        
        return rect

    }
    
    func getRectBounds()->CGRect{
        let width = Int(isTextPost ? captionView.bounds.width : imageToPostView.bounds.width) - 100
        let height = Int(isTextPost ? captionView.bounds.height : imageToPostView.bounds.height)
       
        let x = Int.random(in: 50...width)
        let y = Int.random(in: 100...height)
        
        return CGRect(x: x, y: y, width: 120, height: 28)
    }
    
    func getVaildBounds(center: CGPoint)->Bool{
        
        let maxX = isTextPost ? captionView.bounds.size.width : imageToPostView.bounds.size.width
        let maxY = isTextPost ? captionView.bounds.size.height : imageToPostView.bounds.size.height
        
        
        
        let x = center.x
        let y = center.y
        
        //checking if u
        if(y > 1){
            if (x < maxX && y < maxY) {
                return  true
            }
            
        }else{
            return false
        }
   
        return false
    }
    
}
