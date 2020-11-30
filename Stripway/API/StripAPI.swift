//
//  StripAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/17/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import Firebase

class StripAPI {
    
    var stripsDatabaseReference = Database.database().reference().child("strips")
    var postsForStripHandle:DatabaseHandle!
    var fetchStripHandle:DatabaseHandle!
    var fetchStripIDsHandle:DatabaseHandle!
    
    func removeAllObservers() {
        stripsDatabaseReference.removeAllObservers()
    }
    
    /// Fetches all the strips at a database reference, uses .childAdded so it updates whenever we add a new strip
    func fetchStrips(atDatabaseReference ref: DatabaseReference, completion: @escaping (String)->()) {
        if fetchStripHandle != nil {
            ref.removeObserver(withHandle: fetchStripHandle)
        }
        fetchStripHandle =  ref.observe(.childAdded) { (snapshot) in
            completion(snapshot.key)
        }
    }
    
    /// Fetches all the strips IDs at a database reference, uses .childAdded so it updates whenever we add a new strip
    func fetchStripIDs(forUserID userID: String, completion: @escaping (String)->()) {
        let ref = API.User.usersReference.child(userID).child("myStrips")
        if fetchStripIDsHandle != nil {
            ref.removeObserver(withHandle: fetchStripIDsHandle)
        }
        fetchStripIDsHandle = ref.observe(.childAdded) { (snapshot) in
            completion(snapshot.key)
        }
    }
    
    /// Fetches all the strips IDs at a database reference, and observe it's change like add or remove
    func fetchStripIDsConstantly(forUserID userID: String, completion: @escaping ([String]?)->()) {
        let ref = API.User.usersReference.child(userID).child("myStrips")
        if fetchStripIDsHandle != nil {
            ref.removeObserver(withHandle: fetchStripIDsHandle)
        }
        fetchStripIDsHandle = ref.observe(.value, with: { (snapshot) in
            print(snapshot.value)
            let stripeIDsArray = snapshot.value as? [String:String]
            var stripeIDs:[String]? = []
            
            if let iDs = stripeIDsArray {
                for id in iDs {
                    stripeIDs?.append(id.key)
                }
                completion(stripeIDs)
            }
            else {
                completion(nil)
            }
        })
    }
    
