//
//  HomeViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/6/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import NYTPhotoViewer
import FirebaseMessaging
import Zoomy

class HomeViewController: UIViewController {
    
    @IBOutlet weak var linearProgressView: LinearProgressView!
    @IBOutlet weak var tableView: UITableView!
    
    var posts = [StripwayPost]()
    var users = [StripwayUser]()
    var accurateUsers: [String: StripwayUser] = [:]
    var isLoading = false
    var isPulling = false
    var tappedUser: StripwayUser?
    var tappedStrip: StripwayStrip?
    var currentUser: StripwayUser?
    
    let refreshControl = UIRefreshControl()
    var customView: UIView!
    var canRefresh = true
    
    var postToView: StripwayPost!
    
    var hashtagForSegue: String?
    
    var tappedUsernameForSegue: String?
    
    var shouldShowWelcomeStuff = false
    
    var initialOffset:CGFloat = -64.0
    var lastContentOffset: CGFloat = -64.0
    
    //Watermark:
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gImageView: UIImageView!
    @IBOutlet weak var watermarkLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    var vSpinner : UIView?

    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    
    /// This is needed so we can know whether to register a single or double tap on the HomeVC
    var doubleTapGestureRecognizer: UITapGestureRecognizer?
    
    var shouldHidePhotoOverlays = false
    var isFirstTimeRefreshTbl = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.isHidden = true
        Messaging.messaging().subscribe(toTopic: "all")
        Messaging.messaging().subscribe(toTopic: "all") { (err) in
//            print(err)
        }        
        if let currentUserUID = Auth.auth().currentUser?.uid {
//            Messaging.messaging().subscribe(toTopic: currentUserUID)
            Messaging.messaging().subscribe(toTopic: currentUserUID) { (err) in
//                print(err)
            }
        }
        
        setUpUI()
        print("Running newPostPosted() viewdidload")
        loadPosts()

