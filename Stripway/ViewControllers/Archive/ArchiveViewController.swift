//
//	ArchiveViewController
//	Stripway
//
//	Created by: Nedim on 17/05/2020
//	Copyright © 2020 Stripway LLC. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SDWebImage


class ArchiveViewController: UIViewController{

    
    @IBOutlet weak var mBackButton: UIButton!
    @IBOutlet weak var mHeaderImage: UIImageView!
    
    @IBOutlet weak var mCountArchivesLabel: UILabel!
    @IBOutlet weak var mProfileImage: SpinImageView!
    
    @IBOutlet weak var mTableView: UITableView!
    
    let profileOwner = Auth.auth().currentUser

    // The data source for the table view when top tab 1 is selected
    var strips: [StripwayStrip] = []
    var posts: [StripwayPost] = []
    var stripPosts: [String: [StripwayPost]] = [:]

    //Delegate
    weak var refreshDelegate: ProcessArchiveDelegate?

    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    var ref: DatabaseReference = Database.database().reference()
    


    
    override func viewDidLoad() {
        super.viewDidLoad()
        mBackButton.layer.cornerRadius = 15

        getUser()
        
        mTableView.delegate = self
        mTableView.dataSource = self
        
        mTableView.tableFooterView = UIView()
    }
    
    
    func getUser(){
        
        if let userId = Auth.auth().currentUser?.uid {
           
            self.ref.child("users").child(userId).observe(DataEventType.value, with: { (snapshot) in
              let user = snapshot.value as? [String : AnyObject] ?? [:]
                
                let headerImage = user["headerImageURL"]
                let profileImage = user["profileImageURL"]
               
                
                self.fetchStrips(userID: userId)
              
                if(headerImage != nil){
                    self.mHeaderImage.sd_setImage(with: URL(string: headerImage as! String))
                }else{
                    self.mHeaderImage.backgroundColor = UIColor.gray

                }
                
                self.mProfileImage.layer.masksToBounds = true
                self.mProfileImage.layer.borderWidth = 3
                self.mProfileImage.layer.borderColor = UIColor.white.cgColor
                self.mProfileImage.layer.cornerRadius = self.mProfileImage.bounds.width / 2
                
                self.mProfileImage.sd_setImage(with: URL(string: profileImage as! String))

                
            })

        }
           
        
    }
    
    // TODO: Really need to double check that we're not uneccessarily redownloading data here
    func fetchStrips(userID:String) {
        var i:Int = 1

        API.Strip.fetchStripIDsConstantly(forUserID: userID) { (keys) in
         if(keys != nil){
            for key in keys! {
                API.Strip.observeStrip(withID: key, completion: { (strip) in
                    self.strips.append(strip)
                    
                    //If you ever want to make this archive more then one thing at the time change observer to observerSingleEvent
                    API.Strip.observePostsForStrip(atDatabaseReference: self.strips[0].archivedReference!, completion: { (post, error, shouldClear) in
                        
                        if let shouldClear = shouldClear, shouldClear {
                                
                            strip.posts.removeAll()
                        }
                       
                        if let error = error {
                            print(error.localizedDescription)
                        } else if let post = post {
                            
                            var strip: StripwayStrip?
                            
                            for s in self.strips {
                                
                                if (post.stripID == s.stripID){
                                    strip = s
                                    break
                                    
                                }
                            }
                            
                            if (strip == nil ){return}
                            i += 1
                        
                            if( i % self.strips.count == 0){
                            
                                strip!.posts.append(post)

                            }
                            

                            DispatchQueue.main.async {
                                
                                
                                self.updateArchiveCounter()
                                self.mTableView.reloadData()

                                
                            }
                        }
                    })
                    
                })
            }

            }
            
        }
            
    }
    
    
    
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    func updateArchiveCounter(){
        
        var c = 0
        for strip in strips {
            
            c += strip.posts.count
        }
        
        mCountArchivesLabel.text = "\(c) Archive"
   
    }
    
    func showNoDataFound (counter: Int) -> UILabel{
        var label = UILabel(frame: CGRect(x:0, y: 95, width: mTableView.bounds.width, height: 30))
        print("conter: \(counter)")
        if(counter == 0){
            
            print("hello")
            label.text  = "No archives in this strip"
            label.textColor = .gray
            label.backgroundColor = .white
            label.textAlignment = .center
            label.font = UIFont(name: "Avenir Next", size:18)
            label.font = UIFont.boldSystemFont(ofSize: 18)
            
            return label

        }
        
        return label
    }
    
}

extension ArchiveViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if strips.count == 0 {
            
            mTableView.setEmptyView(title: "You don't have any archives", message: "We will show your archives here",bottomPosition: -150)
        }else{
            mTableView.restore()
        }
        
        return strips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        strips = strips.sorted(by: { $0.index < $1.index })
        

        var archiveCell:ArchiveTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ArchiveStripTableViewCell", for: indexPath) as! ArchiveTableViewCell
        
        let strip = strips[indexPath.row]
        let posts = self.posts
        
        print("posts -------------------------->")
        print(strip.posts.count)
        
        let counter = strip.posts.count
        print(counter)
        
           
            
        archiveCell.mTitleOfStrip.text = strips[indexPath.row].name
        
        archiveCell.mCountLabel.text = "\(counter ?? 00)"//Fix when real archive code comes in
    
        archiveCell.loadPosts(post: strip.posts)

        
        let label = showNoDataFound(counter: counter)

        archiveCell.contentView.addSubview(label)
        
        archiveCell.noDataLabel = label
                    
        archiveCell.delegate = self
        
        return archiveCell
        
    }
    
    // MARK: Header animation stuff happens here add if needed
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // If you are within two screen lengths of the bottom of the scrollView's content, it triggers the loading of more posts
                if scrollView.contentOffset.y + 2*self.view.frame.height >= scrollView.contentSize.height {
                        //print("offset ", scrollView.contentOffset.y, " frame ", self.view.frame.height, " content ", scrollView.contentSize.height)
    //                    loadMore()
                }
            }
    
    
}

extension ArchiveViewController: ArchiveViewCellDelegate {
    func presentAlertController(postID:String, authorID:String,post: StripwayPost?)-> Bool?{
        
        var archived = false
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title:"Cancle", style: .cancel, handler: {(action) in }))

        alertController.addAction(UIAlertAction(title:"Restore", style: .default, handler: {(action) in
 
            //Restoring user post by removing postID from database
            API.Post.unarchive(postWithID: postID, fromPostAuthor: authorID)
            
            self.refreshDelegate?.updateProcessStatus(isCompleted: false, post: post!, index: nil)
            
            //Send user back (keeping user more in the app if they want to edit their strips)
            self.navigationController?.popViewController(animated: true)
            
        

        }))
        self.present(alertController, animated: true, completion: nil)
        
        return archived
    }
    
    

}


extension UITableView {
    func setEmptyView(title: String, message: String, bottomPosition: Int?) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont(name: "Avenir Next", size: 14)
        messageLabel.textColor = UIColor.lightGray
        messageLabel.font = UIFont(name: "Avenir Next", size: 12)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor, constant: CGFloat(bottomPosition ?? -150)).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 10).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -10).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        // The only tricky part is here:
        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    func restore() {
        self.backgroundView = nil

    }
}
