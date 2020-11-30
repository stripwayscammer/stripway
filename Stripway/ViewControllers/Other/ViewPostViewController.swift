//
//  ViewPostViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/1/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import Zoomy

class ViewPostViewController: UIViewController {
    
    var currentUser: StripwayUser?
    var post: StripwayPost!
    
    weak var refreshDelegate: ProcessArchiveDelegate?

    /// The posts for the strip
    var posts =  [StripwayPost]()
    
    // If this doesn't exist, we must load the author of the post's uid
    var user: StripwayUser?
    
    var currentCell: PostTableViewCell!
    
    var tappedUser: StripwayUser?
    var tappedStrip: StripwayStrip?
    var isAlreadyEditing = false
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: ViewPostViewControllerDelegate?
    var downloadDelegate: DownloadWatermarkedPhotoDelegate?
    
    //Watermark
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gImageView: UIImageView!
    @IBOutlet weak var watermarkLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    var vSpinner : UIView?

    
    var hashtagForSegue: String?
    
    var tappedUsernameForSegue: String?
    
    var suggestionsTableViewController: SuggestionsTableViewController?
    
    @IBOutlet weak var suggestionsContainerView: UIView!
    
    var rangeToReplace: UITextRange?
    
    var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    /// Used when peeking/popping, because we don't want to see the icons/text when we're just peeking (photo only)
    var shouldShowPhotoOverlay: Bool?
    var shouldHideOverlays = false
    var shouldHidePhotoOverlays = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.tintColor = UIColor.black
//        tableView.estimatedRowHeight = 664
//        tableView.rowHeight = UITableView.automaticDimension
        // Do any additional setup after loading the view.
        
        // switch back to view controller 1

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let sharedPost = appDelegate.post
        
        if(sharedPost != nil ) {
            post = sharedPost
            posts.append(sharedPost!)
            appDelegate.post = nil
        }

        
        if user == nil {
            
            if(sharedPost != nil){
                
                API.User.observeUser(withUID: post.authorUID) { (user, error) in
                    if let user = user {
                        self.user = user
                        
                        self.setupUI()
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }else{
                
                if(post != nil){
                    API.User.observeUser(withUID: post.authorUID) { (user, error) in
                        if let user = user {
                            self.user = user
                            self.setupUI()
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }else{
                    
                    //Go back
                    navigationController?.popViewController(animated: true)
                    
                }
                
            }
            
            
        } else {
            
            setupUI()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                let currentPostIndex = self.posts.index{$0 === self.post}
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    let indexPath = NSIndexPath(row: self.posts.count - 1-currentPostIndex!, section: 0)
                    self.tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                }
            }
        }
        
        if isAlreadyEditing {
            self.navigationItem.setHidesBackButton(true, animated: false)
        }
        if self.posts.count == 0 && self.tappedStrip != nil {
            
            API.Strip.observePostsForStrip(atDatabaseReference: tappedStrip!.postsReference!) { (post, error, shouldClear) in
                if let shouldClear = shouldClear, shouldClear {
                    self.posts.removeAll()
                    return
                }
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.posts.append(post!)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if self.posts.count <= 2 {return}
                    if let currentPostIndex = self.posts.index(where: {$0.postID == self.post.postID}) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            let indexPath = NSIndexPath(row: self.posts.count - 1-currentPostIndex, section: 0)
                            self.tableView.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                        }
                    }
                }
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDoubleTapped))
              if let doubleTapGestureRecognizer = doubleTapGestureRecognizer {
                  doubleTapGestureRecognizer.numberOfTapsRequired = 2
                  self.view.addGestureRecognizer(doubleTapGestureRecognizer)
              }
              
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)

    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    @objc func viewDoubleTapped() {
        print("DOUBLETAP: HOME HAS BEEN DOUBLE TAPPED")
        self.shouldHidePhotoOverlays = !shouldHidePhotoOverlays
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            for indexPath in visibleIndexPaths {
                if let postCell = tableView.cellForRow(at: indexPath) as? PostTableViewCell {
                    print("DOUBLETAP: Should be hiding/showing overlay in visible cells")
                    postCell.shouldHideOverlay = self.shouldHidePhotoOverlays
                }
            }
        }
    }
    
    func setupUI() {
        
//        posts.reverse()
//        let currentPostIndex = posts.index{$0 === post}
//        posts.rotate(positions: currentPostIndex!)
        
        // Create a navView to add to the navigation bar
        
        let navView = UIView()
        
        // Create the label
        let label = UILabel()
        label.text = user!.username
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.sizeToFit()
        label.center.y = navView.center.y
        label.center.x = navView.center.x + label.frame.size.height / 2 + 3.0
        label.textAlignment = NSTextAlignment.center
        
        // Create the image view
        let profileImageView = UIImageView()
        
        if let profileImageURL = user!.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            profileImageView.sd_setImage(with: profileURL)
            // To maintain the image's aspect ratio:
            let imgHeight = label.frame.size.height + 6.0
            // Setting the image frame so that it's immediately before the text:
            profileImageView.frame = CGRect(x: label.frame.origin.x-imgHeight-5.0, y: label.frame.origin.y - 3.0, width: imgHeight, height: imgHeight)
            
            profileImageView.layer.masksToBounds = true
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        }
        
        profileImageView.contentMode = UIView.ContentMode.scaleAspectFit
        
        // Add both the label and image view to the navView
        navView.addSubview(label)
        navView.addSubview(profileImageView)
        
        // Set the navigation bar's navigation item's titleView to the navView
        self.navigationItem.titleView = navView
        
        // Set the navView's frame to fit within the titleView
        navView.sizeToFit()
        
