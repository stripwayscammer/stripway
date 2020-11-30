//
//  ViewStripViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/13/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class PostCollectionViewController: UIViewController {

    var strip: StripwayStrip?
    var stripAuthor: StripwayUser!
    var tappedPost: StripwayPost?
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var guideView: UIView!
    @IBOutlet weak var newHeaderImageView: UIImageView!
    @IBOutlet weak var headerBlurImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerProfileImageView: UIImageView!
    
    var collectionType: CollectionType = .other
    
    var headerCell: HeaderStripCollectionReusableView?
    
    @IBOutlet weak var profileInfoView: UIView!
    
    
    @IBOutlet weak var imageHeaderView: UIView!
    
    var likedPosts = [StripwayPost]()
    var bookmarkedPosts = [StripwayPost]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.layer.cornerRadius = 15
//        stripTitleLabel.text = strip.name
        collectionView.contentInset.top = -UIApplication.shared.statusBarFrame.height
        
        updateHeaderBlur()
        
        if let headerImageURL = stripAuthor.headerImageURL {
            let headerURL = URL(string: headerImageURL)
            newHeaderImageView.sd_setImage(with: headerURL)
            headerBlurImageView.sd_setImage(with: headerURL)
        }
        
        if let profileImageURL = stripAuthor.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            headerProfileImageView.sd_setImage(with: profileURL)
        }
        
        headerLabel.text = stripAuthor.username
        
        switch collectionType {
        case .likes:
            loadLikes()
        case .bookmarks:
            loadBookmarks()
        default:
            print("Error with title of strip page")
        }
    }
    
    func loadLikes() {
        API.Post.fetchLikes(forUID: stripAuthor.uid) { (post) in
            self.likedPosts.append(post)
            self.collectionView.reloadData()
        }
    }
    
    func loadBookmarks() {
        API.Post.fetchBookmarks(forUID: stripAuthor.uid) { (post) in
            self.bookmarkedPosts.append(post)
            self.collectionView.reloadData()
        }
    }
    
    func updateHeaderBlur() {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = newHeaderImageView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        headerBlurImageView.addSubview(blurEffectView)
        
        headerProfileImageView.layer.masksToBounds = true
        headerProfileImageView.layer.cornerRadius = headerProfileImageView.bounds.width / 2
        
    }

    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        // Pops view if it's in a navigation controller, otherwise just dismisses it
        // I don't think the dismiss one actually happens anymore so that can be removed
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                viewPostViewController.post = tappedPost!
//                viewPostViewController.user = stripAuthor
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = false
    }

}

extension PostCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionType {
        case .likes:
            return likedPosts.count
        case .bookmarks:
            return bookmarkedPosts.count
        default:
            return strip!.posts.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionViewCell", for: indexPath) as! PostCollectionViewCell
        
        switch collectionType {
        case .likes:
            cell.post = likedPosts[indexPath.row]
        case .bookmarks:
            cell.post = bookmarkedPosts[indexPath.row]
        default:
            cell.post = strip!.posts[indexPath.row]
        }
        
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerViewCell = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderStripCollectionReusableView", for: indexPath) as! HeaderStripCollectionReusableView
        
        headerViewCell.stripOwner = stripAuthor
        if collectionType == .strip {
            headerViewCell.strip = strip
        }
        headerViewCell.collectionType = collectionType
        
        self.headerCell = headerViewCell
        
        return headerViewCell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

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
        
        // put this outside the else
        if offset <= offset_HeaderStop {
            imageHeaderView.layer.zPosition = 0
            
        } else {
            imageHeaderView.layer.zPosition = 2
            guideView.layer.zPosition = 3
        }
        
        let newLabelNumber = offset - offset_HeaderStop
        print("newLabelNumber: \(newLabelNumber)")
        
        let labelNumber = newLabelNumber - 18
        let labelTransform = CATransform3DIdentity
        if labelNumber >= 0 && labelNumber <= 44 {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, -labelNumber, 0)
//            headerLabel.layer.transform = labelTransform
//            headerProfileImageView.layer.transform = labelTransform
            profileInfoView.layer.transform = labelTransform
        }
        if labelNumber < 0  {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, 0, 0)
//            headerLabel.layer.transform = labelTransform
//            headerProfileImageView.layer.transform = labelTransform
            profileInfoView.layer.transform = labelTransform
        } else if labelNumber > 44 {
            let labelTransform = CATransform3DTranslate(labelTransform, 0, -44, 0)
//            headerLabel.layer.transform = labelTransform
//            headerProfileImageView.layer.transform = labelTransform
            profileInfoView.layer.transform = labelTransform
        }
        
        headerBlurImageView.alpha = (labelNumber)/100 * 2.5
        print("headerBlurImageView.alpha: \(headerBlurImageView.alpha)")
        
        imageHeaderView.layer.transform = headerTransform
        headerCell.profileImageView.layer.transform = avatarTransform
        
    }
    
}

extension PostCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3 - 2, height: collectionView.frame.size.width / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}

extension PostCollectionViewController: PostCellDelegate {
    func deletePost(post: StripwayPost) {
        
    }
    
    func goToPostVC(post: StripwayPost) {
        self.tappedPost = post
        performSegue(withIdentifier: "ShowPost", sender: self)
    }
    
    
}

class HeaderStripCollectionReusableView: UICollectionReusableView {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var stripTitleLabel: UILabel!
    @IBOutlet weak var userInfoLabel: UILabel!
    @IBOutlet weak var headerImageSpacer: UIView!
    var collectionType: CollectionType = .other
    
    @IBOutlet weak var stripTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var stripTitleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var stripTitleCenterConstraint: NSLayoutConstraint!
    
    var strip: StripwayStrip? {
        didSet {
            stripTitleLabel.text = strip!.name
        }
    }
    
    var stripOwner: StripwayUser? {
        didSet {
            if let profileImageURL = stripOwner!.profileImageURL {
                let profileURL = URL(string: profileImageURL)
                profileImageView.sd_setImage(with: profileURL)
            }
            
            if let headerImageURL = stripOwner!.headerImageURL {
                let headerURL = URL(string: headerImageURL)
            }
            
            if collectionType != .likes && collectionType != .bookmarks {
                //            userInfoLabel.text = stripOwner!.name + " @" + stripOwner!.username
                let attributedString = NSMutableAttributedString(string: stripOwner!.name, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)])
                let attributedString2 = NSAttributedString(string: " @\(stripOwner!.username)", attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: .semibold), NSAttributedStringKey.foregroundColor: UIColor.lightGray])
                attributedString.append(attributedString2)
                userInfoLabel.attributedText = attributedString
            } else {
                userInfoLabel.isHidden = true
                stripTitleTopConstraint.isActive = false
                stripTitleBottomConstraint.isActive = false
                stripTitleCenterConstraint.isActive = true
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        switch self.collectionType {
        case .likes:
            stripTitleLabel.text = "Liked Posts"
        case .bookmarks:
            stripTitleLabel.text = "Saved Posts"
        default:
            print("Error with title of strip page")
        }
//        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        setupUI()
    }
    
    func setupUI() {
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.borderWidth = 3
        profileImageView.layer.borderColor = UIColor.white.cgColor
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        
//        profileImageButton.layer.borderWidth = 3
//        profileImageButton.layer.borderColor = UIColor.white.cgColor
//        profileImageButton.layer.cornerRadius = profileImageButton.bounds.width / 2
    }
    
}

enum CollectionType: String {
    case strip = "Strip"
    case likes = "Likes"
    case bookmarks = "Bookmarks"
    case other = "Other"
}
