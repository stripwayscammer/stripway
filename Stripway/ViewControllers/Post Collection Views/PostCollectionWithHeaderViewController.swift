//
//  ViewStripViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/13/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Zoomy

/// This one has a header because it just uses the author's profile header
class PostCollectionWithHeaderViewController: UIViewController {
    
    // Strip author or liker or bookmarker (not necessarily the author of the posts in the collection view)
    var collectionAuthor: StripwayUser!
    
    // Used when segueing to ViewPostViewController
    var tappedPost: StripwayPost?
    
    // Used to determine datasource and some small UI differences
    var collectionType: CollectionType = .strip
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Header stuff
    var headerCell: HeaderStripCollectionReusableView?
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var profileInfoView: UIView!
    @IBOutlet weak var imageHeaderView: UIView!
    @IBOutlet weak var guideView: UIView!
    @IBOutlet weak var newHeaderImageView: UIImageView!
    @IBOutlet weak var headerBlurImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerProfileImageView: UIImageView!
    
    // Data source stuff
    var strip: StripwayStrip?
    var stripPosts = [StripwayPost]()
    var likedPosts = [StripwayPost]()
    var bookmarkedPosts = [StripwayPost]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        setUpUI()
        loadPosts()
    }

    
    /// Loads the posts for whichever collection we're loading
    func loadPosts() {
        switch collectionType {
        case .likes:
            loadLikes()
        case .bookmarks:
            loadBookmarks()
        default:
            loadStripPosts()
        }
    }
    
    /// TODO: load these in batches
    func loadLikes() {
        API.Post.fetchLikes(forUID: collectionAuthor.uid) { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.likedPosts.insert(post!, at: 0)
            self.collectionView.reloadData()
        }
    }
    
    /// TODO: load these in batches
    func loadBookmarks() {
        API.Post.fetchBookmarks(forUID: collectionAuthor.uid) { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.bookmarkedPosts.append(post!)
            self.collectionView.reloadData()
        }
    }
    
    /// TODO: load these in batches
    func loadStripPosts() {
        API.Strip.observePostsForStrip(atDatabaseReference: strip!.postsReference!) { (post, error, shouldClear) in
            if let shouldClear = shouldClear, shouldClear {
                self.stripPosts.removeAll()
                return
            }
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.stripPosts.append(post!)
            self.collectionView.reloadData()
        }
    }
    
    /// Basically just sets up the header
    func setUpUI() {
        
        backButton.layer.cornerRadius = 15
        collectionView.contentInset.top = -UIApplication.shared.statusBarFrame.height
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = newHeaderImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerBlurImageView.addSubview(blurEffectView)
        
        headerProfileImageView.layer.masksToBounds = true
        headerProfileImageView.layer.cornerRadius = headerProfileImageView.bounds.width / 2
        
        if let headerImageURL = collectionAuthor.headerImageURL {
            let headerURL = URL(string: headerImageURL)
            newHeaderImageView.sd_setImage(with: headerURL)
            headerBlurImageView.sd_setImage(with: headerURL)
        }
        
        if let profileImageURL = collectionAuthor.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            headerProfileImageView.sd_setImage(with: profileURL)
        }
        headerLabel.text = collectionAuthor.username
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        // Pops view if it's in a navigation controller, otherwise just dismisses it
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = tappedPost!
                
                switch collectionType {
                case .likes:
                    viewPostViewController.posts = [tappedPost!]
                case .bookmarks:
                    viewPostViewController.posts = [tappedPost!]
                case .strip:
                    viewPostViewController.posts = self.stripPosts
                }
                
                if collectionType == .strip {
                    viewPostViewController.user = collectionAuthor
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
//        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
//        self.tabBarController?.tabBar.isHidden = false
    }
    
}

