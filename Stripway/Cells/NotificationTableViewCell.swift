//
//  NotificationTableViewCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 12/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    // User interface stuff
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var followButton: UIButton!
    
    var delegate: NotificationTableViewCellDelegate?
    
    // Constraints that change depending on the type of notification
    // (Some have a post image on the right, some don't)
    @IBOutlet weak var labelYesImageTrailingAnchor: NSLayoutConstraint!
    @IBOutlet weak var labelNoAssetTrailingAnchor: NSLayoutConstraint!
    @IBOutlet weak var labelYesFollowTrailingAnchor: NSLayoutConstraint!
    @IBOutlet weak var buttonWidthConstraint: NSLayoutConstraint!
    
    var cellIndex:Int!    
    
    /// When this is set in NotificationsViewController, it does some UI stuff
    var notification: StripwayNotification? {
        didSet {
            updateView()
        }
    }
    
    /// When this is set in NotificationsViewController, it does some UI stuff
    var user: StripwayUser? {
        didSet {
            setupUserInfo()
        }
    }
    
    /// If a notification is on a post, that post is included in the notification
    var post: StripwayPost? {
        didSet {
            setupPost()
        }
    }
    
    /// If the notification is about a follow, the follow back button will appear
    var followBack = false {
        didSet {
            if followBack {
                followButton.isHidden = false
                labelNoAssetTrailingAnchor.isActive = false
                labelYesImageTrailingAnchor.isActive = false
                labelYesFollowTrailingAnchor.isActive = true
                setupFollowBack()
            }
            else {
                labelYesFollowTrailingAnchor.isActive = false
                followButton.isHidden = true
            }
        }
    }
    
    /// If there is no post then this is set to true, and some constraint stuff is done
    var noPost = false {
        didSet {
            if noPost {
                labelYesImageTrailingAnchor.isActive = false
                if followBack {
                    labelYesFollowTrailingAnchor.isActive = true
                }
                else {
                    labelNoAssetTrailingAnchor.isActive = true
                }
                postImageView.isHidden = true
            }
        }
    }
    
    /// Called once we have the notification (and user), sets up the text content and appearance of the cell
    func updateView() {
        guard let notification = notification else { return }
        guard let user = user else { return }
        
        // Set the text and font for the username and timestamp
        let username = NSMutableAttributedString(string: user.username, attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-DemiBold", size: 15)!])
        let timestamp = NSMutableAttributedString(string: notification.timestamp.convertToTimestamp(), attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        // Change the notificationText depending on the type of notification
        var notificationText = ""
        switch notification.type! {
        case .like:
            notificationText = " liked your post "
        case .repost:
            notificationText = " reposted your post "
        case .follow:
            notificationText = " followed you "
        case .commentMention:
            notificationText = " mentioned you in a comment: \"\(notification.commentText ?? "")\" "
        case .postMention:
            notificationText = " mentioned you in a post "
        case .comment:
            notificationText = " commented on your post: \"\(notification.commentText ?? "")\" "
        }
        
        // Add all the text and attributes and everything and put them in the cell
        let finalNotificationText = NSMutableAttributedString(string: "")
        finalNotificationText.append(username)
        finalNotificationText.append(NSMutableAttributedString(string: notificationText))
        finalNotificationText.append(timestamp)
        notificationLabel.attributedText = finalNotificationText
    }
    
    @objc func tapNotifcationLabel(tap: UITapGestureRecognizer) {
        if user == nil {
            self.delegate?.tapCell(self.cellIndex)
            return
        }
        guard let range = self.notificationLabel.text?.range(of: user!.username)?.nsRange else {
            self.delegate?.tapCell(self.cellIndex)
            return
        }
        if tap.didTapAttributedTextInLabel(label: self.notificationLabel, inRange: range) {
            delegate?.profilePicTappedFor(user: user!)
        }
        else {
            self.delegate?.tapCell(self.cellIndex)
        }
    }
    
    @objc func profilePhotoPressed() {
        print("Profile photo was tapped")
        if let user = user {
            delegate?.profilePicTappedFor(user: user)
        }
    }
    
    @IBAction func followButtonPressed(_ sender: Any) {
        if (user?.isFollowing)! == false {
            self.setupUnfollow()
            
        }
        else {
            self.setupFollow()
        }
        if let user = user {
            delegate?.followBackButtonTappedFor(user: user)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Add a gesture recognizer for the profile photo
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(profilePhotoPressed))
        profileImageView.addGestureRecognizer(profileTapGesture)
        
        let notificationLabelTap = UITapGestureRecognizer(target: self, action: #selector(tapNotifcationLabel(tap:)))
        self.notificationLabel.addGestureRecognizer(notificationLabelTap)
        self.notificationLabel.isUserInteractionEnabled = true
    }
    
    /// Called once the user is set for this cell
    func setupUserInfo() {
        // Just sets the profile image
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        if let photoURLString = user?.profileImageURL {
            profileImageView.sd_setImage(with: URL(string: photoURLString), completed: nil)
        }
    }
    
    /// Called when (if) a post is set for the cell
    func setupPost() {
        // Adjusts the constraitns and sets the image
        postImageView.isHidden = false
        labelNoAssetTrailingAnchor.isActive = false
        labelYesImageTrailingAnchor.isActive = true
        postImageView.layer.cornerRadius = 0
        if let photoURLString = post?.photoURL {
            postImageView.sd_setImage(with: URL(string: photoURLString), completed: nil)
        }
    }
    
    /// Called when someone follows you to allow button to show up
    func setupFollowBack() {
        
        followButton.layer.cornerRadius = 5
        followButton.clipsToBounds = true

        //checks if we are already following the user or not
        if let isFollowing = user?.isFollowing {
            if (isFollowing)
            {
                setupUnfollow()
            }
            else {
                setupFollow()
            }
        }
    }
    
    
    
    func setupUnfollow()
    {
        labelYesFollowTrailingAnchor.constant = -22
        buttonWidthConstraint.constant = 108
        self.layoutIfNeeded()
        followButton.setTitle("Following", for: .normal)
        followButton.layer.borderWidth = 1
        followButton.layer.cornerRadius = 16.0
        followButton.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        followButton.setTitleColor(UIColor.black, for: .normal)
        followButton.backgroundColor = UIColor.clear
        self.layoutIfNeeded()
    }
    
    func setupFollow() {
        labelYesFollowTrailingAnchor.constant = -22
        buttonWidthConstraint.constant = 108
        self.layoutIfNeeded()
        followButton.setTitle("Follow", for: .normal)
        followButton.layer.borderWidth = 1
        followButton.layer.cornerRadius = 16.0
        followButton.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        followButton.setTitleColor(UIColor.white, for: .normal)
        followButton.backgroundColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1)
        self.layoutIfNeeded()
    }
    
    /// Not sure if any of this actually needs to be done but it works
    override func prepareForReuse() {
        super.prepareForReuse()
        self.user = nil
        self.post = nil
        self.postImageView.image = nil
        self.notification = nil
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

extension UITapGestureRecognizer {
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

extension Range where Bound == String.Index {
    var nsRange:NSRange {
        return NSRange(location: self.lowerBound.encodedOffset,
                       length: self.upperBound.encodedOffset -
                        self.lowerBound.encodedOffset)
    }
}


protocol NotificationTableViewCellDelegate {
    func profilePicTappedFor(user: StripwayUser)
    func followBackButtonTappedFor(user: StripwayUser)
    func tapCell(_ index:Int)
}
