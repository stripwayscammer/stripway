//
//  HashtagViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/12/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Zoomy

/// This is for post collection views that don't have a header, like hashtags or trendtags (or reports for admins)
class PostsCollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    /// The tapped post to use to segue to ViewPostViewController
    var tappedPost: StripwayPost?
    
    var posts = [StripwayPost]()
    
    /// The hashtag if it's a hashtag
    var hashtag: String? {
        didSet {
            hashtag = hashtag!.lowercased()
            self.title = hashtag!
            loadHashtagPosts()
        }
    }
    
    /// The trendtag if it's a trendtag
    var trendtag: Trendtag? {
        didSet {
            self.title = trendtag!.name
            loadTrendtagPosts()
        }
    }
    
    /// If it's for reports then this is true, and we load reports from the only reports section in the database
    var reports: Bool = false {
        didSet {
            if reports {
                self.title = "Reported Posts"
                loadReportedPosts()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        // Fixed a weird bug with a transition I think
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.navigationBar.tintColor = UIColor.black
    }
    
    /// Loads the posts for that hashtag from the database and populates the array
    func loadHashtagPosts() {
        API.Hashtag.fetchPosts(forHashtag: hashtag!) { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.posts.append(post!)
            self.collectionView.reloadData()
        }
    }
    
    /// Loads the posts for that trendtag from the database and populates the array
    func loadTrendtagPosts() {
        API.Trending.fetchPostsForTrendtag(trendtag: trendtag!) { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.posts.append(post!)
            self.collectionView.reloadData()
        }
    }
    
    /// Loads reported posts and populates the array
    func loadReportedPosts() {
        API.Post.fetchReportedPosts { (post, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.posts.append(post!)
            self.collectionView.reloadData()
        }
        API.Post.fetchRemovedReportedPosts { (key) in
            self.posts.removeAll(where: { $0.postID == key })
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = tappedPost!
                viewPostViewController.posts = [tappedPost!]
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
}

/// Populating the collection view with the appropriate posts
extension PostsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionViewCell", for: indexPath) as! PostCollectionViewCell
        cell.post = posts[indexPath.row]
        cell.delegate = self
        cell.isNowEditing = reports
        cell.accessoryButton.isHidden = !reports
        
        let settings = Settings.instaZoomSettings
            .with(maximumZoomScale: 1)
            .with(defaultAnimators: DefaultAnimators().with(dismissalAnimator: SpringAnimator(duration: 0.7, springDamping:1)))
        
        
        addZoombehavior(for: cell.photo, settings: settings)
        
        return cell
    }
}

/// Some layout stuff for the collection view
extension PostsCollectionViewController: UICollectionViewDelegateFlowLayout {
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


extension PostsCollectionViewController: PostCellDelegate {
    func accessoryPressedForPost(post: StripwayPost) {
        let alert = UIAlertController(title: "Remove post?", message: "Are you sure you want remove post from reported?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (action) in
            API.Post.removePostFromReported(post: post)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    /// Admin can delete posts from here, should probably ask for a confirmation, also need to add
    /// an approve to remove it from reported if it's not offensive.
    func deletePost(post: StripwayPost) {
        if reports {
            let alert = UIAlertController(title: "Delete post?", message: "Are you sure you want to delete this post?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                API.Post.deletePost(post: post)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func goToPostVC(post: StripwayPost) {
        self.tappedPost = post
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
}

extension PostsCollectionViewController: UIViewControllerPreviewingDelegate {
    
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
extension PostsCollectionViewController: Zoomy.Delegate {

      func didBeginPresentingOverlay(for imageView: Zoomable) {
        
        self.collectionView.isScrollEnabled = false
      }
      
      func didEndPresentingOverlay(for imageView: Zoomable) {

        self.collectionView.isScrollEnabled = true
      }
      
}
