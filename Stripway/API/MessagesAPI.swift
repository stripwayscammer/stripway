//
//  MessagesAPI.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/21/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class MessagesAPI {
    
    private let storage = Storage.storage().reference(forURL: "gs://stripeway-2.appspot.com").child("messages")

    
    /// Where conversations are stored on the database
    var conversationsReference = Database.database().reference().child("conversations")
    
    /// All references that use .observe for the ConversationListViewController
    var conversationsListReferences = [DatabaseReference]()
    /// All references that use .observe for the ViewConversationViewController
    var conversationReferences = [DatabaseReference]()
    
    /// Creates a message and adds it to the conversation on the database
    func createMessage(forConversationID convoID: String, withText messageText: String, senderUser: StripwayUser, receiverUser: StripwayUser, completion: @escaping()->()) {
        let newMessageID = conversationsReference.child(convoID).child("messages").childByAutoId().key!
        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessageID)
        let timestamp = Int(Date().timeIntervalSince1970)
        let newMessage = StripwayMessage(messageID: newMessageID, messageText: messageText, timestamp: timestamp, senderUser: senderUser, receiverUID: receiverUser.uid)
        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
            if let error = error {
                print("Error saving message to the database: \(error.localizedDescription)")
            }
//            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
            self.updateUsersConversations(message: newMessage, senderID: senderUser.uid, receiverID: receiverUser.uid, inConversation: convoID)

        }
    }
    
    /// This updates the conversation for each user when a new message is sent
