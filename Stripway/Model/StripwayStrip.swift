//
//  StripwayStrip.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/17/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

class StripwayStrip {

    var stripID: String
    var name: String
    var authorID: String
    var index: Int
    var posts: [StripwayPost]
    var stripReference: DatabaseReference?
    var postsReference: DatabaseReference?
    var archivedReference:DatabaseReference?


    init(snapshot: DataSnapshot) {
        print("And here's the snapshot in the actual initializer: \(snapshot)")
        let snapshotValue = snapshot.value as! [String: Any]
        stripID = snapshot.key
        name = snapshotValue["name"] as! String
        authorID = snapshotValue["authorID"] as! String
        index = snapshotValue["index"] as! Int
        stripReference = snapshot.ref
        postsReference = stripReference?.child("posts")
        archivedReference = Firebase.Database.database().reference().child("archived").child("posts").child(authorID)
        posts = []
    }
    
    init(stripID: String, name: String, authorID: String, index: Int) {
        self.stripID = stripID
        self.name = name
        self.authorID = authorID
        self.index = index
        self.posts = []
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "stripID": stripID,
            "name": name,
            "authorID": authorID,
            "index": index
        ]
    }
    
}
