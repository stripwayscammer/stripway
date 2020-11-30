//
//  ActivityViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/23/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase
import ImageSlideshow
import SDWebImage
import NYTPhotoViewer
import Zoomy

class TrendingViewController: UIViewController {
    
    var trendtags = [Trendtag]()
    var trendtagPosts = [String: [StripwayPost]]()
    var trendtagRecentPosts = [String: [StripwayPost]]()
    var trendtagRecentCount = [String: Int]()
    
    var featured = [(StripwayPost, StripwayUser, Int)]()
//    var featuredPosts = [StripwayPost]()
//    var featuredPostUsers = [StripwayUser]()
//    var featuredTimestamps = [Int]()

    var tappedUser: StripwayUser?
    var tappedPost: StripwayPost?
    var tappedPosts: [StripwayPost]?
    var tappedStrip: StripwayStrip?
    
    let refreshTrendingCtrl = UIRefreshControl()
    let refreshFeatureCtrl = UIRefreshControl()
    var canRefresh = true
    var isLoading = false
    
    var selectedTrendtag: Trendtag?
    var currentTopTabSelected: Int = 0
    
    // we set a variable to hold the contentOffSet before scroll view scrolls
    var lastContentOffset: CGFloat = 0.0
    var initialOffset:CGFloat = -64.0
    
    @IBOutlet weak var editButton: UIBarButtonItem!
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var headerView: UIView!

    var showsAccessoryButton = false
    
//    var headerImageSources = [SDWebImageSource]()
    
    var headerImageURLs = [(snapshotKey: String, urlString: String, index: Int)]()
    
    @IBOutlet weak var slideshowView: ImageSlideshow!
    
    @IBOutlet weak var btnTrending: UIButton!
    @IBOutlet weak var btnFeatured: UIButton!
    
    @IBOutlet weak var switchTabView: UIView!
    @IBOutlet weak var maskView: UIView!
    
    @IBOutlet weak var tabLine: UIView!
    @IBOutlet weak var featuredLine: UIView!
    
    @IBOutlet weak var featureLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var slideTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        // Do any additional setup after loading the view.
        setupUI()

