//
//  BlockAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/30/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

class BlockAPI {
    
    /// Block user uid for currentUser
    func blockUser(withUID uid: String) {
        if Constants.currentUser!.uid == uid {
            return
        }
        // Add the blocked user to the current user's blockees
        API.User.usersReference.child(Constants.currentUser!.uid).child("blockees").child(uid).setValue(true)
        // Add the current user to the blocked user's blockers
        API.User.usersReference.child(uid).child("blockers").child(Constants.currentUser!.uid).setValue(true)
        
        // Remove blocked user from blockees followers and vice versa
        API.Follow.removeFollower(followerUID: uid, fromUser: Constants.currentUser!.uid)
        API.Follow.removeFollower(followerUID: Constants.currentUser!.uid, fromUser: uid)
    }
    
    func unblockUser(withUID uid: String) {
        // Remove the blocked user from the current user's blockees
        API.User.usersReference.child(Constants.currentUser!.uid).child("blockees").child(uid).setValue(NSNull())
        // Remove the current user from the blocked user's blockers
        API.User.usersReference.child(uid).child("blockers").child(Constants.currentUser!.uid).setValue(NSNull())
    }
    
    func isBlocked(userID: String, completion: @escaping (Bool)->()) {
        // Check in the blockees of the current user for the userID
        API.User.usersReference.child(Constants.currentUser!.uid).child("blockees").child(userID).observeSingleEvent(of: .value) { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func hasBlocked(userID: String, completion: @escaping (Bool)->()) {
        // Check in the blockers of the current user for the userID
        API.User.usersReference.child(Constants.currentUser!.uid).child("blockers").child(userID).observeSingleEvent(of: .value) { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// Get all the users that userID has blocked
    func fetchBlockees(forUserID userID: String, completion: @escaping (StripwayUser?, Error?)->()) {
        API.User.usersReference.child(userID).child("blockees").observeSingleEvent(of: .value) { (snapshot) in
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                API.User.observeUser(withUID: child.key, completion: { (user, error) in
                    if let error = error {
                        completion(nil, error)
                    } else if let user = user {
                        completion(user, nil)
                    }
                })
            })
        }
    }
}