/// Populates the collectionView depending on what type of content it's supposed to have, and deals
/// with the scrolling stuff for the header
extension PostCollectionWithHeaderViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionType {
        case .likes:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if(self.likedPosts.count == 0 ){
                    collectionView.setEmptyView(title: "You did not like any post", message: "Your liked posts will be displayed here")
                }else{
                    collectionView.restore()
                }
            }
            
            return likedPosts.count
        case .bookmarks:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                
                if(self.bookmarkedPosts.count == 0 ){
                    collectionView.setEmptyView(title: "You did not save any post", message: "Your saved posts will be displayed here")
                }else{
                    collectionView.restore()
                }
            }
            
            return bookmarkedPosts.count
        case .strip:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                
                if(self.stripPosts.count == 0 ){
                    collectionView.setEmptyView(title: "This strip is empty", message: "There are no posts for this strip")
                }else{
                    collectionView.restore()
                }
                
            }
            
            return stripPosts.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionViewCell", for: indexPath) as! PostCollectionViewCell
        
        switch collectionType {
        case .likes:
            cell.post = likedPosts[indexPath.row]
        case .bookmarks:
            cell.post = bookmarkedPosts[indexPath.row]
        case .strip:
            cell.post = stripPosts[stripPosts.count - indexPath.row - 1]
        }
        
        cell.delegate = self
        
        let settings = Settings.instaZoomSettings
            .with(maximumZoomScale: 1)
            .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
        
        
        addZoombehavior(for: cell.photo, settings: settings)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderStripCollectionReusableView", for: indexPath) as! HeaderStripCollectionReusableView
        
        headerViewCell.collectionAuthor = collectionAuthor
        if collectionType == .strip {
            headerViewCell.strip = strip
        }
        headerViewCell.collectionType = collectionType
        
        self.headerCell = headerViewCell
        
        return headerViewCell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // This is the same dynamic header that is used on user profiles, should probably make a class for it or something
        // since it's being reused. Anyway, better explanation of how it works in ProfileViewController.swift
        guard let headerCell = self.headerCell else { return }
        
        var offset = scrollView.contentOffset.y
        var avatarTransform = CATransform3DIdentity
        var headerTransform = CATransform3DIdentity
        
        let headerImageViewMaxY = headerCell.headerImageSpacer.frame.maxY
        let guideViewMaxY = guideView.frame.maxY
        let offset_HeaderStop = headerImageViewMaxY - guideViewMaxY
        
        print("offset: \(offset), offset_HeaderStop: \(offset_HeaderStop)")
        
        if offset < 0 {
            
            let headerScaleFactor:CGFloat = -(offset) / imageHeaderView.bounds.height
            let headerSizevariation = ((imageHeaderView.bounds.height * (1.0 + headerScaleFactor)) - imageHeaderView.bounds.height)/2.0
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            
            imageHeaderView.layer.transform = headerTransform
            
        } else {
            
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offset_HeaderStop, -offset), 0)
            
            let avatarScaleFactor = (min(offset_HeaderStop, offset)) / headerCell.profileImageView.bounds.height / 1.4 // Slow down the animation
            let avatarSizeVariation = ((headerCell.profileImageView.bounds.height * (1.0 + avatarScaleFactor)) - headerCell.profileImageView.bounds.height) / 2.0
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
            
            imageHeaderView.layer.transform = headerTransform
            
        }
        
        if offset <= offset_HeaderStop {
            imageHeaderView.layer.zPosition = 0
            
        } else {
            imageHeaderView.layer.zPosition = 2
            guideView.layer.zPosition = 3
        }
        
        let newLabelNumber = offset - offset_HeaderStop
        
        let labelNumber = newLabelNumber - 18
        let labelTransform = CATransform3DIdentity
        if labelNumber >= 0 && labelNumber <= 44 {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, -labelNumber, 0)
            profileInfoView.layer.transform = labelTransform
        }
        if labelNumber < 0  {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, 0, 0)
            profileInfoView.layer.transform = labelTransform
        } else if labelNumber > 44 {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, -44, 0)
            profileInfoView.layer.transform = labelTransform
        }
        
        headerBlurImageView.alpha = (labelNumber)/100 * 2.5
        
        imageHeaderView.layer.transform = headerTransform
        headerCell.profileImageView.layer.transform = avatarTransform
    }
    
}

