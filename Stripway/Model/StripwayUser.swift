//
//  StripwayUser.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/16/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import Firebase

class StripwayUser {
    
    let uid: String
    let email: String
    var username: String
    var name: String
    var databaseReference: DatabaseReference
    /// Same thing as the bio, should rename this but it's called "description" in the database
    var description: String
    var bioLink: String
    var profileImageURL: String?
    var headerImageURL: String?
    var isFollowing: Bool?
    var isVerified: Bool
    var isBlocked: Bool = false
    var hasBlocked: Bool = false
    var blockees: Dictionary<String, Any>
    var blockers: Dictionary<String, Any>
    var showCard: Bool?
    /// I don't know if this is used anywhere in the app and I don't know if it stays accurate,
    /// should look into that.
    var isCurrentUser: Bool {
        if let currentUser = Constants.currentUser {
            if currentUser.uid == self.uid {
                return true
            }
            return false
        }
        return false
    }
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]

        uid = snapshot.key
        email = snapshotValue["email"] as! String
        username = snapshotValue["username"] as! String
        name = snapshotValue["name"] as! String
        databaseReference = API.User.usersReference.child(uid)
        description = snapshotValue["description"] as? String ?? ""
        bioLink = snapshotValue["bioLink"] as? String ?? ""
        profileImageURL = snapshotValue["profileImageURL"] as? String
        headerImageURL = snapshotValue["headerImageURL"] as? String
        isVerified = snapshotValue["isVerified"] as? Bool ?? false
        
        // Load the dictionary of blockees and blockers for this user
        blockees = snapshotValue["blockees"] as? Dictionary<String, Any> ?? [:]
        blockers = snapshotValue["blockers"] as? Dictionary<String, Any> ?? [:]
        showCard = snapshotValue["showCard"] as? Bool
        if !blockees.isEmpty {
            hasBlocked = blockees[Constants.currentUser!.uid] != nil
        }
        if !blockers.isEmpty {
            isBlocked = blockers[Constants.currentUser!.uid] != nil
        }
    }
}

class TaggedUser{
    var user: StripwayUser
    let view: UIButton
    
    init(user:StripwayUser, view:UIButton) {
        self.user = user
        self.view = view
    }
}