        fetchTrendtags()
        configureSlideshow()
        loadHeaderImages()
        checkAdmins()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        fetchTrendtags()
//        navigationController?.hidesBarsOnSwipe = true
    }
    
    func setupUI() {
        
        if Utilities.isIphoneX()  {
            initialOffset = -88.0
        }
        else {
            initialOffset = -64.0
        }
        
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 21)!]
        self.navigationController?.navigationBar.isTranslucent = true
        self.tabBarController?.tabBar.isTranslucent = true
        self.showFeaturedList()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height:42)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maskView.addSubview(blurEffectView)
        
        refreshTrendingCtrl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        refreshFeatureCtrl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        tableView.addSubview(refreshTrendingCtrl)
        collectionView.addSubview(refreshFeatureCtrl)
        refreshFeatureCtrl.bounds = CGRect(x:refreshFeatureCtrl.bounds.origin.x, y:-25, width:refreshFeatureCtrl.bounds.size.width, height:refreshFeatureCtrl.bounds.size.height)
        refreshTrendingCtrl.bounds = CGRect(x:refreshTrendingCtrl.bounds.origin.x, y:-25, width:refreshTrendingCtrl.bounds.size.width, height:refreshTrendingCtrl.bounds.size.height)
        
    }
    
    func configureSlideshow() {
        slideshowView.slideshowInterval = 3
//        slideshowView.pageIndicator = nil
        slideshowView.contentScaleMode = .scaleAspectFill
        let oldFrame = headerView.frame
        let newFrame = CGRect(x: oldFrame.minX, y: oldFrame.minY, width: oldFrame.width, height: oldFrame.width * (5/9))
        headerView.frame = newFrame
    }
    
    func loadHeaderImages() {
        headerImageURLs.removeAll()
        API.Trending.loadHeaderImagesOnce { (resultTuple, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let resultTuple = resultTuple {
                self.headerImageURLs.append(resultTuple)
                //                let imageSource = SDWebImageSource(urlString: resultTuple.1)
                //                self.headerImageSources.append(imageSource!)
                self.setSlideshowImages()
                //                self.tableview.reloadData()
            }
        }
    }
    
    func setSlideshowImages() {
        headerImageURLs = headerImageURLs.sorted(by: { $0.index < $1.index })
        var imageSources = [SDWebImageSource]()
        for imageURL in headerImageURLs {
            let imageSource = SDWebImageSource(urlString: imageURL.urlString)!
            imageSources.append(imageSource)
        }
        slideshowView.setImageInputs(imageSources)
    }
    
    func fetchTrendtags() {
        isLoading = true
        
        API.Trending.fetchAllTrendtags { (tags) in
            self.trendtags = tags
            
            let myGroup = DispatchGroup()

            for tag in self.trendtags {
                myGroup.enter()
                API.Trending.fetchAllPostsForTrendtag(trendtag: tag, completion: { (posts, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        print("ERROR THING")
                        myGroup.leave()
                        return
                    }
                    var postsForTag = self.trendtagPosts[tag.name] ?? []
                    postsForTag = posts
                    self.trendtagPosts[tag.name] = postsForTag
                    
                    myGroup.leave()
                })
                
                API.Trending.fetchRemovedPostsForTrendtag(trendtag: tag, completion: { (key) in
                    var postsForTag = self.trendtagPosts[tag.name] ?? []
                    postsForTag.removeAll(where: { $0.postID == key })
                    self.trendtagPosts[tag.name] = postsForTag
                    self.tableView.reloadData()
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main, execute: {
                self.tableView.reloadData()
                if self.refreshTrendingCtrl.isRefreshing == true {
                    self.refreshTrendingCtrl.endRefreshing()
                    
                    if self.tableView.contentOffset.y != self.initialOffset && !Utilities.isIphoneX() {
                        UIView.animate(withDuration: 0.7, animations: {
                            print("end scroll reset called")
                            self.tableView.contentOffset.y = self.initialOffset
                            self.slideTopConstraint.constant = 42.0
                            self.slideTopConstraint.isActive = true
                            self.headerView.layoutIfNeeded()
                        })
                    }
                }
                self.isLoading = false
            })
        }
    }
    
    func fetchFeaturedList(){
        self.featured.removeAll()
        self.btnFeatured.isUserInteractionEnabled = false

        Database.database().reference().child("admin").child("adminUsers").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                let group = DispatchGroup()
                for case let child as DataSnapshot in snapshot.children {
                    group.enter()
                    API.Reposts.getRepostsFeed(withID: child.key) { (results) in
                        if results.count > 0 {
                            results.forEach({ (result) in
                                self.featured.append(result)
                                self.featured.sort(by: {$0.2 > $1.2})
                            })
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    self.collectionView.reloadData()
                    if self.refreshFeatureCtrl.isRefreshing == true {
                        self.refreshFeatureCtrl.endRefreshing()
                        if self.collectionView.contentOffset.y < self.initialOffset && !Utilities.isIphoneX() {
                            UIView.animate(withDuration: 0.7, animations: {
                                self.collectionView.contentOffset.y = self.initialOffset
                                print("refresh called reset")
                            })
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.btnFeatured.isUserInteractionEnabled = true
            }            
        }
    }
    
    func showFeaturedList() {
        currentTopTabSelected = 0
        
        self.collectionView.isHidden = false
        self.tableView.isHidden = true
        
        self.btnFeatured.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.btnTrending.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        
        self.fetchFeaturedList()
    }

    func showTrendingList() {
        currentTopTabSelected = 1
        self.collectionView.isHidden = true
        self.tableView.isHidden = false

        self.btnTrending.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.btnFeatured.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        self.tableView.reloadData()
        
    }
    
    @IBAction func onFeaturedSelect(_ sender: Any) {
        
        UIView.animate(withDuration: 0.3) {
            self.featureLeadingConstraint.constant = 0
            self.switchTabView.layoutIfNeeded()
        }
        showFeaturedList()
    }
    
    @IBAction func onTrendingSelect(_ sender: Any) {
        let w = UIScreen.main.bounds.width / 2

        UIView.animate(withDuration: 0.3) {
            self.featureLeadingConstraint.constant = w
            self.switchTabView.layoutIfNeeded()
        }
        
        showTrendingList()
    }    
    
    func checkAdmins() {
        guard let currentUserUID = Constants.currentUser?.uid else { return }
        Database.database().reference().child("admin").child("adminUsers").observeSingleEvent(of: .value) { (snapshot) in
            for case let child as DataSnapshot in snapshot.children {
                if child.key == currentUserUID {
                    self.showsAccessoryButton = true
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func refresh() {
        print("Refresh is called")
        if currentTopTabSelected == 0 {
            fetchFeaturedList()
        }
        else {
            fetchTrendtags()
            loadHeaderImages()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowUserProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                if let tappedUser = self.tappedUser {
                    profileViewController.profileOwner = tappedUser
                }
            }
        }
        if segue.identifier == "ShowPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = tappedPost!
                viewPostViewController.tappedStrip = tappedStrip
                viewPostViewController.posts = []
            }
        }
        if segue.identifier == "SegueToTrendtag" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.trendtag = self.selectedTrendtag!
            }
        }
    }
}

extension TrendingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trendtags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if trendtags.count == 0 {
            return UITableViewCell()
        }
        trendtags = trendtags.sorted(by: { $0.index < $1.index })
        let cell = tableView.dequeueReusableCell(withIdentifier: "StripTableViewCell", for: indexPath) as! StripTableViewCell
        let trendtag = trendtags[indexPath.row]
        var posts = trendtagPosts[trendtag.name]
        posts?.sort(by: { $0.likeCount > $1.likeCount })
        cell.trendtag = trendtag
        cell.posts = posts
        
        
        
        cell.index = indexPath.row
        cell.delegate = self
        cell.showsAccessoryButton = self.showsAccessoryButton
    
        
        return cell
    }
    
//    // this delegate is called when the scrollView (i.e your UITableView) will start scrolling
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print("official scroll end ", scrollView.contentOffset.y)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(" offset ",  scrollView.contentOffset.y, self.canRefresh)

        if (self.lastContentOffset >= scrollView.contentOffset.y) {
            // moved to top
            self.switchTabView.isHidden = false
        }
        else if self.lastContentOffset <= -64.0 {
            self.switchTabView.isHidden = false
        }
        else {
            print("content ", self.lastContentOffset, " offset ",  scrollView.contentOffset.y)
            // moved to bottom
            self.switchTabView.isHidden = true
        }
        
        if scrollView.contentOffset.y <= initialOffset + (-16.0) {
            if canRefresh && !self.refreshFeatureCtrl.isRefreshing {
                //                print(" refresh called ", scrollView.contentOffset.y, self.canRefresh)
                self.canRefresh = false
                if self.currentTopTabSelected == 0 {
                    self.refreshFeatureCtrl.beginRefreshing()
                }
                else {
                    self.refreshTrendingCtrl.beginRefreshing()
                }
                
                let impact = UIImpactFeedbackGenerator()
                impact.impactOccurred()
                self.refresh()
            }
        } else if scrollView.contentOffset.y >= initialOffset {
            self.canRefresh = true
        }
    }
}

extension TrendingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.featured.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacing section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeatureCollectionViewCell", for: indexPath) as! FeatureCollectionViewCell
        
        if indexPath.row >= featured.count {
            //to resolve crash when overflow
            return cell
        }
        cell.index = indexPath.row
        cell.post = featured[indexPath.row].0
        cell.user = featured[indexPath.row].1
        cell.delegate = self
        
        let settings = Settings.instaZoomSettings
            .with(maximumZoomScale: 1)
            .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
        
        
        addZoombehavior(for: cell.postImageView, settings: settings)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let halfScreenWidth = UIScreen.main.bounds.width / 2
        //to remove white line between 3/4 rows, convert height to int
        return CGSize(width: CGFloat(Double(halfScreenWidth) - 0.8), height: CGFloat(Double(halfScreenWidth * 1.3)))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row >= self.featured.count {
            return
        }
        self.goToPostVC(post: self.featured[indexPath.row].0, posts: [self.featured[indexPath.row].0])
    }
}

