//
//  File.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/3/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

class StripwayComment {
    var commentText: String
    var authorUID: String
    var timestamp: Int
    var commentID: String
    var likeCount: Int
    var likes: Dictionary<String, Any>
    var isLiked: Bool = false
    var replies: Dictionary<String, Any>?
    var commentReference: DatabaseReference?
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        commentText = snapshotValue["commentText"] as! String
        authorUID = snapshotValue["authorUID"] as! String
        timestamp = snapshotValue["timestamp"] as? Int ?? 0
        commentID = snapshot.key 
        likeCount = snapshotValue["likeCount"] as? Int ?? 0
        likes = snapshotValue["likes"] as? Dictionary<String, Any> ?? [:]
        if !likes.isEmpty {
            isLiked = likes[Constants.currentUser!.uid] != nil
        }
        replies = snapshotValue["replies"] as? Dictionary<String, Any>
        commentReference = snapshot.ref
    }
    
    init(commentID: String, commentText: String, authorUID: String, timestamp: Int) {
        self.commentText = commentText
        self.authorUID = authorUID
        self.timestamp = timestamp
        self.commentID = commentID
        self.likeCount = 0
        self.likes = [:]
        self.commentReference = nil
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "commentText": commentText,
            "authorUID": authorUID,
            "timestamp": timestamp
        ]
    }
}


