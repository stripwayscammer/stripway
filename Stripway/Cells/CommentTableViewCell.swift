//
//  CommentTableViewCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import FirebaseDatabase
import ReadMoreTextView

class CommentTableViewCell: UITableViewCell {

    // All the UI stuff
    @IBOutlet weak var profileImageViewLeft: NSLayoutConstraint!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var likeImageView: UIImageView!
    @IBOutlet weak var likesNumberLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var verifiedImage: UIImageView!
    
    var singleTap: UITapGestureRecognizer!
    
    // UID of the author of the post this comment belongs to, used to determine if the current user is also the post author
    var postAuthorUID: String!
    
    var delegate: CommentTableViewCellDelegate?
    
    /// When this is set in CommentViewController, it does some UI stuff
    var comment: StripwayComment? {
        didSet {
            updateView()
        }
    }
    var parentComment: StripwayComment!
    /// When this is set in CommentViewController, it does some UI stuff
    var user: StripwayUser? {
        didSet {
            setupUserInfo()
        }
    }
    @objc func didSingleTap() {
        delegate?.replyToComment(parentComment, reply: self.comment)
    }
    @objc func didLongPress() {
        print("longPressed")
        delegate?.longPressReply(self)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = 15
        commentTextView.isEditable = true
        // Sets up the buttons/gestures for the comment
        let likeTapGesture = UITapGestureRecognizer(target: self, action: #selector(likeButtonPressed))
        likeImageView.addGestureRecognizer(likeTapGesture)
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameProfileButtonPressed))
        profileImageView.addGestureRecognizer(profileTapGesture)
        let usernameTapGesture = UITapGestureRecognizer(target: self, action: #selector(usernameProfileButtonPressed))
        usernameLabel.addGestureRecognizer(usernameTapGesture)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
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
        commentTextView.delegate = self
        commentTextView.resolveHashtagsAndMentions()
        self.updateLike(comment: comment!)
        timestampLabel.text = self.comment!.timestamp.convertToTimestamp()
    }
    
    /// Sets up the view once we have the actual user
    func setupUserInfo() {
        usernameLabel.text = user!.username
        if let photoURLString = user?.profileImageURL {
            profileImageView.sd_setImage(with: URL(string: photoURLString), completed: nil)
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
        API.Comment.incrementLikes(replyID: self.comment!.commentID) { (comment, error) in
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
            likeImageView.image = #imageLiteral(resourceName: "Like Picture Selected")
            if let bigLikeImageV = likeImageView {
                UIView.animate(withDuration: 0.02, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .allowUserInteraction, animations: {
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
                        bigLikeImageV.alpha = 0.9
                    }) { finished in
                        bigLikeImageV.alpha = 1.0
                        bigLikeImageV.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
            }
        } else {
            likeImageView.image = #imageLiteral(resourceName: "Black Like")
        }
        likesNumberLabel.text = "\(comment.likeCount)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        likeImageView.image = #imageLiteral(resourceName: "Like Picture")
    }

}
extension CommentTableViewCell: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        didSingleTap()
        return false
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? false
    }
}

// Need a delegate because we're segueing from a different view and can't do that here
protocol CommentTableViewCellDelegate {
    func usernameProfileButtonPressed(user: StripwayUser)
    func expandSection(_ header: CommentTableViewHeader, section: Int)
    func replyToComment(_ comment: StripwayComment, reply: StripwayComment?)
    func longPressReply(_ header: CommentTableViewCell)
    func longPressComment(_ header: CommentTableViewHeader)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
}
