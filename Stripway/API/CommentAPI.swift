//
//  CommentAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// The way that comments work is a little convoluted and needs to be redone. "post-comments" in the database has a list of postIDs and under them
/// is a list of commentIDs for the comments on that post. But then you have to look up the comment using that commentID in the "comments" part of the database, it's not actually under the
/// postID. Ideally it would just be "post-comments" with the list of postIDs and under them are the full comments (user, commentText, likes, etc) so we'll need to do that eventually.
class CommentAPI {
    
    /// Where the full comments are on the database
    var commentsReference = Database.database().reference().child("comments")
    var repliesReference = Database.database().reference().child("replies")
    /// Where the commentIDs are matched to the postIDs in the database.
    /// TODO: Just put the full comment in "post-comments" and not just the commentID
    var postCommentsReference = Database.database().reference().child("post-comments")
    var commentsCountHandle:DatabaseHandle!
    
    func createReply(forCommentID commentID: String, fromPostAuthor postAuthorID: String, withText commentText: String, commentAuthorID: String, withMentions mentions: [String], completion: @escaping (StripwayComment) -> ()) {
        let newReplyID = repliesReference.childByAutoId().key!
        let newReplyReference = repliesReference.child(newReplyID)
        let timestamp = Int(Date().timeIntervalSince1970)
        let newComment = StripwayComment(commentID: newReplyID, commentText: commentText, authorUID: commentAuthorID, timestamp: timestamp)
        // TODO: Use multipath for this
        // Creates a new comment and adds it to database
        newReplyReference.setValue(newComment.toAnyObject()) { (error, ref) in
            if let error = error {
                print("here's an error: \(error.localizedDescription)")
            }
            // Matches the reply with the comment it belongs to and adds a timestamp as well
            API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: postAuthorID, objectID: commentID, type: .comment, commentText: newComment.commentText)
            self.addReply(toComment: commentID, replyID: newReplyID)
            completion(newComment)
            
            // Notify mentions
            
            // Remove duplicates from mentions
            let newMentions = Array(Set(mentions))
            for uid in newMentions {
                API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: uid, objectID: commentID, type: .commentMention, commentText: newComment.commentText)
            }
        }
    }
    /// Update replies
    func addReply(toComment commentID: String, replyID: String) {
        let timestamp = -(Int(Date().timeIntervalSince1970)) // invert timestamp to sort from latest to oldest

        let ref = commentsReference.child(commentID).child("replies").child(replyID)
        ref.updateChildValues(["timestamp" : timestamp])
    }
    
    
    /// Adds a comment to a post
    func createComment(forPostID postID: String, fromPostAuthor postAuthorID: String, withText commentText: String, commentAuthorID: String, withMentions mentions: [String], completion: @escaping (StripwayComment) -> ()) {
        let newCommentID = commentsReference.childByAutoId().key!
        let newCommentReference = commentsReference.child(newCommentID)
        let timestamp = Int(Date().timeIntervalSince1970)
        let newComment = StripwayComment(commentID: newCommentID,commentText: commentText, authorUID: commentAuthorID, timestamp: timestamp)
        // TODO: Use multipath for this
        // Creates a new comment and adds it to database
        newCommentReference.setValue(newComment.toAnyObject()) { (error, ref) in
            if let error = error {
                print("here's an error: \(error.localizedDescription)")
            }
            // Matches the comment with the post it belongs to and adds a timestamp as well
            self.postCommentsReference.child(postID).child(newCommentID).setValue(["timestamp": timestamp], withCompletionBlock: { (error, ref) in
                if let error = error {
                    print("here's an error: \(error.localizedDescription)")
                }
                API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: postAuthorID, objectID: postID, type: .comment, commentText: newComment.commentText)
                completion(newComment)
                
                // Notify mentions
                
                // Remove duplicates from mentions
                let newMentions = Array(Set(mentions))
                for uid in newMentions {
                    API.Notification.createNotification(fromUserID: commentAuthorID, toUserID: uid, objectID: postID, type: .commentMention, commentText: newComment.commentText)
                }
            })
        }
    }
    
    /// Increments likes on a reply
    func incrementLikes(replyID: String, completion: @escaping(StripwayComment?, Error?)->()) {
        let ref = repliesReference.child(replyID)
        ref.runTransactionBlock({ (currentData) -> TransactionResult in
            if var comment = currentData.value as? [String: AnyObject], let uid = Constants.currentUser?.uid {
                var likes: Dictionary<String, Bool>
                likes = comment["likes"] as? [String: Bool] ?? [:]
                var likeCount = comment["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                } else {
                    likeCount += 1
                    likes[uid] = true
                }
                comment["likeCount"] = likeCount as AnyObject?
                comment["likes"] = likes as AnyObject?
                
                currentData.value = comment
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let comment = StripwayComment(snapshot: snapshot!)
                completion(comment, nil)
            }
        }
    }
    /// Increments likes on a comment
    func incrementLikes(commentID: String, completion: @escaping(StripwayComment?, Error?)->()) {
        let ref = commentsReference.child(commentID)
        ref.runTransactionBlock({ (currentData) -> TransactionResult in
            if var comment = currentData.value as? [String: AnyObject], let uid = Constants.currentUser?.uid {
                var likes: Dictionary<String, Bool>
                likes = comment["likes"] as? [String: Bool] ?? [:]
                var likeCount = comment["likeCount"] as? Int ?? 0
                if let _ = likes[uid] {
                    likeCount -= 1
                    likes.removeValue(forKey: uid)
                } else {
                    likeCount += 1
                    likes[uid] = true
                }
                comment["likeCount"] = likeCount as AnyObject?
                comment["likes"] = likes as AnyObject?
                
                currentData.value = comment
                
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            }
            if let _ = snapshot?.value as? [String: Any] {
                let comment = StripwayComment(snapshot: snapshot!)
                completion(comment, nil)
            }
        }
    }
    
    /// Observe replies for a comment
    func observeReplies(forComment comment: StripwayComment, lastLoaded: StripwayComment? = nil, sizeToLoad: Int = 3, completion: @escaping([(StripwayComment, StripwayUser)]?, Error?)->()) {
        var results: [(StripwayComment, StripwayUser)] = []

        var query = commentsReference.child(comment.commentID).child("replies").queryOrdered(byChild: "timestamp")
        if lastLoaded == nil {
            query = query.queryLimited(toFirst: UInt(sizeToLoad))
        } else {
            let timestamp = -(lastLoaded!.timestamp) // invert timestamp to match timestamp on database
            query = query.queryStarting(atValue: timestamp).queryLimited(toFirst: UInt(sizeToLoad + 1))
        }
        query.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                let group = DispatchGroup()
                for snap in snapshot.children.allObjects as! [DataSnapshot] {
                    let id = snap.key
                    group.enter()
                    self.repliesReference.child(id).observeSingleEvent(of: .value) { (snapshot) in
                        if snapshot.value != nil {
                            let reply = StripwayComment(snapshot: snapshot)
                            API.User.observeUser(withUID: reply.authorUID, completion: { (user, error) in
                                if let _ = error {
                                    group.leave()
                                } else if let user = user {
                                    if user.isBlocked || user.hasBlocked {
                                        group.leave()
                                    } else {
                                        print("observing reply: \(reply.commentText)")
                                        if reply.commentID != lastLoaded?.commentID {
                                            results.append((reply, user))
                                        }
                                        group.leave()
                                    }
                                }
                            })
                        } else {
                            group.leave()
                        }
                    }
                    
                }
                group.notify(queue: .global()) {
                    completion(results, nil)
                }
            } else {
                completion(nil, nil)
            }
           
        }
//        if var replies = comment.replies as? [String : [String : Int]] {
//            let replyIDs = Array(replies.keys) // sorted by latest to oldest reply
//            var startIndex = 0
//            var lastIndex = 0
//            if lastLoadedIndex > 0 {
//                startIndex = lastLoadedIndex + 1
//            }
//            lastIndex = startIndex + sizeToLoad - 1
//            if lastIndex > replyIDs.count - 1 {
//                lastIndex = replyIDs.count - 1
//            }
//            if startIndex > lastIndex {return}
//            let group = DispatchGroup()
//
//            for i in startIndex...lastIndex {
//                let id = replyIDs[i]
//                group.enter()
//                self.repliesReference.child(id).observeSingleEvent(of: .value) { (snapshot) in
//                    if snapshot.value != nil {
//                        let reply = StripwayComment(snapshot: snapshot)
//                        API.User.observeUser(withUID: comment.authorUID, completion: { (user, error) in
//                            if let _ = error {
//                                group.leave()
//                            } else if let user = user {
//                                if user.isBlocked || user.hasBlocked {
//                                    group.leave()
//                                } else {
//                                    print("observing comment: \(reply.commentText)")
//                                    results.append((reply, user))
//                                    group.leave()
//                                }
//                            }
//                        })
//                    } else {
//                        group.leave()
//                    }
//                }
//            }
//            group.notify(queue: .global()) {
//                completion(results, nil)
//            }
//        } else {
//            completion(nil, CustomError("No replies"))
//        }
//        commentsReference.child(comment.commentID).child("replies").queryOrdered(byChild: "timestamp").observe(.childAdded) { (snapshot) in
//            self.repliesReference.child(snapshot.key).observeSingleEvent(of: .value) { (replySnapshot) in
//                let reply = StripwayComment(snapshot: replySnapshot)
//                // Observe the author of the comment
//                API.User.observeUser(withUID: reply.authorUID, completion: { (user, error) in
//                    if let error = error {
//                        completion(nil, error)
//                    } else if let user = user {
//                        if user.isBlocked || user.hasBlocked {
//                            let error = CustomError("This user is blocked")
//                            completion(nil, error)
//                        } else {
//                            print("observing comment: \(reply.commentText)")
//                            completion((reply, user), nil)
//                        }
//                    }
//                })
//            }
//        }
        
    }
    /// Observes comments for a post
    func observeComments(forPostID postID: String, completion: @escaping((StripwayComment, StripwayUser)?, Error?)->()) {
        // Finds which comments belong to the post
        postCommentsReference.child(postID).queryOrdered(byChild: "timestamp").observe(.childAdded) { (snapshot) in
            // Observe the actual comment itself
            self.commentsReference.child(snapshot.key).observeSingleEvent(of: .value, with: { (commentSnapshot) in
                let comment = StripwayComment(snapshot: commentSnapshot)
                // Observe the author of the comment
                API.User.observeUser(withUID: comment.authorUID, completion: { (user, error) in
                    if let error = error {
                        completion(nil, error)
                    } else if let user = user {
                        if user.isBlocked || user.hasBlocked {
                            let error = CustomError("This user is blocked")
                            completion(nil, error)
                        } else {
                            print("observing comment: \(comment.commentText)")
                            completion((comment, user), nil)
                        }
                    }
                })
            })
        }
    }
    func deleteReply(withID replyID: String, fromCommentID commentID: String) {
        let replyReference = repliesReference.child(replyID)
        replyReference.removeValue()
        
        let commentReplyReference = commentsReference.child(commentID).child("replies").child(replyID)
        commentReplyReference.removeValue()
    }
    
    func deleteComment(_ comment: StripwayComment, fromPost postID: String) {
        let commentReference = commentsReference.child(comment.commentID)
        commentReference.removeValue()
        
        let postCommentReference = postCommentsReference.child(postID).child(comment.commentID)
        postCommentReference.removeValue()
        
        if let replies = comment.replies {
            for reply in replies.keys {
                repliesReference.child(reply).removeValue()
            }
        }
    }
    /// Observes removed relies
//    func observeReplyRemoved(forCommentID commentID: String, completion: @escaping (String)->()) {
//        repliesReference.child(commentID).observe(.childRemoved) { (snapshot) in
//        let key = snapshot.key
//        completion(key)
//    }

    /// Observes removed comments (mainly so it immediately shows when you delete your own comment)
    func observeCommentRemoved(forPostID postID: String, completion: @escaping (String)->()) {
        postCommentsReference.child(postID).observe(.childRemoved) { (snapshot) in
            let key = snapshot.key
            completion(key)
        }
    }
        
    
    func observeCommentCount(forPostID postID: String, completion: @escaping (UInt)->()) {
        
        let perPostCommentsReference:DatabaseQuery = postCommentsReference.child(postID)
        if commentsCountHandle != nil {
            perPostCommentsReference.removeObserver(withHandle: commentsCountHandle)
        }
        
        commentsCountHandle = perPostCommentsReference.observe(.value) { (snapshot) in
            let numberOfComments = snapshot.childrenCount
            completion(numberOfComments)
        }
    }
    
}
