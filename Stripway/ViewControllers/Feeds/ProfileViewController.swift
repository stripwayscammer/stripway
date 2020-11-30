//
//  ProfileViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/6/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import SDWebImage
import Photos
import NYTPhotoViewer
import Toaster
import MBProgressHUD
import Zoomy
import FMPhotoPicker
import Segmentio

// TODO: There's an observeFeedRemoved method in FeedAPI that might be useful for when strips or posts are deleted
// idk though it might already be efficient
class ProfileViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // Self-explanatory UI stuff
    @IBOutlet weak var headerWithProfileView: UIView!
    @IBOutlet weak var headerImageButton: UIButton!
    @IBOutlet weak var profileImageView: SpinImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var linkTextView: UITextView!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var followingView: UIView!
    @IBOutlet weak var followersView: UIView!
    
    
    @IBOutlet weak var menuProfileImageView: UIImageView!
    @IBOutlet weak var menuNameLabel: UILabel!
    @IBOutlet weak var menuUsernameLabel: UILabel!
    
    // This is all stuff for the resizing header view
    @IBOutlet weak var resizingHeaderSuperview: UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerBlurImageView: UIImageView!
    @IBOutlet weak var headerProfileInfoSuperview: UIView!
    @IBOutlet weak var headerUsernameLabel: UILabel!
    @IBOutlet weak var headerProfileImageView: UIImageView!
    @IBOutlet weak var segmentView: Segmentio!
    
    
    @IBOutlet weak var mArchiveLabel: UILabel!
    
    @IBOutlet weak var mImageArchiveIcon: UIImageView!
    
    // The data source for the table view when top tab 1 is selected
    var archivedStripPost : [String: [StripwayPost]] = [:]
    // The data source for the table view when top tab 2 is selected

    
    var postsForStrip = [StripwayPost]()
    
    // For a feature that doesn't exist yet, which allows users to cancel changes to profile
    // which would mean everything needs to change back
    var oldProfileImage: UIImage?
    var oldHeaderImage: UIImage?
    
    // If profile or header image are changed then this is the data that represents that UIImage
    var newProfileImageData: Data?
    var newHeaderImageData: Data?
    
    // The data source for the table view when top tab 1 is selected
    var strips: [StripwayStrip] = []
    var stripPosts: [String: [StripwayPost]] = [:]
    // The data source for the table view when top tab 2 is selected
    var reposts = [StripwayPost]()
    var repostsUsers = [StripwayUser]()
    var repostTimestamps = [Int]()
    
    var newStripNames: [String: (String, StripwayStrip)] = [:]
    
    /// Used to tell the image picker which image to change
    var imagePicked: NewImageType = .other
    
    // The user whose profile is being viewed
    var profileOwner: StripwayUser!
