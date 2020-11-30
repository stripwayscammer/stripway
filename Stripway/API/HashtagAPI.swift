//
//  HashtagAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/12/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

class HashtagAPI {
    
    // Where hashtags are stored in the database, looks like this /hashtags/{hashtag}/{postID}
    var hashtagDatabaseReference = Database.database().reference().child("hashtags")
    
    var fetchHashTagsHandle:DatabaseHandle!
    var fetchHashTagsIDHandle:DatabaseHandle!

    
    // Called when post is created or caption is edited, should add all new hashtags and remove those that
    // were removed from the caption
    func updateHashtagsForPost(post: StripwayPost) {
        
        // Each separate word has potential to be a hashtag
        var words = post.caption.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        // Lowercase all of them because hashtags are lowercased in the database
        words = words.map{ $0.lowercased() }
        
        for var word in words {
            // If the word is prefixed with a # then it's a hashtag
            if word.hasPrefix("#") {
                // Remove punctuation and the #
                word = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
                // Add the post to the hashtag
                let newHashtagRef = API.Hashtag.hashtagDatabaseReference.child(word.lowercased())
                newHashtagRef.updateChildValues([post.postID: post.timestamp])
                // Add the hashtag to the post
                API.Post.postsDatabaseReference.child(post.postID).child("hashtags").updateChildValues([word: true])
            }
        }
        
        // Obseve the posts hashtags
        API.Post.postsDatabaseReference.child(post.postID).child("hashtags").observeSingleEvent(of: .value) { (snapshot) in
            // For each of the posts hashtags
            for case let childSnapshot as DataSnapshot in snapshot.children {
                // If the new caption doesn't contain that hashtag, remove it from the post and remove the post
                // from the hashtag
                if !words.contains("#" + childSnapshot.key) {
                    print("\(childSnapshot.key) has been removed from hashtags")
                    self.remove(post: post, fromHashtag: childSnapshot.key)
                } else {
                    print("\(childSnapshot.key) has NOT been removed from hashtags")
                }
            }
        }
    }
    
    func remove(post: StripwayPost, fromHashtag hashtag: String) {
        // Remove the post from the hashtag
        API.Hashtag.hashtagDatabaseReference.child(hashtag).child(post.postID).removeValue()
        // Remove the hashtag from the post
        API.Post.postsDatabaseReference.child(post.postID).child("hashtags").child(hashtag).removeValue()
    }
    
    
    // Change this to single event (actually maybe not)
    func fetchPosts(forHashtag hashtag: String, completion: @escaping (StripwayPost?, Error?)->()) {
        hashtagDatabaseReference.child(hashtag.lowercased()).observe(.childAdded) { (snapshot) in
            API.Post.observePost(withID: snapshot.key, completion: { (post, error) in
                completion(post, error)
            })
        }
    }
    
    /// Looks at user's recent posts to get most recently used hashtags
    func queryRecentHashtags(withUserUID: String, limitResults:Int = 50, completion: @escaping (String?)->()) {        API.User.usersReference.child(withUserUID).child("myPosts").queryLimited(toFirst: UInt(limitResults)).observeSingleEvent(of: .value) {(snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for key in dict.keys {
                    API.Post.postsDatabaseReference.child(key).child("hashtags").observeSingleEvent(of: .value) { (hashtagSnapshot) in
                        if let hashtagDict = hashtagSnapshot.value as? [String: Any] {
                            for tag in hashtagDict.keys {
                                completion(tag)
                            }
                        }
                    }
                }
            }
        }
    }

    
    /// Fetches all the hashTags at a user reference, uses
    func fetchHashtags(withUserUID: String, completion: @escaping ([String]?)->()) {
        let ref = API.User.usersReference.child(withUserUID).child("myHashTags")
        if fetchHashTagsHandle != nil {
            ref.removeObserver(withHandle: fetchHashTagsHandle)
        }
        fetchHashTagsHandle = ref.observe(.value, with: { (snapshot) in
            if let data = snapshot.value as? [String] {
                completion(data)
            }else{
                completion([])
            }
        })
    }
    
    func postHashtags(withUserUID: String, tags: [String]) {
        let ref = API.User.usersReference.child(withUserUID).child("myHashTags")
        if fetchHashTagsHandle != nil {
            ref.removeObserver(withHandle: fetchHashTagsHandle)
        }
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let data = snapshot.value as? [String] {
                var temp = tags
                temp = tags + data
                ref.setValue(temp)
            }else{
                ref.setValue(tags)
            }
        })
    }
    
    func updatePostToHashTag(post: StripwayPost) {
        for hashTag in post.hashTags {
            hashtagDatabaseReference.child(hashTag).child(post.postID).setValue(post.timestamp)
        }
    }
    
    // Queries hashtags based on a string, used for the search
    func queryHashtags(withText text: String, limitResults:Int = 13, completion: @escaping (String, Int)->()) {
        
        if limitResults != 0
        {
            hashtagDatabaseReference.queryOrderedByKey().queryStarting(atValue: text).queryEnding(atValue: text+"\u{f8ff}").queryLimited(toFirst: UInt(limitResults)).observeSingleEvent(of: .value) { (snapshot) in
                snapshot.children.forEach({ (childSnapshot) in
                    let childSnapshot = childSnapshot as! DataSnapshot
                    print("Returned \(childSnapshot.key) for search term: \(text)")
                    print("Returned object\(childSnapshot) for search term: \(text)")
                    completion(childSnapshot.key, Int(childSnapshot.childrenCount))
                })
            }
        }
            else {
                hashtagDatabaseReference.queryOrderedByKey().queryStarting(atValue: text).queryEnding(atValue: text+"\u{f8ff}").observeSingleEvent(of: .value) { (snapshot) in
                    snapshot.children.forEach({ (childSnapshot) in
                        let childSnapshot = childSnapshot as! DataSnapshot
                        print("Returned \(childSnapshot.key) for search term: \(text)")
                        print("Returned object\(childSnapshot) for search term: \(text)")
                        completion(childSnapshot.key, Int(childSnapshot.childrenCount))
                    })
                }
            }
        
    }
    
}
