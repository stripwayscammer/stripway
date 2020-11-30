//
//  UserAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/13/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

class UserAPI {
    
    var usersReference = Database.database().reference().child("users")
    var usernamesReference = Database.database().reference().child("usernames")
    var userHandle:DatabaseHandle!
    var suggestedUsersHandle:DatabaseHandle!
    
    /// Observes current user in the database and returns as a StripwayUser in the completion.
    /// Probably doesn't need to exist, could just use observeUser
    func observeCurrentUser(completion: @escaping (StripwayUser)->()) {
        guard let currentUser = Auth.auth().currentUser else { return }
        usersReference.child(currentUser.uid).observeSingleEvent(of: .value) { (snapshot) in
            let user = StripwayUser(snapshot: snapshot)
            completion(user)
        }
    }
    
    func observeCurrentUserConstantly(completion: @escaping (StripwayUser)->()) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let userQuery =  usersReference.child(currentUser.uid)
        if userHandle != nil {
            userQuery.removeObserver(withHandle: userHandle)
        }
        
       userHandle = userQuery.observe(.value) { (snapshot) in
            let user = StripwayUser(snapshot: snapshot)
            completion(user)
        }
    }
    
    /// Observes user in the database and returns as a StripwayUser in the completion.
    /// Returns an error in the completion handler if the user doesn't exist
    func observeUser(withUID uid: String, completion: @escaping (StripwayUser?, Error?)->()) {
        usersReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.value as? [String: Any]) != nil {
                let user = StripwayUser(snapshot: snapshot)
                print("TEST4: user: \(user.username) isBlocked = \(user.isBlocked)")
                completion(user, nil)
            } else {
                print("This user doesn't exist: \(uid)")
                let error = CustomError("User doesn't exist")
                completion(nil, error)
            }
        }
    }
    
    /// Gets user from username, just returns nil if that user doesn't exist
    func getUser(withUsername username: String, completion: @escaping (StripwayUser?)->()) {
        usernamesReference.child(username).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print("This user exists!")
                let snapshotValue = snapshot.value as! [String: Any]
                let userUID = snapshotValue["uid"] as! String
                print("And his uid = \(userUID)")
                API.User.observeUser(withUID: userUID, completion: { (user, error) in
                    if error != nil {
                        completion(nil)
                    } else if let user = user {
                        completion(user)
                    }
                })
            } else {
                print("User doesn't exist :(")
                completion(nil)
            }
        }
    }
    
    /// The new function to edit user information
    func updateUserInfo(forUser user: StripwayUser, newUsername: String?, newName: String?, newBio: String?, newBioLink: String?, newProfileImage: UIImage?, newHeaderImage: UIImage?, showCard: Bool?, completion: @escaping ()->()) {
        
        let myGroup = DispatchGroup()
        
        if let newUsername = newUsername, newUsername != user.username {
            let newUsernameData = [
                "/usernames/\(newUsername)": ["email": user.email, "uid": user.uid],
                "/usernames/\(user.username)": NSNull(),
                "/users/\(user.uid)/username": newUsername
            ] as [String: Any]
            myGroup.enter()
            Database.database().reference().updateChildValues(newUsernameData) { (_, _) in
                myGroup.leave()
            }
        }
        
        var otherNewUserData = [String: Any]()
        if let newName = newName, newName != user.name {
            otherNewUserData["/users/\(user.uid)/name"] = newName
        }
        if let newBio = newBio, newBio != user.description {
            otherNewUserData["/users/\(user.uid)/description"] = newBio
        }
        if let newBioLink = newBioLink, newBioLink != user.bioLink {
            otherNewUserData["/users/\(user.uid)/bioLink"] = newBioLink
        }
        if let showCard = showCard {
            otherNewUserData["/users/\(user.uid)/showCard"] = showCard
        }
        myGroup.enter()
        Database.database().reference().updateChildValues(otherNewUserData) { (_, _) in
            myGroup.leave()
        }
        
        if let newProfileImage = newProfileImage {
            
            var compressionQuality:CGFloat = AVATAR_COMPRESSION_QUALITY
            
            if let imageData = newProfileImage.pngData() {
                let bytes = imageData.count
                let KB = Double(bytes) / 1024.0 // Note the difference
                
                print("uploading avatar size \(KB)")
                if KB > 8000 {
                    compressionQuality = AVATAR_COMPRESSION_QUALITY
                }
                else {
                    compressionQuality = IMAGE_COMPRESSION_QUALITY
                }
            }

            let newProfileImageData = newProfileImage.jpegData(compressionQuality: compressionQuality)
            if let imageData = newProfileImageData {
                myGroup.enter()
                HelperService.uploadImage(imageData: imageData, storageReference: Constants.storageRef.child("profile_image").child(user.uid)) { (error, url) in
                    myGroup.leave()
                    if let url = url {
                        let userRef = self.usersReference.child(user.uid)
                        myGroup.enter()
                        userRef.child("profileImageURL").setValue(url.absoluteString, withCompletionBlock: { (_, _) in
                            myGroup.leave()
                        })
                    }
                }
            }
        }
        
        if let newHeaderImage = newHeaderImage {
            
            var compressionQuality:CGFloat = AVATAR_COMPRESSION_QUALITY
            if let imageData = newHeaderImage.pngData() {
                let bytes = imageData.count
                let KB = Double(bytes) / 1024.0 // Note the difference
                
                print("uploading avatar size \(KB)")
                if KB > 8000 {
                    compressionQuality = AVATAR_COMPRESSION_QUALITY
                }
                else {
                    compressionQuality = IMAGE_COMPRESSION_QUALITY
                }
            }

            let newHeaderImageData = newHeaderImage.jpegData(compressionQuality: compressionQuality)
            
            if let imageData = newHeaderImageData {
                myGroup.enter()
                HelperService.uploadImage(imageData: imageData, storageReference: Constants.storageRef.child("header_image").child(user.uid)) { (error, url) in
                    myGroup.leave()
                    if let url = url {
                        let userRef = self.usersReference.child(user.uid)
                        myGroup.enter()
                        userRef.child("headerImageURL").setValue(url.absoluteString, withCompletionBlock: { (_, _) in
                            myGroup.leave()
                        })
                    }
                }
            }
        }
        myGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
        
    }
    
    /// OLD FUNCTION
    /// Updates user info once the profile is done being edited, only uploads anything to the database if it's actually different
    /// TODO: Change this to take UIImages instead of image data so the VC doesn't have to do that conversion
    func updateUserInformation(forUID uid: String, description: String? = nil, bioLink: String? = nil, profileImageData: Data? = nil, headerImageData: Data? = nil, completion: @escaping (Error?)->()) {
        if let description = description {
            usersReference.child(uid).updateChildValues(["description": description])
        }
        
        if let bioLink = bioLink {
            usersReference.child(uid).updateChildValues(["bioLink": bioLink])
        }
        
        // For the images it takes in Data as the parameter instead of UIImage, should probably change it to take the image
        if let profileImageData = profileImageData {
            HelperService.uploadImage(imageData: profileImageData, storageReference: Constants.storageRef.child("profile_image").child(uid)) { (error, url) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(error)
                }
                if let url = url {
                    let profileOwnerRef = self.usersReference.child(uid)
                    profileOwnerRef.child("profileImageURL").setValue(url.absoluteString)
                }
            }
        }
        
        if let headerImageData = headerImageData {
            HelperService.uploadImage(imageData: headerImageData, storageReference: Constants.storageRef.child("header_image").child(uid)) { (error, url) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(error)
                }
                if let url = url {
                    let profileOwnerRef = self.usersReference.child(uid)
                    profileOwnerRef.child("headerImageURL").setValue(url.absoluteString)
                }
            }
        }
        
    }
    
