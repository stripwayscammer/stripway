//
//  StripwayMessage.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/21/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

class StripwayMessage {
    var messageText: String
    var senderUID: String
    var receiverUID: String
    var timestamp: Int
    var messageID: String
    var senderUser: StripwayUser
    var type: StripwayMessageType
    var photoURL: String?
    var photoImage: UIImage?
    var postID: String?
    var postCaption: String?
    var authorUID: String?
    
    init(snapshot: DataSnapshot, user: StripwayUser) {
        let snapshotValue = snapshot.value as! [String: Any]
        messageText = snapshotValue["messageText"] as! String
        senderUID = snapshotValue["senderUID"] as! String
        receiverUID = snapshotValue["receiverUID"] as? String ?? "none"
        timestamp = snapshotValue["timestamp"] as! Int
        messageID = snapshot.key 
        senderUser = user
        if let messageType = snapshotValue["type"] as? String
        {
            type = StripwayMessageType(rawValue: messageType)!
            if  type ==  StripwayMessageType.image
            {
                photoURL = snapshotValue["photoURL"] as? String
                type = StripwayMessageType.image
            }
            else if type == StripwayMessageType.post {
                photoURL = snapshotValue["photoURL"] as? String
                postID = snapshotValue["postID"] as? String
                postCaption = snapshotValue["postCaption"] as? String
                authorUID = snapshotValue["authorUID"] as? String
            }
        }
        else {
            type = StripwayMessageType.text
        }
    }
    
    init(messageID: String, messageText: String, timestamp: Int, senderUser: StripwayUser, receiverUID: String) {
        self.messageText = messageText
        self.senderUID = senderUser.uid
        self.receiverUID = receiverUID
        self.timestamp = timestamp
        self.messageID = messageID
        self.senderUser = senderUser
        self.type = StripwayMessageType.text
    }
    
    init(messageID: String, imageURL: String, timestamp: Int, senderUser: StripwayUser, receiverUID: String) {
        self.senderUID = senderUser.uid
        self.receiverUID = receiverUID
        self.timestamp = timestamp
        self.messageID = messageID
        self.messageText = "Media Message"
        self.senderUser = senderUser
        self.type = StripwayMessageType.image
        self.photoURL = imageURL
    }
    
    init(messageID: String, imageURL: String, postID: String, authorUID: String, timestamp: Int, senderUser: StripwayUser, receiverUID:String)
    {
        self.senderUID = senderUser.uid
        self.receiverUID = receiverUID
        self.timestamp = timestamp
        self.messageID = messageID
        self.messageText = "Share Post"
        self.senderUser = senderUser
        self.type = StripwayMessageType.post
        self.photoURL = imageURL
        self.postID = postID
        self.authorUID = authorUID
    }
 
    init(messageID: String, image: UIImage, timestamp: Int, senderUser: StripwayUser, receiverUID: String) {
        self.senderUID = senderUser.uid
        self.receiverUID = receiverUID
        self.timestamp = timestamp
        self.messageID = messageID
        self.messageText = "Media Message"
        self.senderUser = senderUser
        self.type = StripwayMessageType.image
        self.photoImage = image
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "messageText": messageText,
            "photoURL" : photoURL ?? "No Image",
            "postID" : postID ?? "No Post",
            "postCaption" : postCaption ?? "",
            "authorUID" : authorUID ?? "No Post",
            "senderUID": senderUID,
            "receiverUID": receiverUID,
            "timestamp": timestamp,
            "type" : type.rawValue
        ]
    }
}

enum StripwayMessageType: String {
    case image = "image"
    case text = "text"
    case post = "post"
}

private struct ImageMediaItem: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
    
    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}

private struct PostMediaItem: MediaItem {
    
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(image: UIImage) {
        self.image = image
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
    
    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}


/// This was necessary to get the StripwayMessage to work with MessageKit
extension StripwayMessage: MessageType {
    var messageId: String {
        return messageID
    }
    
    var sentDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(exactly: timestamp)!)
    }
    
    var kind: MessageKind {
        if type == StripwayMessageType.text
        {
            return .text(messageText)
        }
        else if type == StripwayMessageType.image
        {
            if photoURL != nil {
                return .photo(ImageMediaItem.init(url: URL.init(string: photoURL!)!))
            }
            else {
                return .photo(ImageMediaItem.init(image: photoImage!))
            }            
        }
        else if type == StripwayMessageType.post {
            if photoURL != nil {
                return .custom(ImageMediaItem.init(url: URL.init(string: photoURL!)!))
            }
            else {
                return .custom(ImageMediaItem.init(image: photoImage!))
            }
        }

        return .text(messageText)
    }
    
    var sender: SenderType {
        return Sender(id: senderUser.uid, displayName: senderUser.username)
    }
}
