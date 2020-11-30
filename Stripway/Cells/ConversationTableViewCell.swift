//
//  ConversationTableViewCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/21/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    
    // Basic UI stuff
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var unreadIcon: UIImageView!
    
    var isUnread = false
    
    /// User for this cell (the user that isn't the current user in the coversation) does some UI stuff when set
    var user: StripwayUser? {
        didSet {
            updateUserInfo()
        }
    }
    
    /// The actual conversation for the cell, does some UI stuff when set
    var conversation: StripwayConversation? {
        didSet {
            updateConversationInfo()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = 25
    }
    
    /// Sets the profile image and username stuff
    func updateUserInfo() {
        self.usernameLabel.text = user!.username
        if let photoURLString = user?.profileImageURL {
            let photoURL = URL(string: photoURLString)
            profileImageView.sd_setImage(with: photoURL)
        }
    }
    
    /// Includes the most recent message text in the cell
    func updateConversationInfo() {
        guard let conversation = conversation else { return }
        if isUnread {
            self.lastMessageLabel.attributedText = NSAttributedString(string: conversation.mostRecentMessageText, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)])
            self.lastMessageLabel.textColor = UIColor.black
        } else {
            self.lastMessageLabel.attributedText = NSAttributedString(string: conversation.mostRecentMessageText, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15)])
            self.lastMessageLabel.textColor = UIColor.lightGray
        }
    }
    
    func markConversationUnread() {
        isUnread = true
        unreadIcon.isHidden = false
        updateConversationInfo()
    }
    
    func markConversationRead() {
        isUnread = false
        unreadIcon.isHidden = true
        updateConversationInfo()
    }
}