extension TrendingViewController: FeatureCollectionViewCellDelegate {
    func segueToProfileFor(_ index: Int) {
        if self.featured.count > index {
            self.tappedUser = self.featured[index].1
            performSegue(withIdentifier: "ShowUserProfile", sender: self)
        }
    }
}


extension TrendingViewController: StripCellDelegate {
    func accessoryPressedForPost(post: StripwayPost, forTrendtag trendtag: Trendtag) {
        let alert = UIAlertController(title: "Remove post?", message: "Are you sure you want to remove this post from #\(trendtag.name)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (action) in
            API.Trending.blockPostFromTrendtag(postID: post.postID, trendtagName: trendtag.name)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func goToTrendtagVC(trendtag: Trendtag) {
        self.selectedTrendtag = trendtag
        performSegue(withIdentifier: "SegueToTrendtag", sender: self)
    }
    
    func deletePost(post: StripwayPost, fromStrip strip: StripwayStrip) {
    }
    
    func deleteStrip(strip: StripwayStrip, atIndex: Int) {
    }
    
//    func goToPostVC(post: StripwayPost) {
    func goToPostVC(post: StripwayPost, posts: [StripwayPost]) {
        self.tappedPost = post
        self.tappedPosts = posts
        API.Strip.observeStrip(withID: post.stripID) { (strip) in
            self.tappedStrip = strip
            self.performSegue(withIdentifier: "ShowPost", sender: self)
        }
        
    }
    
    func goToStripVC(strip: StripwayStrip) {
    }
    
    func didEditStripName(newName: String, forStrip strip: StripwayStrip) {
    }
}

// MARK: Peek/Pop stuff
extension TrendingViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.navigationController?.show(viewControllerToCommit, sender: nil)
        if let newPostViewController = viewControllerToCommit as? ViewPostViewController {
            newPostViewController.viewPopped()
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if currentTopTabSelected == 0 {
            
            let location = CGPoint(x: location.x, y: location.y + collectionView.contentOffset.y)
            guard let collectionViewIndexPath = collectionView.indexPathForItem(at: location) else { return nil }
            
            guard let collectionViewCell = collectionView.cellForItem(at: collectionViewIndexPath) as? FeatureCollectionViewCell else { return nil }
            
            guard let previewPost = collectionViewCell.post else { return nil }
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let viewPostViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
            viewPostViewController.viewPeeked()
            viewPostViewController.post = previewPost
            viewPostViewController.posts = [previewPost]

            viewPostViewController.preferredContentSize = CGSize(width: 0.0, height: view.frame.width * 0.91/previewPost.imageAspectRatio)
            return viewPostViewController
            
            
        } else if currentTopTabSelected == 1 {
            
            let location = CGPoint(x: location.x, y: location.y + tableView.contentOffset.y)
            guard let tableViewIndexPath = tableView.indexPathForRow(at: location) else { return nil }
            print("PEEKPOP: Got tableViewIndexPath at location: \(location)")
            
            guard let tableViewCell = tableView.cellForRow(at: tableViewIndexPath) as? StripTableViewCell else { return nil }
            print("PEEKPOP: Got tableViewCell: \(String(describing: tableViewCell.strip?.name))")
            
            let collectionView = tableViewCell.collectionView
            
            let collectionViewLocation = tableView.convert(location, to: collectionView)
            
            guard let collectionViewIndexPath = collectionView?.indexPathForItem(at: collectionViewLocation) else { return nil }
            print("PEEKPOP: Got collectionViewIndexPath: \(collectionViewIndexPath)")
            
            guard let collectionViewCell = tableViewCell.collectionView.cellForItem(at: collectionViewIndexPath) as? PostCollectionViewCell else  { return nil }
            print("PEEKPOP: I guess we got the collectionView: \(String(describing: collectionViewCell.post?.caption))")
            
            guard let previewPost = collectionViewCell.post else { return nil }
            
            let storyboard = UIStoryboard(name: "Home", bundle: nil)
            let viewPostViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
            
            viewPostViewController.viewPeeked()
            viewPostViewController.post = previewPost
            viewPostViewController.posts = [previewPost]
            viewPostViewController.preferredContentSize = CGSize(width: 0.0, height: view.frame.width * 0.91/previewPost.imageAspectRatio)
            return viewPostViewController
            
        }
        
        return nil
    }
}

/// Input Source to image using SDWebImage
@objcMembers
public class SDWebImageSource: NSObject, InputSource {
    /// url to load
    public var url: URL
    
