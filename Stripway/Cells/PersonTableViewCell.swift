//
//  PeopleCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/25/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class PersonTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    /// Updates UI once the user is set
    var user: StripwayUser? {
        didSet {
            updateView()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = 25
    }
    
    /// This is called when the user is set
    func updateView() {
        if let user = self.user {
            
            // Don't need follow button for current user
            if user.isCurrentUser {
                followButton.isHidden = true
            } else {
                followButton.isHidden = false
            }
            
            // Set user info
            nameLabel.text = user.username
            usernameLabel.text = user.name
            if let photoURLString = user.profileImageURL {
                let photoURL = URL(string: photoURLString)
                profileImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "placeholderImg"))
            }
            if user.isVerified {
                print("\(user.name) is verified!")
                verifiedImageView.isHidden = false
            } else {
                print("\(user.name) is NOT verified!")
                verifiedImageView.isHidden = true
            }
        }
        
        // Configure button for this user, relative to current user's relation to them
        if user!.isBlocked {
            configureUnblockButton()
        } else if let isFollowing = user?.isFollowing {
            if isFollowing {
                configureUnfollowButton()
            } else {
                configureFollowButton()
            }
        } else {
            hideFollowButton()
        }
        
    }
    
    func configureFollowButton() {
        followButton.layer.borderWidth = 1
        followButton.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        followButton.layer.cornerRadius = 16
        followButton.clipsToBounds = true
        followButton.setTitleColor(UIColor.white, for: .normal)
        followButton.backgroundColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1)
        
        followButton.setTitle("Follow", for: .normal)
        followButton.addTarget(self, action: #selector(followAction), for: .touchUpInside)
    }
    
    func configureUnfollowButton() {
        followButton.layer.borderWidth = 1
        followButton.layer.borderColor = UIColor(red: 63/255, green: 63/255, blue: 63/255, alpha: 1).cgColor
        followButton.layer.cornerRadius = 16
        followButton.clipsToBounds = true
        followButton.setTitleColor(UIColor.black, for: .normal)
        followButton.backgroundColor = UIColor.clear
        
        self.followButton.setTitle("Following", for: .normal)
        followButton.addTarget(self, action: #selector(unfollowAction), for: .touchUpInside)
    }
    
    func hideFollowButton() {
        followButton.isHidden = true
    }
    
    func configureUnblockButton() {
        followButton.layer.borderWidth = 1
        followButton.layer.borderColor = UIColor(red: 226/255, green: 228/255, blue: 232/255, alpha: 1).cgColor
        followButton.layer.cornerRadius = 5
        followButton.clipsToBounds = true
        followButton.setTitleColor(UIColor.white, for: .normal)
        followButton.backgroundColor = UIColor(red: 200/255, green: 9/255, blue: 35/255, alpha: 1) //UIColor.red
        
        followButton.setTitle("Unblock", for: .normal)
        followButton.addTarget(self, action: #selector(unblockAction), for: .touchUpInside)
    }
    
    
    @objc func unblockAction() {
        API.Block.unblockUser(withUID: user!.uid)
        user!.isBlocked = false
        configureFollowButton()
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    @objc func followAction() {
        if user!.isFollowing! == false {
            API.Follow.followAction(withUser: user!.uid)
            configureUnfollowButton()
            user!.isFollowing! = true
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    @objc func unfollowAction() {
        if user!.isFollowing! == true {
            API.Follow.unfollowAction(withUser: user!.uid)
            configureFollowButton()
            user!.isFollowing! = false
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
}
