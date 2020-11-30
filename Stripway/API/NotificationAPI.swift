//
//  NotificationAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/23/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class NotificationAPI {
    
    var notificationsReference = Database.database().reference().child("notifications")
    var unreadNotificationCountHandle:DatabaseHandle!
    
    /// Adds the notification to the database for that user
    func createNotification(fromUserID: String, toUserID: String, objectID: String, type: NotificationType!, commentText: String? = nil) {
        if fromUserID == toUserID { return }
        
        // If it's a comment or commentMention generate a random notificationID because
        // user should be able to receive more than one of these notifications per post per user within 24 hours
        // If we later want to limit that then we can just add a hash based on the comment text
        if type == .comment || type == .commentMention {
            let newNotificationID = notificationsReference.childByAutoId().key!
            let newNotificationReference = notificationsReference.child(toUserID).child(newNotificationID)
            let timestamp = Int(Date().timeIntervalSince1970)
            let newNotification = StripwayNotification(fromUserID: fromUserID, toUserID: toUserID, objectID: objectID, type: type, timestamp: timestamp, notificationID: newNotificationID, commentText: commentText)
            newNotificationReference.setValue(newNotification.toAnyObject()) { (error, ref) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Notification successfully uploaded")
                }
            }
        } else {
            let timestamp = Int(Date().timeIntervalSince1970)
            let newNotificationID = self.generateNotificationID(fromUserID: fromUserID, toUserID: toUserID, objectID: objectID, type: type, timestamp: Double(timestamp))
            let newNotificationReference = notificationsReference.child(toUserID).child(newNotificationID)
            let newNotification = StripwayNotification(fromUserID: fromUserID, toUserID: toUserID, objectID: objectID, type: type, timestamp: timestamp, notificationID: newNotificationID)
            newNotificationReference.observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    // This notification already exists on the database, meaning it's been sent on
                    // the current UTC day
                    print("Notification is a duplicate")
                } else {
                    // Notification is not a duplicate, send it
                    newNotificationReference.setValue(newNotification.toAnyObject()) { (error, ref) in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("Notification successfully uploaded")
                        }
                    }
                }
            }
        }
    }
    
    /// Notification ID is generated based on notification info, so user can't receive exact same notification in one UTC day
    private func generateNotificationID(fromUserID: String, toUserID: String, objectID: String, type: NotificationType!, timestamp: Double) -> String {
        
        var notificationID = ""
        // Add the last 5 digits of the fromUser's uid
        notificationID += fromUserID.suffix(5)
        // Add the string for the type of notification ("like" or "repost" etc.)
        notificationID += type.rawValue
        // Add the last 5 digis of the toUser's uid
        notificationID += toUserID.suffix(5)
        // Add the last 5 digits of the object
        notificationID += objectID.suffix(5)
        // Add the current number of days since 1970 in UTC, round down so we get current UTC day
        notificationID += String(Int(floor(timestamp / 86400)))
        
        return notificationID
    }
    
    ///Batch loading of notifications, gets notification starting at timestamp
    func getRecentNotifications(forUserID uid: String, start timestamp: Int? = nil, limit: UInt, completion: @escaping ([(StripwayNotification, StripwayUser, StripwayPost?)])->()) {
        
        var notificationQuery = notificationsReference.child(uid).queryOrdered(byChild: "timestamp")
        if let latestNotificationTimestamp = timestamp, latestNotificationTimestamp > 0 {
            notificationQuery = notificationQuery.queryStarting(atValue: latestNotificationTimestamp + 1, childKey: "timestamp").queryLimited(toLast: limit)
        }
        else {
            notificationQuery = notificationQuery.queryLimited(toLast: limit)
        }
        
        notificationQuery.observeSingleEvent(of: .value) { (snapshot) in
            // Old versions of the app have "feed" notification types so we need to get rid of those
            let items = snapshot.children.allObjects
            let myGroup = DispatchGroup()
            
            var results: [(notification: StripwayNotification, user: StripwayUser, post: StripwayPost?)] = []
            
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()

                let snapshotValue = item.value as! [String: Any]
                print(snapshotValue)
                let type = snapshotValue["type"] as! String
                if type == "feed" {
                    let error = CustomError("Incompatible notification type")
                    print(error.localizedDescription)
                    myGroup.leave()
                    return
                }
                
                // Create the notification from the firebase snapshot
                let notification = StripwayNotification(snapshot: item)
                // Observe the user for that notification
                API.User.observeUser(withUID: notification.fromUserID, completion: { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        myGroup.leave()
                        return
                    } else if let user = user {
                        if user.isBlocked || user.hasBlocked {
                            let error = CustomError("User is blocked")
                            print(error.localizedDescription)
                            myGroup.leave()
                            return
                        }
                        switch notification.type! {
                        case .like, .comment, .commentMention, .postMention, .repost:
                            let postID = notification.objectID
                            // If the notification is for a post then return that post with the notification
                            API.Post.observePost(withID: postID, completion: { (post, error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                    myGroup.leave()
                                    return
                                }
                                if let post = post {
                                    results.append((notification, user, post))
                                    myGroup.leave()
                                }
                            })
                        case .follow:
                            results.append((notification, user, nil))
                            myGroup.leave()
                        }
                    }
                })
                
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.notification.timestamp > $1.notification.timestamp})
                completion(results)
            })
      
        }
    }
    
    ///Batch loading of notifications, gets notification older than the timestamp
    func getOlderNotifications(forUserID uid: String, start timestamp: Int, limit: UInt, completion: @escaping ([(StripwayNotification, StripwayUser, StripwayPost?)])->()) {
        let notificationQuery = notificationsReference.child(uid).queryOrdered(byChild: "timestamp")
        let limitedQuery = notificationQuery.queryEnding(atValue: timestamp - 1, childKey: "timestamp").queryLimited(toLast: limit)
    
        
        limitedQuery.observeSingleEvent(of: .value) { (snapshot) in
            // Old versions of the app have "feed" notification types so we need to get rid of those
            let items = snapshot.children.allObjects
            let myGroup = DispatchGroup()
            
            var results: [(notification: StripwayNotification, user: StripwayUser, post: StripwayPost?)] = []
            
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()
                
                let snapshotValue = item.value as! [String: Any]
                let type = snapshotValue["type"] as! String
                if type == "feed" {
                    let error = CustomError("Incompatible notification type")
                    print(error.localizedDescription)
                    myGroup.leave()
                    return
                }
                
                // Create the notification from the firebase snapshot
                let notification = StripwayNotification(snapshot: item)
                // Observe the user for that notification
                API.User.observeUser(withUID: notification.fromUserID, completion: { (user, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        myGroup.leave()
                        return
                    } else if let user = user {
                        if user.isBlocked || user.hasBlocked {
                            let error = CustomError("User is blocked")
                            print(error.localizedDescription)
                            myGroup.leave()
                            return
                        }
                        switch notification.type! {
                        case .like, .comment, .commentMention, .postMention, .repost:
                            let postID = notification.objectID
                            // If the notification is for a post then return that post with the notification
                            API.Post.observePost(withID: postID, completion: { (post, error) in
                                if let error = error {
                                    print(error.localizedDescription)
                                    myGroup.leave()
                                    return
                                }
                                if let post = post {
                                    results.append((notification, user, post))
                                    myGroup.leave()
                                }
                            })
                        case .follow:
                            results.append((notification, user, nil))
                            myGroup.leave()
                        }
                    }
                })
                
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.notification.timestamp > $1.notification.timestamp})
                completion(results)
            })
            
        }
    }
    
    /// Observes the notifications for a user to display in NotificationsViewController, NON batch loading
    /// Deprecated
    func observeNotifications(forUserID uid: String, completion: @escaping ((StripwayNotification, StripwayUser)?, StripwayPost?, Error?)->()) {
        notificationsReference.child(uid).observe(.childAdded) { (snapshot) in
            
            // Old versions of the app have "feed" notification types so we need to get rid of those
            let snapshotValue = snapshot.value as! [String: Any]
            let type = snapshotValue["type"] as! String
            if type == "feed" {
                let error = CustomError("Incompatible notification type")
                completion(nil, nil, error)
                return
            }
            
            // Create the notification from the firebase snapshot
            let notification = StripwayNotification(snapshot: snapshot)
            // Observe the user for that notification
            API.User.observeUser(withUID: notification.fromUserID, completion: { (user, error) in
                if let error = error {
                    completion(nil, nil, error)
                    return
                } else if let user = user {
                    if user.isBlocked || user.hasBlocked {
                        let error = CustomError("User is blocked")
                        completion(nil, nil, error)
                        return
                    }
                    switch notification.type! {
                    case .like, .comment, .commentMention, .postMention, .repost:
                        let postID = notification.objectID
                        // If the notification is for a post then return that post with the notification
                        API.Post.observePost(withID: postID, completion: { (post, error) in
                            if let error = error {
                                print(error)
                                completion(nil, nil, error)
                                return
                            }
                            if let post = post {
                                completion((notification, user), post, nil)
                            }
                        })
                    case .follow:
                        completion((notification, user), nil, nil)
                    }
                }
            })
        }
        
    }
    
    func resetUnreadNotificationsCount() {
        let ref = Database.database().reference().child("userNotificationInfo").child(Auth.auth().currentUser!.uid)
        ref.updateChildValues(["unreadNotificationsCount": 0])
        resetSpecificUnreadNotificationsCount()
    }
    
    // This is for the badge count on the notifications button in the home feed
    func getUnreadNotificationsCount(completion: @escaping (Int)->()) {
        let ref = Database.database().reference().child("userNotificationInfo").child(Auth.auth().currentUser!.uid).child("unreadNotificationsCount")
        if self.unreadNotificationCountHandle != nil {
            ref.removeObserver(withHandle: self.unreadNotificationCountHandle)
        }
        unreadNotificationCountHandle =  ref.observe(.value) { (snapshot) in
            if let unreadNotifications = snapshot.value as? Int {
                completion(unreadNotifications)
                return
            }
            completion(0)
        }
    }
    
    func getSpecificUnreadNotificationsCount(completion: @escaping (Int?, Int?, Int?, Int?)->()) {
        let ref = Database.database().reference().child("userNotificationInfo").child(Auth.auth().currentUser!.uid).child("specificUnreadNotificationCounts")
        ref.observeSingleEvent(of: .value) { (snapshot) in
            var reposts: Int?
            var followers: Int?
            var comments: Int?
            var likes: Int?
            if let snapshotValue = snapshot.value as? [String: Any] {
                if let newReposts = snapshotValue["unreadRepostsCount"] as? Int {
                    reposts = newReposts
                }
                if let newFollowers = snapshotValue["unreadFollowersCount"] as? Int {
                    followers = newFollowers
                }
                if let newComments = snapshotValue["unreadCommentsCount"] as? Int {
                    comments = newComments
                }
                if let newLikes = snapshotValue["unreadLikesCount"] as? Int {
                    likes = newLikes
                }
                completion(reposts, followers, comments, likes)
            }
        }
    }
    
    func resetSpecificUnreadNotificationsCount() {
        let ref = Database.database().reference().child("userNotificationInfo").child(Auth.auth().currentUser!.uid).child("specificUnreadNotificationCounts")
        ref.updateChildValues(["unreadRepostsCount": 0, "unreadFollowersCount": 0, "unreadCommentsCount": 0, "unreadLikesCount": 0])
    }
    
}

