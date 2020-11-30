//
//  FeedAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/30/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CoreData

class FeedAPI {
    
    var feedReference = Database.database().reference().child("feed")
    var recentReference = Database.database().reference().child("recentFeed")
    
    /// This is never actually called but I'm afraid to remove it yet
    func observeFeed(withID id: String, completion: @escaping (StripwayPost?, Error?)->()) {
        feedReference.child(id).observe(.childAdded) { (snapshot) in
            let key = snapshot.key
            API.Post.observePost(withID: key, completion: { (post, error) in
                completion(post, error)
            })
        }
    }
    
    
//    func getFeed(withID id: String, start timestamp: Int? = nil, limit: UInt, completion: @escaping ([(StripwayPost, StripwayUser)])->()) {
//
//        feedReference.child(id).child("feedSync").observeSingleEvent(of: .value) { (syncValue) in
//            let status = syncValue.value as? String
//            if status == "true"{
//                //get from recent short list.
//                self.getRecentFeed(withID: id, limit: limit, getFrom: true, completion: {_ in })
//            }
//            else {
//                //need to copy from feed list now
//                self.getRecentFeed(withID: id, limit: limit, getFrom: false, completion: {_ in })
//            }
//        }
//    }

    /// This uses some complicated logic from the zero2launch tutorials to pull the feed in batches
    /// Could probably be improved but it works and I don't want to break it
    func getRecentFeed(withID id: String, start timestamp: Int? = nil, limit: UInt, completion: @escaping ([(StripwayPost, StripwayUser)])->()) {

        var feedQuery:DatabaseQuery!
        feedQuery = self.feedReference.child(id).queryOrdered(byChild: "timestamp")
        if let latestPostTimestamp = timestamp, latestPostTimestamp > 0 {
            feedQuery = feedQuery.queryStarting(atValue: latestPostTimestamp + 1, childKey: "timestamp").queryLimited(toLast: UInt(ONE_TIME_LOAD))
        } else {
            feedQuery = feedQuery.queryLimited(toLast: UInt(ONE_TIME_LOAD))
        }
        
        feedQuery.observeSingleEvent(of: .value) { (snapshot) in
            
            let items = snapshot.children.allObjects
            let myGroup = DispatchGroup()
            
            var results: [(post: StripwayPost, user: StripwayUser)] = []
            
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()
                // do not return until array is full
                
                // Observes the post and that post's user, if either don't exist then that post/user are just skipped over
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
                                //                        results.insert((post, user), at: index)
                                results.append((post, user))
                                
                                myGroup.leave()
                            }
                        })
                    }
                })
            }
            
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.0.timestamp > $1.0.timestamp})
                
                completion(results)
            })
        }
    }
    
    /// More complicated logic from zero2launch, works well though
    func getOldFeed(withID id: String, start timestamp: Int, limit: UInt, completion: @escaping ([(StripwayPost, StripwayUser)])->()) {
        let feedOrderQuery = feedReference.child(id).queryOrdered(byChild: "timestamp")
        let feedLimitedQuery = feedOrderQuery.queryEnding(atValue: timestamp - 1, childKey: "timestamp").queryLimited(toLast: limit)
    
        print("\nShould only ever get posts with a timestamp later than: \(timestamp)\n")
        
        feedLimitedQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects as! [DataSnapshot]
            let myGroup = DispatchGroup()
    
            var results: [(post: StripwayPost, user: StripwayUser)] = []
            
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
                                //                        results.insert((post, user), at: index)
                                results.append((post, user))
                                print("But this post has a timestamp of: \(post.timestamp)")
                                myGroup.leave()
                            }
                        })
                    }
                    
                })
            }
            myGroup.notify(queue: DispatchQueue.main, execute: {
                results.sort(by: {$0.0.timestamp > $1.0.timestamp})
                completion(results)
            })
        }
    }
    
    /// Removes a post if it is deleted while the user is looking at their feed, mainly for when users delete their own posts
    /// it's visible immediately
    func observeFeedRemoved(withID id: String, completion: @escaping (String)->()) {
        feedReference.child(id).observe(.childRemoved) { (snapshot) in
            let key = snapshot.key
            completion(key)
        }
    }
    
}