    func observeNameAndIndexForStripID(stripID: String, completion: @escaping (String?, Int?)->()) {
        stripsDatabaseReference.child(stripID).observe(.childChanged) { (snapshot) in
            if snapshot.key == "name" {
                completion(snapshot.value as? String, nil)
            } else if snapshot.key == "index" {
                completion(nil, snapshot.value as? Int)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    /// Also observe .childRemoved so when a strip is deleted it updates
    func observeStripIDsRemoved(forUserID userID: String, completion: @escaping (String)->()) {
        let ref = API.User.usersReference.child(userID).child("myStrips")
        ref.observe(.childRemoved) { (snapshot) in
            let key = snapshot.key
            completion(key)
        }
    }
    
    /// Returns the StripwayStrip object for a stripID
    func observeStrip(withID stripID: String, completion: @escaping (StripwayStrip)->()) {
        stripsDatabaseReference.child(stripID).observeSingleEvent(of: .value) { (snapshot) in
            let strip = StripwayStrip(snapshot: snapshot)
            completion(strip)
        }
    }
    
    /// TODO: make this load posts in a strip chronologically
    /// Observes posts at the database reference inside the strip, uses .observe so whenever a new post is added it updates
    /// TODO: Invert timestamps on postIDs in a strip and we can load them chronologically instead of loading them backwards and
    /// then just displaying them chronologically
    func observePostsForStrip(atDatabaseReference ref: DatabaseReference, completion: @escaping (StripwayPost?, Error?, Bool?)->()){
        // We use this instead of the posts array under the strip so we can observe any new changes
        if postsForStripHandle != nil {
            ref.removeObserver(withHandle: postsForStripHandle)
        }
        postsForStripHandle = ref.observe(.value) { (snapshot) in
            completion(nil, nil, true)
            for case let childSnapshot as DataSnapshot in snapshot.children {
                API.Post.observePost(withID: childSnapshot.key, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    completion(post, error, nil)
                })
            }
        }
    }
    
    /// Creates a new strip and then adds a post to it
    func addPostToNewStrip(postID:String, stripName: String, newStripID:String, authorUID: String, postImage: UIImage, caption: String,captionBgColorCode:String,captionTxtColorCode:String, hashTags: [String], timestamp:Int, imageAspectRatio: CGFloat, withMentions: [String],tags:[String:Any], completion: @escaping (Error?)->()) {
//        let newStripID = stripsDatabaseReference.childByAutoId().key!
        let strip = StripwayStrip(stripID: newStripID, name: stripName, authorID: authorUID, index: 999)
        let newStripReference = stripsDatabaseReference.child(strip.stripID)
        // Adding the strip to the strips part of the database
        newStripReference.setValue(strip.toAnyObject()) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                completion(error)
                return
            }
            // Adding the strip to the user's myStrips
            let authorsStripsReference = API.User.usersReference.child(strip.authorID).child("myStrips").child(strip.stripID)
            authorsStripsReference.setValue(strip.stripID, withCompletionBlock: { (error, ref) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(error)
                    return
                }
                
                API.Post.createPost(postID:postID, postImage: postImage, authorUID: authorUID, caption: caption, captionBgColorCode: captionBgColorCode,captionTxtColorCode: captionTxtColorCode, hashTags: hashTags, timestamp:timestamp, stripName: stripName, stripID: strip.stripID, imageAspectRatio: imageAspectRatio, withMentions: withMentions, tags: tags, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    API.Strip.addPostToStrip(withID: strip.stripID, post: post!)
                    completion(nil)
                })
            })
        }
    }
    
    /// Sets the index for a strip, this happens automatically when a user reorders their strip cells on their profile
    func setIndex(index: Int, forStrip strip: StripwayStrip) {
        let stripReference = strip.stripReference!
        // this should maybe be in completion handler
        strip.index = index
        stripReference.child("index").setValue(index) { (error, ref) in
            if let error = error {
                print("couldn't set strip index: \(error.localizedDescription)")
                return
            }
        }
    }
    
    /// Adds a post to an exising strip
    /// TODO: Invert the timestamp because when you query by timestamp it loads smaller numbers first,
    /// So if we wanted it in reverse chronological order (newest first) we could just use 0-timestamp
    func addPostToStrip(withID stripID: String, post: StripwayPost) {
        stripsDatabaseReference.child(stripID).child("posts").child(post.postID).setValue(["timestamp": post.timestamp])
    }
    
    /// Deletes a strip everywhere it exists, and also deletes all its posts
    func deleteStrip(strip: StripwayStrip) {
        
        // Get all the postIDs from the postsReference, observe the posts, then delete them
        // TODO: Improve this so we only need a postID (instead of the whole post) to delete it
        // Though it's not that big a deal because posts aren't deleted that often
        let postsReference = strip.postsReference!
        postsReference.observeSingleEvent(of: .value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                API.Post.observePost(withID: childSnapshot.key, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    if let post = post {
                        API.Post.deletePost(post: post)
                    }
                })
            }
        }
        
        // Delete strip from user's myStrips
        let stripReferenceInUser = API.User.usersReference.child(strip.authorID).child("myStrips").child(strip.stripID)
        stripReferenceInUser.removeValue { (error, ref) in
            if let error = error {
                print("didn't delete stripReferenceInUser correctly")
                print(error.localizedDescription)
            } else {
                print("deleted stripReferenceInUser correctly")
            }
        }
        
        // Delete strip from actualy strips part of the database
        let stripReferenceInStrips = stripsDatabaseReference.child(strip.stripID)
        stripReferenceInStrips.removeValue { (error, ref) in
            if let error = error {
                print("didn't delete stripReferenceInStrips correctly")
                print(error.localizedDescription)
            } else {
                print("deleted stripReferenceInStrips correctly")
            }
        }
        
    }
    
    /// Updates the name for the strip in the database
    func updateName(forStrip strip: StripwayStrip, withName name: String, completion: @escaping (String)->()) {
        
        // Change the name in the actual strips part of the database
        API.Strip.stripsDatabaseReference.child(strip.stripID).child("name").setValue(name) { (error, ref) in
            completion(name)
        }
        
        // Iterate through all the posts in the strip and change their stripName property
        API.Strip.stripsDatabaseReference.child(strip.stripID).child("posts").observeSingleEvent(of: .value) { (snapshot) in
            print("Printing posts for strip: \(strip.name)")
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                print(child.key)
                API.Post.postsDatabaseReference.child(child.key).child("stripName").setValue(name)
            })
        }
    }
    
}

