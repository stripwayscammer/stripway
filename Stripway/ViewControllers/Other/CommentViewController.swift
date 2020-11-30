//
//  CommentViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseDatabase
import MBProgressHUD

class Section {
    var comment: StripwayComment
    var replies: [StripwayComment]?
    var collapsed: Bool
    var observedReply: Bool = false
    var currentReplyPage = 1
    init(comment: StripwayComment, replies: [StripwayComment]? = nil, collapsed: Bool = true) {
        self.comment = comment
        self.replies = replies
        self.collapsed = collapsed
    }
}
class CommentTextView: PlaceholderTextView {
    var replyToUser: StripwayUser?
    var replyingComment: StripwayComment?
}
class CommentViewController: UIViewController {

    @IBOutlet weak var scrollTopView: UIView!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var textView: CommentTextView!
    
    @IBOutlet var tableViewTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIButton!
        
    var post: StripwayPost!
    var sections = [Section]()
    var currentUser: StripwayUser?
    var users: [StripwayUser] = []
    var accurateUsers: [String: StripwayUser] = [:]
    
    @IBOutlet weak var commentsNumberLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var tappedUser: StripwayUser!
    
    var delegate: CommentViewControllerDelegate?
    var commentHandle:DatabaseHandle!
    
    @IBOutlet weak var suggestionsContainerView: UIView!
    var suggestionsTableViewController: SuggestionsTableViewController?

    var mentionedUIDs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        tableView.estimatedRowHeight = 69
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 100
        tableView.keyboardDismissMode = .onDrag
        tableView.allowsSelection = true
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.sectionFooterHeight = 0.0
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let commentsRef = API.Comment.postCommentsReference.child(post!.postID)
        if commentHandle != nil {
            commentsRef.removeObserver(withHandle: commentHandle)
        }
        commentHandle = commentsRef.observe(.value) { (snapshot) in
            let numberOfComments = snapshot.childrenCount
            self.commentsNumberLabel.text = "\(numberOfComments) comments"
        }
        