//    func updateUsersConversations(message: StripwayMessage, senderUser: StripwayUser, receiverUser: StripwayUser, inConversation convoID: String) {
    func updateUsersConversations(message: StripwayMessage, senderID: String, receiverID: String, inConversation convoID: String) {
        
        let newConversationForSender = StripwayConversation(convoID: convoID, mostRecentTimestamp: message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: receiverID)
        let senderConversationsReference = API.User.usersReference.child(senderID).child("myConversations").child(receiverID)
        senderConversationsReference.updateChildValues(newConversationForSender.toAnyObject())

        let newConversationForReceiver = StripwayConversation(convoID: convoID, mostRecentTimestamp: message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: senderID)
        let receiverConversationsReference = API.User.usersReference.child(receiverID).child("myConversations").child(senderID)
        receiverConversationsReference.updateChildValues(newConversationForReceiver.toAnyObject())

        receiverConversationsReference.child("unreadMessagesCount").runTransactionBlock { (currentData) -> TransactionResult in
            if let currentNumber = currentData.value as? Int {
                currentData.value = currentNumber + 1
                return TransactionResult.success(withValue: currentData)
            }
            currentData.value = 1
            return TransactionResult.success(withValue: currentData)
        }
        
        
//        let newConversationForSender = StripwayConversation(convoID: convoID, mostRecentTimestamp: message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: receiverUser.uid)
//        let senderConversationsReference = API.User.usersReference.child(senderUser.uid).child("myConversations").child(receiverUser.uid)
//        senderConversationsReference.updateChildValues(newConversationForSender.toAnyObject())
//
//        let newConversationForReceiver = StripwayConversation(convoID: convoID, mostRecentTimestamp: message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: senderUser.uid)
//        let receiverConversationsReference = API.User.usersReference.child(receiverUser.uid).child("myConversations").child(senderUser.uid)
//        receiverConversationsReference.updateChildValues(newConversationForReceiver.toAnyObject())
//
//        receiverConversationsReference.child("unreadMessagesCount").runTransactionBlock { (currentData) -> TransactionResult in
//            if let currentNumber = currentData.value as? Int {
//                currentData.value = currentNumber + 1
//                return TransactionResult.success(withValue: currentData)
//            }
//            currentData.value = 1
//            return TransactionResult.success(withValue: currentData)
//        }
    }
    
    /// Batch loading of messages, gets messages starting at timestamp
    /// Uses similar logic from FeedAPI in the zero2launch tutorials, similar to RepostAPI in this app
    func getRecentMessages(fromConversationID convoID: String, usersDictionary: [String: StripwayUser], start timestamp: Int? = nil, limit: UInt, completion: @escaping ([StripwayMessage])->()) {
        
        var messagesQuery = conversationsReference.child(convoID).child("messages").queryOrdered(byChild: "timestamp")
        if let latestMessageTimestamp = timestamp, latestMessageTimestamp > 0 {
            messagesQuery = messagesQuery.queryStarting(atValue: latestMessageTimestamp + 1, childKey: "timestamp").queryLimited(toLast: limit)
        } else {
            messagesQuery = messagesQuery.queryLimited(toLast: limit)
        }
        
        // Get the 20 most recent messages in one batch
        messagesQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects
            var results = [StripwayMessage]()
            
            // Iterate through them and then append the message to the array
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                if let snapshotValue = item.value as? [String: Any],
                    let senderUID = snapshotValue["senderUID"] as? String,
                    let senderUser = usersDictionary[senderUID] {
                    let newMessage = StripwayMessage(snapshot: item, user: senderUser)
                    results.append(newMessage)
                }
            }
            // Return the array in the completion handler
            completion(results)
        }
        
    }
    
    func getConversationID(_ userID:String, completion: @escaping (String)->()) {
        // Checking if sender (aka current user) already has a conversation with this person
        API.User.usersReference.child(Constants.currentUser!.uid).child("myConversations").observeSingleEvent(of: .value, with: { (snapshot) in
            // If they have receiver's uid in their "myConversations" then a conversation already exists, return its id
            // TODO: Use .exists() instead
            var conversationID:String
            if snapshot.hasChild(userID) {
                conversationID = snapshot.childSnapshot(forPath: userID).childSnapshot(forPath: "conversationDatabaseID").value as? String ?? API.Messages.conversationsReference.childByAutoId().key!
            } else {
                print("sender does not have a convo with receiver")
                // Else create a new one and set it to that
                conversationID = API.Messages.conversationsReference.childByAutoId().key!
            }
            
            completion(conversationID)
        })
    }
    
    /// Batch loading of older messages starting at timestamp
    func getOlderMessages(fromConversationID convoID: String, usersDictionary: [String: StripwayUser], start timestamp: Int, limit: UInt, completion: @escaping ([StripwayMessage])->()) {
        
        let messagesQuery = conversationsReference.child(convoID).child("messages").queryOrdered(byChild: "timestamp")
        let messagesLimitedQuery = messagesQuery.queryEnding(atValue: timestamp - 1, childKey: "timestamp").queryLimited(toLast: limit)
        
        // Get the 20 messages before timestamp in one batch
        messagesLimitedQuery.observeSingleEvent(of: .value) { (snapshot) in
            let items = snapshot.children.allObjects
            var results = [StripwayMessage]()
            
            // Iterate through them and append them to the array
            for (_, item) in (items as! [DataSnapshot]).enumerated() {
                if let snapshotValue = item.value as? [String: Any],
                    let senderUID = snapshotValue["senderUID"] as? String,
                    let senderUser = usersDictionary[senderUID] {
                    let newMessage = StripwayMessage(snapshot: item, user: senderUser)
                    results.append(newMessage)
                }
            }
            completion(results)
        }
        
    }
    
    /// Constantly observes for any new messages that might come in while the user has the convo open (aka getRecentMessages and getOlderMessages won't
    /// be able to retrieve them). Gets everything older than timestamp.
    func observeNewMessages(forConversationID convoID: String, usersDictionary: [String: StripwayUser], start timestamp: Int, completion: @escaping(StripwayMessage)->()) {
        
        conversationReferences.append(conversationsReference.child(convoID).child("messages"))
        // Observe the new child then return it in the completion handler
        let newMessagesQuery = conversationsReference.child(convoID).child("messages").queryOrdered(byChild: "timestamp").queryStarting(atValue: timestamp + 1, childKey: "timestamp")
        newMessagesQuery.observe(.childAdded) { (snapshot) in
            print("OBSERVEBUG: Just observed a new message")
            if let snapshotDict = snapshot.value as? [String: Any] {
                let senderUID = snapshotDict["senderUID"] as! String
                let senderUser = usersDictionary[senderUID]!
                let newMessage = StripwayMessage(snapshot: snapshot, user: senderUser)
                completion(newMessage)
            }
        }
    }
    
    /// Constantly observes for any deleted messages, then returns the key (messageID) so we know which one to delete
    func observeDeletedMessages(forConversationID convoID: String, completion: @escaping(String)->()) {
        conversationReferences.append(conversationsReference.child(convoID).child("messages"))
        conversationsReference.child(convoID).child("messages").observe(.childRemoved) { (snapshot) in
            completion(snapshot.key)
        }
    }
    
    /// This resets the count of unread messages.
    func resetUnreadCount(forCurrentUID currentUID: String, fromOtherUID otherUID: String) {
        // Reset the unreadCount to zero
        let receiverConversationsReference = API.User.usersReference.child(currentUID).child("myConversations").child(otherUID)
        receiverConversationsReference.child("unreadMessagesCount").runTransactionBlock { (currentData) -> TransactionResult in
            currentData.value = 0
            return TransactionResult.success(withValue: currentData)
        }
    }
    
    
    /// Observes all the conversations that a user has. Shows the other user's profile image and the text of the most recent message
    /// in the conversation.
    /// TODO: Load these in batches too.
    func observeConversations(forUserID userID: String, completion: @escaping(StripwayConversation?, StripwayUser?, Error?)->()) {
        conversationsListReferences.append(API.User.usersReference.child(userID).child("myConversations"))
        API.User.usersReference.child(userID).child("myConversations").observe(.value) { (snapshot) in
            for case let childSnapshot as DataSnapshot in snapshot.children {
                print("observingConversations: \(childSnapshot.key)")
                // TODO: Change this to just check .exists() because then we don't have to download all
                // of that users conversationIDs
                if !childSnapshot.hasChild("conversationDatabaseID") {
                    print("THIS CONVERSATION ISN'T FORMATTED CORRECTLY")
                    let newError = CustomError("BAD CONVO")
                    completion(nil, nil, newError)
                } else {
                    let newConversation = StripwayConversation(snapshot: childSnapshot)
                    API.User.observeUser(withUID: newConversation.otherParticipantUID, completion: { (user, error) in
                        if let error = error {
                            completion(nil, nil, error)
                        } else if let user = user {
                            if user.isBlocked || user.hasBlocked {
                                let error = CustomError("Blocked user")
                                completion(nil, nil, error)
                            }
                            completion(newConversation, user, nil)
                        }
                    })
                }
            }
        }
    }
    
    /// This actually returns the number of conversations with unread messages in them. So if one convo has 4 unread messages,
    /// and another has 5, this number will only return 2 because there are two unread convos. This is used for the badge on the messages
    /// icon on the home feed.
    func getUnreadMessagesCount(completion: @escaping (Int)->()) {
        let ref = Database.database().reference().child("userNotificationInfo").child(Auth.auth().currentUser!.uid).child("unreadMessagesCount")
        ref.observe(.value) { (snapshot) in
            if let unreadMessages = snapshot.value as? Int {
                completion(unreadMessages)
                return
            }
            completion(0)
        }
    }
    
    /// Deletes the conversation reference for the user that initiated the delete
    /// Does not delete the entire conversation, we may want to do this at some point as a Cloud Function in order to prevent zombie conversations. If we do that here we must check for the other user in the conversation, see if they still have the conversation in the list etc.
    func deleteConversationForUser(forUserID userID: String, forConversationID convoID: String) {
        
        let query = API.User.usersReference.child(userID).child("myConversations").queryOrdered(byChild: "conversationDatabaseID").queryEqual(toValue: convoID)
        query.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                print(snap.key)
                
                let ref = API.User.usersReference.child(userID).child("myConversations").child(key)
                
                ref.removeValue { error, _ in
                    
                    print(error ?? "Deleted conversation from user list successfully")
                }
            }
        })
        
    }
    
    /// Observes the conversation list for deleted conversations
    func observeConversationsDelete(forUserID userID: String, completion: @escaping(StripwayConversation?, Error?)->()) {
        conversationsListReferences.append(API.User.usersReference.child(userID).child("myConversations"))
        API.User.usersReference.child(userID).child("myConversations").observe(.childRemoved) { (snapshot) in
            let oldConvo = StripwayConversation(snapshot: snapshot)
            completion(oldConvo, nil)
        }
    }
    /// Deletes the conversation entirely from the database
    func deleteConversation(forConversationID convoID:String)
    {
        let ref = conversationsReference.child(convoID)
        ref.removeValue { error, _ in
            
            print(error ?? "Deleted conversation from database successfully")
        }
    }
    
    /// Deletes a message within a conversation
    func deleteMessage(forConversationID convoID:String, forMessageID messageID:String, lastMessage: StripwayMessage?, senderUser: StripwayUser?, receiverUser: StripwayUser?)
    {
        let ref = conversationsReference.child(convoID).child("messages").child(messageID)
        ref.removeValue { error, _ in
            
            print(error ?? "Deleted message from conversation successfully")
        }
        if let message = lastMessage
        {
            let newConversationForSender = StripwayConversation(convoID: convoID, mostRecentTimestamp:
                message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: receiverUser!.uid)
            let senderConversationsReference = API.User.usersReference.child(senderUser!.uid).child("myConversations").child(receiverUser!.uid)
            senderConversationsReference.updateChildValues(newConversationForSender.toAnyObject())
            
            let newConversationForReceiver = StripwayConversation(convoID: convoID, mostRecentTimestamp: message.timestamp, mostRecentMessageText: message.messageText, otherParticipantUID: senderUser!.uid)
            let receiverConversationsReference = API.User.usersReference.child(receiverUser!.uid).child("myConversations").child(senderUser!.uid)
            receiverConversationsReference.updateChildValues(newConversationForReceiver.toAnyObject())
        }
        
    }
    
    func loadConversationID(senderUser: StripwayUser, receiverUser:StripwayUser, loadCompleted: @escaping(String)->()) {
        
        // Checking if sender (aka current user) already has a conversation with this person
        API.User.usersReference.child(senderUser.uid).child("myConversations").observeSingleEvent(of: .value, with: { (snapshot) in
            // If they have receiver's uid in their "myConversations" then a conversation already exists, return its id
            // TODO: Use .exists() instead
            var conversationID = ""
            if snapshot.hasChild(receiverUser.uid) {
                conversationID = snapshot.childSnapshot(forPath: receiverUser.uid).childSnapshot(forPath: "conversationDatabaseID").value as? String ?? API.Messages.conversationsReference.childByAutoId().key!
            } else {
                print("sender does not have a convo with receiver")
                // Else create a new one and set it to that
                conversationID = API.Messages.conversationsReference.childByAutoId().key!
            }
            loadCompleted(conversationID)
        })
    }
    
    /// Creates a image or post message and adds it to the conversation on the database
    func createMediaMessage(forConversationID convoID: String, newMessage:StripwayMessage, completion: @escaping()->()) {
        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessage.messageID)
        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
            if let error = error {
                print("Error saving message to the database: \(error.localizedDescription)")
            }
            //            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
            return self.updateUsersConversations(message: newMessage, senderID: newMessage.senderUID, receiverID: newMessage.receiverUID, inConversation: convoID)
        }
    }

    /// Creates a image or post message and adds it to the conversation on the database
