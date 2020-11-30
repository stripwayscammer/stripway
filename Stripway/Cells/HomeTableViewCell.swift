//
//  HomeTableViewCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/29/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import NYTPhotoViewer
import FirebaseDatabase
import ReadMoreTextView
import Macaw
import TagListView
import SDWebImage
import Zoomy



class HomeTableViewCell: UITableViewCell{
    @IBOutlet weak var myScrollView: UIScrollView!
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var viewHashTagContnr: UIView!
    @IBOutlet weak var viewCaptionContner: UIView!
    @IBOutlet weak var textViewCaption: UITextView!
    @IBOutlet weak var tagViewList: TagListView!
    @IBOutlet weak var lblHashText: UILabel!
//    @IBOutlet weak var heightConstantOfCaptionText: NSLayoutConstraint!
    var postsModelArr = [StripwayPost]()
    // Main post information
    @IBOutlet weak var heightConstantOfCaptionText: NSLayoutConstraint!
    @IBOutlet weak var profileImageView: SpinImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var nameLabel_Title: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionTextView: ReadMoreTextView!
    @IBOutlet weak var editableTextView: UITextView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    // Buttons and interactive stuff
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var commentImageView: UIImageView!
    @IBOutlet weak var repostImageView: UIImageView!
    @IBOutlet weak var bookmarkImageView: UIImageView!
    @IBOutlet weak var ellipsisButton: UIButton!
    @IBOutlet weak var likesNumberButton: UIButton!
    @IBOutlet weak var commentsNumberButton: UIButton!
    @IBOutlet weak var repostsNumberButton: UIButton!
    
    @IBOutlet weak var spottedView: UIView!
    
    
    @IBOutlet weak var topGradient: UIImageView!
    @IBOutlet weak var bottomGradient: UIImageView!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var popProfileView: ShadesView!
    @IBOutlet weak var popProfileImageView: SpinImageView!
    
    @IBOutlet weak var popNameLbl: UILabel!
    @IBOutlet weak var popTipLabel: UILabel!
    
    @IBOutlet weak var tagView: UIView!
    
    @IBOutlet weak var fanMenu: UIView!
    
    @IBOutlet weak var btnSharePost: ShadesView!
    @IBOutlet weak var btnDM: ShadesView!
    @IBOutlet weak var btnBookMark: ShadesView!
    @IBOutlet weak var btnRePost: ShadesView!
    @IBOutlet weak var focusImgView: UIImageView!
    
    @IBOutlet weak var focusWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var shareLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var shareTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var shareWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dmLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var dmTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dmWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bookLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bookWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var repostLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var repostTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var repostWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var postImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postImageViewAspectRatioConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var popMenuTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var popMenuLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var popInfoLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var popInfoTopConstraint: NSLayoutConstraint!
    
    /// Whenever the caption height changes, this changes too, so we know where to put the top of the
    /// suggestions container view
    var captionMaxY: CGFloat = 0
    
    //parameters for shaking animation
    let effectRadius:CGFloat = 50.0
    var dmDistance:CGFloat = 0.0
    var shareDistance:CGFloat = 0.0
    var bookDistance:CGFloat = 0.0
    var repostDistance:CGFloat = 0.0
    
    let shakeBandX:CGFloat = 0.3
    
    var showThumb:Bool = false
    var showingPopUp:Bool = false
    var shakingPopup:Bool = false
    
    var taggedButtons = [UIButton]()
    var taggedVisible = false
    
    var popUpCenter:CGPoint!
    var DMRect:CGRect!
    var sharePostRect:CGRect!
    var bookMarkRect:CGRect!
    var rePostRect:CGRect!
    
    let popUpButtonWidth:CGFloat = 48.0
    var shareLeft:CGFloat = 0.0
    var shareTop:CGFloat = 0.0
    var dmLeft:CGFloat = 0.0
    var dmTop:CGFloat = 0.0
    var bookLeft:CGFloat = 0.0
    var bookTop:CGFloat = 0.0
    var repostLeft:CGFloat = 0.0
    var repostTop:CGFloat = 0.0
    
    let shareLeftInitial:CGFloat = 0.0
    let shareTopInitial:CGFloat = 0.0
    let dmLeftInitial:CGFloat = 0.0
    let dmTopInitial:CGFloat = 0.0
    var bookLeftInitial:CGFloat = 0.0
    var bookTopInitial:CGFloat = 0.0
    var repostLeftInitial:CGFloat = 0.0
    var repostTopInitial:CGFloat = 0.0
    
    var dx:CGFloat = 30.0
    var animationAlpha:CGFloat = 0.7
    
    var hashTag = ""
    var captionText = ""
    var tagArr = [String]()
    
    //Tagged
    var taggedButton:UIButton!
    
    var shouldHideOverlay: Bool? {
        didSet {
            if let shouldHideOverlay = shouldHideOverlay {
                if shouldHideOverlay {
                    hidePhotoOverlay()
                } else {
                    showPhotoOverlay()
                }
            }
        }
    }
    
    
    
    /// The post for this cell, does some UI stuff when set
    var post: StripwayPost? {
        didSet {
            self.updateView()
        }
    }
    
    /// The user for this cell, does some UI stuff when set
    var user: StripwayUser? {
        didSet {
            updateUserInfo()
        }
    }
    
    /// The delegate for when we need to do things that we can't do from within the cell
    var delegate: HomeTableViewCellDelegate?
    /// The delegate used to pass url to View controller so it can perform generating of watermark image
    
    var downloadDelegate: DownloadWatermarkedPhotoDelegate?
    
    /// This is needed so we can know whether to register a single or double tap on the HomeVC
    var homeVCDoubleTapGesture: UITapGestureRecognizer?
    
    /// Setup needed before the cell is fully functional
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        for button in taggedButtons {
            button.isHidden = true
        }
        taggedVisible = false
        
        //Check if tags are empty
        
        guard let post = post else {return}
        
        if(post.tags.isEmpty){
            
            tagView.isHidden = true
            tagView.alpha = 0
            
        }else{
            
            tagView.isHidden = false
            tagView.alpha = 1
        }
        
