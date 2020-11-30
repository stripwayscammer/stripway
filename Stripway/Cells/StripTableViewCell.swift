//
//  CategoryRow.swift
//  
//
//  Created by Drew Dennistoun on 9/7/18.
//

import UIKit
import Zoomy

class StripTableViewCell: UITableViewCell {
    
    // UI stuff
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var cellHeaderView: UIView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var countView: UIView!
    @IBOutlet weak var arrowImg: UIImageView!
    
    var showsAccessoryButton = false
    
    // The index of this strip on the user's profile, default at 10000 so it goes to the bottom
    var index = 10000
    
    /// This handles all the apperance stuff for strips and posts when they're editing
    var isCurrentlyEditing: Bool = false {
        didSet {
            startStopEditing()
        }
    }
    
    var delegate: StripCellDelegate?

    /// This is set in cellForRowAt in ProfileViewController
    var strip: StripwayStrip? {
        didSet {
            let viewStripTapGesture = UITapGestureRecognizer(target: self, action: #selector(viewStripPressed))
            cellHeaderView.addGestureRecognizer(viewStripTapGesture)
            titleLabel.text = strip?.name
        }
    }
    
    /// Trending hashtags are loaded in strips on the trending page, set the title/gesture when this is set
    var trendtag: Trendtag? {
        didSet {
            let viewTrendtagTapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTrendtagPressed))
            cellHeaderView.addGestureRecognizer(viewTrendtagTapGesture)
            titleLabel.text = "#" + trendtag!.name.uppercased()
        }
    }
    
    var noDataLabel: UILabel?

    override func prepareForReuse() {
           

               
           noDataLabel?.isHidden = true
          
           
       }
    
    /// The posts for either the trendtag or the strip
    var posts: [StripwayPost]? {
        didSet {
            if posts != nil {
                if posts!.count > 0 {
                    self.countLabel.text = String(posts!.count)
                }
            }
            self.collectionView.reloadData()
        }
    }
    
    /// The posts for either the trendtag or the strip
    var postKeys: [String]? {
        didSet {
            if postKeys != nil {
                if postKeys!.count > 0 {
                    self.countLabel.text = String(postKeys!.count)
                }
            }
            self.collectionView.reloadData()
        }
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        deleteButton.imageView?.contentMode = .scaleAspectFit
    }
    

    /// Changes the strips name if the user edits it
    @IBAction func nameTextFieldDidChange(_ sender: Any) {
        guard let strip = strip else { return }
        delegate?.didEditStripName(newName: titleTextField.text ?? "", forStrip: strip)
        strip.name = titleTextField.text ?? ""
    }
    
    @objc func viewStripPressed() {
        delegate?.goToStripVC(strip: strip!)
    }
    
    @objc func viewTrendtagPressed() {
        delegate?.goToTrendtagVC(trendtag: trendtag!)
    }
    
    @IBAction func deleteStripButtonPressed(_ sender: Any) {
        if let strip = strip {
            delegate?.deleteStrip(strip: strip, atIndex: index)
        }
    }
    
    /// Does the UI stuff when editing starts or stops
    func startStopEditing() {
        collectionView.reloadData()
        deleteButton.isHidden = !isCurrentlyEditing
        titleTextField.isHidden = !isCurrentlyEditing
        titleLabel.isHidden = isCurrentlyEditing
        if isCurrentlyEditing {
            titleTextField.text = titleLabel.text!
        }
    }
}

extension StripTableViewCell: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.posts?.count ?? 0

//        if self.strip != nil {
//            return self.posts?.count ?? 0
//        }
//        else {
//            //for trend page.. we are using postkeys instead of posts
//            return self.postKeys?.count ?? 0
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCollectionViewCell", for: indexPath) as! PostCollectionViewCell
        
        if let posts = self.posts {

            // We load strips in reverse order because of the way Firebase orders timestamps (backwards),
            // eventually want to fix that in the Firebase database by inverting timestamps for posts in strips
            if self.strip != nil {
                cell.post = posts[posts.count - indexPath.row - 1]
            } else {
                // But for trendtags they're loaded in the correct order (ordered by likes,
                // but I inverted the likes so it actually queries correctly)
                cell.post = posts[indexPath.row]
            }
            cell.isNowEditing = isCurrentlyEditing
            cell.delegate = self
            
             
            
            
        }
        if showsAccessoryButton {
            cell.accessoryButton.isHidden = false
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// Delegate stuff for the individual cells
extension StripTableViewCell: PostCellDelegate {
    
    // When you tap on a post it segues to the ViewPostViewController with that post,
    // have to use yet another delegate method because we cannot segue from a StripTableViewCell
    func goToPostVC(post: StripwayPost) {
//        delegate?.goToPostVC(post: post)
        
        delegate?.goToPostVC(post: post, posts:posts!)
    }
    
    // This delegate method exists because we can't just delete a post, we must remove it from
    // the strip or else there will be a reference pointing towards nothing
    func deletePost(post: StripwayPost) {
        if let strip = strip {
            delegate?.deletePost(post: post, fromStrip: strip)
        } else {
            print("strip doesn't exist, that's not good")
        }
    }
    
    /// This is the top left button on a PostCollectionViewCell
    func accessoryPressedForPost(post: StripwayPost) {
        if let trendtag = trendtag {
//            print("Should be removing post from trendtag: \(trendtag.name)")
//            API.Trending.blockPostFromTrendtag(postID: post.postID, trendtagName: trendtag.name)
            delegate?.accessoryPressedForPost(post: post, forTrendtag: trendtag)
//            if var posts = posts {
//                posts.removeAll(where: { $0.postID == post.postID })
//                self.posts = posts
//            }
        }
    }
}

protocol StripCellDelegate {
    func deletePost(post: StripwayPost, fromStrip strip: StripwayStrip)
    func accessoryPressedForPost(post: StripwayPost, forTrendtag trendtag: Trendtag)
    func deleteStrip(strip: StripwayStrip, atIndex: Int)
//    func goToPostVC(post: StripwayPost)
    func goToPostVC(post: StripwayPost, posts:[StripwayPost])
    func goToStripVC(strip: StripwayStrip)
    func goToTrendtagVC(trendtag: Trendtag)
    func didEditStripName(newName: String, forStrip strip: StripwayStrip)
}

extension StripTableViewCell : UICollectionViewDelegateFlowLayout {
    // This extension seems to do nothing but it actually removes the slight gap to the left of strips
}