//    var profileOwnerUID: String?
    
    // Will only exist if we're not on current user's profile
    var currentUser: StripwayUser?
    
    // Image chosen from image picker and passed to NewPostViewController
    var imageForNewPost: UIImage?
    
    // The post of the cell that is tapped to pass to ViewPostViewController
    var tappedPost: StripwayPost?
    var tappedPosts: [StripwayPost]?
    
    
    /// Guide view used for positioning header stuff, and superview to backButton
    @IBOutlet weak var userCardButton: UIButton!
    @IBOutlet weak var guideView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var topRightButton: UIButton!
    var menuIsVisible = false
    @IBOutlet weak var menuLeadingConstraint: NSLayoutConstraint!
    
    // All stuff for the tab bar right under the header, used for switching between strips and reposts
    @IBOutlet weak var topTabsBackgroundView: UIView!
    var currentTopTabSelected: Int = 0 {
        didSet {
            topTabChanged()
        }
    }
    
    @IBOutlet weak var reportedPostsButton: UIButton!
    
    // These are used in segues to pass info to the destination view controllers
    var tappedUser: StripwayUser?
    var tappedStrip: StripwayStrip?

    // Used to know if we should load more posts when scrolled to the bottom
    var isLoading = false
    
    // Refresh for top of reposts table, doesn't exist for strips
    let refreshControl = UIRefreshControl()
    
    var canRefresh = true
    
    var postToView: StripwayPost!
    
    var viewStripCollectionType: CollectionType = .strip
    
    var hashtagForSegue: String?
    
    var tappedUsernameForSegue: String?
    
    var resolvedUser: StripwayUser?
    
    var mentionedUsername: String? {
        didSet {
            mentionedUsername = mentionedUsername?.lowercased()
        }
    }
    
    var shouldShowPhotoOverlay: Bool?
    var shouldHideOverlays = false
    var shouldHidePhotoOverlays = false
    
    var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    lazy var tabUnderline: UIView = {
        let v = UIView(frame: CGRect.zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.black
        return v
    }()
    
    
    func topTabChanged() {
        tableView.reloadData()
        if currentTopTabSelected == 0 {
            if refreshControl.superview != nil {
                refreshControl.removeFromSuperview()
            }
        } else if currentTopTabSelected == 1 {
            tableView.isEditing = false
            refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
            tableView.addSubview(refreshControl)
        }
    }
    
    @IBOutlet var tableFooterView: UIView!
    
    override func viewDidLayoutSubviews() {
        followingView.roundCorners(corners: [.topRight], radius: 20.0)
        followersView.roundCorners(corners: [.topLeft], radius: 20.0)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        resolvedUser = appDelegate.passedUser
        
        if(resolvedUser != nil ) {
           
            profileOwner = resolvedUser
            
            appDelegate.passedUser = nil

        }
        
        

        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        
        }

        mArchiveLabel.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(goToArchive))

        mArchiveLabel.addGestureRecognizer(gestureRecognizer)
        
        
        
        (self.view as! ProfileView).subview = menuView
        menuViewWidthConstraint.constant = self.view.frame.width * (2/3)
        self.tableView.tableFooterView = nil
        
        if let mentionedUsername = mentionedUsername {
            API.User.getUser(withUsername: mentionedUsername) { (user) in
                if let user = user {
                    self.profileOwner = user
                    self.updateTopButtons()
                    self.updateProfileUI()
                    self.fetchStrips()
                    self.checkSuggestedUsers()
                    API.Follow.isFollowing(userID: user.uid) { (value) in
                        self.profileOwner.isFollowing = value
                        self.setUpButtonsForUser()
                    }
                } else {
                    let alert = UIAlertController(title: "User Doesn't Exist", message: "The user @\(mentionedUsername) doesn't seem to exist. Their username may have been typed incorrectly.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else if profileOwner == nil {
            print("profileOwner = nil so it's crashing, can just load current user stuff here")
//            API.User.observeCurrentUser { (user) in
//                self.profileOwner = user
//                self.updateTopButtons()
//                self.updateProfileUI()
//                self.fetchStrips()
//                self.setUpButtonsForUser()
//                self.bigButton.isEnabled = true
//            }
            API.User.observeCurrentUserConstantly { (user) in
                if self.profileOwner == nil {
                    self.profileOwner = user
                    self.updateTopButtons()
                    self.fetchStrips()
                    self.setUpButtonsForUser()
                    self.checkSuggestedUsers()
                }
                self.profileOwner = user
                self.updateProfileUI()
            }
        } else {
            API.Follow.isFollowing(userID: profileOwner.uid) { (value) in
                self.profileOwner.isFollowing = value
            }
            self.updateProfileUI()
            self.fetchStrips()
            self.checkSuggestedUsers()
            
            // Need to make sure message button can't be pressed until this is loaded
            API.User.observeCurrentUser { (currentUser) in
                self.currentUser = currentUser
                self.setUpButtonsForUser()
            }
        }
        checkAdmins()
        setUpUI()
        setupSegment()
    }
    func setupSegment() {
        
        let strips = SegmentioItem(title: "Strips", image: nil)
        let reposts = SegmentioItem(title: "Reposts", image: nil)
        
        let content = [strips, reposts]
        
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
                                      segmentPosition: .fixed(maxVisibleItems: 2),
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
            self.currentTopTabSelected = segmentIndex
        }
    }
    
    
    @IBAction func savedPostsButtonPressed(_ sender: Any) {
        print("Saved posts button pressed")
        self.viewStripCollectionType = .bookmarks
        performSegue(withIdentifier: "ViewStripSegue", sender: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.hideMenu()
        }
    }
    
    @IBAction func likedPostsButtonPressed(_ sender: Any) {
        print("Liked posts button pressed")
        self.viewStripCollectionType = .likes
        performSegue(withIdentifier: "ViewStripSegue", sender: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.hideMenu()
        }
    }
    
    @IBAction func blockedUsersButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "ShowBlockeesSegue", sender: self)
    }
    
    
    
    var currentUserIsAdmin = false
    func checkAdmins() {
        guard let currentUserUID = Constants.currentUser?.uid else { return }
        Database.database().reference().child("admin").child("adminUsers").observeSingleEvent(of: .value) { (snapshot) in
            for case let child as DataSnapshot in snapshot.children {
                if child.key == currentUserUID {
                    self.reportedPostsButton.isEnabled = true
                    self.reportedPostsButton.isHidden = false
                    self.currentUserIsAdmin = true
                }
            }
        }
    }
    
    var profileOwnerIsSuggested: Bool?
    func checkSuggestedUsers() {
        let profileOwnerUID = self.profileOwner.uid
        Database.database().reference().child("admin").child("suggestedUsers").observeSingleEvent(of: .value) { (snapshot) in
            // TODO: Use .exists() instead
            if snapshot.hasChild(profileOwnerUID) {
                self.profileOwnerIsSuggested = true
            } else {
                self.profileOwnerIsSuggested = false
            }
        }
    }

    @IBOutlet weak var floatingButton: UIButton!
    var shouldShowFooterView: Bool?
    func setUpButtonsForUser() {
        floatingButton.isHidden = false
        floatingButton.isEnabled = true
        floatingButton.backgroundColor = .clear
        if profileOwner.isCurrentUser {
//            self.tableView.tableFooterView = self.tableFooterView
//            if let shouldShowFooterView = shouldShowFooterView, !shouldShowFooterView {
//                self.tableView.tableFooterView = nil
//            } else {
//
//            }
            floatingButton.setBackgroundImage(UIImage(named: "FloatingEdit"), for: .normal)
        } else {
            if profileOwner.hasBlocked {
                floatingButton.isHidden = true
                self.descriptionTextView.alpha = 0
                self.linkTextView.alpha = 0
                let alert = UIAlertController(title: "Blocked", message: "You have been blocked by this user.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            } else if profileOwner.isBlocked {
                print("We have blocked this user")
                floatingButton.setBackgroundImage(UIImage(named: "FloatingBlocked"), for: .normal)
            } else if let isFollowingProfileOwner = profileOwner.isFollowing, isFollowingProfileOwner {
                print("We are following this user")
                floatingButton.setBackgroundImage(UIImage(named: "FloatingMessage"), for: .normal)
            } else {
                print("We are not following this user")
                floatingButton.setBackgroundImage(UIImage(named: "FloatingFollow"), for: .normal)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        if currentTopTabSelected == 1 {
//            loadReposts()
//        }
        
        // This will fix the follow button if you viewed a post, changed following status, and then went back to the profile
        if profileOwner != nil {
            setUpButtonsForUser()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        /*
        NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main) { notification in
              print("Screenshot taken!")
              self.ifUserScreenshot()
          }
 
 */
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        resolvedUser = appDelegate.passedUser
        
        print(resolvedUser)
        
        //For good luck
        if(resolvedUser != nil ) {
           
            profileOwner = resolvedUser

        }
        
        updateTopButtons()
        
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDoubleTapped))
              if let doubleTapGestureRecognizer = doubleTapGestureRecognizer {
                  doubleTapGestureRecognizer.numberOfTapsRequired = 2
                  self.view.addGestureRecognizer(doubleTapGestureRecognizer)
              }
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
    
    func updateTopButtons() {
        if profileOwner != nil {
            guard let customTabBarController = self.tabBarController as? CustomTabBarController else { return }
            print("Back Button Bug, viewController count = \(self.navigationController?.viewControllers.count) and selectedIndex = \(self.tabBarController?.selectedIndex)")
            // Back button should only not be shown if we're on the profile tab and the root view controller
            if customTabBarController.futureSelectedIndex == 4{
                print("Back Button Bug: We're at the root view of the profile tab, shouldn't be showing back button")
                
                if profileOwner.isCurrentUser{
                    self.backButton.isHidden = true
                }else{
                    self.backButton.isHidden = false
                }
                
                
                self.tabBarController?.tabBar.isHidden = false
            } else {
                print("Back Button Bug: We should be showing the back button")
                
//                if profileOwner.isCurrentUser {
//                     self.backButton.isHidden = true
//                    print("current user: \(profileOwner.email)")
//
//                }else{
                     self.backButton.isHidden = false
                   
                     self.tabBarController?.tabBar.isHidden = false
                    
//                }
                
               

            }
            if profileOwner.isCurrentUser {
                topRightButton.addTarget(self, action: #selector(self.menuButtonPressed), for: .touchUpInside)
                topRightButton.setImage(#imageLiteral(resourceName: "Settings"), for: .normal)
            } else {
                topRightButton.addTarget(self, action: #selector(self.ellipsisButtonPressed), for: .touchUpInside)
                topRightButton.setImage(#imageLiteral(resourceName: "White Ellipsis"), for: .normal)
            }
            if let showCard = profileOwner.showCard {
                userCardButton.isHidden = !showCard
            } else {
                userCardButton.isHidden = true
            }
            
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.translucentView.alpha = 0
        self.tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: Helper methods
    
    @objc func refresh() {
        self.reposts.removeAll()
        self.repostsUsers.removeAll()
        self.repostTimestamps.removeAll()
        loadReposts()
    }
    
    var timesOpened = 0
    func ifUserScreenshot(){
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            
            alertController.addAction(UIAlertAction(title: "Copy URL", style: .default, handler: { (action) in
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                           
                
                let url = UniversalLinkStruct.url
                let postURL = "\(url)/u=\(self.profileOwner.username)"
                
                let sharableLink = "\(url)/\(self.profileOwner.username)"
                
                
                
                Meta().setupMetaTags(url: postURL, title: "Stripway @\(self.profileOwner.username)", description: self.profileOwner.description, image: self.profileOwner.profileImageURL ?? "nodata", passed_url: sharableLink
                    , completion: {value in
                        //
                })
                
                
                ToastView.appearance().font = UIFont(name: "AvenirNext", size: 16.0)
                ToastView.appearance().bottomOffsetPortrait = 100.0
                Toast(text: "Link copied to cliboard!").show()
                
                let pasteboard = UIPasteboard.general
                pasteboard.string = sharableLink
                
                MBProgressHUD.hide(for: self.view, animated: true)

                
            }))
        
        alertController.addAction(UIAlertAction(title: "Cancle", style: .cancel, handler: nil))
        alertController.view.tintColor = UIColor.black
        
  
            
            if(self.profileOwner.isCurrentUser){
                self.present(alertController, animated: true, completion: nil)
            }
      
    }
    
    /// Basic UI setup like buttons and stuff
    func setUpUI() {
        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        let bottomBorder = UIView(frame: CGRect.zero)
        topTabsBackgroundView.addSubview(bottomBorder)
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.bottomAnchor.constraint(equalTo: topTabsBackgroundView.bottomAnchor).isActive = true
        bottomBorder.leadingAnchor.constraint(equalTo: topTabsBackgroundView.leadingAnchor).isActive = true
        bottomBorder.trailingAnchor.constraint(equalTo: topTabsBackgroundView.trailingAnchor).isActive = true
        bottomBorder.heightAnchor.constraint(equalToConstant: 0.3).isActive = true
        bottomBorder.backgroundColor = UIColor.lightGray
        
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        menuProfileImageView.layer.cornerRadius = menuProfileImageView.bounds.width / 2
        
        headerProfileImageView.layer.masksToBounds = true
        headerProfileImageView.layer.cornerRadius = headerProfileImageView.bounds.width / 2

        
        backButton.layer.cornerRadius = 15
        topRightButton.layer.cornerRadius = 15
        userCardButton.layer.cornerRadius = 15
        
        self.floatingButton.layer.shadowColor = UIColor.black.cgColor
        self.floatingButton.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.floatingButton.layer.masksToBounds = false
        self.floatingButton.layer.shadowRadius = 1.0
        self.floatingButton.layer.shadowOpacity = 0.5
        
        updateHeaderBlur()
    
        //Add gesture recognizer for side settings menu
        let gestureRec = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognized(_:)))
        gestureRec.delegate = self
        self.menuView.addGestureRecognizer(gestureRec)
        self.view.layoutIfNeeded()
        
        //Delete resolved  user from memory
        resolvedUser = nil
        
    }
    
    var removedStripIDs = [String]()
    /*
    func saveUserDefault(postID: String, postIndex: Int){
        let preferences = UserDefaults.standard
        
        
        preferences.setInteger(postIndex, forKey: postID)

        //  Save to disk
        let didSave = preferences.synchronize()

        if !didSave {
            //  Couldn't save (I've never seen this happen in real world testing)
        }
    }*/
    
    @objc func goToArchive(){
         
         performSegue(withIdentifier: "archivedSegue",sender: self)
     }
    
    // TODO: Really need to double check that we're not uneccessarily redownloading data here
      func fetchStrips() {
          
          
          if profileOwner.isBlocked || profileOwner.hasBlocked {
              return
          }
          print("BUG: fetchStrips()")
          
          API.Strip.fetchStripIDsConstantly(forUserID: profileOwner.uid) { (keys) in

              if keys == nil {

                  if self.profileOwner.uid != Auth.auth().currentUser?.uid {
                      //if it's other's profile -- no show guide view
                      self.tableView.tableFooterView = nil
                  }
                  else {
                      //User does not have any strips created -- show guide view
                      self.tableView.tableFooterView = self.tableFooterView
                  }
              }
              else {
                  //User has strip we load them, hide guide view
                  self.strips.removeAll()
                  
                  
                  
                  //Get posts in strips
                  for key in keys! {
                      API.Strip.observeStrip(withID: key, completion: { (strip) in
                          if self.removedStripIDs.contains(key) {
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
                                  self.shouldShowFooterView = false
                                  self.tableView.tableFooterView = nil
                                  print("Strip Bug: Just observed post: \(post)")
                                  self.postsForStrip = self.stripPosts[strip.stripID] ?? []
                                  self.postsForStrip.append(post)
                                
                                  var postsForStrip1 = self.stripPosts[strip.stripID] ?? []
                                  postsForStrip1.append(post)
                                  self.stripPosts[strip.stripID] = postsForStrip1

                                  self.tableView.reloadData()
                              }
                          })
                          
                          API.Strip.observePostsForStrip(atDatabaseReference: strip.archivedReference!, completion: { (post, error, shouldClear) in
                                      if let shouldClear = shouldClear, shouldClear {
                                          self.archivedStripPost[strip.stripID] = []
                                          return
                                      }
                                      if let error = error {
                                          print(error.localizedDescription)
                                      } else if let post = post {
                                     
                                          var archivePostsForStrip = self.archivedStripPost[strip.stripID] ?? []
                                          archivePostsForStrip.append(post)
                                      
                                          
                                          self.archivedStripPost[strip.stripID] = archivePostsForStrip
                                
                                          print("check this----------------------------------------")
                                          print("Archive: \(archivePostsForStrip) and posts \(self.postsForStrip)")
                                          
                                          var numberInArray = -1
                                          
                                          
                                          
                                          for p in self.postsForStrip {
                                              print("All regular posts: \(p.postID)" )
                                              numberInArray += 1
                                              for a in archivePostsForStrip{
                                                  
                                                  print("All archives posts: \(a.postID) " )
                                                  if(p.postID == a.postID){
                                                      
                                                      if(numberInArray  <= self.postsForStrip.count){
                                                          
                                                          print("number: \(numberInArray) count ... \(self.postsForStrip.count)")
                                                          self.postsForStrip.remove(at: numberInArray)
                                                          
                                                          self.stripPosts[p.stripID] = self.postsForStrip
                                                          
                                                      }
                                                    
                                                      
                                                      
                                                      print("true, there is one which the same")
                                                  
                                              }
                                              
                                            }
                                          }
                                      }
                                  })
                          
                          
                          //If you ever want to make this archive more then one thing at the time change observer to observerSingleEvent
    
                          
                          
                          if self.profileOwner.isCurrentUser {
                              // This is pretty hacky but it works pretty well
                              API.Strip.observeNameAndIndexForStripID(stripID: key, completion: { (stripName, stripIndex) in
                                  if let stripName = stripName {
                                      let changedStrip = self.strips.first(where: { $0.stripID == key })
                                      changedStrip?.name = stripName
                                      self.tableView.reloadData()
                                      print("CHANGED STRIPNAME TO \(stripName)")
                                  }
                                  if let stripIndex = stripIndex {
                                      let changedStrip = self.strips.first(where: { $0.stripID == key })
                                      changedStrip?.index = stripIndex
                                      self.tableView.reloadData()
                                      print("CHANGED STRIPINDEX TO \(stripIndex)")
                                  }
                                  if stripName == nil && stripIndex == nil {
                                      print("CHANGED NOTHING IMPORTANT")
                                  }
                              })
                          }
                      })
                  }
              }
          }
          
                        
        
//this was old code for each observing when add
        
//        API.Strip.fetchStripIDs(forUserID: profileOwner.uid) { (key) in
//            API.Strip.observeStrip(withID: key, completion: { (strip) in
//                if self.removedStripIDs.contains(key) {
//                    return
//                }
//                self.strips.append(strip)
//                API.Strip.observePostsForStrip(atDatabaseReference: strip.postsReference!, completion: { (post, error, shouldClear) in
//                    if let shouldClear = shouldClear, shouldClear {
//                        self.stripPosts[strip.stripID] = []
//                        return
//                    }
//                    if let error = error {
//                        print(error.localizedDescription)
//                    } else if let post = post {
//                        self.shouldShowFooterView = false
//                        self.tableView.tableFooterView = nil
//                        print("Strip Bug: Just observed post: \(post)")
//                        var postsForStrip = self.stripPosts[strip.stripID] ?? []
//                        postsForStrip.append(post)
//                        self.stripPosts[strip.stripID] = postsForStrip
//                        self.tableView.reloadData()
//                    }
//                })
//                if self.profileOwner.isCurrentUser {
//                    // This is pretty hacky but it works pretty well
//                    API.Strip.observeNameAndIndexForStripID(stripID: key, completion: { (stripName, stripIndex) in
//                        if let stripName = stripName {
//                            let changedStrip = self.strips.first(where: { $0.stripID == key })
//                            changedStrip?.name = stripName
//                            self.tableView.reloadData()
//                            print("CHANGED STRIPNAME TO \(stripName)")
//                        }
//                        if let stripIndex = stripIndex {
//                            let changedStrip = self.strips.first(where: { $0.stripID == key })
//                            changedStrip?.index = stripIndex
//                            self.tableView.reloadData()
//                            print("CHANGED STRIPINDEX TO \(stripIndex)")
//                        }
//                        if stripName == nil && stripIndex == nil {
//                            print("CHANGED NOTHING IMPORTANT")
//                        }
//                    })
//                }
//            })
//        }

        API.Strip.observeStripIDsRemoved(forUserID: profileOwner.uid) { (key) in
            self.strips = self.strips.filter{ $0.stripID != key }
            self.removedStripIDs.append(key)
            self.tableView.reloadData()
        }
    }
    
    func updateHeaderBlur() {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = headerImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerBlurImageView.addSubview(blurEffectView)
        
    }
    
    func loadReposts() {
        //        API.Reposts.observeReposts(forUserID: profileOwner.uid) { (post) in
        //            self.fetchUser(uid: post.authorUID, completed: {
        //                self.reposts.insert(post, at: 0)
        //                self.tableView.reloadData()
        //            })
        //        }
        if profileOwner.isBlocked || profileOwner.hasBlocked {
            return
        }
        isLoading = true
        
        API.Reposts.getRepostsFeed(withID: profileOwner.uid) { (results) in
            self.isLoading = false
            if results.count > 0 {
                results.forEach({ (result) in
                    print("loading repost: \(result.2)")
                    self.reposts.append(result.0)
                    self.repostsUsers.append(result.1)
                    self.repostTimestamps.append(result.2)
                })
            }
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.tableFooterView = nil
            self.tableView.reloadData()
        }
        
//        API.Reposts.getRecentRepostsFeed(withID: profileOwner.uid, start: repostTimestamps.first, limit: 5) { (results) in
//            self.isLoading = false
//            if results.count > 0 {
//                results.forEach({ (result) in
//                    print("loading repost: \(result.2)")
//                    self.reposts.append(result.0)
//                    self.repostsUsers.append(result.1)
//                    self.repostTimestamps.append(result.2)
//                })
//            }
//            if self.refreshControl.isRefreshing {
//                self.refreshControl.endRefreshing()
//            }
//            self.tableView.reloadData()
//        }
        
    }
    
    func loadMore() {
        if profileOwner.isBlocked || profileOwner.hasBlocked {
            return
        }
        print("loading more reposts")
        guard !isLoading else {
            return
        }
        isLoading = true
        guard let lastPostTimestamp = self.repostTimestamps.last else {
            isLoading = false
            return
        }
        API.Reposts.getOldRepostsFeed(withID: profileOwner.uid, start: lastPostTimestamp, limit: 5) { (results) in
            if results.count == 0 {
                return
            }
            for result in results {
                self.reposts.append(result.0)
                self.repostsUsers.append(result.1)
                self.repostTimestamps.append(result.2)
            }
            self.tableView.reloadData()
            self.isLoading = false
        }
    }
    
    
    /// Updates profile's UI once the user is loaded from the database
    func updateProfileUI() {
        
        linkTextView.textContainer.maximumNumberOfLines = 1
        
//        if profileOwner.isCurrentUser {
//            setUpCurrentUserButtons()
//        } else {
//            setUpAnotherUsersButtons()
//        }
        
        
        nameLabel.text = profileOwner.name
        menuNameLabel.text = profileOwner.name
        usernameLabel.text = "@" + profileOwner.username
        headerUsernameLabel.text = "" + profileOwner.username
        menuUsernameLabel.text = "@" + profileOwner.username
//        if let description = profileOwner.description {
            descriptionTextView.text = profileOwner.description
//            adjustHeaderHeight()
//        }
//        if let bioLink = profileOwner.bioLink, !bioLink.isEmpty {
            linkTextView.text = profileOwner.bioLink
//            adjustHeaderHeight()
//        }
        if let profileImageURL = profileOwner.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            profileImageView.showLoading()
            profileImageView.sd_setImage(with: profileURL) { (image, error, type, url) in
                self.profileImageView.hideLoading()
            }
            headerProfileImageView.sd_setImage(with: profileURL)
            menuProfileImageView.sd_setImage(with: profileURL)
        }
        if let headerImageURL = profileOwner.headerImageURL {
            let headerURL = URL(string: headerImageURL)
            headerImageView.sd_setImage(with: headerURL)
            headerBlurImageView.sd_setImage(with: headerURL)
        }
        
        API.Follow.fetchFollowerCount(userID: profileOwner.uid) { (followerCount) in
            self.followersLabel.text = String(followerCount)
        }
        
        API.Follow.fetchFollowingCount(userID: profileOwner.uid) { (followingCount) in
            self.followingLabel.text = String(followingCount)
        }
        
        if profileOwner.isVerified {
            verifiedImageView.isHidden = false
        }
        adjustHeaderHeight()
    }

    
    // MARK: Every method for a button press
    
    /// Selected the first top tab, viewing profile owner's strips and posts
//    @IBAction func topTabOnePressed(_ sender: Any) {
//        currentTopTabSelected = 0
//        topTabOneButton.setTitleColor(UIColor.darkText, for: .normal)
//        topTabTwoButton.setTitleColor(UIColor.darkGray, for: .normal)
//    }
//
//    /// Selected the second top tab, viewing the profile owner's reposts
//    @IBAction func topTabTwoPressed(_ sender: Any) {
//        currentTopTabSelected = 1
//        topTabTwoButton.setTitleColor(UIColor.darkText, for: .normal)
//        topTabOneButton.setTitleColor(UIColor.darkGray, for: .normal)
//        loadReposts()
//    }
    
   
    @IBAction func userCardButtonPressed(_ sender: Any) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        API.UserCard.getCard(userID: profileOwner.uid) { (card) in
            hud.hide(animated: true)
            if let card = card {
                let cardView = UserCardView()
                cardView.card = card
                cardView.showIn(self.tabBarController!.view)
            }
                
        }
    }
    
    /// Back button pressed
    @IBAction func backButtonPressed(_ sender: Any) {
        
        // Pops view if it's in a navigation controller, otherwise just dismisses it
        // I don't think the dismiss one actually happens anymore so that can be removed
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var translucentView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuViewWidthConstraint: NSLayoutConstraint!
    
    @IBAction func tapGestureTapped(_ sender: Any) {
        print("Tap gesture tapped")
        if menuIsVisible {
            hideMenu()
        }
    }
    
    @objc func menuButtonPressed() {
        print("Menu button pressed")
        if menuIsVisible {
            hideMenu()
        } else {
            showMenu()
        }
    }
    
    @objc func ellipsisButtonPressed() {
        print("Ellipsis button pressed")
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
        
        if let isFollowing = profileOwner.isFollowing, isFollowing {
            alertController.addAction(UIAlertAction(title: "Unfollow User", style: .default, handler: { (action) in
                self.unFollowAction()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Copy URL", style: .default, handler: { (action) in
            
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            
            let url = UniversalLinkStruct.url
            let postURL = "\(url)/u=\(self.profileOwner.username)"
            
            let sharableLink = "\(url)/\(self.profileOwner.username)"
            
            Meta().setupMetaTags(url: postURL, title: "Stripway @\(self.profileOwner.username)", description: self.profileOwner.description, image: self.profileOwner.profileImageURL ?? "nodata", passed_url: sharableLink
                , completion: {value in
                    //
            })

            
            ToastView.appearance().font = UIFont(name: "AvenirNext", size: 16.0)
            ToastView.appearance().bottomOffsetPortrait = 100.0
            Toast(text: "Link copied to cliboard!").show()
            
            let pasteboard = UIPasteboard.general
            pasteboard.string = sharableLink

            MBProgressHUD.hide(for: self.view, animated: true)

            
          }))
        
        alertController.addAction(UIAlertAction(title: "Block User", style: .default, handler: { (action) in
            print("Should be blocking this user")
            API.Block.blockUser(withUID: self.profileOwner.uid)
            self.profileOwner.isBlocked = true
            self.setUpButtonsForUser()
        }))
        

        
        if let profileOwnerIsSuggested = self.profileOwnerIsSuggested, currentUserIsAdmin {
            if profileOwnerIsSuggested {
                alertController.addAction(UIAlertAction(title: "Remove from Suggested Users", style: .default, handler: { (action) in
                    API.User.removeFromSuggestedUsers(uid: self.profileOwner.uid, completion: {
                        self.profileOwnerIsSuggested = false
                    })
                }))
            } else {
                alertController.addAction(UIAlertAction(title: "Add to Suggested Users", style: .default, handler: { (action) in
                    API.User.addToSuggestedUsers(uid: self.profileOwner.uid, completion: {
                        self.profileOwnerIsSuggested = true
                    })
                }))
            }
            
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.tintColor = UIColor.black
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func panGestureRecognized(_ recognizer: UIPanGestureRecognizer) {

        if menuIsVisible {
            hideMenu()
        }
    }
    
    
    func showMenu() {
        let menuDistance = self.view.frame.width
        menuView.layer.zPosition = 10
        translucentView.isUserInteractionEnabled = true
        menuIsVisible = true
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.frame.origin.x = -(menuDistance * (2/3))
            self.translucentView.alpha = 0.3
        }, completion: nil)
    }
    
    func hideMenu() {
        translucentView.isUserInteractionEnabled = false
        menuIsVisible = false
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.frame.origin.x = 0
            self.translucentView.alpha = 0
        }, completion: nil)
    }
    
    
    /// Segue's to view that shows the users following profile owner
    @IBAction func followersButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "FollowersSegue", sender: self)
    }
    
    /// Segues to view that shows the users profile owner is following
    @IBAction func followingsButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "FollowingsSegue", sender: self)
    }
    
    func presentPeopleSelectionController(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "SharePostVC") as! SharePostVC
        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
    }
    
    /// Big button on profile is pressed, it will have different functions based on current user's relationship
    /// to the profile owner
    @IBAction func floatingButtonPressed(_ sender: UIButton) {
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        UIButton.animate(withDuration: 0.2,
             animations: {
                sender.transform = CGAffineTransform(scaleX: 0.975, y: 0.96)
        },
             completion: { finish in
                UIButton.animate(withDuration: 0.2, animations: {
                    sender.transform = CGAffineTransform.identity
                })
        })
        
        if profileOwner.isCurrentUser {
            print("Edit button pressed")
            performSegue(withIdentifier: "EditProfileSegue", sender: self)
        } else if profileOwner.isBlocked {
            let alert = UIAlertController(title: "Unblock User?", message: "Are you sure you want to unblock this user?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Unblock", style: .default, handler: { (action) in
                API.Block.unblockUser(withUID: self.profileOwner.uid)
                self.profileOwner.isBlocked = false
                self.setUpButtonsForUser()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            if profileOwner.isFollowing! {
                performSegue(withIdentifier: "ShowConversationFromProfile", sender: self)
            } else {
                followAction()
            }
        }
    }
    
    func followAction() {
        if profileOwner.isFollowing == false {
            API.Follow.followAction(withUser: profileOwner.uid)
            profileOwner.isFollowing = true
            setUpButtonsForUser()
        }
    }
    
    func unFollowAction() {
        if profileOwner.isFollowing == true {
            API.Follow.unfollowAction(withUser: profileOwner.uid)
            profileOwner.isFollowing = false
            setUpButtonsForUser()
        }
    }
    
    // MARK: Important segue stuff
    // Makes sure that destination view controllers get all the info that they need
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // NewPostViewController needs the actual image that the new post will contain, as well as the author
        if segue.identifier == "NewPostSegue" {
            if let newPostViewController = segue.destination as? NewPostViewController {
                if let image = imageForNewPost {
                    newPostViewController.imageToPost = image
                    newPostViewController.postAuthor = profileOwner
                } else {
                    print("Something went wrong with the image for the new post, should probably cancel this segue.")
                }
            }
        }
        if segue.identifier == "showFromPost" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.senderUser = self.currentUser!
                viewConversationViewController.receiverUser = self.tappedUser
            }
        }
        
        // ViewPostViewController needs the post and user who created that post (which is the author because this segue
        // will only happen for posts by the profile owner)
        if segue.identifier == "ShowPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = self.tappedPost
                viewPostViewController.posts = self.tappedPosts!
                viewPostViewController.user = self.profileOwner
                viewPostViewController.refreshDelegate  = self

            }
        }
        
        if segue.identifier == "archivedSegue" {
             if let viewPostViewController = segue.destination as? ArchiveViewController {
                 
                 viewPostViewController.refreshDelegate  = self
             }
         }
        
        
        // This is the segue to view profile owner's followers, needs the type of list and person whose followers we're viewing
        if segue.identifier == "FollowersSegue" {
            if let peopleViewController = segue.destination as? PeopleViewController {
                peopleViewController.listType = .followers
                peopleViewController.profileOwner = self.profileOwner
            }
        }
        // Same as above but for followings
        if segue.identifier == "FollowingsSegue" {
            if let peopleViewController = segue.destination as? PeopleViewController {
                peopleViewController.listType = .following
                peopleViewController.profileOwner = self.profileOwner
            }
        }
        
        // This is for any segue to another user's profile from this profile, which will occur from either a repost,
        // comment, or when viewing likes and reposts on a repost
        if segue.identifier == "ShowUserProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                if let tappedUser = self.tappedUser {
                    profileViewController.profileOwner = tappedUser
                } else if let tappedUsernameForSegue = tappedUsernameForSegue {
                    profileViewController.mentionedUsername = tappedUsernameForSegue
                }
            }
        }
        
        // This is for viewing a strip full page, just need the strip and its owner (which can only be the profileOwner for
        // now but that might need to be changed for reposts later)
        if segue.identifier == "ViewStripSegue" {
            if let viewStripViewController = segue.destination as? PostCollectionWithHeaderViewController {
                if let strip = tappedStrip {
                    viewStripViewController.strip = strip
                }
                viewStripViewController.collectionAuthor = profileOwner
                viewStripViewController.collectionType = self.viewStripCollectionType
            }
        }
        
        if segue.identifier == "ShowConversationFromProfile" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.senderUser = self.currentUser!
                viewConversationViewController.receiverUser = self.profileOwner
            }
        }
        
        if segue.identifier == "EditPostSegue" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = postToView
                viewPostViewController.user = repostsUsers.first(where: { $0.uid == postToView.authorUID })
                viewPostViewController.isAlreadyEditing = true
                viewPostViewController.delegate = self
            }
        }
        
        if segue.identifier == "SegueToHashtag" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.hashtag = self.hashtagForSegue!
            }
        }
        
        if segue.identifier == "SegueToReports" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.reports = true
            }
        }
        
        if segue.identifier == "SettingsSegue" {
            if let settingsViewController = segue.destination as? SettingsViewController {
                // TODO: Double check that profileOwner is currentUser
                settingsViewController.currentStripwayUser = self.profileOwner!
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.hideMenu()
            }
        }
        
        if segue.identifier == "ShowBlockeesSegue" {
            if let peopleViewController = segue.destination as? PeopleViewController {
                peopleViewController.profileOwner = profileOwner
                peopleViewController.listType = .blockees
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.hideMenu()
            }
        }
        if segue.identifier == "EditProfileSegue" {
            if let editProfileViewController = segue.destination as? EditProfileViewController {
                editProfileViewController.profileOwner = profileOwner
                editProfileViewController.userInfo = ["name": profileOwner.name, "username": profileOwner.username, "link": profileOwner.bioLink, "bio": profileOwner.description]
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
    
    @IBOutlet weak var linkFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var linkImageView: UIImageView!
    var captionTextViewBottomSpace: CGFloat = 60
    
    // Need to do something about the constraints on the link image as they're broken,
    // but it looks fine for now
    func showLinkTextField() {
        linkFieldHeightConstraint.constant = 30
        captionTextViewBottomSpace = 60
        linkImageView.isHidden = false
    }
    
    func hideLinkTextField() {
        linkFieldHeightConstraint.constant = 0
        captionTextViewBottomSpace = 40
        linkImageView.isHidden = true
    }
    
//    func adjustHeaderHeight() {
////        if let header = tableView.tableHeaderView {
////            header.frame.size.height = linkTextView.frame.maxY + distanceFromBottomOfLinkFieldToBottomOfHeader
////            self.tableView.tableHeaderView = header
////            self.view.layoutIfNeeded()
////        }
//    }
    
    func adjustHeaderHeight() {
        print("HEADERBUG: running adjustHeaderHeight()")
        if let header = tableView.tableHeaderView {
            print("HEADERBUG: header exists")
            print("HEADERBUG: isn't editing profile")
            if linkTextView.text.isEmpty {
                print("HEADERBUG: Hiding link")
                hideLinkTextField()
            } else {
                print("HEADERBUG: Showing link")
                showLinkTextField()
            }
            self.view.layoutIfNeeded()
            print("HEADERBUG: linkTextView.frame.maxY: \(linkTextView.frame.maxY)")
            header.frame.size.height = descriptionTextView.frame.maxY + captionTextViewBottomSpace + 10
            self.tableView.tableHeaderView = header
            self.view.layoutIfNeeded()
        }
    }
    
}

extension ProfileViewController:SharePostVCDelegate {
    
}

// Updates the caption if you edit one of your posts in someone's reposts
extension ProfileViewController: ViewPostViewControllerDelegate {
    func updateCaptionForPost(post: StripwayPost) {
        guard let oldPostIndex = reposts.firstIndex(where: { $0.postID == post.postID }) else { return }
        let oldPost = reposts[oldPostIndex]
        oldPost.caption = post.caption
        tableView.reloadRows(at: [IndexPath(row: oldPostIndex, section: 0)], with: .none)
    }
    
    func showNoDataFound (counter: Int) -> UILabel{
        let label = UILabel(frame: CGRect(x:0, y: 95, width: tableView.bounds.width, height: 30))
        print("conter: \(counter)")
        if(counter == 0){
            
            print("hello")
            label.text  = "\(profileOwner.username) has archived all posts for this strip"
            label.textColor = .gray
            label.backgroundColor = .white
            label.textAlignment = .center
            label.font = UIFont(name: "Avenir Next", size:14)
            label.font = UIFont.boldSystemFont(ofSize: 14)
            
            return label

        }
        
        return label
    }
}



// MARK: All the important tableview stuff
extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    
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
        updateIndices()
    }
    
    // Helper method for moving strips, just updates their Firebase index to match their index in strips array
    func updateIndices() {
        for (index, strip) in strips.enumerated() {
            API.Strip.setIndex(index: index + 1, forStrip: strip)
        }
    }
    
    // currently doesn't work because this is called for each cell that is loading
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentTopTabSelected == 0 {
            strips = strips.sorted(by: { $0.index < $1.index })
            let cell = tableView.dequeueReusableCell(withIdentifier: "StripTableViewCell") as! StripTableViewCell
            
            //to resolve crash when remove
            if strips.count <= indexPath.row {
                return cell
            }
            
//            cell.showThumb = true
            let strip = strips[indexPath.row]
            let posts = stripPosts[strip.stripID]
            cell.strip = strip
            cell.posts = posts
            cell.delegate = self
            cell.index = indexPath.row
            cell.arrowImg.isHidden = true
            
            let label = showNoDataFound(counter: posts?.count ?? 0)
            cell.contentView.addSubview(label)
            

            cell.noDataLabel = label
            
            return cell
        } else {
            // This fixes a crash
            if reposts.count == 0 {
                return UITableViewCell()
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
            cell.showThumb = false
            let post = reposts[indexPath.row]
            let user = repostsUsers[indexPath.row]
            print("Loading repost cell with repost timestamp: \(repostTimestamps[indexPath.row])")
            cell.post = post
            cell.user = user
            cell.delegate = self
            cell.truncateCaption()
            
            let settings = Settings.instaZoomSettings
                .with(maximumZoomScale: 1)
                .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
            
               
               addZoombehavior(for: cell.postImageView, settings: settings)
               
               cell.delegate = self
            
            cell.homeVCDoubleTapGesture = self.doubleTapGestureRecognizer
            
            cell.shouldHideOverlay = shouldHidePhotoOverlays
            
            // Peek/pop could have happened before current cell is set, so we make sure hide/show overlay is up to date
            if let shouldShowPhotoOverlay = shouldShowPhotoOverlay {
                if shouldShowPhotoOverlay {
                    cell.showPhotoOverlay()
                } else {
                    cell.hidePhotoOverlay()
                }
            }
            
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if reposts.count == 0 {
            return UITableView.automaticDimension
        }
        if currentTopTabSelected == 1 {
            var ratio = reposts[indexPath.row].imageAspectRatio
            if ratio == 0 {ratio = 3/4}
            let height = self.tableView.frame.width / ratio
            
            //to remove white line between 3/4 rows, convert height to int
            return CGFloat(Int(height))
        }  else {
            return UITableView.automaticDimension
        }
    }
    
    // TableView data source changes depending on which top tab we're currently on, so we return the correct count
    // according to which data source is currently being used
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentTopTabSelected == 0 {
            print("BUG: Returning strips.count: \(strips.count)")
            
            return strips.count
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if(self.reposts.count == 0 ){
                    tableView.setEmptyView(title: "No reposts", message: "\(self.profileOwner.username) likes the void", bottomPosition: 150)
                }else{
                    tableView.restore()
                }
            }
            return reposts.count
        }
    }
    
    // MARK: Header animation stuff happens here
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // If you are within two screen lengths of the bottom of the scrollView's content, it triggers the loading of more posts
        if self.isLoading == false {
            if scrollView.contentOffset.y + 2*self.view.frame.height >= scrollView.contentSize.height {
                if currentTopTabSelected == 1 {
                    print("offset ", scrollView.contentOffset.y, " frame ", self.view.frame.height, " content ", scrollView.contentSize.height)
//                    loadMore()
                }
            }
        }

        // This is all the stuff for the resizing header view, it's pretty messy and sorta complicated so if you have any huge issues
        // email me at andrewdennistoun@gmail.com or look at the tutorial I based it off of:
        // www.thinkandbuild.it/implementing-the-twitter-ios-app-ui/
        let offset = scrollView.contentOffset.y
        var avatarTransform = CATransform3DIdentity
        var headerTransform = CATransform3DIdentity

        // I had to do this weird calculation to compensate for different safe area heights on notched and notchless screens
        // but basically one the bottom of the header hits the bottom of guideView it should stop moving upwards
        let headerImageViewMaxY = headerImageButton.frame.maxY
        let guideViewMaxY = guideView.frame.maxY
        let offset_HeaderStop = headerImageViewMaxY - guideViewMaxY
        print("offerset ", offset, " offset Header stop", offset_HeaderStop)

        if offset < 0 {
            // If the scroll view has been scrolled up past the top of the view, then enlarge the header image
            let headerScaleFactor:CGFloat = -(offset) / resizingHeaderSuperview.bounds.height
            let headerSizevariation = ((resizingHeaderSuperview.bounds.height * (1.0 + headerScaleFactor)) - resizingHeaderSuperview.bounds.height)/2.0
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
        } else {
            // Otherwise, translate the header image upwards until it reaches the stop height, offset_HeaderStop (aka the
            // bottom of guideView)
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offset_HeaderStop, -offset), 0)
            let avatarScaleFactor = (min(offset_HeaderStop, offset)) / profileImageView.bounds.height / 1.4 // Slow down the animation
            let avatarSizeVariation = ((profileImageView.bounds.height * (1.0 + avatarScaleFactor)) - profileImageView.bounds.height) / 2.0
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
        }

        // Once the header image has moved up as much as possible, we then move the profile image under it
        if offset <= offset_HeaderStop {
            resizingHeaderSuperview.layer.zPosition = 0
        } else {
            resizingHeaderSuperview.layer.zPosition = 2
            // Guide view has the back button in it so we should always keep that at the top
            guideView.layer.zPosition = 3
        }

        // Not quite sure what the math is for this but it works
        let newLabelNumber = offset - offset_HeaderStop

        // 58 is the default distance (aka before scrolling) from the top of the nameLabel to the bottom of the header
        let labelNumber = newLabelNumber - 58
        var labelTransform = CATransform3DIdentity

        // 44 is how much into the header we want the label to go
        if labelNumber >= 0 && labelNumber <= 44 {
            labelTransform = CATransform3DTranslate(labelTransform, 0, -labelNumber, 0)
        }
        if labelNumber < 0  {
            labelTransform = CATransform3DTranslate(labelTransform, 0, 0, 0)
        } else if labelNumber > 44 {
            labelTransform = CATransform3DTranslate(labelTransform, 0, -44, 0)
        }

        // This just basically sets the blur depending on how far into the header the label is (40 * 2.5 = 100% aka fully opaque)
        headerBlurImageView.alpha = (labelNumber)/100 * 2.5

        // Finally apply all the transformations that we made
        resizingHeaderSuperview.layer.transform = headerTransform
        profileImageView.layer.transform = avatarTransform
        headerProfileInfoSuperview.layer.transform = labelTransform

        // This is just stuff to shorten the pull to refresh length
        if currentTopTabSelected == 1 && refreshControl.superview != nil {
            if scrollView.contentOffset.y <= (-70-88) {
                if canRefresh && !self.refreshControl.isRefreshing {
                    self.canRefresh = false
                    self.refreshControl.beginRefreshing()
                    let impact = UIImpactFeedbackGenerator()
                    impact.impactOccurred()
                    self.refresh()
                }
            } else if scrollView.contentOffset.y >= 0 {
                self.canRefresh = true
            }
        }
        
    }
    
}