        myScrollView.layoutIfNeeded()
        if let shouldHideOverlay = shouldHideOverlay {
            if shouldHideOverlay {
                hidePhotoOverlay()
            } else {
                showPhotoOverlay()
            }
        }
        
        
        tagViewList.delegate = self
        
        
        profileImageView.layer.cornerRadius = 20
        self.topView.alpha = 0.0
        self.fanMenu.alpha = 0.0
        
        captionTextView.delegate = self
        editableTextView.delegate = self
        
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(likeButtonPressed))
        likeImageView.addGestureRecognizer(likeTapGesture)
        
        let commentTapGesture = UITapGestureRecognizer(target: self, action: #selector(commentButtonPressed))
        commentImageView.addGestureRecognizer(commentTapGesture)
        
        let repostTapGesture = UITapGestureRecognizer(target: self, action: #selector(repostButtonPressed))
        repostImageView.addGestureRecognizer(repostTapGesture)
        
        let bookmarkTapGesture = UITapGestureRecognizer(target: self, action: #selector(bookmarkButtonPressed))
        bookmarkImageView.addGestureRecognizer(bookmarkTapGesture)
        
        let postImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(showImage))
        contentView.addGestureRecognizer(postImageTapGesture)
                
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(showPopUp))
        longPressRecognizer.minimumPressDuration = 0.2
        if post.photoURL == "" {
            contentView.addGestureRecognizer(longPressRecognizer)
        } else {
            self.postImageView.addGestureRecognizer(longPressRecognizer)
        }
        if let doubleTap = homeVCDoubleTapGesture {
            print("DOUBLETAP: adding the require toFail stuff in PostTableViewCell")
            postImageTapGesture.delaysTouchesBegan = true
            postImageTapGesture.require(toFail: doubleTap)
        } else {
            print("DOUBLETAP: NOT adding the require toFail stuff in PostTableViewCell")
        }
    }
    
    
    
    //set caption
    //var i = 0
    func setTag(_ hidePageControl: Bool = false){
        self.pageControll.isHidden = hidePageControl
        tagViewList.delegate = self
        tagViewList.removeAllTags()
        tagViewList.textFont = UIFont.systemFont(ofSize: 14)
        tagViewList.alignment = .center
        for item in tagArr {
            tagViewList.addTag("#\(item)")
        }
        
        textViewCaption.backgroundColor = .clear
        if self.post?.captionBgColorCode == "#000000" {
            
            textViewCaption.textColor = .white
            viewHashTagContnr.backgroundColor = .black
            viewCaptionContner.backgroundColor = .black
            //
            tagViewList.borderColor = .white
            tagViewList.textColor = .white
            lblHashText.textColor = .white
        }else {
            textViewCaption.textColor = .black
            viewHashTagContnr.backgroundColor = .white
            viewCaptionContner.backgroundColor = .white
            tagViewList.borderColor = .black
            tagViewList.textColor = .black
            lblHashText.textColor = .black
        }
        
        
        textViewCaption.isEditable = false
        textViewCaption.text = captionText
        self.textViewCaption.fitTextToBounds()
        self.textViewCaption.alignTextVerticallyInContainer()
        let height = ceil(textViewCaption.contentSize.height) // ceil to avoid decimal
//        if height != heightConstantOfCaptionText.constant && viewCaptionContner.frame.height > heightConstantOfCaptionText.constant { // set when height changed
            heightConstantOfCaptionText.constant = height
            textViewCaption.isScrollEnabled = true
            textViewCaption.setContentOffset(CGPoint.zero, animated: false) // scroll to top to avoid "wrong contentOffset" artefact when line count changes
//        }
    }
    
    /// Called when the post is set, just some UI setup
    func updateView() {
        hashTag = ""
        captionText = ""
        tagArr.removeAll()
        formatUsernameLabel()
        captionTextView.text = ""//self.post?.caption
        editableTextView.text = self.post?.caption
        editableTextView.isHidden = true // hide caption
        captionTextView.isHidden = true
        captionTextView.resolveHashtagsAndMentions()
        
        //Rj
        self.viewHashTagContnr.isHidden = true
        self.viewCaptionContner.isHidden = true
        self.pageControll.isHidden = true
        self.postImageView.isHidden = false
        self.viewHashTagContnr.backgroundColor = .clear
        self.viewCaptionContner.backgroundColor = .clear
        
        if self.post?.caption == "" || self.post?.caption == nil {
            self.myScrollView.contentOffset.x = 0// only image
            self.pageControll.isHidden = true
            print("Image only")
        } else {
            var trimText = ""
            trimText = self.post?.caption.trimNewLine() ?? ""
            print("After trimmed text -->>\(trimText)")
            let arrObj = trimText.getHasTagPrefixesObjArr()
            if arrObj.count > 0 {
                for text in arrObj{
                    
                    if text.prefix == nil {
                        captionText = (captionText) + text.text
                        captionText = captionText + " "
                    }else {
                        hashTag = hashTag  + text.text
                        hashTag = hashTag + " "
                        tagArr.append(text.text)
                    }
                }
                
                captionText = post?.caption ?? ""
                tagArr = post?.hashTags ?? []
                self.postImageView.isHidden = self.post?.photoURL == ""
                if post?.photoURL == "" || post?.photoURL == nil {
                    DispatchQueue.main.async {
                        self.myScrollView.contentOffset.x = SCREEN_WIDTH
                        self.viewCaptionContner.isHidden = false
                        //show caption
                        self.viewHashTagContnr.isHidden = false
                        self.postImageView.isHidden = true
                        self.pageControll.isHidden = false
                        let tagFound = self.tagArr.count != 0
                        self.pageControll.numberOfPages = tagFound ? 2 : 1
                        self.pageControll.currentPage = tagFound  ? 2 : 1
                        self.myScrollView.isUserInteractionEnabled = tagFound  ? true : false
                        self.setTag(!tagFound)
                    }
                } else {
                    self.myScrollView.isUserInteractionEnabled = true
                    self.pageControll.isHidden = false
                    if captionText != "" && tagArr.count != 0 {
                        DispatchQueue.main.async {
                            self.viewHashTagContnr.isHidden = false
                            self.viewCaptionContner.isHidden = false
                            self.myScrollView.contentOffset.x = SCREEN_WIDTH * 2 // hash tag and caption
                            self.pageControll.numberOfPages = 3
                            self.pageControll.currentPage = 3
                            self.setTag()
                        }
                    } else if captionText != "" && tagArr.count == 0 {
                        DispatchQueue.main.async {
                            self.myScrollView.contentOffset.x = SCREEN_WIDTH
                            self.viewHashTagContnr.isHidden = true
                            self.viewCaptionContner.isHidden = false
                            self.pageControll.numberOfPages = 2
                            self.pageControll.currentPage = 2
                            self.setTag()
                        }
                    } else if captionText == "" && tagArr.count != 0 {
                        DispatchQueue.main.async {
                            self.viewHashTagContnr.isHidden = false
                            self.viewCaptionContner.isHidden = true
                            self.myScrollView.contentOffset.x = SCREEN_WIDTH
                            self.pageControll.numberOfPages = 2
                            self.pageControll.currentPage = 2
                            self.setTag()
                        }
                    }
                    
                }
            }
        }
        self.layoutIfNeeded()
        self.setPostImage()
        
        API.Comment.observeCommentCount(forPostID: post!.postID) { (numberOfComments) in
            self.commentsNumberButton.setTitle("\(numberOfComments)", for: .normal)
        }
        
        updateLike(post: post!, justLoading: true)
        updateRepost(post: post!)
        updateBookmark(post: post!)
        timestampLabel.baselineAdjustment = .alignCenters
        timestampLabel.text = self.post!.timestamp.convertToTimestamp()        
        

    }
    
    
    //Set post image
    func setPostImage() {
        // Could probably just use an aspect ratio constraint and set the constant equal to ratio, but
        if post?.photoURL == "" {return}
        //TODO: Fastly -- add
        var photoURLString = ""
        
        let ratio = post!.imageAspectRatio
        
        if post?.thumbURL != nil {
            photoURLString = post!.photoURL
            print("this never is \(photoURLString)")
        }
        else {
            photoURLString = post!.photoURL
        }
        
        if photoURLString != "" {
            postImageView.alpha = 1.0
            
            if API.Post.newPost != nil {
                
                
                if self.post?.postID == API.Post.newPost.postID {
                    print(photoURLString)
                    postImageView.sd_setImage(with: URL(string: photoURLString), placeholderImage: API.Post.newPost.postImage, options: .retryFailed ){ (_, _, _, _) in
                    }
                }
                else {
                    postImageView.sd_setImage(with: URL(string: photoURLString)) { (image, error, _, _) in
                        guard let image = image else { return }
                        let imageRatio = image.size.width / image.size.height
                        print("ANDREWTEST 2: Just double checking the image aspect ratio: \(imageRatio) and this is the cell aspect ratio: \(ratio)")
                    }
                }
            }
            else {
                
                postImageView.sd_setImage(with: URL(string: photoURLString)) { (image, error, _, _) in
                    
                    guard let image = image else { return }
                    let imageRatio = image.size.width / image.size.height
                    print("ANDREWTEST 3: Just double checking the image aspect ratio: \(imageRatio) and this is the cell aspect ratio: \(ratio)")
                    
                    if self.post?.photoURL != nil && self.post?.thumbURL == nil{
                        print("image width height ", image.size.width, image.size.height)
                        API.Post.addMissingThumbnail(postWithID: self.post!.postID, forPostURL: self.post!.photoURL, forWidth: Int(image.size.width*0.5), forHeight: Int(image.size.height*0.5))
                    }
                }
            }
        }
        else if post?.postImage != nil {
            postImageView.image = post?.postImage
            postImageView.alpha = 0.4
        }
    }
    
    /// Called when the user is set, just some UI setup
    func updateUserInfo() {
        formatUsernameLabel()
        if let photoURLString = user?.profileImageURL {
            //            profileImageView.sd_setImage(with: URL(string: photoURLString), completed: nil)
            profileImageView.showLoading()
            profileImageView.sd_setImage(with: URL(string: photoURLString)) { (outImg, error, type, url) in
                self.profileImageView.hideLoading()
                self.popProfileImageView.image = outImg
            }
        }
        
        API.Follow.isFollowing(userID: user!.uid) { (value) in
            self.user!.isFollowing = value
        }
    }
    
    /// Formats the username label to include the user and strip name
    func formatUsernameLabel() {
        if let post = post, let user = user {
            let boldText = user.username
            let attrs = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17)]
            let popAttrs = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Medium", size: 27)]
            
            if user.isVerified {
                verifiedImageView.isHidden = false
            }else{
                verifiedImageView.isHidden = true
            }
            
            let attributedString = NSMutableAttributedString(string: boldText, attributes: attrs as [NSAttributedString.Key : Any])
            nameLabel_Title.attributedText = attributedString
            
            let popAttributedString = NSMutableAttributedString(string: boldText, attributes: popAttrs as [NSAttributedString.Key : Any])
            
            popNameLbl.attributedText = popAttributedString
            
            let normalText = "\nadded to "
            let attrs2 = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Regular", size: 17)]
            let normalString = NSMutableAttributedString(string: normalText, attributes: attrs2 as [NSAttributedString.Key : Any])
            
            let boldText2 = post.stripName
            let attributedString2 = NSMutableAttributedString(string: boldText2, attributes: attrs as [NSAttributedString.Key : Any])
            
            attributedString.append(normalString)
            attributedString.append(attributedString2)
            
            nameLabel.attributedText = attributedString
        }
    }
    
    /// Segues to the user's profile when their photo/name are tapped
    @IBAction func usernameProfileButtonPressed(_ sender: Any) {
        print("Segue to user's profile")
        if user != nil {
            delegate?.usernameProfileButtonPressed(user: user!)
        }
    }
    
    @IBAction func userStripeButtonPressed(_ sender: Any) {
        print("Segue to user's strip")
        API.Strip.observeStrip(withID: post?.stripID ?? "") { (strip) in
            self.delegate?.userStripeButtonPressed(user: self.user!, strip: strip)
        }
    }
    
    /// Called in ViewPostViewController when that post is being edited, takes care of the UI stuff
    func startEditing() {
        print("BUG3: Started editing post")
        captionTextView.isHidden = true
        postImageView.isUserInteractionEnabled = false
        ellipsisButton.isHidden = true
        editableTextView.isEditable = true
        editableTextView.isHidden = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        myScrollView.delegate = self
        //myScrollView.contentOffset.x = UIScreen.main.bounds.width
        
        self.layoutIfNeeded()
        self.fanMenu.alpha = 0.0
        textViewCaption.alignTextVerticallyInContainer()
    }
    
    /// Shortens the caption and gives the read more option, this is never called from ViewPostViewController because
    /// it's fine if we have the full caption there
    func truncateCaption() {
        captionTextView.resolveHashtagsAndMentions()
        captionTextView.shouldTrim = true
        captionTextView.maximumNumberOfLines = 2
        captionTextView.attributedReadMoreText = NSAttributedString(string: "... read more", attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
        captionTextView.attributedReadLessText = NSAttributedString(string: " read less", attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 17)!, NSAttributedString.Key.foregroundColor: UIColor.white])
        captionTextView.font = UIFont(name: "AvenirNext-DemiBold", size: 17)
        captionTextView.textColor = UIColor.white
    }
    
    /// Updates the UI on this post to match the likes of the parameter passed into this method
    func updateLike(post: StripwayPost, justLoading: Bool) {
        if post.isLiked {
            likeImageView.image = #imageLiteral(resourceName: "Like Picture Selected")
            if(!justLoading){
                if let bigLikeImageV = likeImageView {
                    UIView.animate(withDuration: 0.02, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                        bigLikeImageV.alpha = 0.9
                    }) { finished in
                        bigLikeImageV.alpha = 1.0
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
                
            }
        } else {
            likeImageView.image = #imageLiteral(resourceName: "Like Picture")
        }
        likesNumberButton.setTitle("\(post.likeCount)", for: .normal)
    }
    
    /// Updates the UI on this post to match the reposts of the parameter passed into this method
    func updateRepost(post: StripwayPost) {
        if post.isReposted {
            repostImageView.image = #imageLiteral(resourceName: "Repost Picture Selected")
        } else {
            repostImageView.image = #imageLiteral(resourceName: "Repost Picture")
        }
        repostsNumberButton.setTitle("\(post.repostCount)", for: .normal)
    }
    
    /// Updates the UI on this post to match the bookmarks of the parameter passed into this method
    func updateBookmark(post: StripwayPost) {
        if post.isBookmarked {
            bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture Selected")
        } else {
            bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture")
        }
    }
    
    /// Changes the like in the database and updates the UI
    @objc func likeButtonPressed() {
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        likeImageView.isUserInteractionEnabled = false
        API.Post.incrementLikes(postID: post!.postID) { (post, error) in
            self.likeImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateLike(post: post, justLoading: false)
                self.post?.likes = post.likes
                self.post?.isLiked = post.isLiked
                self.post?.likeCount = post.likeCount
            }
        }
        
    }
    
    /// Changes the repost in the database and updates the UI
    @objc func repostButtonPressed() {
        repostImageView.isUserInteractionEnabled = false
        API.Post.incrementReposts(postID: post!.postID) { (post, error) in
            self.repostImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateRepost(post: post)
                self.post?.reposts = post.reposts
                self.post?.isReposted = post.isReposted
                self.post?.repostCount = post.repostCount
            }
        }
        
    }
    
    /// Changes the bookmark in the database and updates the UI
    @objc func bookmarkButtonPressed() {
        print("bookmark button pressed")
        bookmarkImageView.isUserInteractionEnabled = false
        
        API.Post.incrementBookmarks(postID: post!.postID) { (post, error) in
            self.bookmarkImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let post = post {
                self.updateBookmark(post: post)
                self.post?.bookmarks = post.bookmarks
                self.post?.isBookmarked = post.isBookmarked
                self.post?.bookmarkCount = post.bookmarkCount
            }
        }
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Segues to the PeopleViewController (from the delegate) and shows the likers of the post
    @IBAction func likesNumberButtonPressed(_ sender: Any) {
        delegate?.viewLikersButtonPressed(post: post!)
    }
    
    /// Segues to the PeopleViewController (from the delegate) and shows the reposters of the post
    @IBAction func repostsNumberButtonPressed(_ sender: Any) {
        delegate?.viewRepostersButtonPressed(post: post!)
    }
    
    /// Segues to the CommentViewController (from the delegate) and shows the comments for the post
    @IBAction func commentsNumberButtonPressed(_ sender: Any) {
        self.commentButtonPressed()
    }
    
    @IBAction func toggleSpotted(_ sender: UIButton) {
        
        if !taggedVisible {//show
            guard let post = post else {return}
            for (_,value) in post.tags{
                if let value = value as? [String:Any], let x = value["x"] as? CGFloat, let y = value["y"] as? CGFloat, let username = value["username"] as? String{
                    
                    let myText = username
                    
                    let rect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    let labelSize = myText.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font:  UIFont.systemFont(ofSize: 14)], context: nil)
                    
                    
                    
                    print("Value x: \(x) and value y \(y)")
                    taggedButton = UIButton(frame: CGRect(x: x, y: y+200, width: labelSize.width + 30, height: 28))
                    taggedButton.setTitle("@" + username, for: .normal)
                    taggedButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                    var titleColor = UIColor.white
                    var bgColor = UIColor.black
                    if post.photoURL == "" {
                        if post.captionBgColorCode == "#000000" { // caption bg = black
                            bgColor = .white
                            titleColor = .black
                        } else {
                            bgColor = .black
                            titleColor = .white
                        }
                    }
                    taggedButton.setTitleColor(titleColor, for: .normal)
                    taggedButton.backgroundColor = bgColor
                    taggedButton.titleLabel?.adjustsFontSizeToFitWidth = true
                    taggedButton.alpha = 0.7
                    taggedButton.layer.cornerRadius = 14
                    taggedButton.clipsToBounds = true
//                    if post.photoURL != "" {
//                        postImageView.addSubview(taggedButton)
//                    } else {
                        contentView.addSubview(taggedButton)
                        contentView.bringSubviewToFront(taggedButton)
//                    }
                    
                    taggedButton.isUserInteractionEnabled = true
                    
                    
                    //Set listener
                    let tapOnUsername =  TaggedButtonUIGesture(target: self, action: #selector(usernameTagPressed(_:)))
                    tapOnUsername.data = username
                    
                    taggedButton.addGestureRecognizer(tapOnUsername)
                    
                    taggedButtons.append(taggedButton)
                }
            }
            
            taggedVisible = true
        }else{//hide
            
            _ = taggedButtons.map({$0.removeFromSuperview()})
            taggedButtons = []
            
            taggedVisible = false
        }
        
    }
    
    //Tag pressed
    @objc func usernameTagPressed(_ sender: TaggedButtonUIGesture){
        
        API.User.getUser(withUsername: sender.data!) { (user) in
            if let user = user {
                
                let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                let postViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.passedUser = user
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
            
        }
        
        
    }
    
    /// Segues to the CommentViewController (from the delegate) and shows the comments for the post
    @objc func commentButtonPressed() {
        delegate?.commentButtonPressed(post: post!)
    }
    
    func setPopUpConstraint(_ point:CGPoint) {
        
        shareLeft = shareLeftInitial
        shareTop = shareTopInitial
        dmLeft = dmLeftInitial
        dmTop = dmTopInitial
        bookLeft = bookLeftInitial
        bookTop = bookTopInitial
        repostLeft = repostLeftInitial
        repostTop = repostTopInitial
        
    }
    
    func setPopButtonPostions() {
        self.shareLeftConstraint.constant = self.shareLeft
        self.shareTopConstraint.constant = self.shareTop
        self.dmTopConstraint.constant = self.dmTop
        self.dmLeftConstraint.constant = self.dmLeft
        self.bookLeftConstraint.constant = self.bookLeft
        self.bookTopConstraint.constant = self.bookTop
        self.repostLeftConstraint.constant = self.repostLeft
        self.repostTopConstraint.constant = self.repostTop
    }
    
    func beginShowPopUpMenu(_ point:CGPoint) {
//        let maxTopBounds = min(fanMenu.bounds.height + infoView.bounds.height, postImageView.bounds.height - 20.0)
        
        self.popMenuLeftConstraint.constant = point.x - self.fanMenu.bounds.width / 2
        self.popMenuTopConstraint.constant = point.y - self.fanMenu.bounds.height / 2
        self.dmDistance = 0.0
        self.shareDistance = 0.0
        self.bookDistance = 0.0
        self.repostDistance = 0.0
        
        self.fanMenu.alpha = 1.0
        self.topView.alpha = 1.0
        self.popUpCenter = point
        self.dmWidthConstraint.constant = self.popUpButtonWidth
        self.shareWidthConstraint.constant = self.popUpButtonWidth
        self.bookWidthConstraint.constant = self.popUpButtonWidth
        self.repostWidthConstraint.constant = self.popUpButtonWidth
        self.setPopUpConstraint(point)
        
        
        
        self.popInfoLeftConstraint.constant = UIScreen.main.bounds.width - 30.0 - self.infoView.bounds.width
        if frame.size.height - point.y > 250 {
            self.popInfoTopConstraint.constant = 20
        } else {
            self.popInfoTopConstraint.constant = -20 - fanMenu.frame.size.height - infoView.frame.size.height
        }
        UIView.animate(withDuration: 0.1, animations: {
            
            self.shareLeftConstraint.constant = self.shareLeft
            self.shareTopConstraint.constant = self.shareTop - self.dx
            self.btnSharePost.alpha = self.animationAlpha
            
            self.dmLeftConstraint.constant = self.dmLeft - self.dx
            self.dmTopConstraint.constant = self.dmTop
            self.btnDM.alpha = self.animationAlpha
            
            self.bookLeftConstraint.constant = self.bookLeft - self.dx
            self.bookTopConstraint.constant = self.bookTop
            self.btnBookMark.alpha = self.animationAlpha
            
            self.repostLeftConstraint.constant = self.repostLeft
            self.repostTopConstraint.constant = self.repostTop - self.dx
            self.btnRePost.alpha = self.animationAlpha
            
        }, completion: { finished in
            self.setPopButtonPostions()
            self.btnDM.alpha = 1.0
            self.btnSharePost.alpha = 1.0
            self.btnBookMark.alpha = 1.0
            self.btnRePost.alpha = 1.0
            self.showingPopUp = true
        })
        
        sharePostRect =
            CGRect(x: popUpCenter.x - focusWidthConstraint.constant / 2 + shareLeftInitial, y: popUpCenter.y + focusWidthConstraint.constant / 2 + shareTopInitial, width: shareWidthConstraint.constant, height: shareWidthConstraint.constant)
        
        DMRect = CGRect(x: popUpCenter.x + focusWidthConstraint.constant / 2 + dmLeftInitial, y: popUpCenter.y - focusWidthConstraint.constant / 2 - dmTopInitial, width: dmWidthConstraint.constant, height: dmWidthConstraint.constant)
        
        bookMarkRect = CGRect(x: popUpCenter.x - focusWidthConstraint.constant / 2 - bookWidthConstraint.constant - bookLeftInitial, y: popUpCenter.y - focusWidthConstraint.constant / 2 + dmTopInitial, width: bookWidthConstraint.constant, height: bookWidthConstraint.constant)
        
        rePostRect = CGRect(x: popUpCenter.x - focusWidthConstraint.constant / 2 + shareLeftInitial, y: popUpCenter.y - focusWidthConstraint.constant / 2 - repostWidthConstraint.constant - repostTopInitial, width: repostWidthConstraint.constant, height: repostWidthConstraint.constant)
        
        
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    func endShowPopUpMenu(_ point:CGPoint) {
        
        if sharePostRect.contains(point) {
            self.post?.postImage = self.postImageView.image
            self.fanMenu.alpha = 0.0
            self.topView.alpha = 0.0
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            self.delegate?.sharePost(post: self.post!)
        }
        else if DMRect.contains(point) {
            self.fanMenu.alpha = 0.0
            self.topView.alpha = 0.0
            print("fan menu direct message show")
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            self.delegate?.directMessage(user: self.user!)
        }
        else if bookMarkRect.contains(point) {
            self.fanMenu.alpha = 0.0
            self.topView.alpha = 0.0
            print("fan menu bookmark")
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            self.bookmarkButtonPressed()
        }
        else if rePostRect.contains(point) {
            self.fanMenu.alpha = 0.0
            self.topView.alpha = 0.0
            print("fan menu repost")
            let impact = UIImpactFeedbackGenerator()
            impact.impactOccurred()
            self.repostButtonPressed()
        }
        self.fanMenu.alpha = 0.0
        self.topView.alpha = 0.0
        
        self.showingPopUp = false
    }
    
    func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let xDist = a.x - b.x
        let yDist = a.y - b.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    func shakeShareButton(_ point:CGPoint, _ isIncrease:CGFloat) {
        self.shakingPopup = true
        let direction:CGFloat = (popUpCenter.x - sharePostRect.center.x)/(popUpCenter.y - sharePostRect.center.y)
        
        UIView.animate(withDuration: 1.0, delay: 0.1, options: .curveLinear,
                       animations: {
                        
                        self.shareLeftConstraint.constant = self.shareLeftConstraint.constant + isIncrease * direction
                        
                        if self.shareTop >= self.shareTopInitial {
                            self.shareTopConstraint.constant = max(self.shareTopConstraint.constant + isIncrease, self.shareTopInitial)
                        }
                        else {
                            
                            self.shareTopConstraint.constant = min(self.shareTopConstraint.constant - isIncrease, -self.shareTopInitial - self.focusWidthConstraint.constant - self.shareWidthConstraint.constant)
                        }
                       },
                       completion: { finished in
                        
                        if self.shareWidthConstraint.constant >= self.popUpButtonWidth {
                            self.shareWidthConstraint.constant = max(min(self.shareWidthConstraint.constant + isIncrease, self.popUpButtonWidth * 1.3), self.popUpButtonWidth)
                        }
                        self.shakingPopup = false
                       })
    }
    
    func shakeDMButton(_ point:CGPoint, _ isIncrease:CGFloat) {
        self.shakingPopup = true
        let direction:CGFloat = (popUpCenter.x - DMRect.center.x)/(popUpCenter.y - DMRect.center.y)
        
        UIView.animate(withDuration: 1.0, delay: 0.1, options: .curveLinear,
                       animations: {
                        if self.dmLeft >= self.dmLeftInitial {
                            self.dmLeftConstraint.constant = max(min(self.dmLeftConstraint.constant + isIncrease * direction * self.shakeBandX, self.dmLeftInitial + 12.0), self.dmLeft)
                        }
                        else {
                            
                            let x = -self.dmLeftInitial - self.focusWidthConstraint.constant - self.dmWidthConstraint.constant
                            self.dmLeftConstraint.constant = min(max(self.dmLeftConstraint.constant + isIncrease * direction * self.shakeBandX, x - 12.0), x)
                        }
                        
                        self.dmTopConstraint.constant = self.dmTopConstraint.constant + isIncrease * self.shakeBandX
                       }, completion: { finished in
                        if self.dmWidthConstraint.constant >= self.popUpButtonWidth {
                            self.dmWidthConstraint.constant = max(min(self.dmWidthConstraint.constant + isIncrease * 0.5, self.popUpButtonWidth * 1.3), self.popUpButtonWidth)
                        }
                        self.shakingPopup = false
                       })
    }
    
    func shakeBookButton(_ point:CGPoint, _ isIncrease:CGFloat) {
        self.shakingPopup = true
        let direction:CGFloat = (popUpCenter.x - bookMarkRect.center.x)/(popUpCenter.y - bookMarkRect.center.y)
        
        UIView.animate(withDuration: 1.0, delay: 0.1, options: .curveLinear,
                       animations: {
                        
                        if self.bookLeft >= self.bookLeftInitial {
                            self.bookLeftConstraint.constant = max(min(self.bookLeftConstraint.constant + isIncrease * direction * self.shakeBandX, self.bookLeftInitial + 12.0), self.bookLeft)
                        }
                        else {
                            
                            let x = -self.bookLeftInitial - self.focusWidthConstraint.constant - self.bookWidthConstraint.constant
                            self.bookLeftConstraint.constant = min(max(self.bookLeftConstraint.constant + isIncrease * direction * self.shakeBandX, x - 12.0), x)
                        }
                        
                        self.bookTopConstraint.constant = self.bookTopConstraint.constant + isIncrease * self.shakeBandX
                       },
                       completion: { finished in
                        
                        if self.bookWidthConstraint.constant >= self.popUpButtonWidth {
                            self.bookWidthConstraint.constant = max(min(self.bookWidthConstraint.constant + isIncrease * 0.5, self.popUpButtonWidth * 1.3), self.popUpButtonWidth)
                        }
                        self.shakingPopup = false
                       })
    }
    
    func shakeRepostButton(_ point:CGPoint, _ isIncrease:CGFloat) {
        self.shakingPopup = true
        let direction:CGFloat = (popUpCenter.x - rePostRect.center.x)/(popUpCenter.y - rePostRect.center.y)
        
        UIView.animate(withDuration: 1.0, delay: 0.1, options: .curveLinear,
                       animations: {
                        
                        self.repostLeftConstraint.constant = self.repostLeftConstraint.constant + isIncrease * direction
                        
                        if self.repostTop >= self.repostTopInitial {
                            self.repostTopConstraint.constant = max(self.repostTopConstraint.constant + isIncrease, self.repostTopInitial)
                        }
                        else {
                            
                            self.repostTopConstraint.constant = min(self.repostTopConstraint.constant - isIncrease, -self.repostTopInitial - self.focusWidthConstraint.constant - self.repostWidthConstraint.constant)
                        }
                       },
                       completion: { finished in
                        
                        if self.repostWidthConstraint.constant >= self.popUpButtonWidth {
                            self.repostWidthConstraint.constant = max(min(self.repostWidthConstraint.constant + isIncrease, self.popUpButtonWidth * 1.3), self.popUpButtonWidth)
                        }
                        self.shakingPopup = false
                       })
    }
    
    func movingShowPopUpMenu(_ point:CGPoint) {
        
        if self.showingPopUp == false {
            return
        }
        var isDMIncrease:CGFloat = 1
        if distance(point, DMRect.center) < self.dmDistance {
            isDMIncrease = 1
        }
        else {
            isDMIncrease = -1
        }
        
        var isShareIncrease:CGFloat = 1
        if distance(point, sharePostRect.center) < self.shareDistance {
            isShareIncrease = 1
        }
        else {
            isShareIncrease = -1
        }
        
        var isBookIncrease:CGFloat = 1
        if distance(point, bookMarkRect.center) < self.bookDistance {
            isBookIncrease = 1
        }
        else {
            isBookIncrease = -1
        }
        
        var isRepostIncrease:CGFloat = 1
        if distance(point, rePostRect.center) < self.repostDistance {
            isRepostIncrease = 1
        }
        else {
            isRepostIncrease = -1
        }
        
        dmDistance = distance(point, DMRect.center)
        shareDistance = distance(point, sharePostRect.center)
        bookDistance = distance(point, bookMarkRect.center)
        repostDistance = distance(point, rePostRect.center)
        if dmDistance < effectRadius {
            if self.shakingPopup == false {
                self.shakeDMButton(point, 0)
            }
        }
        
        if shareDistance < effectRadius {
            if self.shakingPopup == false {
                self.shakeShareButton(point, 0)
            }
        }
        
        if bookDistance < effectRadius {
            if self.shakingPopup == false {
                self.shakeBookButton(point, 0)
            }
        }
        
        if repostDistance < effectRadius {
            if self.shakingPopup == false {
                self.shakeRepostButton(point, 0)
            }
        }
        
        
        //to show/hide tip view
        if dmDistance < self.dmWidthConstraint.constant {
            self.infoView.alpha = 1.0
            self.popTipLabel.text = "DM User"
        }
        else if shareDistance < self.shareWidthConstraint.constant {
            self.infoView.alpha = 1.0
            self.popTipLabel.text = "Share Post"
        }
        else if bookDistance < self.bookWidthConstraint.constant {
            self.infoView.alpha = 1.0
            self.popTipLabel.text = "BookMark"
        }
        else if repostDistance < self.repostWidthConstraint.constant {
            self.infoView.alpha = 1.0
            self.popTipLabel.text = "RePost"
        }
        else {
            self.infoView.alpha = 0.0
        }
    }
    
    
    //show Pinterest+Twitter style pop up
    @objc func showPopUp(sender: UILongPressGestureRecognizer) {
        let point:CGPoint = sender.location(in: post?.photoURL != "" ? self.postImageView : contentView)
        
        if sender.state == UIGestureRecognizer.State.began {
            self.beginShowPopUpMenu(point)
        }
        else if sender.state == UIGestureRecognizer.State.ended {
            self.endShowPopUpMenu(point)
        }
        else if sender.state == UIGestureRecognizer.State.cancelled || sender.state == UIGestureRecognizer.State.failed {
            self.fanMenu.alpha = 0.0
            self.topView.alpha = 0.0
            self.showingPopUp = false
        }
        else {
            self.movingShowPopUpMenu(point)
        }
    }
    
    
    /// Shows the image full-screen when the postImageView is tapped, presesnts it from the delegate
    @objc func showImage() {}
    
    /// Resets some views so new cells don't have data from previous posts
    override func prepareForReuse() {
        super.prepareForReuse()
        
        let x = myScrollView.contentOffset.x
        let w = myScrollView.bounds.size.width
        pageControll.currentPage = Int(x/w)
        
        profileImageView.image = nil
        
        likeImageView.image = #imageLiteral(resourceName: "Like Picture")
        repostImageView.image = #imageLiteral(resourceName: "Repost Picture")
        bookmarkImageView.image = #imageLiteral(resourceName: "Save Picture")
        
        likesNumberButton.setTitle("0", for: .normal)
        repostsNumberButton.setTitle("0", for: .normal)
        
        
        
    }
    
    /// Options for a post depend on the user that presses the button
    @IBAction func ellipsisButtonPressed(_ sender: Any) {
        guard let user = user else { return }
        if user.isFollowing == nil { return }
        
        // Post owner can edit the post, everyone else can follow/unfollow/block
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if user.isCurrentUser {
            alertController.addAction(UIAlertAction(title: "Edit", style: .default, handler: { (action) in
                self.delegate?.startEditingPost(post: self.post!)
            }))
            alertController.addAction(UIAlertAction(title: "Delete Post", style: .default, handler: { (action) in
                let deleteAlert = UIAlertController(title: "Delete Post?", message: "Are you sure you want to delete this post? This cannot be undone.", preferredStyle: .alert)
                deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                deleteAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                    if let post = self.post {
                        API.Post.deletePost(post: post)
                        self.delegate?.postDeleted(post: post)
                    }
                }))
                self.delegate?.presentAlertController(alertController: deleteAlert, forCell: self)
            }))
        } else {
            if user.isFollowing! {
                alertController.addAction(UIAlertAction(title: "Unfollow", style: .default, handler: { (action) in
                    self.unfollowUser(user: user)
                }))
            } else {
                alertController.addAction(UIAlertAction(title: "Follow", style: .default, handler: { (action) in
                    self.followUser(user: user)
                }))
            }
            
            alertController.addAction(UIAlertAction(title: "Block User", style: .default, handler: { (action) in
                print("Should be blocking this user")
                API.Block.blockUser(withUID: user.uid)
            }))
            alertController.addAction(UIAlertAction(title: "Report Post", style: .default, handler: { (action) in
                print("Should be reporting this post")
                if let post = self.post {
                    API.Post.reportPost(post: post)
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "Share", style: .default, handler: { (action) in
            print("Should be reporting this post")
            
            
            if let post = self.post {
                
                let alertController1 = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                
                
                alertController1.addAction(UIAlertAction(title: "Share In App", style: .default, handler: { (action) in
                    
                    self.delegate?.presentPeopleSelectionController(post: post)
                    
                    
                }))
                if post.photoURL != "" {
                    alertController1.addAction(UIAlertAction(title: "Share Photo", style: .default, handler: { (action) in
                        
                        self.downloadDelegate?.generateImageWithWatermark(from: post.photoURL, of: user.username, post: post, onlyLink: false )
                        
                    }))
                }
                
                
                alertController1.addAction(UIAlertAction(title: "Copy URL", style: .default, handler: { (action) in
                    
                    self.downloadDelegate?.generateImageWithWatermark(from: post.photoURL, of: user.username, post: post, onlyLink: true )
                    
                    
                }))
                
                
                alertController1.addAction(UIAlertAction(title: "Back", style: .cancel, handler: { (action) in
                    
                    self.delegate?.presentAlertController(alertController: alertController, forCell: self)
                    
                }))
                alertController1.view.tintColor = UIColor.black
                self.delegate?.presentAlertController(alertController: alertController1, forCell: self)
                
            }
            
            
        }))
        
        
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.tintColor = UIColor.black
        delegate?.presentAlertController(alertController: alertController, forCell: self)
    }
    
    /// Current user follows the post owner
    func followUser(user: StripwayUser) {
        if user.isFollowing! == false {
            API.Follow.followAction(withUser: user.uid)
            user.isFollowing! = true
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    /// Current user unfollows the post owner
    func unfollowUser(user: StripwayUser) {
        print("Unfollowing \(user.username)")
        if user.isFollowing! == true {
            API.Follow.unfollowAction(withUser: user.uid)
            user.isFollowing! = false
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    /// Used in HomeViewController when double tapped
    func hidePhotoOverlay() {
        //        self.contentView.bringSubviewToFront(postImageView)
        //        profileImageView.isHidden = true
        //        nameLabel.isHidden = true
        captionTextView.isHidden = true
        tagView.isHidden = true
        editableTextView.isHidden = true
        timestampLabel.isHidden = true
        likeImageView.isHidden = true
        commentImageView.isHidden = true
        repostImageView.isHidden = true
        bookmarkImageView.isHidden = true
        ellipsisButton.isHidden = true
        likesNumberButton.isHidden = true
        commentsNumberButton.isHidden = true
        repostsNumberButton.isHidden = true
        topGradient.isHidden = true
        bottomGradient.isHidden = true
    }
    
    /// Used in HomeViewController when double tapped
    func showPhotoOverlay() {
        //        self.contentView.sendSubviewToBack(postImageView)
        //        profileImageView.isHidden = false
        //        nameLabel.isHidden = false
        
        //captionTextView.isHidden = false//Rj
        //editableTextView.isHidden = false//Rj
        timestampLabel.isHidden = false
        tagView.isHidden = false
        likeImageView.isHidden = false
        commentImageView.isHidden = false
        repostImageView.isHidden = false
        bookmarkImageView.isHidden = false
        ellipsisButton.isHidden = false
        likesNumberButton.isHidden = false
        commentsNumberButton.isHidden = false
        repostsNumberButton.isHidden = false
        topGradient.isHidden = false
        bottomGradient.isHidden = false
    }
    
}

extension HomeTableViewCell: UITextViewDelegate {
    
    /// Adjusts the caption view stuff when the text changes in it
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        adjustFrames()
        return true
    }
    
    /// Adjusts the caption view stuff when the text changes in it (not sure if calling it again here is necessary)
    /// Also passes the current word to the delegate
    func textViewDidChange(_ textView: UITextView) {
        adjustFrames()
        delegate?.currentWordBeingTyped(word: textView.currentWord)
        if textView == textViewCaption {
            let height = ceil(textView.contentSize.height) // ceil to avoid decimal
            
            if height != heightConstantOfCaptionText.constant && viewCaptionContner.frame.height > heightConstantOfCaptionText.constant { // set when height changed
                heightConstantOfCaptionText.constant = height
                textView.isScrollEnabled = true
                textView.setContentOffset(CGPoint.zero, animated: false) // scroll to top to avoid "wrong contentOffset" artefact when line count changes
            }
        }
    }
    
    /// This works but it's very CPU intensive os ideally find a better way
    /// Basically makes sure that we always know the location of the bottom of the textView
    func adjustFrames() {
        var frame = self.editableTextView.frame
        if captionTextView.text.isEmpty {
            frame.size.height = 0
        } else {
            frame.size.height = self.editableTextView.contentSize.height
        }
        self.editableTextView.frame = frame
        captionMaxY = editableTextView.frame.maxY
        delegate?.textViewChanged()
    }
    
    /// Allows user to interact with hashtags and mentions and segues to the appropriate screen from the delegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        var newURL = URL.absoluteString
        let segueType = newURL.prefix(4)
        newURL.removeFirst(5)
        if segueType == "hash" {
            delegate?.segueToHashtag(hashtag: newURL)
        } else if segueType == "user" {
            delegate?.segueToProfileFor(username: newURL)
        }
        return false
    }
}

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

protocol HomeTableViewCellDelegate {
    func sharePost(post:StripwayPost)
    func directMessage(user:StripwayUser)
    func presentImageVC(imageVC: NYTPhotosViewController)
    func presentPeopleSelectionController(post: StripwayPost)
    func textViewChanged()
    func commentButtonPressed(post: StripwayPost)
    func usernameProfileButtonPressed(user: StripwayUser)
    func userStripeButtonPressed(user: StripwayUser, strip: StripwayStrip)
    func viewLikersButtonPressed(post: StripwayPost)
    func viewRepostersButtonPressed(post: StripwayPost)
    func presentAlertController(alertController: UIAlertController, forCell cell: HomeTableViewCell)
    func startEditingPost(post: StripwayPost)
    func segueToHashtag(hashtag: String)
    func segueToProfileFor(username: String)
    func currentWordBeingTyped(word: String?)
    func postDeleted(post: StripwayPost)
}

protocol DownloadWatermarkedPhotoDelegate {
    
    func generateImageWithWatermark(from photoURL: String, of username:String, post: StripwayPost?, onlyLink: Bool)
}

extension CGRect {
    var center: CGPoint { return CGPoint(x: midX, y: midY) }
}



extension HomeTableViewCell : UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("Lavaneesh :- \(scrollView.contentOffset.x)")
        //self.post = postsModelArr[scrollView.tag]
        //        DispatchQueue.main.async {
        //            UIView.animate(withDuration: 0.4, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
        //                self.myScrollView.center.x = self.myScrollView.center.x - 1
        //            }, completion: nil)
        //        }
        let x = myScrollView.contentOffset.x
        let w = myScrollView.bounds.size.width
        pageControll.currentPage = Int(x/w)
        
    }
    
}
extension HomeTableViewCell:TagListViewDelegate {
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        
        let trimmedTitle = title.replacingOccurrences(of: "#", with: "")
        delegate?.segueToHashtag(hashtag: trimmedTitle)
    }
}

class TaggedButtonUIGesture:  UITapGestureRecognizer {
    
    var data: String?
}
