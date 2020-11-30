//
//  CommentTableViewHeader.swift
//  Stripway
//
//  Created by iBinh on 10/5/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit

class CommentTableViewHeader: UITableViewHeaderFooterView {
    var usernameLabel: UIButton = UIButton()
    var commentTextView: UITextView = UITextView()
    var profileImageView: UIButton = UIButton()
    var likeImageView: UIButton = UIButton()
    var likesNumberLabel: UILabel = UILabel()
    var timestampLabel: UILabel = UILabel()
    var viewRepliesButton: UIButton = UIButton()
    var verifiedImage = UIImageView()
    var viewRepliesButtonHeight: NSLayoutConstraint!
    var longPress: UILongPressGestureRecognizer!
    var singleTap: UITapGestureRecognizer!
    var timestampBottom: NSLayoutConstraint!
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    func setupViews() {
        
        verifiedImage.image = UIImage(named: "verified")
        
        viewRepliesButton.setTitleColor(.darkGray, for: .normal)
        viewRepliesButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        viewRepliesButton.addTarget(self, action: #selector(btnViewRepliesClicked), for: .touchUpInside)
        viewRepliesButton.setImage(UIImage(named: "down-arrow"), for: .normal)
        viewRepliesButton.semanticContentAttribute = .forceRightToLeft
        
        usernameLabel.contentHorizontalAlignment = .left
        usernameLabel.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        usernameLabel.setTitleColor(.black, for: .normal)
        
        timestampLabel.font = .systemFont(ofSize: 12)
        timestampLabel.textColor = .darkGray
        
        likesNumberLabel.textColor = .lightGray
        likesNumberLabel.font = .systemFont(ofSize: 12)
                
        commentTextView.isEditable = true
        commentTextView.isScrollEnabled = false
        commentTextView.showsVerticalScrollIndicator = false
        commentTextView.showsHorizontalScrollIndicator = false
        commentTextView.bouncesZoom = false
        commentTextView.bounces = false
        commentTextView.font = .systemFont(ofSize: 14)        
        
        let marginGuide = contentView.layoutMarginsGuide

        contentView.addSubview(profileImageView)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.leadingAnchor.constraint(equalTo: marginGuide.leadingAnchor, constant: 12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 36).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        profileImageView.topAnchor.constraint(equalTo: marginGuide.topAnchor).isActive = true
        
        contentView.addSubview(usernameLabel)
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor).isActive = true
        usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12).isActive = true
        usernameLabel.heightAnchor.constraint(equalToConstant: 21).isActive = true
        
        contentView.addSubview(verifiedImage)
        verifiedImage.translatesAutoresizingMaskIntoConstraints = false
        verifiedImage.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 4).isActive = true
        verifiedImage.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor).isActive = true
