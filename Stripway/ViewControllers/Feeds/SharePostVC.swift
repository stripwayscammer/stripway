//
//  CommentViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseDatabase

class SharePostVC: UIViewController {
    
    @IBOutlet weak var scrollTopView: UIView!
    @IBOutlet weak var searchView: UIView!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet var tableViewTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var suggestionsContainerView: UIView!
    
    var post: StripwayPost!
    
    var users: [StripwayUser] = []
    var searchedUsers: [StripwayUser] = []
    var selectedUsers: [Bool] = []
    var tappedUser: StripwayUser!
    var profileOwner: StripwayUser!
    
    var delegate: SharePostVCDelegate?
    
    var suggestionsTableViewController: SuggestionsTableViewController?
    
    var mentionedUIDs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableView.automaticDimension
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        handleTextField()
        loadFollowings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func handleTextField() {
        //        textView.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
    }
    
    func loadFollowings() {
        
        self.users.removeAll()
        self.searchedUsers.removeAll()
        self.selectedUsers.removeAll()
        self.tableView.reloadData()
        
        API.Follow.fetchFollowings(forUserID: Constants.currentUser!.uid) { (user, error) in
            if let error = error {
                return
            } else if let user = user {
                self.isFollowing(userID: user.uid, completion: { (value) in
                    user.isFollowing = value
                    self.users.append(user)
                    self.searchedUsers.append(user)
                    self.selectedUsers.append(false)
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }
    
    func doSearch() {
        var searchText = searchBar.text?.lowercased()
        if searchText == nil {
            searchText = ""
        }
        print("SEARCHING WITH TEXT: |\(searchText)|")
        self.searchedUsers.removeAll()
        self.tableView.reloadData()
        for user in self.users {
            if searchText! == "" {
                self.searchedUsers.append(user)
            }
            else if user.username.lowercased().contains(searchText!){
                self.searchedUsers.append(user)
            }
        }
        self.tableView.reloadData()
    }
   
 
    @objc func textFieldDidChange() {
        return
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizer.State.ended {
            let velocity = recognizer.velocity(in: self.view)
            
            if (velocity.y > VELOCITY_LIMIT_SWIPE) {
                textView.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }
            
            let magnitude = sqrt(velocity.y * velocity.y)
            let slideMultiplier = magnitude / 200
            
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            var finalPoint = CGPoint(x:recognizer.view!.center.x,
                                     y:recognizer.view!.center.y + (velocity.y * slideFactor))
            finalPoint.x = min(max(finalPoint.x, 0), self.view.bounds.size.width)
            
            let finalY = recognizer.view!.center.y
            if finalY < UIScreen.main.bounds.height {
                finalPoint.y = UIScreen.main.bounds.height * 0.625
            }
            else {
                textView.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }
            
            UIView.animate(withDuration: Double(slideFactor),
                           delay: 0,
                           // 6
                options: UIView.AnimationOptions.curveEaseOut,
                animations: {recognizer.view!.center = finalPoint },
                completion: nil)
        }
        
        let translation = recognizer.translation(in: self.view)
        
        if let view = recognizer.view {
            print("translation Y", translation.y)
            view.center = CGPoint(x:view.center.x,
                                  y:view.center.y + translation.y)
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func setupUI() {
        bottomView.layer.cornerRadius = 20
        bottomView.layer.shadowOffset = CGSize(width: 4, height: 4)
        bottomView.layer.shadowRadius = 6
        bottomView.layer.shadowOpacity = 0.5
        
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.sizeToFit()
        searchBar.placeholder = "Search by username"
    }
    
    @IBAction func topViewTapped(_ sender: Any) {
        textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tableViewGestureTapped(_ sender: Any) {
        textView.resignFirstResponder()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        tableViewTapGestureRecognizer.isEnabled = true
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        print("Here's keyboardFrame in keyboardWillShow: \(keyboardFrame)")
        let difference = bottomView.superview!.frame.maxY - bottomView.frame.maxY
        
        UIView.animate(withDuration: 0.05) {
            self.textFieldBottomConstraint.constant = keyboardFrame.size.height - difference - 150
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide() {
        UIView.animate(withDuration: 0.05) {
            self.textFieldBottomConstraint.constant = -150
            self.view.layoutIfNeeded()
        }
    }
    
    func sendPostMessage() {
        
        var comment:String = ""
        if self.textView.text != "Write a message..." {
            comment = self.textView.text
        }
        
        for index in 0..<self.selectedUsers.count {
            if selectedUsers[index] == true {
                API.Messages.sendPost(post: self.post, comment:comment, senderUser: profileOwner, receiverUser: searchedUsers[index])
            }
        }
        self.textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
        postButton.isEnabled = true
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        postButton.isEnabled = false
        
        if self.profileOwner == nil {
            API.User.observeCurrentUser { (currentUser) in
                self.profileOwner = currentUser
                self.sendPostMessage()
            }
        }
        else {
            self.sendPostMessage()
        }
    }
    
    @IBAction func xButtonPressed(_ sender: Any) {
        textView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
}

extension SharePostVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        print(searchBar.text)
        doSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(searchBar.text)
        doSearch()
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        print("cancel pressed")
        searchBar.text = ""
        doSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel pressed")
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        doSearch()
    }
}


extension SharePostVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SharePersonCell", for: indexPath) as! SharePersonCell
        //        cell.user = users[indexPath.row]
        cell.cellIndex = indexPath.row
        cell.delegate = self
        cell.user = searchedUsers[indexPath.row]
        
        cell.selectButton.setImage(UIImage(named: "unselected_share"), for: UIControl.State.normal)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension SharePostVC: SharePersonCellDelegate {
    
    func selectPerson(_ cellIndex: Int, _ status: Bool) {
        self.selectedUsers[cellIndex] = status
    }
}

extension SharePostVC: SuggestionsTableViewControllerDelegate {
    
    func autoComplete(withSuggestion suggestion: String, andUID uid: String?) {
        print("replacing with suggestion")
        textView.autoComplete(withSuggestion: suggestion)
        self.textViewDidChange(textView)
        
        if let uid = uid {
            mentionedUIDs.append(uid)
        }
    }
    
    //    func autoComplete(withSuggestion suggestion: String) {
    //        print("replacing with suggestion")
    //        textView.autoComplete(withSuggestion: suggestion)
    //        self.textViewDidChange(textView)
    //    }
}

extension SharePostVC: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//        var newURL = URL.absoluteString
//        let segueType = newURL.prefix(4)
//        newURL.removeFirst(5)
//        if segueType == "hash" {
//            print("Should segue to page for hashtag: \(newURL)")
//            delegate?.segueToHashtag(hashtag: newURL, fromVC: self)
//        } else if segueType == "user" {
//            print("Should segue to profile for user: \(newURL)")
//            delegate?.segueToProfileFor(username: newURL, fromVC: self)
//        }
        return false
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
        if textView.tag == 0 {
            textView.tag = 1
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        textFieldDidChange()
        guard let word = textView.currentWord else {
            suggestionsContainerView.isHidden = true
            return
        }
        guard let suggestionsTableViewController = self.suggestionsTableViewController else { return }
        if word.hasPrefix("#") || word.hasPrefix("@") {
            suggestionsTableViewController.searchWithText(text: word)
            suggestionsContainerView.isHidden = false
        } else {
            suggestionsContainerView.isHidden = true
        }
    }
}

extension SharePostVC: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("This thing should run")
        //detecting a direction
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = recognizer.velocity(in: self.view)
            
            if abs(velocity.y) > abs(velocity.x) {
                // this is swipe up/down so you can handle that gesture
                return true
            } else {
                //this is swipe left/right
                //do nothing for that gesture
                return false
            }
        }
        return true
    }
    
    //    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    //
    //        //detecting a direction
    //        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer {
    //            let velocity = recognizer.velocity(in: self.view)
    //
    //            if fabs(velocity.y) > fabs(velocity.x) {
    //                // this is swipe up/down so you can handle that gesture
    //                return true
    //            } else {
    //                //this is swipe left/right
    //                //do nothing for that gesture
    //                return false
    //            }
    //        }
    //        return true
    //    }
}

protocol SharePostVCDelegate {
}
