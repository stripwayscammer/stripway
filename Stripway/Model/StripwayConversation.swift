//
//  StripwayConversation.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/21/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// StripwayConversations are displayd in a list on ConversationsListViewController, and then when you select one, the
/// images are loaded using the conversationDatabaseID
class StripwayConversation {
    var conversationDatabaseID: String
    var mostRecentTimestamp: Int
    var mostRecentMessageText: String
    var otherParticipantUID: String
    var unreadMessagesCount: Int

    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        conversationDatabaseID = snapshotValue["conversationDatabaseID"] as! String
        mostRecentTimestamp = snapshotValue["mostRecentTimestamp"] as! Int
        mostRecentMessageText = snapshotValue["mostRecentMessageText"] as! String
        unreadMessagesCount = snapshotValue["unreadMessagesCount"] as? Int ?? 0
        otherParticipantUID = snapshot.key
    }
    
    init(convoID: String, mostRecentTimestamp: Int, mostRecentMessageText: String, otherParticipantUID: String) {
        self.conversationDatabaseID = convoID
        self.mostRecentTimestamp = mostRecentTimestamp
        self.mostRecentMessageText = mostRecentMessageText
        self.otherParticipantUID = otherParticipantUID
        self.unreadMessagesCount = 0
    }
    
    func toAnyObject() -> [String: Any] {
        return [
            "mostRecentTimestamp": mostRecentTimestamp,
            "mostRecentMessageText": mostRecentMessageText,
            "conversationDatabaseID": conversationDatabaseID
        ]
    }
}
