//
//  FeatureTableViewCell.swift
//  Stripway
//
//  Created by iOS Dev on 2/7/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit

class FeatureTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    
    var posts: [StripwayPost]?
    var users: [StripwayUser]?
    
    func setFeaturePost(_ posts:[StripwayPost], _ users:[StripwayUser]) {
        self.posts = posts
        self.users = users
        self.collectionView.reloadData()        
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension FeatureTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeatureCollectionViewCell", for: indexPath) as! FeatureCollectionViewCell
        if let posts = self.posts {
            cell.post = posts[indexPath.row]
        }
        
        if let users = self.users {
            cell.user = users[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width / 2 - 2.0, height: 240)
    }

}
