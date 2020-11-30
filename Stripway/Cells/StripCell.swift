//
//  CategoryRow.swift
//  
//
//  Created by Drew Dennistoun on 9/7/18.
//

import UIKit

class StripTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    var index = 10000
    
    /// This handles all the apperance stuff for strips and posts when they're editing
    var isCurrentlyEditing: Bool = false {
        didSet {
            collectionView.reloadData()
            deleteButton.isHidden = !isCurrentlyEditing
        }
    }

    var delegate: StripCellDelegate?

    /// This is set in cellForRowAt in ProfileViewController, and that's when posts are loaded and the title is set
    var strip: StripwayStrip? {
        didSet {
            loadPosts()
            titleLabel.text = strip?.name
        }
    }
    var posts: [StripwayPost] = []

    
    func loadPosts() {
        self.collectionView.reloadData()
    }
    
    @IBAction func deleteStripButtonPressed(_ sender: Any) {
        if let strip = strip {
            delegate?.deleteStrip(strip: strip, atIndex: index)
        }
    }
}

extension StripTableViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let strip = strip {
            return strip.posts.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCollectionViewCell
//        cell.post = posts[posts.count - indexPath.row-1]
        if let strip = strip {
            cell.post = strip.posts[strip.posts.count - indexPath.row-1]
            cell.isNowEditing = isCurrentlyEditing
            cell.delegate = self
        }
        return cell
    }
    
}

extension StripTableViewCell: PostCellDelegate {
    func goToPostVC(post: StripwayPost) {
        delegate?.goToPostVC(post: post)
    }
    
    func deletePost(post: StripwayPost) {
        if let strip = strip {
            delegate?.deletePost(post: post, fromStrip: strip)
        } else {
            print("strip doesn't exist, that's not good")
        }
    }
}

protocol StripCellDelegate {
    func deletePost(post: StripwayPost, fromStrip strip: StripwayStrip)
    func deleteStrip(strip: StripwayStrip, atIndex: Int)
    func goToPostVC(post: StripwayPost)
}

extension StripTableViewCell : UICollectionViewDelegateFlowLayout {
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        let itemsPerRow:CGFloat = 4
//        let hardCodedPadding:CGFloat = 5
//        let itemWidth = (collectionView.bounds.width / itemsPerRow) - hardCodedPadding
//        let itemHeight = collectionView.bounds.height - (2 * hardCodedPadding)
//        return CGSize(width: itemWidth, height: itemHeight)
//    }
    
}
