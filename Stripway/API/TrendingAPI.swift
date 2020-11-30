//
//  TrendingAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 12/5/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage

class TrendingAPI {
    
    var trendtagDatabaseReference = Database.database().reference().child("trendtags")
    var trendTagHanlde:DatabaseHandle!
    var headerImageHandle:DatabaseHandle!
    
    /// This is for admin to create a new trending hashtag
    func createNewTrendtag(name: String) {
        let newTrendtagData = ["/tags/\(name)/index": 10000, "/posts/\(name)": name] as [String : Any]
        trendtagDatabaseReference.updateChildValues(newTrendtagData) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    /// This fetches the trending hashtags
    func fetchTrendtags(completion: @escaping (Trendtag)->()) {
        trendtagDatabaseReference.child("tags").observeSingleEvent(of: .value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let trendtag = Trendtag(snapshot: childSnapshot)
                completion(trendtag)
            }
        }
    }
    
    /// This fetches the all trending hashtags
    func fetchAllTrendtags(completion: @escaping ([Trendtag])->()) {
        trendtagDatabaseReference.child("tags").observeSingleEvent(of: .value) { (snapshot) in
            var tags:[Trendtag] = []
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let trendtag = Trendtag(snapshot: childSnapshot)
                tags.append(trendtag)
            }
            completion(tags)
        }
    }


    /// This observes trendtags for the admin so they can add/delete them
    func observeTrendtags(completion: @escaping (Trendtag?, Bool?)->()) {
        let tagRef = trendtagDatabaseReference.child("tags")
        if trendTagHanlde != nil {
            tagRef.removeObserver(withHandle: trendTagHanlde)
        }
        trendTagHanlde = tagRef.observe(.value) { (snapshot) in
            completion(nil, true)
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let trendtag = Trendtag(snapshot: childSnapshot)
                completion(trendtag, nil)
            }
        }
    }
    
    /// Returns the posts that exist for a trendtag
    /// TODO: load these in batches
    func fetchPostsForTrendtag(trendtag: Trendtag, completion: @escaping (StripwayPost?, Error?)->()) {
        let tag = trendtag.name
        trendtagDatabaseReference.child("posts").child(tag).queryOrdered(byChild: "likeCount").observeSingleEvent(of: .value) { (snapshot) in
            
            for case let child as DataSnapshot in snapshot.children {
                API.Post.observePost(withID: child.key, completion: { (post, error) in
                    completion(post, error)
                })
            }
        }
    }
    
    /// Returns the posts that exist for a trendtag
    /// TODO: load all in one call
    func fetchAllPostsForTrendtag(trendtag: Trendtag, completion: @escaping ([StripwayPost], Error?)->()) {
        let tag = trendtag.name
        trendtagDatabaseReference.child("posts").child(tag).queryOrdered(byChild: "likeCount").observeSingleEvent(of: .value) { (snapshot) in
            
            let myGroup = DispatchGroup()
            var posts: [StripwayPost] = []
            
            for case let child as DataSnapshot in snapshot.children {
                myGroup.enter()
                // do not return until array is full

                API.Post.observePost(withID: child.key, completion: { (post, error) in
                    if let post = post {
                        posts.append(post)
                    }
                    myGroup.leave()
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main, execute: {
                completion(posts, nil)
            })

        }
    }
    
//    /// Returns the recent posts that exist for a trendtag
//    /// TODO: load all in one call
    func fetchRecentPostsForTrendtag(trendtag: Trendtag, start postID: String? = nil, limit: UInt, completion: @escaping ([StripwayPost], Error?)->()) {
        let tag = trendtag.name

        var trendQuery:DatabaseQuery!

        if postID == "" {
            trendQuery = trendtagDatabaseReference.child("posts").child(tag).queryOrdered(byChild: "likeCount").queryLimited(toLast: UInt(ONE_TIME_LOAD))
        }
        else {
            trendQuery = trendtagDatabaseReference.child("posts").child(tag).queryStarting(atValue: postID).queryOrdered(byChild: "likeCount").queryLimited(toLast: UInt(ONE_TIME_LOAD))
        }

//        if let latestPostTimestamp = timestamp, latestPostTimestamp > 0 {
//            trendQuery = trendQuery.queryStarting(atValue: latestPostTimestamp + 1, childKey: "likeCount").queryLimited(toLast: 50)
//        } else {
//        }
        
        trendQuery.observeSingleEvent(of: .value) { (snapshot) in

            let myGroup = DispatchGroup()
            var posts: [StripwayPost] = []

            for case let child as DataSnapshot in snapshot.children {
                myGroup.enter()
                // do not return until array is full

                API.Post.observePost(withID: child.key, completion: { (post, error) in
                    if let post = post {
                        posts.append(post)
                    }
                    myGroup.leave()
                })
            }

            myGroup.notify(queue: DispatchQueue.main, execute: {
                completion(posts, nil)
            })

        }
    }
    
    /// Returns the posts that exist for a trendtag
    /// TODO: load these in batches
    func fetchPostKeysForTrendtag(trendtag: Trendtag, completion: @escaping ([String], Error?)->()) {
        let tag = trendtag.name
        trendtagDatabaseReference.child("posts").child(tag).queryOrdered(byChild: "likeCount").observeSingleEvent(of: .value) { (snapshot) in
            var keys:[String] = []
            for case let child as DataSnapshot in snapshot.children {
                keys.append(child.key)                
            }
            completion(keys, nil)
        }
    }

    
    func fetchRemovedPostsForTrendtag(trendtag: Trendtag, completion: @escaping (String)->()) {
        let tag = trendtag.name
        trendtagDatabaseReference.child("posts").child(tag).observe(.childRemoved) { (snapshot) in
            completion(snapshot.key)
        }
    }
    
    /// Admin uses this to change the order trendtags appear
    func updateIndexForTrendtag(trendtag: Trendtag, toIndex index: Int) {
        trendtagDatabaseReference.child("tags").child(trendtag.name).setValue(["index": index])
    }
    
    /// Admin uses this to change the order header images appear
    func updateIndexForHeaderImage(headerImageKey: String, toIndex index: Int) {
        trendtagDatabaseReference.child("headerImages").child(headerImageKey).child("index").setValue(index) { (error, ref) in
            if let error = error {
                print("Oops here's an error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Admin uses this to delete a trending tag
    /// TODO: Double check that it's deleting /trendtags/posts/ too
    func deleteTrendtag(trendtag: Trendtag) {
        let newTrendtagData = ["/tags/\(trendtag.name)": NSNull(), "/posts/\(trendtag.name)": NSNull()]
        trendtagDatabaseReference.updateChildValues(newTrendtagData)
    }
    
    /// Admin uses this to delete a header image
    func deleteHeaderImage(tuple: (snapshotKey: String, urlString: String, index: Int), completion: @escaping (Error)->()) {
        trendtagDatabaseReference.child("headerImages").child(tuple.snapshotKey).setValue(NSNull()) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
                completion(error)
                return
            }
            Constants.storageRef.child("trending").child("headerImages").child(tuple.snapshotKey).delete(completion: { (error) in
                if let error = error {
                    print(error.localizedDescription)
                    completion(error)
                }
            })
        }
        
    }
    
    /// Admin uses this to upload a new header image
    func uploadNewHeaderImage(imageData: Data, completion: @escaping (Error?)->()) {
        let newHeaderImageID = trendtagDatabaseReference.child("headerImageURL").childByAutoId().key!
        HelperService.uploadImage(imageData: imageData, storageReference: Constants.storageRef.child("trending").child("headerImages").child(newHeaderImageID)) { (error, url) in
            if let error = error {
                print(error.localizedDescription)
                completion(error)
                return
            }
            if let url = url {
                self.trendtagDatabaseReference.child("headerImages").child(newHeaderImageID).setValue(["url": url.absoluteString, "index": 1000])
            }
        }
    }
    
    /// Loads the header images for the admin, observes .value so they get added/deleted immediately
    /// Returns in the completion handler as (String, String, Int) which includes the
    /// postID, url, and index
    func loadHeaderImages(completion: @escaping((String, String, Int)?, Bool?, Error?)->()) {
        
        let headerImagesRef = trendtagDatabaseReference.child("headerImages")
        if headerImageHandle != nil {
            headerImagesRef.removeObserver(withHandle: headerImageHandle)
        }
        
        headerImageHandle = headerImagesRef.observe(.value) { (snapshot) in
            completion(nil, true, nil)
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let snapshotValue = childSnapshot.value as! [String: Any]
                let urlString = snapshotValue["url"] as? String
                let index = snapshotValue["index"] as? Int
                if let urlString = urlString, let index = index {
                    completion((childSnapshot.key, urlString, index), nil, nil)
                } else {
                    completion(nil, nil, CustomError("idk something broke"))
                }
            }
        }
    }
    
    /// Loads header images at the top of the trending page, loads only once because it's not necessary
    /// to constantly observe those.
    func loadHeaderImagesOnce(completion: @escaping((String, String, Int)?, Error?)->()) {
        trendtagDatabaseReference.child("headerImages").observeSingleEvent(of: .value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                let snapshotValue = childSnapshot.value as! [String: Any]
                let urlString = snapshotValue["url"] as? String
                let index = snapshotValue["index"] as? Int
                if let urlString = urlString, let index = index {
                    completion((childSnapshot.key, urlString, index), nil)
                } else {
                    completion(nil, CustomError("idk something broke"))
                }
            }
        }
    }
    
    func blockPostFromTrendtag(postID: String, trendtagName: String) {
        let removedTrendtagPostData = ["/posts/\(trendtagName)/\(postID)": NSNull(), "/removedPosts/\(trendtagName)/\(postID)": true] as [String: Any]
        trendtagDatabaseReference.updateChildValues(removedTrendtagPostData) { (error, ref) in
            if let error = error {
                print("There was an error: \(error.localizedDescription)")
            } else {
                print("Removing post from tag worked")
            }
        }
    }
}

/// The structure of a trendtag, should probably have it's own file but it's very simple
struct Trendtag {
    var name: String
    var index: Int
    var posts = [StripwayPost]()
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        name = snapshot.key
        index = snapshotValue["index"] as! Int
    }
}
