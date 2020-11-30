//
//  PostCell.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/18/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import UIKit


class PostCollectionViewCell: UICollectionViewCell {    
   
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    // Will be used for removing posts from trending or from the report page
    @IBOutlet weak var accessoryButton: UIButton!
    @IBOutlet weak var lblIsTextPost: UILabel!
    var isNowEditing: Bool = false {
        didSet {
            deleteButton.isHidden = !isNowEditing
        }
    }
    
    var delegate: PostCellDelegate?
    
    /// The post for this cell, does some UI stuff when set
    var post: StripwayPost? {
        didSet {
            updateView()
        }
    }
    
    /// Sets the image and adds the tap gesture
    func updateView() {
        // This is eventually where we'll hopefully have post?.thumbnailURL and use that because
        // there's no reason to load the full sized photo in a little collection view cell
        if post?.photoURL == "" {
            print("text post only")
            lblIsTextPost.isHidden = false
            lblIsTextPost.text = post?.caption
            if post?.captionBgColorCode == "#000000" {
                photo.backgroundColor = .black
                lblIsTextPost.textColor = .white
            } else {
                lblIsTextPost.textColor = .black
                photo.backgroundColor = .white
            }
        } else {
            lblIsTextPost.isHidden = true
        }
        
        
        if let thumbURLString = post?.thumbURL {
            let thumbURL = URL(string: thumbURLString)
            
            photo.sd_setImage(with: thumbURL)
        }
        else if let photoURLString = post?.photoURL {
            let photoURL = URL(string: photoURLString)
            photo.sd_setImage(with: photoURL)
        }
        
        let tapGestureForPhoto = UITapGestureRecognizer(target: self, action: #selector(self.photoTapped))
        photo.addGestureRecognizer(tapGestureForPhoto)
        photo.isUserInteractionEnabled = true
    }
    
    @objc func photoTapped() {
        if let post = self.post {
            delegate?.goToPostVC(post: post)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        deleteButton.imageView?.contentMode = .scaleAspectFit
        if isNowEditing {
            deleteButton.isHidden = false
        } else {
            deleteButton.isHidden = true
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        if let post = post {
            delegate?.deletePost(post: post)
        }
        else {
            print("This cell has no post for some reason")
        }
    }
    
    @IBAction func accessoryButtonPressed(_ sender: Any) {
        if let post = post {
            delegate?.accessoryPressedForPost(post: post)
        }
    }
}

protocol PostCellDelegate {
    func deletePost(post: StripwayPost)
    func accessoryPressedForPost(post: StripwayPost)
    func goToPostVC(post: StripwayPost)
}