//      self.navigationController?.navigationBar.tintColor = UIColor.black
//
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    // After the user is loaded, and the cell exists, if the user isn't current user then disable the ellipsis button
    // until we know whether the current user is following them or not
    func finishUserSetup() {
        guard let user = user else { return }
        if !user.isCurrentUser {
            currentCell.ellipsisButton.isEnabled = false
            if self.user!.isFollowing == nil {
                API.Follow.isFollowing(userID: user.uid) { (value) in
                    self.user!.isFollowing = value
                    self.currentCell.ellipsisButton.isEnabled = true
                }
            } else {
                self.currentCell.ellipsisButton.isEnabled = true
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowUserProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                if let tappedUser = self.tappedUser {
                    profileViewController.profileOwner = tappedUser
                } else if let tappedUsernameForSegue = tappedUsernameForSegue {
                    profileViewController.mentionedUsername = tappedUsernameForSegue
                }
            }
        }
        if segue.identifier == "showFromPost" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.senderUser = self.currentUser!
                viewConversationViewController.receiverUser = self.tappedUser
            }
        }
        if segue.identifier == "SegueToHashtag" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.hashtag = self.hashtagForSegue!
            }
        }
        if segue.identifier == "SuggestionsContainerSegue" {
            if let suggestionsTableViewController = segue.destination as? SuggestionsTableViewController {
                self.suggestionsTableViewController = suggestionsTableViewController
                suggestionsTableViewController.delegate = self
            }
        }
        
        if segue.identifier == "ShowUserStrip" {
            if let viewStripViewController = segue.destination as? PostCollectionWithHeaderViewController {
                if let strip = tappedStrip {
                    viewStripViewController.strip = strip
                }
                viewStripViewController.collectionAuthor = self.tappedUser
                viewStripViewController.collectionType = .strip
            }
        }
    }
    
    /// Called when the view is just peeking, hide the photo overlay
    func viewPeeked() {
        print("PEEKPOP: View peeked")
        shouldShowPhotoOverlay = false
        if let currentCell = currentCell {
            currentCell.hidePhotoOverlay()
        }
    }
    
    /// Called when view pops, show the photo overlay
    func viewPopped() {
        print("PEEKPOP: View popped")
        shouldShowPhotoOverlay = true
        if let currentCell = currentCell {
            currentCell.showPhotoOverlay()
        }
    }
    
}

extension ViewPostViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 1
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        cell.showThumb = false
//        cell.post = post
        cell.post = posts[posts.count - indexPath.row - 1]