//    func createMediaMessage(forConversationID convoID: String, newMessage:StripwayMessage, completion: @escaping()->()) {
    func createPostMessage(forConversationID convoID: String, newMessage:StripwayMessage, comment:String, completion: @escaping()->()) {

        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessage.messageID)
        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
            if let error = error {
                print("Error saving message to the database: \(error.localizedDescription)")
            }
            //            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
            self.updateUsersConversations(message: newMessage, senderID: newMessage.senderUID, receiverID: newMessage.receiverUID, inConversation: convoID)
            
            if comment != "" {
                //if comment exists -- send that 
                let commentMsgID = API.Messages.conversationsReference.child(convoID).child("messages").childByAutoId().key!
                let timestamp = Int(Date().timeIntervalSince1970)
                
                let commentMessageRefernce = self.conversationsReference.child(convoID).child("messages").child(commentMsgID)
                
                let commentMsg = StripwayMessage(messageID: commentMsgID, messageText: comment, timestamp: timestamp, senderUser: newMessage.senderUser, receiverUID: newMessage.receiverUID)
                
                commentMessageRefernce.setValue(commentMsg.toAnyObject()) { (error, ref) in
                    if let error = error {
                        print("Error saving message to the database: \(error.localizedDescription)")
                    }
                    return self.updateUsersConversations(message: commentMsg, senderID: newMessage.senderUID, receiverID: newMessage.receiverUID, inConversation: convoID)
                }
            }
        }
        
        //this was old code
