//
//  PeopleCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/25/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

protocol SelectionProtocol:AnyObject{
    func selectUser(_ user:StripwayUser)
    func unselectUser(_ user:StripwayUser)
}

class PersonSelectionCell: UITableViewCell {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!
    weak var delegate:SelectionProtocol?
    
    
    
    /// Updates UI once the user is set
    var data: (user:StripwayUser?, isSelected:Bool)?{
        didSet {
            updateView()
        }
        
    }
    
    var selectedUsers = [String]()
    
    override func prepareForReuse() {
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.cornerRadius = 25
        
    
  
    }
    
    /// This is called when the user is set
    func updateView() {
        if let user = self.data?.user {
            
            // Don't need select button for current user
            if user.isCurrentUser {
                selectButton.isHidden = true
            } else {
                selectButton.isHidden = false
            }
            
            // Set user info
            nameLabel.text = user.username
            usernameLabel.text = user.name
            if let photoURLString = user.profileImageURL {
                let photoURL = URL(string: photoURLString)
                profileImageView.sd_setImage(with: photoURL, placeholderImage: UIImage(named: "placeholderImg"))
            }
            verifiedImageView.isHidden = !user.isVerified
        }
        
        // Configure button for this user, relative to current user's relation to them
        
        //(data?.isSelected ?? false) ? configureselectButton() : configureUnselectButton()
        
        if(data?.isSelected != false){
            configureselectButton()
        }else{
            configureUnselectButton()
        }
        
    }
    
    func configureselectButton() {
        selectButton.clipsToBounds = true
        selectButton.setTitleColor(UIColor.white, for: .normal)

        
        //selectButton.setTitle("select", for: .normal)
        selectButton.addTarget(self, action: #selector(unselectAction), for: .touchUpInside)
    }
    
    func configureUnselectButton() {
        selectButton.clipsToBounds = true
        selectButton.setTitleColor(UIColor.black, for: .normal)
       
        
        //self.selectButton.setTitle("selecting", for: .normal)
        selectButton.addTarget(self, action: #selector(selectAction), for: .touchUpInside)
    }
    
    func hideselectButton() {
        selectButton.isHidden = true
    }
    
    func configureUnblockButton() {

        selectButton.clipsToBounds = true
        selectButton.setTitleColor(UIColor.white, for: .normal)
        selectButton.backgroundColor = UIColor(red: 200/255, green: 9/255, blue: 35/255, alpha: 1) //UIColor.red
        
        selectButton.setTitle("Unblock", for: .normal)
        selectButton.addTarget(self, action: #selector(unblockAction), for: .touchUpInside)
    }
    
    
    @objc func unblockAction() {
        API.Block.unblockUser(withUID: data!.user!.uid)
        data?.user?.isBlocked = false
        //configureselectButton()
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
    }
    
    @objc func selectAction() {
        
        configureselectButton()
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        guard let user = data?.user else {return}
        delegate?.selectUser(user)
        
        selectedUsers.append(user.uid)
      
        selectButton.setImage(UIImage(named: "select_share"), for: UIControl.State.normal)
        
       
    }
    
    @objc func unselectAction() {
        
        configureUnselectButton()
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        guard let user = data?.user else {return}
        delegate?.unselectUser(user)
        
        
        selectButton.setImage(UIImage(named: "unselected_share"), for: UIControl.State.normal)
    
    

    }
    
}