//        cell.post = posts[indexPath.row]
        cell.delegate = self
        cell.downloadDelegate = self
        cell.homeVCDoubleTapGesture = self.doubleTapGestureRecognizer
        
        

                    
        let settings = Settings.instaZoomSettings
            .with(maximumZoomScale: 1)
            .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
        
        
        
        addZoombehavior(for: cell.postImageView, settings: settings )

        currentCell = cell
        
        
        currentCell.shouldHideOverlay = shouldHidePhotoOverlays
        
        // Peek/pop could have happened before current cell is set, so we make sure hide/show overlay is up to date
        if let shouldShowPhotoOverlay = shouldShowPhotoOverlay {
            if shouldShowPhotoOverlay {
                currentCell.showPhotoOverlay()
            } else {
                currentCell.hidePhotoOverlay()
            }
        }
        
        if let user = user {
            cell.user = user
            finishUserSetup()
        }
        
        defer {
            if isAlreadyEditing {
                startEditingPost()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        //        let ratio = post!.imageAspectRatio
        //        let newHeight = self.contentView.frame.width / ratio
        var ratio = posts[posts.count - indexPath.row - 1].imageAspectRatio
        if ratio == 0 {ratio = 3/4}
        let height = self.tableView.frame.width / ratio
        //to remove white line between 3/4 rows, change int and convert to CGFloat again
        return CGFloat(Int(height))
    }
}

