//
//	ArchiveTableViewCell
//	Stripway
//
//	Created by: Nedim on 17/05/2020
//	Copyright © 2020 Stripway LLC. All rights reserved.
//

import Foundation
import UIKit
import Firebase

protocol ArchiveViewCellDelegate:class {
    
    func presentAlertController(postID:String, authorID:String,post: StripwayPost?)->Bool?
}


class ArchiveTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {


    
    @IBOutlet weak var mCollectionView: UICollectionView!
    
    @IBOutlet weak var mTitleOfStrip: UILabel!
    
    @IBOutlet weak var mCountLabel: UILabel!
    
    @IBOutlet weak var mContentView: UIView!
        
    @IBOutlet weak var mLineDivider: UIView!
    
    var cell: ArchiveCollectionViewCell!
    weak var delegate: ArchiveViewCellDelegate?
    

    var stripPosts: [StripwayPost] = []
    
    var noDataLabel: UILabel?
    var isRestoring = false
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        self.mCollectionView.delegate = self
        self.mCollectionView.dataSource = self
        
        
    }
    
    func loadPosts(post:[StripwayPost]){
            
        stripPosts = post
        print(stripPosts)

        DispatchQueue.main.async {
            self.mCollectionView.reloadData()

        }
        
    }
    
    var i = 0
    override func prepareForReuse() {
            
        mLineDivider.isHidden = true
        noDataLabel?.isHidden = true
       
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        print(isRestoring)
        
        
        return stripPosts.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArchivePostCollectionViewCell", for: indexPath) as? ArchiveCollectionViewCell
        let post = stripPosts[indexPath.row]
        if post.photoURL == "" {
            print("text post only")
            cell.lblTextPost.isHidden = false
            cell.lblTextPost.text = post.caption
            if post.captionBgColorCode == "#000000" {
                cell.mImageView.backgroundColor = .black
                cell.lblTextPost.textColor = .white
            } else {
                cell.lblTextPost.textColor = .black
            }
        } else {
            cell.mImageView.sd_setImage(with: URL(string: stripPosts[indexPath.row].photoURL))
            cell.lblTextPost.isHidden = true
        }
        
        return cell
        
}
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        _ = delegate?.presentAlertController(postID: stripPosts[indexPath.row].postID, authorID: stripPosts[indexPath.row].authorUID, post: stripPosts[indexPath.row])
            
//        stripPosts.remove(at: indexPath.row)
//        collectionView.deleteItems(at: [indexPath])
        

        
        
    }
    
    
}