//        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessage.messageID)
//        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
//            if let error = error {
//                print("Error saving message to the database: \(error.localizedDescription)")
//            }
//            //            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
//            return self.updateUsersConversations(message: newMessage, senderID: newMessage.senderUID, receiverID: newMessage.receiverUID, inConversation: convoID)
//        }
    }

    
    func sendPost(post:StripwayPost, comment:String, senderUser: StripwayUser, receiverUser:StripwayUser) {
        loadConversationID(senderUser: senderUser, receiverUser: receiverUser) { conversationID in
            let newMessageID = API.Messages.conversationsReference.child(conversationID).child("messages").childByAutoId().key!
            var timestamp = Int(Date().timeIntervalSince1970)
            
            print("new message = timestamp = ", timestamp)
            
            let sendingPostMsg = StripwayMessage(messageID: newMessageID, imageURL: post.photoURL, postID: post.postID, authorUID: post.authorUID, timestamp: timestamp, senderUser: senderUser, receiverUID: receiverUser.uid)
            sendingPostMsg.postCaption = post.caption
            
//            API.Messages.createMediaMessage(forConversationID: conversationID, newMessage: sendingPhotoMsg) {
//            }
//            sendingPostMsg.messageText = comment
            
            API.Messages.createPostMessage(forConversationID: conversationID, newMessage: sendingPostMsg, comment:comment) {
            }
        }
    }

    /// Creates a image message and adds it to the conversation on the database
    func createImageMessage(forConversationID convoID: String, newMessage:StripwayMessage, completion: @escaping(StripwayMessage?)->()) {
    
        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessage.messageID)
        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
            if let error = error {
                print("Error saving message to the database: \(error.localizedDescription)")
            }
