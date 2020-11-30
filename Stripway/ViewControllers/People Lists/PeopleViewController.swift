//
//  PeopleViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/26/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import UIKit

class PeopleViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var users: [StripwayUser] = []
    var searchedUsers: [StripwayUser] = []
    var listType: ListType!
    var profileOwner: StripwayUser!
    var selectedUserUID: String?
    var selectedUser: StripwayUser?
    var selectedPost: StripwayPost?
    var isBlocked = false
    
    @IBOutlet weak var btnFollower: UIButton!
    @IBOutlet weak var btnFollowing: UIButton!
    @IBOutlet weak var followerLine: UIView!
    @IBOutlet weak var followingLine: UIView!
    @IBOutlet weak var follwerFollowingView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    
    var searchBar = UISearchBar()
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var tuLeadingConstraint1: NSLayoutConstraint!
    @IBOutlet weak var tuTrailingConstraint1: NSLayoutConstraint!
    @IBOutlet weak var tuLeadingConstraint2: NSLayoutConstraint!
    @IBOutlet weak var tuTrailingConstraint2: NSLayoutConstraint!
    
    //this will show/hide search bar and following switch
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.navigationItem.title = listType.rawValue
        setupUI()
        
        API.Follow.fetchFollowerCount(userID: profileOwner.uid) { (followerCount) in
            self.btnFollower.setTitle("Followers " + String(followerCount), for: .normal)
        }
        
        API.Follow.fetchFollowingCount(userID: profileOwner.uid) { (followingCount) in
            self.btnFollowing.setTitle("Following " + String(followingCount), for: .normal)
        }
        
        let w = UIScreen.main.bounds.width

        switch listType! {
        case .followers:
            tuLeadingConstraint1.constant = 0
            tuTrailingConstraint1.constant = 0
            tableTopConstraint.constant = 110.0
            loadFollowers()
        case .following:
            tuLeadingConstraint1.constant = w / 2
            tuTrailingConstraint1.constant = w / 2
            tableTopConstraint.constant = 110.0
            loadFollowings()
        case .messageFollowing:
            tuLeadingConstraint1.constant = w / 2
            tuTrailingConstraint1.constant = w / 2
            tableTopConstraint.constant = 110.0
            loadFollowings()
        case .blockees:
            tableTopConstraint.constant = 0.0
            loadBlockees()
        }
    }
    
    func setupUI() {
        tableView.keyboardDismissMode = .onDrag

        // Create a navView to add to the navigation bar
        let navView = UIView()
        
        // Create the label
        let label = UILabel()
        label.text = profileOwner.username
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.sizeToFit()
        label.center.y = navView.center.y
        label.center.x = navView.center.x + label.frame.size.height / 2 + 3.0
        label.textAlignment = NSTextAlignment.center
        
        // Create the image view
        let profileImageView = UIImageView()
        
        if let profileImageURL = profileOwner.profileImageURL {
            let profileURL = URL(string: profileImageURL)
            profileImageView.sd_setImage(with: profileURL)
            // To maintain the image's aspect ratio:
            let imgHeight = label.frame.size.height + 6.0
            // Setting the image frame so that it's immediately before the text:
            profileImageView.frame = CGRect(x: label.frame.origin.x-imgHeight-5.0, y: label.frame.origin.y - 3.0, width: imgHeight, height: imgHeight)
            
            profileImageView.layer.masksToBounds = true
            profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        }
        
        profileImageView.contentMode = UIView.ContentMode.scaleAspectFit
        
        // Add both the label and image view to the navView
        navView.addSubview(label)
        navView.addSubview(profileImageView)
        
        // Set the navigation bar's navigation item's titleView to the navView
        self.navigationItem.titleView = navView
        
        // Set the navView's frame to fit within the titleView
        navView.sizeToFit()
        
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.sizeToFit()
        searchBar.placeholder = "Search by username"
        
        searchBar.frame = CGRect(x:0, y:0, width:searchView.frame.width, height:searchView.frame.height)
        self.searchView.addSubview(searchBar)
    }
    
    
    @IBAction func onFollowers(_ sender: Any) {
        self.btnFollower.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.3) {
            self.tuLeadingConstraint1.constant = 0
            self.tuTrailingConstraint1.constant = 0
            self.follwerFollowingView.layoutIfNeeded()
        }
        
        self.loadFollowers()
    }
    
    @IBAction func onFollowing(_ sender: Any) {
        self.btnFollowing.isUserInteractionEnabled = false
        let w = UIScreen.main.bounds.width / 2
        UIView.animate(withDuration: 0.3) {
            self.tuLeadingConstraint1.constant = w
            self.tuTrailingConstraint1.constant = w
            self.follwerFollowingView.layoutIfNeeded()
        }

        self.loadFollowings()
    }
    
    
    func doSearch() {
        var searchText = searchBar.text?.lowercased()
        if searchText == nil {
            searchText = ""
        }
        print("SEARCHING WITH TEXT: |\(searchText)|")
        self.searchedUsers.removeAll()
        self.tableView.reloadData()
        for user in self.users {
            if searchText! == "" {
                self.searchedUsers.append(user)
            }
            else if user.username.lowercased().contains(searchText!){
                self.searchedUsers.append(user)
            }
        }
        self.tableView.reloadData()
    }
    
    
    func loadFollowers() {
        
        self.btnFollower.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.btnFollowing.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        
        self.users.removeAll()
        self.searchedUsers.removeAll()
        self.tableView.reloadData()
        
        API.Follow.fetchFollowers(forUserID: profileOwner.uid) { (user, error) in
            if error != nil {
                self.btnFollower.isUserInteractionEnabled = true
                return
            } else if let user = user {
                self.isFollowing(userID: user.uid, completion: { (value) in
                    user.isFollowing = value
                    self.users.append(user)
                    self.searchedUsers.append(user)
                    self.tableView.reloadData()
                    self.btnFollower.isUserInteractionEnabled = true
                })
            }
        }
    }
    
    func loadFollowings() {
        
        self.btnFollowing.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        self.btnFollower.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        
        self.users.removeAll()
        self.searchedUsers.removeAll()
        self.tableView.reloadData()

        API.Follow.fetchFollowings(forUserID: profileOwner.uid) { (user, error) in
            if let error = error {
                self.btnFollowing.isUserInteractionEnabled = true
                return
            } else if let user = user {
                self.isFollowing(userID: user.uid, completion: { (value) in
                    user.isFollowing = value
                    self.users.append(user)
                    self.searchedUsers.append(user)
                    self.tableView.reloadData()
                    self.btnFollowing.isUserInteractionEnabled = true
                })
            }
        }
    }
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }
    
    func loadBlockees() {
        self.isBlocked = true
        API.Block.fetchBlockees(forUserID: profileOwner.uid) { (user, error) in
            if let error = error {
                return
            } else if let user = user {
                self.isFollowing(userID: user.uid, completion: { (value) in
                    user.isFollowing = value
                    self.users.append(user)
                    self.searchedUsers.append(user)
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Is this even preparing for segue?")
        print("Here is the destination: \(segue.destination)")
        if let profileViewController = segue.destination as? ProfileViewController {
            print("Should be preparing for segue")
//            profileViewController.profileOwnerUID = selectedUserUID!
            profileViewController.profileOwner = selectedUser
        }
        if segue.identifier == "ShowConversationSegue" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.senderUser = self.profileOwner
                viewConversationViewController.receiverUser = self.selectedUser!
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-DemiBold", size: 25)!]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 25)!]
    }
    
}

extension PeopleViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        print(searchBar.text)
        doSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(searchBar.text)
        doSearch()
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        print("cancel pressed")
        searchBar.text = ""
        doSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel pressed")
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        doSearch()
    }
}

extension PeopleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return users.count
        
        if(isBlocked){
            
            if(users.count == 0){
                
                tableView.setEmptyView(title: "Your block list is empty", message: "People you block will be here" ,bottomPosition: -150)
            }else{
                tableView.restore()
            }
            
        }
        
        return searchedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
//        cell.user = users[indexPath.row]
        cell.user = searchedUsers[indexPath.row]
        if listType == .messageFollowing {
            cell.followButton.isHidden = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print("selected row for user: \(users[indexPath.row].username)")
//        self.selectedUserUID = users[indexPath.row].uid
//        self.selectedUser = users[indexPath.row]

        print("selected row for user: \(searchedUsers[indexPath.row].username)")
        self.selectedUserUID = searchedUsers[indexPath.row].uid
        self.selectedUser = searchedUsers[indexPath.row]

        if listType == .messageFollowing {
            performSegue(withIdentifier: "ShowConversationSegue", sender: self)
        } else {
            performSegue(withIdentifier: "ShowUserProfile", sender: self)
        }
    }
    
}

enum ListType: String {
    case followers = "Followers"
    case following = "Following"
    case messageFollowing = "Message Following"
    case blockees = "Blocked Users"
}