        handleTextField()
        loadComments()
        API.User.observeCurrentUser { (user) in
            self.currentUser = user
        }
    }
    
    func handleTextField() {
//        textView.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
    }
    
    func loadComments() {
//        API.Comment.observeComments(withPostID: self.post.postID) { (comment) in
//            // could maybe add an isBlocked to the observeUser since it doesn't add untikl later
//            // also should we maybe just return both at the same time anyway?
//            API.User.observeUser(withUID: comment.authorUID, completion: { (user) in
//                self.comments.append(comment)
//                print("Here's the timestamp for the new comment: \(comment.timestamp)")
//                print("Also here's the commentID: \(comment.commentID)")
//                self.users.append(user)
//                self.accurateUsers[user.uid] = user
//                self.tableView.reloadData()
//            })
//        }
        
        API.Comment.observeComments(forPostID: self.post.postID) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let result = result else { return }
            let comment = result.0
            let user = result.1
            let section = Section(comment: comment)
            self.sections.append(section)
            self.users.append(user)
            self.accurateUsers[user.uid] = user
            self.tableView.reloadData()
        }
        
        // this will mess up the order of users, that needs to be fixed too
        API.Comment.observeCommentRemoved(forPostID: post.postID) { (key) in
//            print("This is the removed comment: \(key)")
////            self.comments = self.comments.filter{ $0.commentID != key }
//            let index = self.comments.firstIndex(where: { $0.commentID == key })
//            print("THIS IS THE REMOVED INDEX OF THE COMMENT: \(index)")
            self.tableView.reloadData()
        }
    }
    
    @objc func textFieldDidChange() {
        if let commentText = textView.text, !commentText.isEmpty {
            postButton.isEnabled = true
            return
        }
        postButton.isEnabled = false
        return
    }
    func dismissSelf() {
        self.willMove(toParent: nil)
        UIView.animate(withDuration: 0.25) {
            self.view.frame = .init(x: 0, y: self.view.bounds.size.height, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        } completion: { (_) in
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.didMove(toParent: nil)
        }
    }
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizer.State.ended {
            let velocity = recognizer.velocity(in: self.view)
            
            if (velocity.y > VELOCITY_LIMIT_SWIPE) {
                textView.resignFirstResponder()
                dismissSelf()
            }
            
            let magnitude = sqrt(velocity.y * velocity.y)
            let slideMultiplier = magnitude / 200
            
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            var finalPoint = CGPoint(x:recognizer.view!.center.x,
                                     y:recognizer.view!.center.y + (velocity.y * slideFactor))
            finalPoint.x = min(max(finalPoint.x, 0), self.view.bounds.size.width)
            
            let finalY = recognizer.view!.center.y
            let tabHeight = self.tabBarController!.tabBar.bounds.height
            if finalY < UIScreen.main.bounds.height {
                finalPoint.y = UIScreen.main.bounds.height * 0.625 - tabHeight
            }
            else {
                textView.resignFirstResponder()
                dismissSelf()
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
    }

    @IBAction func topViewTapped(_ sender: Any) {
        textView.resignFirstResponder()
        dismissSelf()
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
        if textView.text.isEmpty { // check if user is replying to a comment
            textView.replyToUser = nil
            textView.replyingComment = nil
            textView.placeholder = "Write a comment..."
        }
        UIView.animate(withDuration: 0.05) {
            self.textFieldBottomConstraint.constant = -150
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        postButton.isEnabled = false
        if let comment = textView.replyingComment {
            var commentText = textView.text ?? ""
            if let user = textView.replyToUser {
                commentText = "Replied to @\(user.username): \(commentText)"
            }
            API.Comment.createReply(forCommentID: comment.commentID, fromPostAuthor: post.authorUID, withText: commentText, commentAuthorID: Constants.currentUser!.uid, withMentions: mentionedUIDs) { newReply in
                self.sections.sort(by: {$0.comment.timestamp < $1.comment.timestamp})
                if let index = self.sections.firstIndex(where: {$0.comment.commentID == self.textView.replyingComment?.commentID}) {
                    if self.sections[index].collapsed {
                        self.expandSection(self.tableView(self.tableView, viewForHeaderInSection: index) as! CommentTableViewHeader, section: index)
                    } else {
                        if self.sections[index].replies != nil {
                            self.sections[index].replies!.insert(newReply, at: 0)
                            UIView.setAnimationsEnabled(false)
                            self.tableView.beginUpdates()
                            self.tableView.insertRows(at: [IndexPath(row: 0, section: index)], with: .top)
                            UIView.setAnimationsEnabled(true)
                            self.tableView.endUpdates()
                        }
                    }
                }
                self.postButton.isEnabled = true
                self.empty()
                self.textView.replyingComment = nil
                self.textView.replyToUser = nil
            }
        } else {
            API.Comment.createComment(forPostID: self.post.postID, fromPostAuthor: self.post.authorUID, withText: textView.text ?? "", commentAuthorID: Constants.currentUser!.uid, withMentions: mentionedUIDs) { newComment in
                self.postButton.isEnabled = true
                self.empty()
            }
        }
        
    }
    
    func empty() {
        textView.text = ""
        textFieldDidChange()
        textView.resignFirstResponder()
    }
    

    @IBAction func xButtonPressed(_ sender: Any) {
        textView.resignFirstResponder()
//        self.dismiss(animated: true, completion: nil)
        dismissSelf()
    }
    @objc func viewMoreReplyClicked(_ sender: UIButton) {
        let section = sender.tag
        self.loadMoreReply(at: section)
    }
}

extension CommentViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedComments = sections.sorted(by: {$0.comment.timestamp < $1.comment.timestamp})
        let count = sortedComments[section].collapsed ? 0 : sortedComments[section].replies?.count ?? 0
        return count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sortedSections = sections.sorted(by: {$0.comment.timestamp < $1.comment.timestamp})
        let sectionComment = sortedSections[section]
        if let replies = sectionComment.comment.replies, let sectionReplies = sectionComment.replies {
            if sectionReplies.count < replies.count {
                let view = UIView()
                let button = UIButton()
                
                button.setTitleColor(.darkGray, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
                button.addTarget(self, action: #selector(viewMoreReplyClicked(_:)), for: .touchUpInside)
                button.setImage(UIImage(named: "down-arrow"), for: .normal)
                button.semanticContentAttribute = .forceRightToLeft
                button.tag = section
                button.setTitle("View more (\(replies.count - sectionReplies.count)) ", for: .normal)
                button.frame = .init(x: 105, y: 0, width: 130, height: 15)
                view.addSubview(button)
                                
                return view
            }
        }
        return nil
        
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let _ = self.tableView(tableView, viewForFooterInSection: section) {
            return 15
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        sections.sort(by: {$0.comment.timestamp < $1.comment.timestamp})
        let comment = sections[indexPath.section].comment
        let sortedReplies = sections[indexPath.section].replies!.sorted(by: { $0.timestamp > $1.timestamp })
        let reply = sortedReplies[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell", for: indexPath) as! CommentTableViewCell
        cell.comment = reply
        cell.parentComment = comment
        cell.user = accurateUsers[reply.authorUID]
        cell.delegate = self
        cell.postAuthorUID = post.authorUID
        cell.profileImageViewLeft.constant = 75

        return cell
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sortedComments = sections.sorted(by: {$0.comment.timestamp < $1.comment.timestamp})
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "CommentHeaderTableViewCell") as? CommentTableViewHeader ?? CommentTableViewHeader(reuseIdentifier: "CommentHeaderTableViewCell")
        let comment = sortedComments[section].comment
        cell.comment = comment
        cell.user = accurateUsers[comment.authorUID]
        cell.collapsed = sortedComments[section].collapsed
        cell.section = section
        cell.delegate = self
        if !sortedComments[section].observedReply && sortedComments[section].comment.replies != nil {
            cell.viewRepliesButton.isHidden = false
            cell.viewRepliesButtonHeight.constant = 18
        } else {
            cell.viewRepliesButton.isHidden = true
            cell.viewRepliesButtonHeight.constant = 0
        }
        cell.postAuthorUID = post.authorUID
        return cell
    }

}

extension CommentViewController: CommentTableViewCellDelegate {
    func replyToComment(_ comment: StripwayComment, reply: StripwayComment?) {
        textView.replyingComment = comment
        if textView.text.isEmpty {
            if let reply = reply {
                if let user = accurateUsers[reply.authorUID] {
                    textView.placeholder = "Reply to \(user.username)"
                }
            } else {
                if let user = accurateUsers[comment.authorUID] {
                    textView.placeholder = "Reply to \(user.username)"
                }
            }
        }
        if let reply = reply {
            if let user = accurateUsers[reply.authorUID] {
                textView.replyToUser = user
            }
        }
        textView.becomeFirstResponder()
    }
    func longPressComment(_ header: CommentTableViewHeader) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copy = UIAlertAction(title: "Copy", style: .default) { (action) in
            UIPasteboard.general.string = header.comment?.commentText
        }
        alert.addAction(copy)

        if header.comment!.authorUID == Constants.currentUser!.uid || post.authorUID == Constants.currentUser!.uid {
            let delete = UIAlertAction(title: "Delete", style: .destructive) { (_) in
                let alertController = UIAlertController(title: "Delete", message: "Are you sure delete this comment?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    self.deleteComment(header.comment!)
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    
                }))
                self.present(alertController, animated: true, completion: nil)
            }
            alert.addAction(delete)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    func longPressReply(_ header: CommentTableViewCell) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copy = UIAlertAction(title: "Copy", style: .default) { (action) in
            UIPasteboard.general.string = header.comment?.commentText
        }
        alert.addAction(copy)

        if header.comment!.authorUID == Constants.currentUser!.uid || post.authorUID == Constants.currentUser!.uid {
            let delete = UIAlertAction(title: "Delete", style: .destructive) { (_) in
                
                let alertController = UIAlertController(title: "Delete", message: "Are you sure delete this comment?", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    self.sections.sort(by: {$0.comment.timestamp < $1.comment.timestamp})
                    let sorted = self.sections
                    for (index, section) in sorted.enumerated() {
                        if let replies = section.replies {
                            if let _ = replies.firstIndex(where: {$0.commentID == header.comment!.commentID }) {
                                self.delete(replyID: header.comment!.commentID, fromCommentID: section.comment.commentID)
                                section.replies = section.replies?.filter({$0.commentID != header.comment!.commentID})
                                section.comment.replies?[header.comment!.commentID] = nil
                                UIView.setAnimationsEnabled(false)
                                self.tableView.beginUpdates()
                                self.tableView.reloadSections(NSIndexSet(index: index) as IndexSet, with: .automatic)
                                self.tableView.endUpdates()
                                UIView.setAnimationsEnabled(true)
                                return
                            }
                        }                        
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    
                }))
                self.present(alertController, animated: true, completion: nil)
                
                
            }
            alert.addAction(delete)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            
        }
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }
    func delete(replyID: String, fromCommentID: String) {
        API.Comment.deleteReply(withID: replyID, fromCommentID: fromCommentID)
    }
    func loadMoreReply(at section: Int) {
        sections.sort(by: {$0.comment.timestamp < $1.comment.timestamp})
        sections[section].currentReplyPage += 1
                
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        let lastLoaded = sections[section].replies![sections[section].replies!.count - 1]
        API.Comment.observeReplies(forComment: sections[section].comment, lastLoaded: lastLoaded) { (results, err) in
            if let results = results, results.count > 0 {
                if self.sections[section].replies == nil {
                    self.sections[section].replies = []
                }
                for result in results {
                    self.sections[section].replies!.append(result.0)
                    self.accurateUsers[result.1.uid] = result.1
                }
            }
            DispatchQueue.main.async {
                hud.hide(animated: true)
                UIView.setAnimationsEnabled(false)
                self.tableView.beginUpdates()
                self.tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
                self.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)

            }
        }
    }
    func expandSection(_ header: CommentTableViewHeader, section: Int) {
        
        let sortedComments = sections.sorted(by: {$0.comment.timestamp < $1.comment.timestamp})
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        API.Comment.observeReplies(forComment: sortedComments[section].comment) { (results, err) in
            if let results = results, results.count > 0 {
                if self.sections[section].replies == nil {
                    self.sections[section].replies = []
                }
                for result in results {
                    self.sections[section].replies!.append(result.0)
                    self.accurateUsers[result.1.uid] = result.1
                }
            }
            DispatchQueue.main.async {
                hud.hide(animated: true)
                if header.collapsed {
                    let collapsed = !sortedComments[section].collapsed
                    sortedComments[section].collapsed = collapsed
                    header.collapsed = collapsed
                }
                sortedComments[section].observedReply = true
                UIView.setAnimationsEnabled(false)
                self.tableView.beginUpdates()
                self.tableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
                self.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)

            }
        }
        
    }
    func usernameProfileButtonPressed(user: StripwayUser) {
//        self.tappedUser = user
//        performSegue(withIdentifier: "ShowUserProfile", sender: self)
        delegate?.userProfilePressed(user: user, fromVC: self)
    }
    
    func deleteComment(_ comment: StripwayComment) {
        // this could probably be better, idk
        API.Comment.deleteComment(comment, fromPost: post.postID)
        if let index = sections.firstIndex(where: { $0.comment.commentID == comment.commentID }) {
            sections.remove(at: index)
            users.remove(at: index)
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUserProfile" {
            if let profileViewController = segue.destination as? ProfileViewController, let user = tappedUser {
//                profileViewController.profileOwnerUID = user.uid
                profileViewController.profileOwner = user
            }
        }
        if segue.identifier == "SuggestionsContainerSegue" {
            if let suggestionsTableViewController = segue.destination as? SuggestionsTableViewController {
                self.suggestionsTableViewController = suggestionsTableViewController
                suggestionsTableViewController.delegate = self
            }
        }
    }
    
}

extension CommentViewController: SuggestionsTableViewControllerDelegate {

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

extension CommentViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var newURL = URL.absoluteString
        let segueType = newURL.prefix(4)
        newURL.removeFirst(5)
        if segueType == "hash" {
            print("Should segue to page for hashtag: \(newURL)")
            delegate?.segueToHashtag(hashtag: newURL, fromVC: self)
        } else if segueType == "user" {
            print("Should segue to profile for user: \(newURL)")
            delegate?.segueToProfileFor(username: newURL, fromVC: self)
        }
        return false
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("textViewDidBeginEditing")
        textView.textColor = UIColor.black
        
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

extension CommentViewController: UIGestureRecognizerDelegate {
    
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

protocol CommentViewControllerDelegate {
    func userProfilePressed(user: StripwayUser, fromVC vc: CommentViewController)
    func segueToHashtag(hashtag: String, fromVC vc: CommentViewController)
    func segueToProfileFor(username: String, fromVC vc: CommentViewController)
}