extension ViewPostViewController: PostTableViewCellDelegate, SharePostVCDelegate {
    func sharePost(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "SharePostVC") as! SharePostVC
//        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
    }
    func directMessage(user: StripwayUser) {
        self.tappedUser = user
        
        API.User.observeCurrentUser { (currentUser) in
            self.currentUser = currentUser
            self.performSegue(withIdentifier: "showFromPost", sender: nil)
        }
    }
    func goBackInStack(post: StripwayPost) {
        
        navigationController?.popViewController(animated: true)
        refreshDelegate?.updateProcessStatus(isCompleted: true, post: post, index: nil)

        
    }
    
    func userStripeButtonPressed(user: StripwayUser, strip: StripwayStrip) {
        self.tappedUser = user
        self.tappedStrip = strip
        performSegue(withIdentifier: "ShowUserStrip", sender: self)
    }
    
    func presentPeopleSelectionController(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "SharePostVC") as! SharePostVC
        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
    }
    
    func postDeleted(post: StripwayPost) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func currentWordBeingTyped(word: String?) {
        print("Currently typing: \(word)")
        guard let word = word else {
            suggestionsContainerView.isHidden = true
            return
        }
        guard let currentCell = currentCell else { return }
        guard let suggestionsTableViewController = self.suggestionsTableViewController else { return }
        if word.hasPrefix("#") || word.hasPrefix("@") {
            suggestionsTableViewController.searchWithText(text: word)
            let oldFrame = suggestionsContainerView.frame
            let newFrame = CGRect(x: oldFrame.minX, y: currentCell.captionMaxY, width: oldFrame.width, height: oldFrame.height)
            suggestionsContainerView.frame = newFrame
            suggestionsContainerView.isHidden = false
            print("CAPTION BUG: captionMaxY: \(currentCell.captionMaxY) and suggestionsMinY: \(suggestionsContainerView.frame.minY)")
        } else {
            suggestionsContainerView.isHidden = true
        }
    }
    
    func segueToHashtag(hashtag: String) {
        self.hashtagForSegue = hashtag
        self.performSegue(withIdentifier: "SegueToHashtag", sender: self)
    }
    
    func startEditingPost(post: StripwayPost) {
        if posts.count > 1 {
            let storyboard = UIStoryboard(name: "Profile", bundle: nil)
            let viewPostViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
            viewPostViewController.post = post
            viewPostViewController.posts = [post]
            viewPostViewController.user = self.user
            viewPostViewController.isAlreadyEditing = true
            viewPostViewController.delegate = self
            self.navigationController?.pushViewController(viewPostViewController, animated: false)
            return
        }
        startEditingPost()
    }
    
    func presentAlertController(alertController: UIAlertController, forCell cell: PostTableViewCell) {
        present(alertController, animated: true, completion: nil)
    }
    
    func viewLikersButtonPressed(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "LikesRepostsDrawer") as! LikesRepostsViewController
        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.likesOrReposts = "likes"
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
    }
    
    func viewRepostersButtonPressed(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "LikesRepostsDrawer") as! LikesRepostsViewController
        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.likesOrReposts = "reposts"
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
    }
    
    func usernameProfileButtonPressed(user: StripwayUser) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
    }
    
    func segueToProfileFor(username: String) {
        self.tappedUsernameForSegue = username
        self.tappedUser = nil
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
    }
    
    func textViewChanged() {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func presentImageVC(imageVC: NYTPhotosViewController) {
        self.present(imageVC, animated: true, completion: nil)
    }
    
    func commentButtonPressed(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "CommentDrawer") as! CommentViewController
//        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.delegate = self
//        tabBarController?.present(pvc, animated: true, completion: nil)
        self.addChild(pvc)
        pvc.willMove(toParent: self)
        view.addSubview(pvc.view)
        pvc.view.frame = .init(x: 0, y: view.bounds.height, width: view.bounds.width, height: view.bounds.height)
        UIView.animate(withDuration: 0.25) {
            pvc.view.frame = .init(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        } completion: { (finished) in
            
        }
        pvc.didMove(toParent: self)
    }
    
    func startEditingPost() {
        print("Started editing post")
//        currentCell.postImageView.isUserInteractionEnabled = false
//        currentCell.ellipsisButton.isHidden = true
//        currentCell.captionTextView.isEditable = true
//        currentCell.captionTextView.textColor = UIColor.lightGray
//        currentCell.captionTextView.layer.borderWidth = 1.0
//        currentCell.captionTextView.layer.borderColor = UIColor.lightGray.cgColor
//        currentCell.isBeingEdited = true
        currentCell.startEditing()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.stopEditingPost))
    }
    
    @objc func stopEditingPost() {
        print("Stopped editing post")
        suggestionsContainerView.isHidden = true
        currentCell.postImageView.isUserInteractionEnabled = true
        currentCell.editableTextView.resignFirstResponder()
        func stopEditing() {
            self.navigationItem.rightBarButtonItem = nil
//            currentCell.ellipsisButton.isHidden = false
//            currentCell.captionTextView.isEditable = false
//            currentCell.captionTextView.textColor = UIColor.black
//            currentCell.captionTextView.layer.borderColor = UIColor.clear.cgColor
            if isAlreadyEditing {
                self.navigationController?.popViewController(animated: false)
            }
        }
        let alert = UIAlertController(title: "Save Changes?", message: "Are you sure you want to save the changes you made to this post?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            print("Saving changes")
            self.post!.caption = self.currentCell.editableTextView.text
            API.Post.updateCaptionForPost(post: self.post!, description: self.post!.caption)
            stopEditing()
            if self.isAlreadyEditing {
                self.delegate?.updateCaptionForPost(post: self.post!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            print("Cancelling changes")
            stopEditing()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
}

extension ViewPostViewController: LikesRepostsViewControllerDelegate {
    func cellWithUserTapped(user: StripwayUser, fromVC vc: LikesRepostsViewController) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
        vc.dismiss(animated: false, completion: nil)
    }
}

extension ViewPostViewController: CommentViewControllerDelegate {
    
    func userProfilePressed(user: StripwayUser, fromVC vc: CommentViewController) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
    func segueToHashtag(hashtag: String, fromVC vc: CommentViewController) {
        self.hashtagForSegue = hashtag
        self.performSegue(withIdentifier: "SegueToHashtag", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
    func segueToProfileFor(username: String, fromVC vc: CommentViewController) {
        self.tappedUsernameForSegue = username
        self.tappedUser = nil
        self.performSegue(withIdentifier: "ShowUserProfile", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
}

extension ViewPostViewController: SuggestionsTableViewControllerDelegate {
    
    
    func autoComplete(withSuggestion suggestion: String, andUID uid: String?) {
        print("replacing with suggestion")
        guard let editableTextView = currentCell.editableTextView else { return }
        editableTextView.autoComplete(withSuggestion: suggestion)
        currentCell.textViewDidChange(editableTextView)
    }
}

extension ViewPostViewController: ViewPostViewControllerDelegate {
    func updateCaptionForPost(post: StripwayPost) {
        print("EDITBUG: We should be updating the caption on the previous VPVC")
        guard let oldPostIndex = posts.firstIndex(where: { $0.postID == post.postID }) else { return }
        let oldPost = posts[oldPostIndex]
        oldPost.caption = post.caption
        tableView.reloadData()
    }
}

protocol ViewPostViewControllerDelegate {
    func updateCaptionForPost(post: StripwayPost)
}


extension ViewPostViewController: Zoomy.Delegate {

      func didBeginPresentingOverlay(for imageView: Zoomable) {
        
        self.tableView.isScrollEnabled = false
      }
      
      func didEndPresentingOverlay(for imageView: Zoomable) {

        self.tableView.isScrollEnabled = true
      }
      
}
