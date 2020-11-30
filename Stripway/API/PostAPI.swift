//
//  PostAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/16/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class PostAPI {
    
    /// This is for the storage section of the database, only images are stored here
    var postsStorageReference = Storage.storage().reference(forURL: "gs://stripeway-2.appspot.com").child("posts")
    var postsDatabaseReference = Database.database().reference().child("posts")
    //when we set postID under missingThumbs, the server will create thumbnail for that
    var missingThumbsReference = Database.database().reference().child("missingThumbs")
    
    var newPost:StripwayPost!
    var newAuthor:StripwayUser!
    var wasNewPostPosted = false
    
    var postLikeHandle:DatabaseHandle!

    /// Creating a new post
    func createPost(postID: String, postImage: UIImage, authorUID: String, caption: String?,captionBgColorCode: String, captionTxtColorCode: String, hashTags: [String], timestamp: Int, stripName: String, stripID: String, imageAspectRatio: CGFloat, withMentions mentions: [String],tags:[String:Any], completion: @escaping (StripwayPost?, Error?)->()) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let captionText = caption ?? ""
        
        var compressionQuality:CGFloat = IMAGE_COMPRESSION_QUALITY
        
        if let imageData = postImage.pngData() {
            let bytes = imageData.count
            let KB = Double(bytes) / 1024.0 // Note the difference
            
            print("uploading image size \(KB)")
            if KB > 8000 {
                compressionQuality = IMAGE_COMPRESSION_QUALITY
            }
            else {
                compressionQuality = 1.0
            }
        }
        if let imageData = postImage.jpegData(compressionQuality: compressionQuality) {
            let photoIDString = NSUUID().uuidString
            let storageRef = postsStorageReference.child(photoIDString)
            HelperService.uploadImage(imageData: imageData, storageReference: storageRef) { (error, url) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(nil, error)
                    return
                }
                if let url = url {
                    
                    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
                    print("Time elapsed for uploading image \(timeElapsed) s.")
                    
//                    let timestamp = Int(Date().timeIntervalSince1970)
                    let post = StripwayPost(postID: postID, photoURL: url.absoluteString, authorUID: authorUID, caption: captionText,captionBgColorCode: captionBgColorCode,captionTxtColorCode: captionTxtColorCode, hashTags: hashTags, timestamp: timestamp, stripName: stripName, stripID: stripID, imageAspectRatio: imageAspectRatio, width:Int(postImage.size.width*0.5), height:Int(postImage.size.height*0.5), tags: tags)
                    
                    self.savePostToDatabase(post: post, completion: { (post, error) in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        completion(post, nil)
                        
                        // Remove duplicates from mentions
                        let newMentions = Array(Set(mentions))
                        // Notify mentions that they were mentioned
                        for uid in newMentions {
                            API.Notification.createNotification(fromUserID: authorUID, toUserID: uid, objectID: post!.postID, type: .postMention)
                        }
                        
                        //Notify to home feed the new post finished publishing
                        NotificationCenter.default.post(name: NEW_POSTING_FINISHED, object: nil, userInfo:nil)

                    })
                }
            }
        } else {
            let post = StripwayPost(postID: postID, photoURL: "", authorUID: authorUID, caption: captionText,captionBgColorCode: captionBgColorCode,captionTxtColorCode: captionTxtColorCode, hashTags: hashTags, timestamp: timestamp, stripName: stripName, stripID: stripID, imageAspectRatio: imageAspectRatio, width:Int(postImage.size.width*0.5), height:Int(postImage.size.height*0.5), tags: tags)
            
            self.savePostToDatabase(post: post, completion: { (post, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                completion(post, nil)
                
                // Remove duplicates from mentions
                let newMentions = Array(Set(mentions))
                // Notify mentions that they were mentioned
                for uid in newMentions {
                    API.Notification.createNotification(fromUserID: authorUID, toUserID: uid, objectID: post!.postID, type: .postMention)
                }
                
                //Notify to home feed the new post finished publishing
                NotificationCenter.default.post(name: NEW_POSTING_FINISHED, object: nil, userInfo:nil)

            })
        }
    }
    
    /// Saves the non image part of the post to the database
    func savePostToDatabase(post: StripwayPost, completion: @escaping (StripwayPost?, Error?)->()) {
        
        let postsReference = postsDatabaseReference
        let newPostReference = postsReference.child(post.postID)
        newPostReference.setValue(post.toAnyObject()) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
                return
            }
            // Adds post to hashtags and adds hashtags to post
            API.Hashtag.updatePostToHashTag(post: post)
            
            // Adds post to poster's feed
            API.Feed.feedReference.child(Constants.currentUser!.uid).child(post.postID).setValue(["timestamp": post.timestamp])
            
            // Adds post to poster's followers' feeds
            // TODO: Consider using a multipath update for this
            API.Follow.followersReference.child(post.authorUID).observeSingleEvent(of: .value, with: { (snapshot) in
                let arraySnapshot = snapshot.children.allObjects as! [DataSnapshot]
                arraySnapshot.forEach({ (child) in
                    print(child.key)
                    API.Feed.feedReference.child(child.key).child(post.postID).setValue(["timestamp": post.timestamp])
                })
            })
            
            // Adds post to myPosts in the users section of the database
            // Also adds timestamp
            post.postReference = ref
            let authorsPostsReference = API.User.usersReference.child(post.authorUID).child("myPosts").child(post.postID)
            authorsPostsReference.setValue(["timestamp": post.timestamp], withCompletionBlock: { (error, ref) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(nil, error)
                } else {
                    completion(post, nil)
                }
            })
        }
        
    }
    
    /// This just updates the caption for a post when the user edits it
    func updateCaptionForPost(post: StripwayPost, description: String) {
        post.postReference?.child("caption").setValue(description, withCompletionBlock: { (error, ref) in
            if let error = error {
                print("That's not good, we couldn't update the description: \(error.localizedDescription)")
            }
            // TODO: Add updateMentionsForPost too
            API.Hashtag.updateHashtagsForPost(post: post)
        })
    }
    
    /// Returns the whole post, if the post doesn't exist then we return an error
    func observePost(withID postID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        
        print("before crash post ID ", postID)
        postsDatabaseReference.child(postID).observeSingleEvent(of: .value) { (snapshot) in
            if (snapshot.value as? [String: Any]) != nil {
                print("OBSERVING POST: \(snapshot.key)")
                let post = StripwayPost(snapshot: snapshot)
                if post.thumbURL != nil {
                    print(post.postID)
                }
                completion(post, nil)
            } else {
                let error = CustomError("Post doesn't exist: \(snapshot.key)")
                completion(nil, error)
            }
        }
    }
    
    /// Deletes a post and all its references on the database
    /// TODO: Remove from users' likes too
    func deletePost(post: StripwayPost) {
        
        // Deleting post from strip
        let postReferenceInStrip = API.Strip.stripsDatabaseReference.child(post.stripID).child("posts").child(post.postID)
        postReferenceInStrip.removeValue { (error, ref) in
            if let error = error {
                print("didn't delete postReferenceInStrip correctly")
                print(error.localizedDescription)
            } else {
                print("deleted postReferenceInStrip correctly")
            }
        }
        
        // Deleting post from user
        let postReferenceInUser = API.User.usersReference.child(post.authorUID).child("myPosts").child(post.postID)
        postReferenceInUser.removeValue { (error, ref) in
            if let error = error {
                print("didn't delete postReferenceInUser correctly")
                print(error.localizedDescription)
            } else {
                print("deleted postReferenceInUser correctly")
            }
        }
        
        // Deleting post from "posts" part of database
        let postReferenceInPosts = postsDatabaseReference.child(post.postID)
        postReferenceInPosts.removeValue { (error, ref) in
            if let error = error {
                print("didn't delete postReferenceInPosts correctly")
                print(error.localizedDescription)
            } else {
                print("deleted postReferenceInPosts correctly")
            }
        }
        
        // Deleting post's image from storage
        if !post.photoURL.isEmpty {
            let postReferenceInStorage = Storage.storage().reference(forURL: post.photoURL)
            postReferenceInStorage.delete { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    print("photo didn't delete")
                } else {
                    print("photo deleted correctly")
                }
            }
        }
        
        
        // Deleting post from author and followers' feeds
        API.Follow.followersReference.child(post.authorUID).observeSingleEvent(of: .value, with: { (snapshot) in
            let arraySnapshot = snapshot.children.allObjects as! [DataSnapshot]
            arraySnapshot.forEach({ (child) in
                print(child.key)
                API.Feed.feedReference.child(child.key).child(post.postID).removeValue()
            })
        })
        API.Feed.feedReference.child(post.authorUID).child(post.postID).removeValue()
        
        // Deleting post from everyone's reposts
        post.reposts.forEach { (item) in
            API.Reposts.repostsReference.child(item.key).child(post.postID).removeValue()
        }
        
        //Remove from hashtags
        post.hashTags.forEach { (item) in
            
            print("Clear it from hashtags too")
            API.Hashtag.hashtagDatabaseReference.child(item).child(post.postID).removeValue()
        }
        
        
        
    }
    
    var reportedPostsReference = Database.database().reference().child("reports").child("posts")
    
    func reportPost(post: StripwayPost) {
        let reportedTimestamp = Int(Date().timeIntervalSince1970)
        reportedPostsReference.child(post.postID).setValue(["reportedTimestamp": reportedTimestamp])
    }
    
    func fetchAllPosts(completion: @escaping (StripwayPost?, Error?)->()) {
        
        postsDatabaseReference.observeSingleEvent(of: .value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                API.Post.observePost(withID: childSnapshot.key, completion: { (post, error) in
                    completion(post, error)
                })
            }
        }
    }

    func fetchReportedPosts(completion: @escaping (StripwayPost?, Error?)->()) {
        reportedPostsReference.observeSingleEvent(of: .value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                API.Post.observePost(withID: childSnapshot.key, completion: { (post, error) in
                    completion(post, error)
                })
            }
        }
    }
    
    func fetchRemovedReportedPosts(completion: @escaping(String)->()) {
        reportedPostsReference.observe(.childRemoved) { (snapshot) in
            completion(snapshot.key)
        }
    }
    
    func removePostFromReported(post: StripwayPost) {
        reportedPostsReference.child(post.postID).removeValue()
    }
    
    //add to missing thumbnails group to create thumbnail now
    // as old images do not have thumbnail, we will create thumbnail when user likes the photo
    func addMissingThumbnail(postWithID postID: String, forPostURL postURL:String, forWidth width:Int, forHeight height:Int) {
        missingThumbsReference.child(postID).setValue(["photoURL" : postURL,
                                                       "width" : width,
                                                       "height" : height
                                                       ])
    }
    var archiveDatabaseReference = Database.database().reference().child("archived")
    
    func archive(postWithID postID: String, fromPostAuthor authorID: String) {
        
        archiveDatabaseReference.child("posts").child(authorID).child(postID).child("archived").setValue(true)
        print("Archived: \(authorID) and post:\(postID)")
        
    }
    
    func unarchive(postWithID postID: String, fromPostAuthor authorID: String) {
        archiveDatabaseReference.child("posts").child(authorID).child(postID).removeValue()
    }
    
    
    var likesReference = Database.database().reference().child("likes")
    
    /// Adds the post to the liker's likes, notifies post owner
    /// TODO: Changed repostedTimestamp to likedTimestamp
    /// TODO: Invert the timestamp so we can load in order
    func like(postWithID postID: String, fromPostAuthor authorID: String, withRepostedTimestamp repostedTimestamp: Int, forUserWithID userID: String) {
        likesReference.child(userID).child(postID).setValue(["repostedTimestamp": repostedTimestamp])
        API.Notification.createNotification(fromUserID: userID, toUserID: authorID, objectID: postID, type: .like)
    }
    
    /// Removes posts from liker's likes
    /// TODO: Maybe remove the notification
    func unLike(postWithID postID: String, forUserWithID userID: String) {
        likesReference.child(userID).child(postID).removeValue()
    }
    
    var bookmarksReference = Database.database().reference().child("bookmarks")
    
    /// Adds the post to the bookmarker's bookmarks
    /// TODO: Change repostedTimestamp to bookmarkedTimestamp
    /// TODO: Invert the timestamp so we can load in order
    func bookmark(postWithID postID: String, withRepostedTimestamp repostedTimestamp: Int, forUserWithID userID: String) {
        bookmarksReference.child(userID).child(postID).setValue(["repostedTimestamp": repostedTimestamp])
    }
    
    /// Removes the post from the bookmarker's bookmarks
    func unBookmark(postWithID postID: String, forUserWithID userID: String) {
        bookmarksReference.child(userID).child(postID).removeValue()
    }
    
    /// Fetches the likes for a user
    /// Uses .observe so we're not waiting a crazy amount of time before we actually see anything
    /// TODO: Load these in batches
    func fetchLikes(forUID userID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        let ref = API.Post.likesReference.child(userID)
        if postLikeHandle != nil {
            ref.removeObserver(withHandle: postLikeHandle)
        }
        postLikeHandle = ref.observe(.childAdded) { (snapshot) in
            API.Post.observePost(withID: snapshot.key, completion: { (post, error) in
                completion(post, error)
            })
        }
    }

    /// Fetches the bookmarks for a user
    /// Uses .observe so we're not waiting a crazy amount of time before we actually see anything
    /// TODO: Load these in batches
    func fetchBookmarks(forUID userID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        API.Post.bookmarksReference.child(userID).observe(.childAdded) { (snapshot) in
            API.Post.observePost(withID: snapshot.key, completion: { (post, error) in
                completion(post, error)
            })
        }
    }
    
    /// Uses transactions to make sure like number for each post as well as list of likers is always accurate
    func incrementLikes(postID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        let ref = postsDatabaseReference.child(postID)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            // TODO: Change post to a StripwayPost here instead of [String : AnyObject]
            if var post = currentData.value as? [String : AnyObject], let uid = Constants.currentUser?.uid {
                print("value 1: \(String(describing: currentData.value))")
                var likes: Dictionary<String, Bool>
                likes = post["likes"] as? [String : Bool] ?? [:]
                var likeCount = post["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    // Unlike the post and remove self from likes
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                    API.Post.unLike(postWithID: ref.key!, forUserWithID: uid)
                } else {
                    // Star the post and add self to stars
                    likeCount += 1
                    likes[uid] = true
                    let newTimestamp = Int(Date().timeIntervalSince1970)
                    let authorUID = post["authorUID"] as! String
                    API.Post.like(postWithID: ref.key!, fromPostAuthor: authorUID, withRepostedTimestamp: newTimestamp, forUserWithID: uid)
                    
                }
                post["likeCount"] = likeCount as AnyObject?
                post["likes"] = likes as AnyObject?
                
                // Set value and report transaction success
                currentData.value = post
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let post = StripwayPost(snapshot: snapshot!)
                completion(post, nil)
            }
        }
    }
    
    /// Uses transactions to make sure repost number for each post as well as list of reposters is always accurate
    /// Also adds to users reposts and sets the timestamp for when the post was reposted
    func incrementReposts(postID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        let ref = postsDatabaseReference.child(postID)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject], let uid = Constants.currentUser?.uid {
                var reposts: Dictionary<String, Bool>
                reposts = post["reposts"] as? [String : Bool] ?? [:]
                var repostCount = post["repostCount"] as? Int ?? 0
                if let _ = reposts[uid] {
                    // Unstar the post and remove self from stars
                    repostCount -= 1
                    reposts.removeValue(forKey: uid)
                    API.Reposts.unRepost(postWithID: ref.key!, forUserWithID: uid)
                    
                } else {
                    // Star the post and add self to stars
                    repostCount += 1
                    reposts[uid] = true
                    let newTimestamp = Int(Date().timeIntervalSince1970)
                    let authorUID = post["authorUID"] as! String
                    API.Reposts.repost(postWithID: ref.key!, fromPostAuthor: authorUID, withRepostedTimestamp: newTimestamp, forUserWithID: uid)
                }
                post["repostCount"] = repostCount as AnyObject?
                post["reposts"] = reposts as AnyObject?
                
                // Set value and report transaction success
                currentData.value = post
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let post = StripwayPost(snapshot: snapshot!)
                completion(post, nil)
            }
        }
    }
    
    /// Uses transactions to make sure bookmark number for each post as well as list of bookmarkers is always accurate
    /// Also adds to users bookmarks and sets the timestamp for when the post was bookmarked
    /// TODO: Bookmarks are private so the count/list stuff may be unnecessary unless we want to implement it later
    func incrementBookmarks(postID: String, completion: @escaping (StripwayPost?, Error?)->()) {
        let ref = postsDatabaseReference.child(postID)
        ref.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var post = currentData.value as? [String : AnyObject], let uid = Constants.currentUser?.uid {
                var bookmarks: Dictionary<String, Bool>
                bookmarks = post["bookmarks"] as? [String : Bool] ?? [:]
                var bookmarkCount = post["bookmarkCount"] as? Int ?? 0
                if let _ = bookmarks[uid] {
                    // Unstar the post and remove self from stars
                    bookmarkCount -= 1
                    bookmarks.removeValue(forKey: uid)
                    API.Post.unBookmark(postWithID: ref.key!, forUserWithID: uid)
                    
                } else {
                    // Star the post and add self to stars
                    bookmarkCount += 1
                    bookmarks[uid] = true
                    let newTimestamp = Int(Date().timeIntervalSince1970)
                    API.Post.bookmark(postWithID: ref.key!, withRepostedTimestamp: newTimestamp, forUserWithID: uid)
                }
                post["bookmarkCount"] = bookmarkCount as AnyObject?
                post["bookmarks"] = bookmarks as AnyObject?
                
                // Set value and report transaction success
                currentData.value = post
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let post = StripwayPost(snapshot: snapshot!)
                completion(post, nil)
            }
        }
    }
    
    /// Fetches all the people who reposted a post, used for the repost list
    func fetchReposters(forPostID postID: String, completion: @escaping (StripwayUser?, Error?)->()) {
        postsDatabaseReference.child(postID).child("reposts").observeSingleEvent(of: .value) { (snapshot) in
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
    
    /// Fetches all the people who liked a post, used for the like list
    func fetchLikers(forPostID postID: String, completion: @escaping (StripwayUser?, Error?)->()) {
        postsDatabaseReference.child(postID).child("likes").observeSingleEvent(of: .value) { (snapshot) in
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