//            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
            return self.updateUsersConversations(message: newMessage, senderID: newMessage.senderUID, receiverID: newMessage.receiverUID, inConversation: convoID)
        }

        
        //this was old code
        
//        let newMessageID = conversationsReference.child(convoID).child("messages").childByAutoId().key!
//        let newMessageReference = conversationsReference.child(convoID).child("messages").child(newMessageID)
//        let timestamp = Int(Date().timeIntervalSince1970)
//        let newMessage = StripwayMessage(messageID: newMessageID, imageURL: imageURL, timestamp: timestamp, senderUser: senderUser, receiverUID: receiverUser.uid)
//        newMessageReference.setValue(newMessage.toAnyObject()) { (error, ref) in
//            if let error = error {
//                print("Error saving message to the database: \(error.localizedDescription)")
//            }
//            self.updateUsersConversations(message: newMessage, senderUser: senderUser, receiverUser: receiverUser, inConversation: convoID)
//        }
    }
    
    /// Uploads image to Firebase Storage
    func uploadImage(_ image: UIImage?, forConversationID convoID:String, completion: @escaping (URL?) -> Void) {
//        guard let convoID = channel.id else {
//            completion(nil)
//            return
//        }
        
        guard let scaledImage = image,
            let data = scaledImage.jpegData(compressionQuality: 0.4) else {
                completion(nil)
                return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let storageRef = storage.child(convoID).child(imageName)
        
        storageRef.putData(data, metadata: metadata) { metadata, error in
            if error == nil, metadata != nil {
                
                storageRef.downloadURL { url, error in
                    completion(url)
                    // success!
                }
            } else {
                // failed
                completion(nil)
            }
        }
    }
    
    ///Deletes image from Cloud Storage
    func deleteImage(forReference urlRef:String) {
        let storageRef = Storage.storage().reference(forURL: urlRef)
        storageRef.delete { error in
        if let error = error {
        print(error)
        } else {
        // File deleted successfully
            print("Image was deleted")
        }
        }
    }

    /// Removes all the observers for ViewConversationViewController because we don't
    /// need to know about new messages unless the convo is currently on screen
    func removeAllConversationObservers() {
        for reference in conversationReferences {
            reference.removeAllObservers()
        }
    }
   
    /// Removes all the observers for ConversationListViewController because we don't
    /// need to be observing unless it's currently on screen
    func removeAllConversationsListObservers() {
        for reference in conversationsListReferences {
            reference.removeAllObservers()
        }
    }
    
    
}