// MARK: Stuff for picking/cropping a new image for a new post or header or profile image
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, FMImageEditorViewControllerDelegate {
    
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
            self.presentCropViewController(withImage: image)
        }
    }
    
    // Once the cropViewController has finished cropping and user has pressed the done button, this delegate method runs
    // It has the cropped image as well as info about the crop in case you want to save the original
    func fmImageEditorViewController(_ editor: FMImageEditorViewController, didFinishEdittingPhotoWith photo: UIImage) {
        dismiss(animated: true, completion: nil)
        let image = photo
        // Depending on which image the user picked to change, we then either set the image (for profile or header)
        // or we pass the image to the NewPostViewController
        switch imagePicked {
        case .profileImage:
            profileImageView.image = image
            newProfileImageData = image.jpegData(compressionQuality: 0.1)
        case .headerImage:
            headerImageView.image = image
            headerBlurImageView.image = image
            newHeaderImageData = image.jpegData(compressionQuality: 0.1)
        case .newPostImage:
            imageForNewPost = image
            performSegue(withIdentifier: "NewPostSegue", sender: self)
        default:
            print("maybe future image types")
            return
        }
        imagePicked = .other
    }
    
    // This helper method determines what kind of cropping we're going to be doing
    func presentCropViewController(withImage image: UIImage) {
       
        var config = FMPhotoPickerConfig()
        config.selectMode = .single
        config.maxImage = 1
        config.mediaTypes = [.image]        
        config.useCropFirst = true
        // Depends on which image user is changing
        switch imagePicked {
        case .profileImage:
            // If it's the profile image, then it must be a circle
            config.availableCrops = [FMCrop.ratioSquare]
            config.eclipsePreviewEnabled = true
            config.forceCropEnabled = true
        case .headerImage:
            // If it's the header image, then it must have a 3:1 width:height ratio
            config.availableCrops = [StripCrop.ratio3x1]
            config.forceCropEnabled = true
        case .newPostImage:
            // If it's a new post, it must have a 3:4 width:height ratio (like default iOS ratio)
            config.availableCrops = [StripCrop.ratio3x4]
            config.forceCropEnabled = true
        default:
            // probably shouldn't happen
            print("maybe future image types")
            return
        }
        let picker = FMImageEditorViewController(config: config, sourceImage: image)
        picker.delegate = self
        self.present(picker, animated: true)
        
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

// MARK: Text view stuff (for resizing when you're editing your bio)
extension ProfileViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        adjustHeaderHeight()
    }
}

