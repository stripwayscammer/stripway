//
//  StripwayPost.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/16/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

class StripwayPost: Equatable {
    
    var postID: String
    var photoURL: String
    var thumbURL: String?
    
    var postImage: UIImage?
    
    var authorUID: String
    var caption: String
    var captionBgColorCode:String
    var captionTxtColorCode:String
    var hashTags: [String]
    
    var timestamp: Int
    var postReference: DatabaseReference?
    var isLiked: Bool = false
    var likeCount: Int
    var likes: Dictionary<String, Any>
    var tags: Dictionary<String, Any>
    var isReposted: Bool = false
    var repostCount: Int
    var reposts: Dictionary<String, Any>
    var isBookmarked: Bool = false
    var bookmarkCount: intmax_t
    var bookmarks: Dictionary<String, Any>
    var stripName: String
    var stripID: String
    var imageAspectRatio: CGFloat
    
    //added width and height param to create proper scaled thumbnail
    var width:Int
    var height:Int
    
    static func ==(lhs: StripwayPost, rhs: StripwayPost) -> Bool {
        return lhs.postID == rhs.postID
    }
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        
        caption = snapshotValue["caption"] as? String ?? ""
        captionBgColorCode = snapshotValue["captionBgColorCode"] as? String ?? ""
        captionTxtColorCode = snapshotValue["captionTxtColorCode"] as?  String ?? ""
        hashTags = snapshotValue["hashTags"] as? [String] ?? []
        print("Rohit Testing------>>>>\(captionBgColorCode)")
        photoURL = snapshotValue["photoURL"] as? String ?? ""
        if let thumbURLStr = snapshotValue["thumbURL"] as? String {
            self.thumbURL = thumbURLStr
        }
        tags = snapshotValue["tags"] as? Dictionary<String, Any> ?? [:]
        
        authorUID = snapshotValue["authorUID"] as? String ?? ""
        postID  = snapshot.key
        timestamp = snapshotValue["timestamp"] as? Int ?? 0
        postReference = snapshot.ref
        likeCount = snapshotValue["likeCount"] as? Int ?? 0
        likes = snapshotValue["likes"] as? Dictionary<String, Any> ?? [:]
        if !likes.isEmpty {
            if Constants.currentUser != nil {
                isLiked = likes[Constants.currentUser!.uid] != nil
            }
            else {
                isLiked = false
            }
        }
        repostCount = snapshotValue["repostCount"] as? Int ?? 0
        reposts = snapshotValue["reposts"] as? Dictionary<String, Any> ?? [:]
        if !reposts.isEmpty {
            if let uID = Constants.currentUser?.uid {
                isReposted = reposts[uID] != nil
            }
        }
        bookmarkCount = snapshotValue["bookmarkCount"] as? Int ?? 0
        bookmarks = snapshotValue["bookmarks"] as? Dictionary<String, Any> ?? [:]
        if !bookmarks.isEmpty {
            isBookmarked = bookmarks[Constants.currentUser!.uid] != nil
        }
        stripName = snapshotValue["stripName"] as? String ?? "No Strip"
        stripID = snapshotValue["stripID"] as? String ?? "No Strip"
        imageAspectRatio = snapshotValue["imageAspectRatio"] as? CGFloat ?? 0.75
        
        width = snapshotValue["width"] as? Int ?? Int(DEFAULT_THUMBNAIL_HEIGHT*0.75)
        height = snapshotValue["height"] as? Int ?? Int(DEFAULT_THUMBNAIL_HEIGHT)
    }
    
    init(postID: String, photoURL: String, authorUID: String, caption: String,captionBgColorCode:String,captionTxtColorCode:String, hashTags:[String], timestamp: Int, stripName: String, stripID: String, imageAspectRatio: CGFloat, width: Int, height: Int, tags:[String:Any]) {
        self.postID = postID
        self.photoURL = photoURL
        self.authorUID = authorUID
        self.caption = caption
        self.captionBgColorCode = captionBgColorCode
        self.captionTxtColorCode = captionTxtColorCode
        self.hashTags = hashTags
        self.timestamp = timestamp
        self.postReference = nil
        self.likeCount = 0
        self.likes = [:]
        self.repostCount = 0
        self.reposts = [:]
        self.bookmarkCount = 0
        self.bookmarks = [:]
        self.stripName = stripName
        self.stripID = stripID
        self.imageAspectRatio = imageAspectRatio
        self.width = width
        self.height = height
        self.tags = tags
    }
    
    init(postID: String, postImage: UIImage, authorUID: String, caption: String,captionBgColorCode:String,captionTxtColorCode:String, hashTags:[String], timestamp: Int, stripName: String, stripID: String, imageAspectRatio: CGFloat, withMentions mentions: [String], width: Int, height: Int, tags:[String:Any]) {
        self.postID = postID
        self.photoURL = ""
        self.postImage = postImage
        self.authorUID = authorUID
        self.caption = caption
        self.captionBgColorCode = captionBgColorCode
        self.captionTxtColorCode = captionTxtColorCode
        self.hashTags = hashTags
        self.timestamp = timestamp
        self.postReference = nil
        self.likeCount = 0
        self.likes = [:]
        self.repostCount = 0
        self.reposts = [:]
        self.bookmarkCount = 0
        self.bookmarks = [:]
        self.stripName = stripName
        self.stripID = stripID
        self.imageAspectRatio = imageAspectRatio
        self.width = width
        self.height = height
        self.tags = tags
        
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "photoURL": photoURL,
            "authorUID": authorUID,
            "caption": caption,
            "captionBgColorCode":captionBgColorCode,
            "captionTxtColorCode":captionTxtColorCode,
            "hashTags":hashTags,
            "timestamp": timestamp,
            "stripName": stripName,
            "stripID": stripID,
            "imageAspectRatio": imageAspectRatio,
            "width": width,
            "height": height,
            "tags": tags
        ]
    }
}