/// Some formatting stuff for the collection view
extension PostCollectionWithHeaderViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         return CGSize(width: (collectionView.frame.size.width - 3) / 3, height: (collectionView.frame.size.width - 3) / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PostCollectionWithHeaderViewController: PostCellDelegate {
    func accessoryPressedForPost(post: StripwayPost) {
        
    }
    
    
    /// Won't delete posts from here so this isn't used
    func deletePost(post: StripwayPost) {}
    
    func goToPostVC(post: StripwayPost) {
        self.tappedPost = post
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
}

/// This is for the header between the top image and the collection view
class HeaderStripCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var stripTitleLabel: UILabel!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var headerImageSpacer: UIView!
    var collectionType: CollectionType = .strip
    
    @IBOutlet weak var stripTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var stripTitleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stripTitleCenterConstraint: NSLayoutConstraint!
    
    var tapOnImage:UITapGestureRecognizer!
    var tapOnUsername:UITapGestureRecognizer!

    
    var strip: StripwayStrip? {
        didSet {
            stripTitleLabel.text = strip!.name
        }
    }
    
    var collectionAuthor: StripwayUser? {
        didSet {
            setHeaderInfo()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupUI()
        setupClickOnName()
        
    }
    
    
    func setupClickOnName(){
        
        profileImageView.isUserInteractionEnabled = true
        userInfoLabel.isUserInteractionEnabled = true
        
        tapOnImage =  UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
            
        tapOnUsername =  UITapGestureRecognizer(target: self, action: #selector(goToProfile(_:)))
        
       profileImageView.addGestureRecognizer(tapOnImage)
       
       userInfoLabel.addGestureRecognizer(tapOnUsername)
    
    }
    
    @objc func goToProfile(_ sender: UITapGestureRecognizer){
        
        let storyboard = UIStoryboard(name: "Profile", bundle: nil)
        let postViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.passedUser = collectionAuthor!
        var currentNavController = appDelegate.currentNavController
        if var navController = currentNavController, let tabController = navController.tabBarController {
            if tabController.selectedIndex != 0 {
                tabController.selectedIndex = 0
                guard let newNavController = appDelegate.currentNavController else { return }
                navController = newNavController
            }
            navController.popToRootViewController(animated: false)
            navController.pushViewController(postViewController, animated: false)
        }
    }
    
    func setupUI() {
        switch self.collectionType {
        case .likes:
            stripTitleLabel.text = "Liked Posts"
        case .bookmarks:
            stripTitleLabel.text = "Saved Posts"
        default:
            print("Setting strip name")
        }
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
    }
    
    func setHeaderInfo() {
        if let profileImageURL = collectionAuthor!.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            profileImageView.sd_setImage(with: profileURL)
        }
        
        // Don't show user info if we're on likes or bookmarks, and center the title
        switch collectionType {
        case .likes, .bookmarks:
            userInfoLabel.isHidden = true
            stripTitleTopConstraint.isActive = false
            stripTitleBottomConstraint.isActive = false
            stripTitleCenterConstraint.isActive = true
        case .strip:
            let attributedString = NSMutableAttributedString(string: collectionAuthor!.name, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)])
            let attributedString2 = NSAttributedString(string: " @\(collectionAuthor!.username)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
            attributedString.append(attributedString2)
            userInfoLabel.attributedText = attributedString
        }
    }
    
}

extension PostCollectionWithHeaderViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let location = CGPoint(x: location.x, y: location.y + collectionView.contentOffset.y)
        guard let collectionViewIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
        
        guard let collectionViewCell = collectionView.cellForItem(at: collectionViewIndexPath) as? PostCollectionViewCell else { return nil }
        
        guard let previewPost = collectionViewCell.post else { return nil }
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let viewPostViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
        viewPostViewController.viewPeeked()
        viewPostViewController.post = previewPost
        viewPostViewController.posts = [previewPost]
        
        viewPostViewController.preferredContentSize = CGSize(width: 0.0, height: view.frame.width * 0.91/previewPost.imageAspectRatio)
        return viewPostViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
        if let newPostViewController = viewControllerToCommit as? ViewPostViewController {
            newPostViewController.viewPopped()
        }
    }
    
}

enum CollectionType: String {
    case strip = "Strip"
    case likes = "Likes"
    case bookmarks = "Bookmarks"
}

extension UICollectionView {
    func setEmptyView(title: String, message: String) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "Avenir Next", size: 18)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "Avenir Next", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: -150).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 10).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -10).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        // The only tricky part is here:
        self.backgroundView = emptyView
    }
    func restore() {
        self.backgroundView = nil

    }
}

extension PostCollectionWithHeaderViewController: Zoomy.Delegate {

      func didBeginPresentingOverlay(for imageView: Zoomable) {
        
        self.collectionView.isScrollEnabled = false
      }
      
      func didEndPresentingOverlay(for imageView: Zoomable) {

        self.collectionView.isScrollEnabled = true
      }
      
}