// MARK: Strip cells stuff
extension ProfileViewController: StripCellDelegate {
    func accessoryPressedForPost(post: StripwayPost, forTrendtag trendtag: Trendtag) {
        
    }
    
    func loadMore(index: Int) {        
    }
    
    func goToTrendtagVC(trendtag: Trendtag) {
    }
    
    func didEditStripName(newName: String, forStrip strip: StripwayStrip) {
        newStripNames[strip.stripID] = (newName, strip)
    }
    
    func goToStripVC(strip: StripwayStrip) {
        tappedStrip = strip
        viewStripCollectionType = .strip
        performSegue(withIdentifier: "ViewStripSegue", sender: self)
    }
    
//    func goToPostVC(post: StripwayPost) {
    func goToPostVC(post: StripwayPost, posts: [StripwayPost]) {
        self.tappedPost = post
        self.tappedPosts = posts
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
    
    func deleteStrip(strip: StripwayStrip, atIndex: Int) {
        print("Deleting strip: \(strip.name)")
        
        let alert = UIAlertController(title: "Delete Strip?", message: "Are you sure you want to delete this strip and all of its posts? This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            print("Actually deleting strip")
            API.Strip.deleteStrip(strip: strip)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func deletePost(post: StripwayPost, fromStrip strip: StripwayStrip) {
        print("DELETING POST WITH ID: \(post.postID)")
        let alert = UIAlertController(title: "Delete Post?", message: "Are you sure you want to delete this post? This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (_) in
            print("Actually deleting post")
            API.Post.deletePost(post: post)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
        
        
    }
    
 
}

extension ProfileViewController: ProcessArchiveDelegate{
    func updateProcessStatus(isCompleted: Bool, post: StripwayPost, index: Int?) {
         if(isCompleted){
            
            self.stripPosts[post.stripID] = self.stripPosts[post.stripID]!.filter{ $0.postID != post.postID }

           self.tableView.reloadData()
         }else{
        
         
            var postsForStrip = self.stripPosts[post.stripID] ?? []
            postsForStrip.append(post)
            self.stripPosts[post.stripID] = postsForStrip

            self.tableView.reloadData()
            
        }
    }
}




// MARK: Repost cells stuff
extension ProfileViewController: PostTableViewCellDelegate {
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
        
    }
    

    func userStripeButtonPressed(user: StripwayUser, strip: StripwayStrip) {
        print("Strip button pressed")
        self.tappedUser = user
        self.tappedStrip = strip
        performSegue(withIdentifier: "ShowUserStrip", sender: self)
    }
    
    func postDeleted(post: StripwayPost) {
        self.reposts = self.reposts.filter{ $0.postID != post.postID }
        self.tableView.reloadData()
    }
    
    func currentWordBeingTyped(word: String?) {
        
    }
    

    func segueToHashtag(hashtag: String) {
        self.hashtagForSegue = hashtag
        self.performSegue(withIdentifier: "SegueToHashtag", sender: self)
    }
    
    func startEditingPost(post: StripwayPost) {
        self.postToView = post
        self.performSegue(withIdentifier: "EditPostSegue", sender: self)
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
        print("Showing reposters")
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
    
}

// MARK: Comment stuff
// When viewing comments, if you tap on a user this is what takes you to their profile
extension ProfileViewController: CommentViewControllerDelegate {
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

// MARK: Likes and Reposts Stuff
// When viewing likers or reposters, if you tap on a user this is what takes you to their profile
extension ProfileViewController: LikesRepostsViewControllerDelegate {
    func cellWithUserTapped(user: StripwayUser, fromVC vc: LikesRepostsViewController) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
        vc.dismiss(animated: false, completion: nil)
    }
}

// MARK: Peek/Pop stuff
extension ProfileViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
        if let newPostViewController = viewControllerToCommit as? ViewPostViewController {
            newPostViewController.viewPopped()
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let location = CGPoint(x: location.x, y: location.y + tableView.contentOffset.y)
        guard let tableViewIndexPath = tableView.indexPathForRow(at: location) else { return nil }
        print("PEEKPOP: Got tableViewIndexPath at location: \(location)")
        
        guard let tableViewCell = tableView.cellForRow(at: tableViewIndexPath) as? StripTableViewCell else { return nil }
        print("PEEKPOP: Got tableViewCell: \(tableViewCell.strip?.name)")
        
        let collectionView = tableViewCell.collectionView
        
        let collectionViewLocation = tableView.convert(location, to: collectionView)
        
        guard let collectionViewIndexPath = collectionView?.indexPathForItem(at: collectionViewLocation) else { return nil }
        print("PEEKPOP: Got collectionViewIndexPath: \(collectionViewIndexPath)")
        
        guard let collectionViewCell = tableViewCell.collectionView.cellForItem(at: collectionViewIndexPath) as? PostCollectionViewCell else  { return nil }
        print("PEEKPOP: I guess we got the collectionView: \(collectionViewCell.post?.caption)")
        
        guard let previewPost = collectionViewCell.post else { return nil }
        
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let viewPostViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
        viewPostViewController.viewPeeked()
        viewPostViewController.post = previewPost
        viewPostViewController.posts = [previewPost]
        viewPostViewController.user = self.profileOwner
        viewPostViewController.preferredContentSize = CGSize(width: 0.0, height: view.frame.width * 0.91/previewPost.imageAspectRatio)
        return viewPostViewController
        
    }
}

// MARK: Menu touch fix
class ProfileView: UIView {
    // This is real hacky but it works, the slide out menu is actually outside of the bounds of the view controller's view, and when
    // it slides in I just shift the view controller's view to the left, so the menu stays out of bounds. This catches the out of bounds
    // touch and passes it to the subview, which is the menu.
    var subview: UIView!
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.x > self.bounds.maxX {
            let newPoint = CGPoint(x: (point.x - self.bounds.maxX), y: point.y)
            return subview.hitTest(newPoint, with: event)
        }
        return super.hitTest(point, with: event)
    }
}

enum NewImageType: String {
    case profileImage = "ProfileImage"
    case headerImage = "HeaderImage"
    case newPostImage = "NewPostImage"
    case other = "Other"
}

protocol ProcessArchiveDelegate:class{
    func updateProcessStatus(isCompleted : Bool,post: StripwayPost, index: Int?)
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}


