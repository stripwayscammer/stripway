//
//  StripwayNotification.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/23/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// This is just the notification stored in the database and displayed on NotificationsViewController, it doesn't have anything to do with
/// how push notifications happen. Those are all done using Firebase Cloud Functions.
class StripwayNotification {
    
    var fromUserID: String
    var toUserID: String
    var objectID: String
    var type: NotificationType!
    var timestamp: Int
    var notificationID: String
    var commentText: String?
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        fromUserID = snapshotValue["fromUserID"] as! String
        toUserID = snapshotValue["toUserID"] as! String
        objectID = snapshotValue["objectID"] as! String
        let notificationType = snapshotValue["type"] as! String
        type = NotificationType(rawValue: notificationType)
        timestamp = snapshotValue["timestamp"] as! Int
        commentText = snapshotValue["commentText"] as? String
        notificationID = snapshot.key
    }
    
    init(fromUserID: String, toUserID: String, objectID: String, type: NotificationType!, timestamp: Int, notificationID: String, commentText: String? = nil) {
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.objectID = objectID
        self.type = type
        self.timestamp = timestamp
        self.notificationID = notificationID
        self.commentText = commentText
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "fromUserID": fromUserID,
            "toUserID": toUserID,
            "objectID": objectID,
            "type": type.rawValue,
            "timestamp": timestamp,
            "commentText": commentText
        ]
    }
}

enum NotificationType: String {
    case like = "like"
    case repost = "repost"
    case follow = "follow"
    case commentMention = "commentMention"
    case postMention = "postMention"
    case comment = "comment"
}
