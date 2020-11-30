//
//  FollowAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/26/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FollowAPI {
    
    var followersReference = Database.database().reference().child("followers")
    var followingReference = Database.database().reference().child("following")
    var followingReferenceHandle:DatabaseHandle!
    var followerReferenceHandle:DatabaseHandle!
    
    /// Current user follows user id
    func followAction(withUser id: String) {
        // When you follow a user, you add all their posts to your feed
        API.User.usersReference.child(id).child("myPosts").observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for key in dict.keys {
                    if let value = dict[key] as? [String: Any] {
                        let timestampPost = value["timestamp"] as! Int
                    Database.database().reference().child("feed").child(Constants.currentUser!.uid).child(key).setValue(["timestamp": timestampPost])
                    }
                }
            }
        }
        // And then record that you're following them in both the followers and followings parts of the database
        followersReference.child(id).child(Constants.currentUser!.uid).setValue(true)
        followingReference.child(Constants.currentUser!.uid).child(id).setValue(true)
        
        // Notify they followee that they've been followed
        API.Notification.createNotification(fromUserID: Constants.currentUser!.uid, toUserID: id, objectID: Constants.currentUser!.uid, type: .follow)
    }
    
    /// Current user unfollows user id
    func unfollowAction(withUser id: String) {
        // When you unfollow someone, remove all their posts from your feed
        API.User.usersReference.child(id).child("myPosts").observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for key in dict.keys {
                    Database.database().reference().child("feed").child(Constants.currentUser!.uid).child(key).removeValue()
                }
            }
        }
        // Remove them from your followings and you from their followers
        followersReference.child(id).child(Constants.currentUser!.uid).setValue(NSNull())
        followingReference.child(Constants.currentUser!.uid).child(id).setValue(NSNull())
        // TODO: Maybe remove notification if they get unfollowed
    }
    
    /// Removes follower followerUID from followeeUID, used when one of these users blocks the other
    func removeFollower(followerUID: String, fromUser followeeUID: String) {
        // When you unfollow someone, remove all their posts from your feed
        API.User.usersReference.child(followeeUID).child("myPosts").observeSingleEvent(of: .value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for key in dict.keys {
                    Database.database().reference().child("feed").child(followerUID).child(key).removeValue()
                }
            }
        }
        // Remove them from your followings and you from their followers
        followersReference.child(followeeUID).child(followerUID).setValue(NSNull())
        followingReference.child(followerUID).child(followeeUID).setValue(NSNull())
    }
    
    /// Checks if current user is following userID
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        followersReference.child(userID).child(Constants.currentUser!.uid).observeSingleEvent(of: .value) { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// Fetches the number of users userID is following
    /// Not super efficient as it loads every UID that userID follows
    /// TODO: Add a followerCount property in the database
    func fetchFollowingCount(userID: String, completion: @escaping (Int)->()) {
        
        let userFollowingRefernce:DatabaseQuery = followingReference.child(userID)
        if followingReferenceHandle != nil {
            userFollowingRefernce.removeObserver(withHandle: followingReferenceHandle)
        }
        
        followingReferenceHandle = userFollowingRefernce.observe(.value) { (snapshot) in
            let count = Int(snapshot.childrenCount)
            completion(count)
        }
    }
    
    /// Fetches the number of followers for userID
    /// Not super efficient as it loads every UID that userID follows
    /// TODO: Add a followerCount property in the database
    func fetchFollowerCount(userID: String, completion: @escaping (Int)->()) {
        
        let userFollowerRefernce:DatabaseQuery = followersReference.child(userID)
        if followerReferenceHandle != nil {
            userFollowerRefernce.removeObserver(withHandle: followerReferenceHandle)
        }
        
        followerReferenceHandle = userFollowerRefernce.observe(.value) { (snapshot) in
            let count = Int(snapshot.childrenCount)
            completion(count)
        }
    }
    
    /// Fetches all the StripwayUsers following userID
    /// Uses .observeSingleEventOf which could be bad if there are a ton of followers
    /// TODO: Change to .observe and maybe load in batches
    func fetchFollowers(forUserID userID: String, completion: @escaping (StripwayUser?, Error?)->()) {
        followersReference.child(userID).observeSingleEvent(of: .value) { (snapshot) in
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                API.User.observeUser(withUID: child.key, completion: { (user, error) in
                    if let error = error {
                        completion(nil, error)
                    } else if let user = user {
                        completion(user, error)
                    }
                })
            })
        }
    }
    
    /// Fetches all the StripwayUsers that userID is following
    /// Uses .observeSingleEventOf which could be bad if there are a ton of followers
    /// TODO: Change to .observe and maybe load in batches
    func fetchFollowings(forUserID userID: String, completion: @escaping (StripwayUser?, Error?)->()) {
        followingReference.child(userID).observeSingleEvent(of: .value) { (snapshot) in
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                API.User.observeUser(withUID: child.key, completion: { (user, error) in
                    if let error = error {
                        completion(nil, error)
                    } else if let user = user {
                        completion(user, error)
                    }
                })
            })
        }
    }
    
}
