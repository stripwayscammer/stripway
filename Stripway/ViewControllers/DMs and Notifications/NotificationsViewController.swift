//
//  NotificationsViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 12/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class NotificationsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    var notifications: [StripwayNotification] = []
    var notificationTimestamps = [Int]()
    var users: [String: StripwayUser] = [:]
    var posts: [String: StripwayPost] = [:]
    var notificationsLoading = false
    
    var selectedUser: StripwayUser?
    var selectedPost: StripwayPost?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchNotifications()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        self.navigationController?.navigationBar.tintColor = UIColor.black
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    
    
    func fetchNotifications() {
        self.notificationsLoading = true
        API.Notification.getRecentNotifications(forUserID: Constants.currentUser!.uid, limit: 30) { (results) in
            
            self.notificationsLoading = true
            if results.count > 0
            {
                results.forEach({ (result) in
                    
                    let notification = result.0
                    let user = result.1
                    API.Follow.isFollowing(userID: user.uid, completion: {(value) in
                        self.users[notification.notificationID]?.isFollowing = value
                        self.tableView.reloadData()
                        
                    })
                    self.notifications.append(notification)
                    self.notificationTimestamps.append(notification.timestamp)
                    self.users[notification.notificationID] = user
                    if let post = result.2 {
                        self.posts[notification.notificationID] = post
                    }
                    self.notificationsLoading = false
                    self.tableView.reloadData()
                    
                })
            }
    
            
        }
    }
    
    func loadMoreNotifications() {
        guard let lastNotificationTimestamp = self.notificationTimestamps.last else {
            return
        }
        if self.notificationsLoading == true {
            return
        }
        self.notificationsLoading = true
        API.Notification.getOlderNotifications(forUserID: Constants.currentUser!.uid, start: lastNotificationTimestamp, limit: 20){ (results) in
            
            self.notificationsLoading = true
            if results.count > 0 {
                results.forEach({ (result) in
                    
                    let notification = result.0
                    let user = result.1
                    API.Follow.isFollowing(userID: user.uid, completion: {(value) in
                        self.users[notification.notificationID]?.isFollowing = value
                        self.tableView.reloadData()
                        
                    })
                    self.notifications.append(notification)
                    self.notificationTimestamps.append(notification.timestamp)
                    self.users[notification.notificationID] = user
                    if let post = result.2 {
                        self.posts[notification.notificationID] = post
                    }
                    
                })
                self.tableView.reloadData()
                self.notificationsLoading = false
            }
            
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                guard let user = self.selectedUser else { return }
                profileViewController.profileOwner = user
            }
        }
        
        if segue.identifier == "SegueToPost" {
            if let viewPostViewController = segue.destination as? ViewPostViewController {
                guard let post = self.selectedPost else { return }
                viewPostViewController.post = post
                viewPostViewController.posts = [post]
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        API.Notification.resetUnreadNotificationsCount()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        API.Notification.resetUnreadNotificationsCount()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appMovedToBackground() {
        API.Notification.resetUnreadNotificationsCount()
    }
    
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    // MARK: Header animation stuff happens here
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 500 {
            if self.notificationsLoading == false
            {
                self.loadMoreNotifications()
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationTableViewCell
        notifications.sort(by: {$0.timestamp > $1.timestamp})
        let notification = notifications[indexPath.row]
        let user = users[notification.notificationID]
        cell.user = user
        cell.notification = notification
        cell.cellIndex = indexPath.row
    
        if let type = notification.type
        {
            if type == .follow
            {
                cell.followBack = true
            }
            else {
                cell.followBack = false
            }
        }
       
        if let post = posts[notification.notificationID] {
            cell.post = post
            print("BUG5: This cell has a post.\nBUG5: And the actual notification is: \(notification.toAnyObject())")
        } else {
            cell.noPost = true
        }
        cell.delegate = self
//        if indexPath.row == self.notifications.count - 1 {
//            self.loadMoreNotifications()
//        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.didTapRow(indexPath.row)
    }
    
    func didTapRow(_ index:Int) {
        let notification = notifications[index]
        let user = users[notification.notificationID]
        let post = posts[notification.notificationID]
        switch notification.type! {
        case .like, .comment, .commentMention, .postMention, .repost:
            if let post = post {
                self.selectedPost = post
                performSegue(withIdentifier: "SegueToPost", sender: self)
            } else {
                print("Post doesn't exist apparently")
            }
        case .follow:
            if let user = user {
                self.selectedUser = user
                performSegue(withIdentifier: "SegueToProfile", sender: self)
            } else {
                print("User doesn't exist apparently")
            }
        }
    }
    
    /// This is to segue when a notification is tapped
    func segueToView(forType type: NotificationType, withID objectID: String) {
        switch type {
        case .like, .comment, .commentMention, .postMention, .repost:
            API.Post.observePost(withID: objectID) { (post, error) in
                if let post = post {
                    self.selectedPost = post
                    self.performSegue(withIdentifier: "SegueToPost", sender: self)
                } else {
                    print("Post doesn't exist apparently")
                }
            }
        case .follow:
            API.User.observeUser(withUID: objectID) { (user, error) in
                if let user = user {
                    self.selectedUser = user
                    self.performSegue(withIdentifier: "SegueToProfile", sender: self)
                } else {
                    print("User doesn't exist apparently")
                }
            }
        }
    }
    
}

extension NotificationsViewController: NotificationTableViewCellDelegate {
    
    func tapCell(_ index: Int) {
        self.didTapRow(index)
    }
    
    func profilePicTappedFor(user: StripwayUser) {
        self.selectedUser = user
        performSegue(withIdentifier: "SegueToProfile", sender: self)
    }
    
    func followBackButtonTappedFor(user: StripwayUser) {
        self.selectedUser = user
        if (self.selectedUser?.isFollowing)! { //this is jank but let's see
            print("We are following this user and shall now unfollow")
            API.Follow.unfollowAction(withUser: (self.selectedUser?.uid)!)
            self.selectedUser?.isFollowing = false
        }
        else {
            API.Follow.followAction(withUser: (self.selectedUser?.uid)!)
            self.selectedUser?.isFollowing = true
        }
        let impact = UIImpactFeedbackGenerator()
        impact.impactOccurred()
        
    }
}
