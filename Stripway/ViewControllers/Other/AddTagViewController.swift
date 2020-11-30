//
//  AddTagViewController.swift
//  CropViewController
//
//  Created by Drew Dennistoun on 10/10/18.
//

import UIKit
import FirebaseDatabase

class AddTagViewController: UIViewController {

    var post: StripwayPost!
    
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchField: UITextField!
    
    var likesOrReposts: String!
    
    @IBOutlet weak var numberLabel: UILabel!
    
    var users: [StripwayUser] = []
    var selectedUsers: [StripwayUser] = []
    var delegate: AddTagViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUsers()
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
        bottomView.layer.cornerRadius = 20
        bottomView.layer.shadowOffset = CGSize(width: 4, height: 4)
        bottomView.layer.shadowRadius = 6
        bottomView.layer.shadowOpacity = 0.5
    }
    
    @IBAction func searchChanged(_ sender: Any) {
        doSearch()
    }
    
    @IBAction func cancelPressed(_ sender: Any) {
        
        searchField.text = ""
        loadUsers()
        
    }
    @IBAction func xButtonPressed(_ sender: Any) {
        self.dismissVC()
    }
    
    @IBAction func topViewTapped(_ sender: Any) {
        self.dismissVC()
    }
    
    func dismissVC(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        
        if recognizer.state == UIGestureRecognizer.State.ended {
            let velocity = recognizer.velocity(in: self.view)
            if (velocity.y > VELOCITY_LIMIT_SWIPE) {
                self.dismissVC()
            }

            let magnitude = sqrt(velocity.y * velocity.y)
            let slideMultiplier = magnitude / 200
            
            let slideFactor = 0.1 * slideMultiplier     //Increase for more of a slide
            var finalPoint = CGPoint(x:recognizer.view!.center.x,
                                     y:recognizer.view!.center.y + (velocity.y * slideFactor))
            finalPoint.x = min(max(finalPoint.x, 0), self.view.bounds.size.width)
            
            let finalY = recognizer.view!.center.y
            if finalY < UIScreen.main.bounds.height {
                finalPoint.y = UIScreen.main.bounds.height * 0.625
            }
            else {
                self.dismissVC()
            }
            
            UIView.animate(withDuration: Double(slideFactor),
                           delay: 0,
                           // 6
                options: UIView.AnimationOptions.curveEaseOut,
                animations: {recognizer.view!.center = finalPoint },
                completion: nil)
        }
        
        let translation = recognizer.translation(in: self.view)
        
        if let view = recognizer.view {
            print("translation Y", translation.y)
            view.center = CGPoint(x:view.center.x,
                                  y:view.center.y + translation.y)
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func loadUsers() {
        
        API.User.observeSuggestedUsers { (userTuple, shouldClear) in
            if let shouldClear = shouldClear, shouldClear {
                self.users.removeAll()
                return
            }
            guard let userTuple  = userTuple else { return }
            self.isFollowing(userID: userTuple.0.uid, completion: { (value) in
                userTuple.0.isFollowing = value
                self.users.append(userTuple.0)
                self.tableView.reloadData()
            })
        }
        
//        if likesOrReposts == "likes" {
//            API.Post.fetchLikers(forPostID: post.postID) { (user, error) in
//                if let error = error {
//                    return
//                } else if let user = user {
//                    if user.isBlocked || user.hasBlocked { return }
//                    print("THIS POST WAS LIKED BY USER: \(user.username)")
//                    self.isFollowing(userID: user.uid, completion: { (value) in
//                        user.isFollowing = value
//                        self.users.append(user)
//                        self.numberLabel.text = "\(self.users.count) " + self.likesOrReposts
//                        self.tableView.reloadData()
//                    })
//                }
//            }
//        } else if likesOrReposts == "reposts" {
//            API.Post.fetchReposters(forPostID: post.postID) { (user, error) in
//                if let error = error {
//                    return
//                } else if let user = user {
//                    if user.isBlocked || user.hasBlocked { return }
//                    print("THIS POST WAS REPOSTED BY USER: \(user.username)")
//                    self.isFollowing(userID: user.uid, completion: { (value) in
//                        user.isFollowing = value
//                        self.users.append(user)
//                        self.numberLabel.text = "\(self.users.count) " + self.likesOrReposts
//                        self.tableView.reloadData()
//                    })
//                }
//            }
//        }
    }
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }

}

extension AddTagViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonSelectionCell", for: indexPath) as! PersonSelectionCell
        cell.data = (user:users[indexPath.row], isSelected:selectedUsers.contains(where: {$0.uid == users[indexPath.row].uid}))
        
        //
        var imageName = ""
        imageName = selectedUsers.contains(where: {$0.uid == users[indexPath.row].uid}) ? "select_share" : "unselected_share"
        cell.selectButton.setImage(UIImage(named: imageName), for: UIControl.State.normal)
        
        
        cell.delegate = self
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row for user: \(users[indexPath.row].username)")
        
        let user = users[indexPath.row]
        delegate?.cellWithUserTapped(user: user, fromVC: self)
        
    }
}

protocol AddTagViewControllerDelegate {
    func cellWithUserTapped(user: StripwayUser, fromVC vc: AddTagViewController)
    func addThisUser(_ user: StripwayUser)
    func removeThisUser(_ user:StripwayUser)
}


extension AddTagViewController{//Search
    
    func doSearch() {
        if let searchText = searchField.text?.lowercased(), searchText != "" {
            //shouldShowSuggestedUsers = false
            print("SEARCHFIX SEARCH WITH TEXT: |\(searchText)|")
            // If we're on the users tab
            self.users = selectedUsers
            self.tableView.reloadData()
            API.User.queryUsers(withText: searchText.lowercased()) { (user) in
                print("SEARCHFIX Search found user: \(user.username)")
                
                self.isFollowing(userID: user.uid, completion: { (value) in
                    user.isFollowing = value
                    if !self.users.contains(where: { $0.uid == user.uid}) && user.username.contains(searchText.lowercased()) {
                        print("SEARCHFIX Searchtext: \(searchText.lowercased()) contains username:  \(user.username)")
                        self.users.append(user)
                        self.tableView.reloadData()
                    }
                    
                })
            }
            
        }
        if searchField.text == "" {
            self.users = selectedUsers
            self.tableView.reloadData()
        }
        
    }
}

extension AddTagViewController:SelectionProtocol{
    
    func selectUser(_ user: StripwayUser) {
        if !(selectedUsers.contains(where: {$0.uid == user.uid})){
            selectedUsers.append(user)
            delegate?.addThisUser(user)
        }
    }
    
    func unselectUser(_ user: StripwayUser) {
        if let index = selectedUsers.firstIndex(where: {$0.uid == user.uid}){
            selectedUsers.remove(at: index)
            delegate?.removeThisUser(user)
        }
    }
    
    
}