        // Trigger it manually because it wasn't triggered before the notification was added
        self.appDidBecomeActive()

    }
    
    @objc func viewDoubleTapped() {
        print("DOUBLETAP: HOME HAS BEEN DOUBLE TAPPED")
        self.shouldHidePhotoOverlays = !shouldHidePhotoOverlays
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            for indexPath in visibleIndexPaths {
                if let homeCell = tableView.cellForRow(at: indexPath) as? HomeTableViewCell {
                    print("DOUBLETAP: Should be hiding/showing overlay in visible cells")
                    homeCell.shouldHideOverlay = self.shouldHidePhotoOverlays
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        print("DOUBLETAP: Adding the gesture recognizer")
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDoubleTapped))
        if let doubleTapGestureRecognizer = doubleTapGestureRecognizer {
            doubleTapGestureRecognizer.numberOfTapsRequired = 2
            self.view.addGestureRecognizer(doubleTapGestureRecognizer)
        }
        
        if let currentNavController = self.navigationController {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.currentNavController = currentNavController
        }
        super.viewWillAppear(animated)
        self.tableViewTopConstraint.constant = 0.0
        self.popupNotificationView.alpha = 0
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = false
        
        // We show the notification popup when the app becomes active
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        // Need to hide the popup when the app is closed
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(onNewPostFinished(notification:)), name: NEW_POSTING_FINISHED, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPostingProgress(notification:)), name: NEW_POSTING_PROGRESS, object: nil)
        
        // This has to be here or there's a weird issue caused by the hidesBarsOnSwipe thing that
        // results in gaps on the sides of tableViewCells. https://stackoverflow.com/a/45556843/10553525
        self.extendedLayoutIncludesOpaqueBars = true
        
        if API.Post.wasNewPostPosted {
            print("Running newPostPosted() viewWillAppear")
            API.Post.wasNewPostPosted = false
            self.posts.insert(API.Post.newPost, at: 0)
            self.users.insert(API.Post.newAuthor, at: 0)
            //            self.posts.append(API.Post.newPost)
            //            self.users.append(API.Post.newAuthor)
            self.accurateUsers[API.Post.newAuthor.uid] = API.Post.newAuthor
            
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnSwipe = true
//        if posts.isEmpty {
//            print("view did appear refresh called")
//            refresh()
//        }
        print("Running newPostPosted() viewDidAppear")
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.popupNotificationView.alpha = 0
        print("View is about to disappear, should dismiss any comment views that are up")
        navigationController?.hidesBarsOnSwipe = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        NotificationCenter.default.removeObserver(self, name: NEW_POSTING_FINISHED, object: nil)
        NotificationCenter.default.removeObserver(self, name: NEW_POSTING_PROGRESS, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        
    }
    
    func setUpUI() {
        
        if Utilities.isIphoneX()  {
            initialOffset = -88.0
        }
        else {
            initialOffset = -64.0
        }
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        refreshControl.bounds = CGRect(x:refreshControl.bounds.origin.x, y:10, width:refreshControl.bounds.size.width, height:refreshControl.bounds.size.height)
        
        linearProgressView.animationDuration = 1.0

//        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 23)!]
        
        let titleLabel = UILabel()
        titleLabel.text = "Stripway"
        titleLabel.sizeToFit()
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 23)!
        
        
        let leftItem = UIBarButtonItem(customView: titleLabel)
        self.navigationItem.leftBarButtonItem = leftItem
        
        let messageButton = UIButton(type: .custom)
        messageButton.setImage(#imageLiteral(resourceName: "Messages 3X"), for: .normal)
        messageButton.contentMode = .scaleAspectFit
        messageButton.frame = CGRect(x: 0, y: 0, width: 27, height: 30)
        messageButton.addTarget(self, action: #selector(messageButtonPressed), for: .touchUpInside)
        messageButton.imageEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 3)
        
        let messageButtonContainer = UIView(frame: messageButton.frame)
        messageButtonContainer.addSubview(messageButton)
        let messageButtonItem = UIBarButtonItem(customView: messageButtonContainer)
        
        let notificationButton = UIButton(type: .custom)
        notificationButton.setImage(#imageLiteral(resourceName: "Notifications 3X"), for: .normal)
        notificationButton.contentMode = .scaleAspectFit
        notificationButton.frame = CGRect(x: 0, y: 0, width: 27, height: 30)
        notificationButton.addTarget(self, action: #selector(notificationButtonPressed), for: .touchUpInside)
        notificationButton.imageEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 0)
        
        
        let notificationButtonContainer = UIView(frame: notificationButton.frame)
        notificationButtonContainer.addSubview(notificationButton)
        let notificationButtonItem = UIBarButtonItem(customView: notificationButtonContainer)
        navigationItem.rightBarButtonItems = [messageButtonItem, notificationButtonItem]
        
//        let shutterButton = UIButton(type: .custom)
//        shutterButton.setImage(#imageLiteral(resourceName: "Shutter 3X"), for: .normal)
//        shutterButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
//        shutterButton.addTarget(self, action: #selector(shutterButtonPressed), for: .touchUpInside)
//
//        let shutterButtonContainer = UIView(frame: shutterButton.frame)
//        shutterButtonContainer.addSubview(shutterButton)
//        //        shutterButton.transform = CGAffineTransform(translationX: -12, y: 0)
//        let shutterButtonItem = UIBarButtonItem(customView: shutterButtonContainer)
//
//        navigationItem.leftBarButtonItem = shutterButtonItem
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.isTranslucent = true
        self.tabBarController?.tabBar.isTranslucent = true
        
        let aTabArray: [UITabBarItem] = (self.tabBarController?.tabBar.items)!
        
        
        for index in 0..<aTabArray.count {
            let item = aTabArray[index]
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
            item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysOriginal)
            if index == 2 {
//                item.imageInsets = UIEdgeInsets.init(top: 6, left: 0, bottom: -6, right: 0)
            } else {
//                item.imageInsets = UIEdgeInsetsMake(5, 0, 5, 0)
            }
        }
        
        API.Messages.getUnreadMessagesCount { (unreadMessages) in
            if unreadMessages == 0 {
                messageButtonItem.removeBadge()
            } else {
                messageButtonItem.addBadge(number: unreadMessages)
            }
        }
        
        API.Notification.getUnreadNotificationsCount { (unreadNotifications) in
            if unreadNotifications == 0 {
                notificationButtonItem.removeBadge()
            } else {
                notificationButtonItem.addBadge(number: unreadNotifications)
            }
        }
    }
    
    @objc func shutterButtonPressed() {
    }
    
    @objc func messageButtonPressed() {
        performSegue(withIdentifier: "ViewConversationsSegue", sender: self)
    }
    
    @objc func notificationButtonPressed() {
        // Make sure navbar is showing before we segue
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        performSegue(withIdentifier: "ShowNotificationsSegue", sender: self)
    }
    
    @IBAction func onReset(_ sender: Any) {
        API.Post.fetchAllPosts { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if post?.photoURL != nil && post?.thumbURL == nil{
                
                let url = URL(string: post!.photoURL)
                do {
                    let data = try Data(contentsOf: url!)
                    let image = UIImage(data: data)
                    
                    if image == nil {
                        return
                    }
                    
                    print("image width height ", image!.size.width, image!.size.height)
                    API.Post.addMissingThumbnail(postWithID: post!.postID, forPostURL: post!.photoURL, forWidth: Int(image!.size.width*0.5), forHeight: Int(image!.size.height*0.5))
                }catch let err {
                    print("Error : \(err.localizedDescription)")
                }
            }
        }
    }
    
    @objc func refresh() {
        print("Refresh is called")
//        self.posts.removeAll()
//        self.users.removeAll()
//        self.accurateUsers.removeAll()
        loadPosts()
    }
  
    func loadPosts() {
        
        guard !isPulling else {
            return
        }
        isPulling = true

        print("posts first stamp ", posts.first?.timestamp)
        API.Feed.getRecentFeed(withID: Constants.currentUser!.uid, start: posts.first?.timestamp, limit: UInt(ONE_TIME_LOAD)) { (results) in

            if results.count == 0 && self.posts.count == 0 {
                print("NEWUSER: There are no posts in your recent feed")
                if !self.shouldShowWelcomeStuff {
                    self.fetchSuggestedUsers()
                }
                self.tableView.tableHeaderView = self.welcomeHeaderView
                self.shouldShowWelcomeStuff = true
            } else {
                self.tableView.tableHeaderView = nil
                self.shouldShowWelcomeStuff = false
            }
            
            if results.count > 0 {
                results.forEach({ (result) in
                    result.1.isFollowing = true
                    print("result timestamp ", result.0.timestamp)
                    self.posts.append(result.0)
                    self.users.append(result.1)
                    self.accurateUsers[result.1.uid] = result.1
                })
            }
            
            self.tableView.reloadData()
            if self.isFirstTimeRefreshTbl {
                self.isFirstTimeRefreshTbl = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("ROhithjhjh")
                    self.tableView.reloadData()
                }
            }
            if self.refreshControl.isRefreshing {
//                self.refreshControl.endRefreshing()
                self.lastContentOffset = self.tableView.contentOffset.y
                self.refreshControl.endRefreshing()
                print("begin refresh scrollView end 0")
            }
            
            self.isPulling = false
        }
        
        API.Feed.observeFeedRemoved(withID: Constants.currentUser!.uid) { (key) in
            print("BUG: observeFeedRemoved run")
            // this might put users and posts arrays out of sync
            // TODO: Fix this now
            self.posts = self.posts.filter{ $0.postID != key }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
//            isFirstTimeRefreshTbl
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            print("ROhithjhjh")
//            self.tableView.reloadData()
//            }
        }
    }
    
    func loadMore() {
        guard !isLoading else {
            return
        }
        isLoading = true
        guard let lastPostTimestamp = self.posts.last?.timestamp else {
            isLoading = false
            return
        }
        print("loading more request ", lastPostTimestamp)
        API.Feed.getOldFeed(withID: Constants.currentUser!.uid, start: lastPostTimestamp, limit: 5) { (results) in
            if results.count == 0 {
                return
            }
            for result in results {
                self.posts.append(result.0)
                self.users.append(result.1)
                self.accurateUsers[result.0.authorUID] = result.1
            }
            self.isLoading = false
            self.tableView.reloadData()
        }
    }
    
    
    @IBOutlet weak var welcomeHeaderView: UIView!
    var suggestedUsers: [(StripwayUser, Int)] = []
    
    func fetchSuggestedUsers() {
        print("Fetching suggested users")
        API.User.observeSuggestedUsers { (userTuple, shouldClear) in
            print("Returning suggestedUser: \(userTuple)")
            if let shouldClear = shouldClear, shouldClear {
                self.suggestedUsers.removeAll()
                return
            }
            guard let userTuple  = userTuple else { return }
            self.isFollowing(userID: userTuple.0.uid, completion: { (value) in
                userTuple.0.isFollowing = value
                self.suggestedUsers.append(userTuple)
                print("reloading tableview")
                self.tableView.reloadData()
            })
        }
    }
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }
    
    @objc func onNewPostFinished(notification:Notification)
    {
        linearProgressView.setProgress(0.0, animated: false)
        self.posts.removeAll()
        self.users.removeAll()
        self.accurateUsers.removeAll()
        self.refresh()
    }
    
    @objc func onPostingProgress(notification:Notification)
    {
        if let progress = notification.userInfo?["progress"] as? Float {
            linearProgressView.setProgress(progress, animated: true)
            print("uploading progress", progress)
        }
    }

    
    func newPostPosted(_ post:StripwayPost, _ postAuthor:StripwayUser) {
        print("Running newPostPosted() in HomeViewController")
        self.posts.append(post)
        self.users.append(postAuthor)
        self.accurateUsers[postAuthor.uid] = postAuthor

//        self.tableView.reloadData()
//        refresh()
//        self.tableView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    // The popup and its labels
    @IBOutlet var popupNotificationView: UIView!
    @IBOutlet var popupIcons: [UIImageView]!
    @IBOutlet var popupLabels: [UILabel]!
    @IBOutlet weak var popupHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var popupImageView: UIImageView!
    @IBOutlet weak var popupCenterXConstraint: NSLayoutConstraint!
    
    // App brought to foreground
    @objc func appDidBecomeActive() {
        // Only show the popup if the home view is the current view when the app becomes active
        if self.tabBarController?.selectedIndex == 0 {
            // Get the specific unread notifications and update the popup with that info
            API.Notification.getSpecificUnreadNotificationsCount { (reposts, followers, comments, likes) in
                // Clear all the labels and icons
                for label in self.popupLabels {
                    label.text = nil
                }
                for imageView in self.popupIcons {
                    imageView.image = nil
                }
                
                // Get all the notifications, only add to the array if they aren't zero
                // Also add the correct icon for that notification type (the icons are white image literals,
                // and the first item in the tuple)
                var newNotifications = [(UIImage, Int)]()
                if let reposts = reposts, reposts != 0 {
                    newNotifications.append((#imageLiteral(resourceName: "Repost Picture"), reposts))
                }
                if let followers = followers, followers != 0 {
                    newNotifications.append((#imageLiteral(resourceName: "New Follower"), followers))
                }
                if let comments = comments, comments != 0 {
                    newNotifications.append((#imageLiteral(resourceName: "New Comment"), comments))
                }
                if let likes = likes, likes != 0 {
                    newNotifications.append((#imageLiteral(resourceName: "New Like"), likes))
                }
                
                // Resize the popup and change the background image depending on how many
                // new notifications there are
                switch newNotifications.count {
                case 1:
                    self.popupImageView.image = UIImage(named: "Popup One")
                    self.popupHeightConstraint.constant = 52
                case 2:
                    self.popupImageView.image = UIImage(named: "Popup Two")
                    self.popupHeightConstraint.constant = 77
                case 3:
                    self.popupImageView.image = UIImage(named: "Popup Three")
                    self.popupHeightConstraint.constant = 102
                default:
                    self.popupImageView.image = UIImage(named: "Popup Four")
                    self.popupHeightConstraint.constant = 127
                }
                
                // Assign the correct icon and number
                for (index, element) in newNotifications.enumerated() {
                    self.popupIcons[index].image = element.0
                    self.popupLabels[index].text = String(element.1)
                }
                // Get the screen width so we can put the popup directly under the notification button
                let screenWidth = UIScreen.main.bounds.width
                print("SCREEN WIDTH: \(screenWidth)")
                
                // iPhone 6+, 7+, 8+, XS Max, XR
                if screenWidth == 414 {
                    self.popupCenterXConstraint.constant = 347
                }
                // iPhone 5, iPhone SE, iPod Touch
                if screenWidth == 320 {
                    self.popupCenterXConstraint.constant = 257
                }
                // iPhone 6, 7, 8, X, XS
                if screenWidth == 375 {
                    self.popupCenterXConstraint.constant = 313
                }
                
                // Finally show the popup
                if !newNotifications.isEmpty {
                    self.showPopup()
                }
            }
        }
    }
    
    // Hide the popup and cancel the 5 second timer
    @objc func appWillResignActive() {
        self.popupNotificationView.alpha = 0
        if let task = task {
            task.cancel()
        }
    }
    
    // Needed to do some weird stuff with a DispatchWorkItem because if the user closed the app
    // during the 5 second wait, it would just pause the timer and resume when the app is reopened
    var task: DispatchWorkItem?
    func showPopup() {
        task = DispatchWorkItem {
            self.hidePopup()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.popupNotificationView.alpha = 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: self.task!)
        }
    }
    
    func hidePopup() {
        UIView.animate(withDuration: 0.4) {
            self.popupNotificationView.alpha = 0
        }
    }
    
    // If the popup is tapped, just segue to notifications
    @IBAction func popupViewTapped(_ sender: Any) {
        self.popupNotificationView.alpha = 0
        self.notificationButtonPressed()
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if shouldShowWelcomeStuff {
            return suggestedUsers.count
        } else {
            return posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt called")
        tableView.deselectRow(at: indexPath, animated: true)
        if shouldShowWelcomeStuff {
            print("shouldShowWelcomeStuff")
            self.tappedUser = suggestedUsers[indexPath.row].0
            self.performSegue(withIdentifier: "ShowUserProfile", sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("cellForRowAt called and shouldShowWelcomeStuff: \(shouldShowWelcomeStuff)")
        if shouldShowWelcomeStuff {
            // This fixes a crash
            if suggestedUsers.count == 0 {
                return UITableViewCell()
            }
            
            suggestedUsers.sort(by: { $0.1 < $1.1 })
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
            cell.user = suggestedUsers[indexPath.row].0
            print("Should be returning a person cell")
            return cell
        } else {
            // This fixes a crash
            if posts.count == 0 {
                return UITableViewCell()
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "HomeTableViewCell", for: indexPath) as! HomeTableViewCell
            print("DOUBLETAP: Adding the gesture recognizer to the cell")
            cell.homeVCDoubleTapGesture = self.doubleTapGestureRecognizer
            let post = posts[indexPath.row]
            //        let user = users[indexPath.row]
            let user = accurateUsers[post.authorUID]
            cell.showThumb = false
            cell.post = post
            cell.user = user
            cell.delegate = self
            
            //Setup download delegate
            cell.downloadDelegate = self
            
//            cell.captionTextView.linkTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([
//                NSAttributedString.Key.foregroundColor.rawValue: UIColor.white
//                ])
            
            
              let settings = Settings.instaZoomSettings
                  .with(maximumZoomScale: 1)
                  .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
              
              addZoombehavior(for: cell.postImageView, settings: settings )
            
            cell.textViewCaption.linkTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([
            NSAttributedString.Key.foregroundColor.rawValue: UIColor.white
            ])
            cell.shouldHideOverlay = shouldHidePhotoOverlays
            cell.truncateCaption()
            cell.profileImageView.layer.borderWidth = 2
            cell.profileImageView.layer.borderColor = UIColor.white.cgColor
            
            //getHasTagPrefixesObjArr
            cell.myScrollView.tag = indexPath.row
           // cell.myScrollView.contentOffset.x = 0//self.view.bounds.width * 2
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if shouldShowWelcomeStuff {
            return 66
        } else {
            if posts.count == 0 {
                return UITableView.automaticDimension
            }
            var ratio = posts[indexPath.row].imageAspectRatio
            if ratio == 0 {ratio = 3/4}
            print("ratio ", ratio)
            let height = self.tableView.frame.width / ratio
            //to remove white line between 3/4 rows, change int and convert to CGFloat again
            return CGFloat(Int(height))
        }
    }
    
    func scrolltoTop() {
        self.tableViewTopConstraint.constant = -self.initialOffset

        self.navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = false
        self.tableView.setContentOffset(.zero, animated: true)
    }
    
    //    // this delegate is called when the scrollView (i.e your UITableView) will start scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.tableViewTopConstraint.constant = 0.0
        navigationController?.hidesBarsOnSwipe = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // If you are within two screen lengths of the bottom of the scrollView's content, it triggers the loading of more posts
        if scrollView.contentOffset.y  + self.view.frame.height >= scrollView.contentSize.height - (2 * self.view.frame.height) {
            print("home load more")
            loadMore()
        }
        if scrollView.contentOffset.y <= initialOffset + (-14.0){

            if canRefresh && !self.refreshControl.isRefreshing {
                print("refresh scrollView.offset: \(scrollView.contentOffset.y)", self.lastContentOffset)
                
                if (self.lastContentOffset >= scrollView.contentOffset.y) {
                    // moved to top
                    print("begin refresh scrollView top move")
                    print("content ", self.lastContentOffset, " offset ",  scrollView.contentOffset.y)
                    // moved to bottom
                    self.canRefresh = false
                    self.refreshControl.beginRefreshing()
                    let impact = UIImpactFeedbackGenerator()
                    impact.impactOccurred()
                    self.refresh()
                }
                else {
                    print("begin refresh scrollView bottom move")
                  
                }
            }
        } else if CGFloat(Int(scrollView.contentOffset.y)) >= initialOffset {
            self.canRefresh = true
        }
    }
    
}

 
extension HomeViewController: HomeTableViewCellDelegate {
    
    func userStripeButtonPressed(user: StripwayUser, strip: StripwayStrip) {
        self.tappedUser = user
        self.tappedStrip = strip
        performSegue(withIdentifier: "ShowUserStrip", sender: self)
    }
    
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
    
    func postDeleted(post: StripwayPost) {
        
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
    
    func presentAlertController(alertController: UIAlertController, forCell cell: HomeTableViewCell) {
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
        
    }
    
    func presentImageVC(imageVC: NYTPhotosViewController) {
        self.present(imageVC, animated: true, completion: nil)
    }
    
    func presentPeopleSelectionController(post: StripwayPost) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let pvc = storyboard.instantiateViewController(withIdentifier: "SharePostVC") as! SharePostVC
        pvc.modalPresentationStyle = .overCurrentContext
        pvc.post = post
        pvc.delegate = self
        tabBarController?.present(pvc, animated: true, completion: nil)
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
        if segue.identifier == "showPeopleList" {
            if let viewPeopleListVC = segue.destination as? PeopleViewController {
                viewPeopleListVC.profileOwner = self.currentUser
                viewPeopleListVC.selectedPost = self.postToView
                viewPeopleListVC.listType = .messageFollowing
            }
        }
        if segue.identifier == "showFromPost" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.senderUser = self.currentUser!
                viewConversationViewController.receiverUser = self.tappedUser
            }
        }
        if segue.identifier == "EditPostSegue" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = postToView
                viewPostViewController.posts = [postToView]
                viewPostViewController.user = accurateUsers[postToView.authorUID]
                viewPostViewController.isAlreadyEditing = true
                viewPostViewController.delegate = self
            }
        }
        if segue.identifier == "SegueToHashtag" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.hashtag = self.hashtagForSegue!
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
    
}

extension HomeViewController : SharePostVCDelegate {
}

extension HomeViewController: CommentViewControllerDelegate {
    func segueToHashtag(hashtag: String, fromVC vc: CommentViewController) {
        self.hashtagForSegue = hashtag
        self.performSegue(withIdentifier: "SegueToHashtag", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
    
    func userProfilePressed(user: StripwayUser, fromVC vc: CommentViewController) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
    
    func segueToProfileFor(username: String, fromVC vc: CommentViewController) {
        self.tappedUsernameForSegue = username
        self.tappedUser = nil
        self.performSegue(withIdentifier: "ShowUserProfile", sender: self)
//        vc.dismiss(animated: false, completion: nil)
    }
}

extension HomeViewController: LikesRepostsViewControllerDelegate {
    func cellWithUserTapped(user: StripwayUser, fromVC vc: LikesRepostsViewController) {
        self.tappedUser = user
        performSegue(withIdentifier: "ShowUserProfile", sender: self)
        vc.dismiss(animated: false, completion: nil)
    }
}

extension HomeViewController: ViewPostViewControllerDelegate {
    func updateCaptionForPost(post: StripwayPost) {
        guard let oldPostIndex = posts.firstIndex(where: { $0.postID == post.postID }) else { return }
        let oldPost = posts[oldPostIndex]
        oldPost.caption = post.caption
        tableView.reloadRows(at: [IndexPath(row: oldPostIndex, section: 0)], with: .none)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

extension CAShapeLayer {
    func drawCircleAtLocation(location: CGPoint, withRadius radius: CGFloat, andColor color: UIColor, filled: Bool) {
        fillColor = filled ? color.cgColor : UIColor.white.cgColor
        strokeColor = color.cgColor
        let origin = CGPoint(x: location.x - radius, y: location.y - radius)
        path = UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: radius * 2, height: radius * 2))).cgPath
    }
}

private var handle: UInt8 = 0;

extension UIBarButtonItem {
    private var badgeLayer: CAShapeLayer? {
        if let b: AnyObject = objc_getAssociatedObject(self, &handle) as AnyObject? {
            return b as? CAShapeLayer
        } else {
            return nil
        }
    }
    
    func addBadge(number: Int, withOffset offset: CGPoint = CGPoint.zero, andColor color: UIColor = UIColor(red: 200/255, green: 9/255, blue: 35/255, alpha: 1), andFilled filled: Bool = true) {
        guard let view = self.value(forKey: "view") as? UIView else { return }
        
        badgeLayer?.removeFromSuperlayer()
        
        var badgeWidth = 8
        var numberOffset = 4
        
        if number > 9 {
            badgeWidth = 12
            numberOffset = 6
        }
        
        // Initialize Badge
        let badge = CAShapeLayer()
        let radius = CGFloat(7)
        let location = CGPoint(x: view.frame.width - (radius + offset.x), y: (radius + offset.y))
        badge.drawCircleAtLocation(location: location, withRadius: radius, andColor: color, filled: filled)
        view.layer.addSublayer(badge)
        
        // Initialiaze Badge's label
        let label = CATextLayer()
        label.string = "\(number)"
        label.alignmentMode = CATextLayerAlignmentMode.center
        label.fontSize = 11
        label.frame = CGRect(origin: CGPoint(x: location.x - CGFloat(numberOffset), y: offset.y), size: CGSize(width: badgeWidth, height: 16))
        label.foregroundColor = filled ? UIColor.white.cgColor : color.cgColor
        label.backgroundColor = UIColor.clear.cgColor
        label.contentsScale = UIScreen.main.scale
        badge.addSublayer(label)
        
        // Save Badge as UIBarButtonItem property
        objc_setAssociatedObject(self, &handle, badge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func updateBadge(number: Int) {
        if let text = badgeLayer?.sublayers?.filter({ $0 is CATextLayer }).first as? CATextLayer {
            text.string = "\(number)"
        }
    }
    
    func removeBadge() {
        badgeLayer?.removeFromSuperlayer()
    }
}

extension HomeViewController:Zoomy.Delegate {

      func didBeginPresentingOverlay(for imageView: Zoomable) {
        
        self.tableView.isScrollEnabled = false
      }
      
      func didEndPresentingOverlay(for imageView: Zoomable) {

        self.tableView.isScrollEnabled = true
      }
      
}

