//
//  LikesRepostsViewController.swift
//  CropViewController
//
//  Created by Drew Dennistoun on 10/10/18.
//

import UIKit
import FirebaseDatabase

class LikesRepostsViewController: UIViewController {

    var post: StripwayPost!
    
    @IBOutlet weak var bottomView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var likesOrReposts: String!
    
    @IBOutlet weak var numberLabel: UILabel!
    
    var users: [StripwayUser] = []
    
    var delegate: LikesRepostsViewControllerDelegate?
    
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
    
    @IBAction func xButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func topViewTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        
        if recognizer.state == UIGestureRecognizer.State.ended {
            let velocity = recognizer.velocity(in: self.view)
            if (velocity.y > VELOCITY_LIMIT_SWIPE) {
                self.dismiss(animated: true, completion: nil)
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
                self.dismiss(animated: true, completion: nil)
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
        if likesOrReposts == "likes" {
            API.Post.fetchLikers(forPostID: post.postID) { (user, error) in
                if let error = error {
                    print(error)
                    return
                } else if let user = user {
                    if user.isBlocked || user.hasBlocked { return }
                    print("THIS POST WAS LIKED BY USER: \(user.username)")
                    self.isFollowing(userID: user.uid, completion: { (value) in
                        user.isFollowing = value
                        self.users.append(user)
                        self.numberLabel.text = "\(self.users.count) " + self.likesOrReposts
                        self.tableView.reloadData()
                    })
                }
            }
        } else if likesOrReposts == "reposts" {
            API.Post.fetchReposters(forPostID: post.postID) { (user, error) in
                if let error = error {
                    print(error)
                    return
                } else if let user = user {
                    if user.isBlocked || user.hasBlocked { return }
                    print("THIS POST WAS REPOSTED BY USER: \(user.username)")
                    self.isFollowing(userID: user.uid, completion: { (value) in
                        user.isFollowing = value
                        self.users.append(user)
                        self.numberLabel.text = "\(self.users.count) " + self.likesOrReposts
                        self.tableView.reloadData()
                    })
                }
            }
        }
    }
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }

}

extension LikesRepostsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
        cell.user = users[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected row for user: \(users[indexPath.row].username)")
        let user = users[indexPath.row]
        delegate?.cellWithUserTapped(user: user, fromVC: self)
    }
}

protocol LikesRepostsViewControllerDelegate {
    func cellWithUserTapped(user: StripwayUser, fromVC vc: LikesRepostsViewController)
}
