//
//  PeopleCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/25/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class SharePersonCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    var selectedForIndex = [Int]()
    
    var delegate: SharePersonCellDelegate?
    var cellIndex:Int!
    
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
    
    override func prepareForReuse() {
        
        self.selectButton.isSelected = false
    }
    
    /// This is called when the user is set
    func updateView() {
        if let user = self.user {
            
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
    }
    
    
    @IBAction func onSelectFollowing(_ sender: Any) {
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()

        self.selectButton.isSelected = !self.selectButton.isSelected
       
        
        self.delegate?.selectPerson(self.cellIndex, self.selectButton.isSelected)
    }    
}

// Need a delegate because we're segueing from a different view and can't do that here
protocol SharePersonCellDelegate {
    func selectPerson(_ cellIndex:Int, _ status:Bool)
}

