//
//  RepostsAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/9/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import Firebase

class RepostsAPI {
    
    var repostsReference = Database.database().reference().child("reposts")
    
    /// Reposts the post onto the database
    func repost(postWithID postID: String, fromPostAuthor authorID: String, withRepostedTimestamp repostedTimestamp: Int, forUserWithID userID: String) {
        repostsReference.child(userID).child(postID).setValue(["repostedTimestamp": repostedTimestamp])
        // Notify the reposted user that their post was reposted
        API.Notification.createNotification(fromUserID: userID, toUserID: authorID, objectID: postID, type: .repost)
    }
    
    /// Unrepost the post from the database
    /// TODO: Maybe have a way to remove the notification too
    func unRepost(postWithID postID: String, forUserWithID userID: String) {
        repostsReference.child(userID).child(postID).removeValue()
    }
    
    func getRepostsFeed(withID id: String, completion: @escaping ([(StripwayPost, StripwayUser, Int)])->()) {
        let feedQuery = repostsReference.child(id).queryOrdered(byChild: "repostedTimestamp")
        
        // .observeSingleEventOf because we don't want it auto reloading when a new post is added
        feedQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects
            let myGroup = DispatchGroup()
            
            var results: [(post: StripwayPost, user: StripwayUser, repostedTimestamp: Int)] = []
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                
                // Observe post and user at same time, also the time that the post was reposted so we can decide how to order it in the view
                // Uses a DispatchQueue so we don't return until limit number of posts has been loaded
                myGroup.enter()
                API.Post.observePost(withID: item.key, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        myGroup.leave()
                    } else if let post = post {
                        API.User.observeUser(withUID: post.authorUID, completion: { (user, error) in
                            if let error = error {
                                print(error.localizedDescription)
                                myGroup.leave()
                            } else if let user = user {
                                let value = item.value as! [String: Any]
                                let repostedTimestamp = value["repostedTimestamp"] as! Int
                                print("Appending post: \(post.postID) with repostTimestamp: \(repostedTimestamp)")
                                if !user.isBlocked && !user.hasBlocked {
                                    results.append((post, user, repostedTimestamp))
                                }
                                myGroup.leave()
                            }
                        })
                    }
                })
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.2 > $1.2})
                completion(results)
            })
        }
    }

    
    /// Gets recent "limit" number of reposts from a user's repost feed
    /// Basically just loads the reposts feed in batches
    func getRecentRepostsFeed(withID id: String, start timestamp: Int? = nil, limit: UInt, completion: @escaping ([(StripwayPost, StripwayUser, Int)])->()) {
        var feedQuery = repostsReference.child(id).queryOrdered(byChild: "repostedTimestamp")
        if let latestPostTimestamp = timestamp, latestPostTimestamp > 0 {
            feedQuery = feedQuery.queryStarting(atValue: latestPostTimestamp + 1, childKey: "repostedTimestamp").queryLimited(toLast: limit)
        } else {
            feedQuery = feedQuery.queryLimited(toLast: limit)
        }
        
        // .observeSingleEventOf because we don't want it auto reloading when a new post is added
        feedQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects
            let myGroup = DispatchGroup()
            
            var results: [(post: StripwayPost, user: StripwayUser, repostedTimestamp: Int)] = []
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                
                // Observe post and user at same time, also the time that the post was reposted so we can decide how to order it in the view
                // Uses a DispatchQueue so we don't return until limit number of posts has been loaded
                myGroup.enter()
                API.Post.observePost(withID: item.key, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        myGroup.leave()
                    } else if let post = post {
                        API.User.observeUser(withUID: post.authorUID, completion: { (user, error) in
                            if let error = error {
                                print(error.localizedDescription)
                                myGroup.leave()
                            } else if let user = user {
                                let value = item.value as! [String: Any]
                                let repostedTimestamp = value["repostedTimestamp"] as! Int
                                print("Appending post: \(post.postID) with repostTimestamp: \(repostedTimestamp)")
                                if !user.isBlocked && !user.hasBlocked {
                                    results.append((post, user, repostedTimestamp))
                                }
                                myGroup.leave()
                            }
                        })
                    }
                })
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.2 > $1.2})
                completion(results)
            })
        }
    }
    
    /// Gets older reposts from a user's repost feed, very similar to getRecentRepostsFeed method
    func getOldRepostsFeed(withID id: String, start timestamp: Int, limit: UInt, completion: @escaping ([(StripwayPost, StripwayUser, Int)])->()) {
        let feedOrderQuery = repostsReference.child(id).queryOrdered(byChild: "repostedTimestamp")
        let feedLimitedQuery = feedOrderQuery.queryEnding(atValue: timestamp - 1, childKey: "repostedTimestamp").queryLimited(toLast: limit)

        // .observeSingleEventOf because we don't want it auto reloading when a new post is added
        feedLimitedQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects as! [DataSnapshot]
            let myGroup = DispatchGroup()
            
            var results: [(post: StripwayPost, user: StripwayUser, repostedTimestamp: Int)] = []
            
            for (_, item) in items.enumerated() {
                myGroup.enter()
                
                API.Post.observePost(withID: item.key, completion: { (post, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        myGroup.leave()
                    } else if let post = post {
                        API.User.observeUser(withUID: post.authorUID, completion: { (user, error) in
                            if let error = error {
                                print(error.localizedDescription)
                                myGroup.leave()
                            } else if let user = user {
                                let value = item.value as! [String: Any]
                                let repostedTimestamp = value["repostedTimestamp"] as! Int
                                if !user.isBlocked && !user.hasBlocked {
                                    results.append((post, user, repostedTimestamp))
                                }
                                myGroup.leave()
                            }
                        })
                    }
                })
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.2 > $1.2})
                completion(results)
            })
        }
    }
    
}