//        verifiedImage.topAnchor.constraint(equalTo: usernameLabel.topAnchor).isActive = true
        verifiedImage.widthAnchor.constraint(equalToConstant: 20).isActive = true
        verifiedImage.heightAnchor.constraint(equalToConstant: 20).isActive = true

        contentView.addSubview(commentTextView)
        commentTextView.translatesAutoresizingMaskIntoConstraints = false
        commentTextView.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor, constant: -4).isActive = true
        commentTextView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor).isActive = true
        
        contentView.addSubview(likeImageView)
        likeImageView.translatesAutoresizingMaskIntoConstraints = false
        likeImageView.topAnchor.constraint(equalTo: marginGuide.topAnchor, constant: 33).isActive = true
        likeImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        likeImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        likeImageView.trailingAnchor.constraint(equalTo: marginGuide.trailingAnchor).isActive = true
        
        contentView.addSubview(likesNumberLabel)
        likesNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        likesNumberLabel.topAnchor.constraint(equalTo: likeImageView.topAnchor, constant: 2).isActive = true
        likesNumberLabel.trailingAnchor.constraint(equalTo: likeImageView.leadingAnchor, constant: -2).isActive = true
        likesNumberLabel.widthAnchor.constraint(equalToConstant: 16).isActive = true
        likesNumberLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true
        likesNumberLabel.leadingAnchor.constraint(equalTo: commentTextView.trailingAnchor, constant: 8).isActive = true
        
        contentView.addSubview(timestampLabel)
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.topAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: 2).isActive = true
        timestampLabel.leadingAnchor.constraint(equalTo: commentTextView.leadingAnchor, constant: 4).isActive = true
        timestampLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        timestampLabel.heightAnchor.constraint(equalToConstant: 10).isActive = true
        
        contentView.addSubview(viewRepliesButton)
        viewRepliesButton.translatesAutoresizingMaskIntoConstraints = false
        viewRepliesButton.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor, constant: 8).isActive = true
        viewRepliesButtonHeight = viewRepliesButton.heightAnchor.constraint(equalToConstant: 18)
        viewRepliesButtonHeight.isActive = true
        viewRepliesButton.leadingAnchor.constraint(equalTo: timestampLabel.leadingAnchor).isActive = true
        viewRepliesButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var postAuthorUID: String!
    
    var delegate: CommentTableViewCellDelegate?
    
    /// When this is set in CommentViewController, it does some UI stuff
    var comment: StripwayComment? {
        didSet {
            updateView()
        }
    }
    
    /// When this is set in CommentViewController, it does some UI stuff
    var user: StripwayUser? {
        didSet {
            setupUserInfo()
        }
    }
    
    @objc func btnViewRepliesClicked() {
        delegate?.expandSection(self, section: section)
    }
    var section = 0
    var collapsed = false {
        didSet {
            if collapsed {
                setViewReplyTitle()
            } else {
                viewRepliesButton.isHidden = true
                viewRepliesButtonHeight.constant = 0
                layoutIfNeeded()
            }
        }
    }
    
    @objc func didLongPress() {
        print("longPressed")
        delegate?.longPressComment(self)
    }
    @objc func didSingleTap() {
        delegate?.replyToComment(self.comment!, reply: nil)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileImageView.layer.cornerRadius = 18
        profileImageView.clipsToBounds = true
        // Sets up the buttons/gestures for the comment
        likeImageView.addTarget(self, action: #selector(likeButtonPressed), for: .touchUpInside)
        profileImageView.addTarget(self, action: #selector(usernameProfileButtonPressed), for: .touchUpInside)
        usernameLabel.addTarget(self, action: #selector(usernameProfileButtonPressed), for: .touchUpInside)
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        longPress.minimumPressDuration = 0.2
        longPress.delaysTouchesBegan = true
        contentView.addGestureRecognizer(longPress)
        
        singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTap))
        singleTap.numberOfTapsRequired = 1
        contentView.addGestureRecognizer(singleTap)
    }
    
    /// Sets up the view once we have the actual comment
    func updateView() {
//        commentTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 0/255, green: 2/255, blue: 53/255, alpha: 1.0) /* #000235 */]
        commentTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.blue, NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .bold)]
        commentTextView.text = comment!.commentText
        commentTextView.resolveHashtagsAndMentions()
        commentTextView.delegate = self
        self.updateLike(comment: comment!)
        timestampLabel.text = self.comment!.timestamp.convertToTimestamp()
    }
    private func setViewReplyTitle() {
        var replyCount = 0
        if let count = comment?.replies?.count {
            replyCount = count
        }
        viewRepliesButton.setTitle("View Replies (\(replyCount)) ", for: .normal)
    }
    
    /// Sets up the view once we have the actual user
    func setupUserInfo() {
        usernameLabel.setTitle(user!.username, for: .normal)
        if let photoURLString = user?.profileImageURL {
            profileImageView.sd_setImage(with: URL(string: photoURLString), for: .normal, completed: nil)
        }
        verifiedImage.isHidden = !user!.isVerified
    }
    
    @objc func usernameProfileButtonPressed() {
        // Send this to the delegate, will segue from delegate to user's profile
        delegate?.usernameProfileButtonPressed(user: user!)
    }
    
    
    @objc func likeButtonPressed() {
        // Disable the like button, it will be reenabled once the like is finished
        likeImageView.isUserInteractionEnabled = false
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
        // Change the like in the database, and then update the UI once that's done
        API.Comment.incrementLikes(commentID: self.comment!.commentID) { (comment, error) in
            self.likeImageView.isUserInteractionEnabled = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let comment = comment {
                self.updateLike(comment: comment)
                
            }
        }
    }
    
    /// UI stuff for when you like/unlike a comment (tag isn't used, idk why I set it)
    func updateLike(comment: StripwayComment) {
        if comment.isLiked {
            likeImageView.setImage(#imageLiteral(resourceName: "Like Picture Selected"), for: .normal)
            let bigLikeImageV = likeImageView
            UIView.animate(withDuration: 0.02, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
                bigLikeImageV.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                bigLikeImageV.alpha = 0.9
            }) { finished in
                bigLikeImageV.alpha = 1.0
                bigLikeImageV.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            
        } else {
            likeImageView.setImage(#imageLiteral(resourceName: "Black Like"), for: .normal)
        }
        likesNumberLabel.text = "\(comment.likeCount)"
    }
}
extension CommentTableViewHeader: UITextViewDelegate, UIGestureRecognizerDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        didSingleTap()
        return false
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? false
    }
}