//    /// Queries users based on a string, used for the search
//    func queryUsers(withText text: String, completion: @escaping (StripwayUser?, Error?)->()) {
//        usersReference.queryOrdered(byChild: "username").queryStarting(atValue: text).queryEnding(atValue: text+"\u{f8ff}").queryLimited(toFirst: 13).observeSingleEvent(of: .value) { (snapshot) in
//            snapshot.children.forEach({ (s) in
//                let child = s as! DataSnapshot
//                if (child.value as? [String: Any]) != nil {
//                    print("searching for user: \(child.key)")
//                    let user = StripwayUser(snapshot: child)
//                    if user.isBlocked || user.hasBlocked {
//                        let error = CustomError("Blocked user")
//                        completion(nil, error)
//                    } else {
//                        completion(user, nil)
//                    }
//
//                }
//            })
//        }
//    }
    
    /// Queries users based on a string, used for the search
    func queryUsers(withText text: String, completion: @escaping (StripwayUser)->()) {
        // Querying by key in /usernames/ in the database because querying by child didn't seem to work well
        usernamesReference.queryOrderedByKey().queryStarting(atValue: text).queryEnding(atValue:
            text+"\u{f8ff}").queryLimited(toFirst: 13).observeSingleEvent(of: .value) { (snapshot) in
            // For each child of /usernames/ returned
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                // If that child is formatted correctly and has a uid child
                if let snapshotValue = child.value as? [String: Any], let uid = snapshotValue["uid"] as? String {
                    // Observe that user and return it
                    API.User.observeUser(withUID: uid, completion: { (user, error) in
                        if let user = user {
                            // Only return the user if they aren't blocked by and haven't blocked current user
                            if !user.isBlocked && !user.hasBlocked {
                                completion(user)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func addToSuggestedUsers(uid: String, completion: @escaping()->()) {
        Database.database().reference().child("admin").child("suggestedUsers").updateChildValues([uid: 1000]) { (_, _) in
            completion()
        }
    }
    func removeFromSuggestedUsers(uid: String, completion: @escaping()->()) {
        Database.database().reference().child("admin").child("suggestedUsers").updateChildValues([uid: NSNull()]) { (_, _) in
            completion()
        }
    }
    
    func updateIndexSuggestedUser(uid: String, index: Int) {
        Database.database().reference().child("admin").child("suggestedUsers").updateChildValues([uid: index])
    }
    
    func observeSuggestedUsers(completion: @escaping((StripwayUser, Int)?, Bool?)->()) {
        let suggestedUsersQuery = Database.database().reference().child("admin").child("suggestedUsers")
        if suggestedUsersHandle != nil {
            suggestedUsersQuery.removeObserver(withHandle: suggestedUsersHandle)
        }
        suggestedUsersHandle = suggestedUsersQuery.observe(.value) { (snapshot) in
            completion(nil, true)
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let index = childSnapshot.value as? Int ?? 1000
                API.User.observeUser(withUID: childSnapshot.key, completion: { (user, error) in
                    if let user = user {
                        completion((user, index), nil)
                    }
                })
            }
        }
    }
}