    /// placeholder used before image is loaded
    public var placeholder: UIImage?
    
    /// Initializes a new source with a URL
    /// - parameter url: a url to be loaded
    /// - parameter placeholder: a placeholder used before image is loaded
    public init(url: URL, placeholder: UIImage? = nil) {
        self.url = url
        self.placeholder = placeholder
        super.init()
    }
    
    /// Initializes a new source with a URL string
    /// - parameter urlString: a string url to load
    /// - parameter placeholder: a placeholder used before image is loaded
    public init?(urlString: String, placeholder: UIImage? = nil) {
        if let validUrl = URL(string: urlString) {
            self.url = validUrl
            self.placeholder = placeholder
            super.init()
        } else {
            return nil
        }
    }
    
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.sd_setImage(with: self.url, placeholderImage: self.placeholder, options: [], completed: { (image, _, _, _) in
            callback(image)
        })
    }
    
    public func cancelLoad(on imageView: UIImageView) {
        imageView.sd_cancelCurrentImageLoad()
    }
}

extension TrendingViewController: Zoomy.Delegate {

      func didBeginPresentingOverlay(for imageView: Zoomable) {
        
        self.tableView.isScrollEnabled = false
        self.collectionView.isScrollEnabled = false
      }
      
      func didEndPresentingOverlay(for imageView: Zoomable) {

        self.tableView.isScrollEnabled = true
        self.collectionView.isScrollEnabled = true
      }
      
}
