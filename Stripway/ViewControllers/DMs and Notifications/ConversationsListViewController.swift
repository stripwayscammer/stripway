//
//  ConversationsListViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/19/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class ConversationsListViewController: UIViewController {

    var conversations: [StripwayConversation] = []
    var users: [String: StripwayUser] = [:]
    var currentStripwayUser: StripwayUser?
    @IBOutlet weak var tableView: UITableView!
    
    var tappedConversationID: String!
    var tappedCellSender: StripwayUser!
    var tappedCellReceiver: StripwayUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCurrentUser()
        print("viewDidLoad() calledaI'm ")
        // Do any additional setup after loading the view.
        self.title = "Conversations"
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        self.navigationController?.navigationBar.tintColor = UIColor.black
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        API.Messages.removeAllConversationsListObservers()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loadConversations()
        print("helloooo")
    }
    
    
    
    func loadCurrentUser() {
        API.User.observeCurrentUser { (user) in
            self.currentStripwayUser = user
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.loadConversations()
        }
    }
    
    /// This is for the notification to segue to the correct convo when tapped
    func segueToConversationWithID(convoID: String, senderUID: String, receiverUID: String) {
        API.User.observeUser(withUID: senderUID) { (user, error) in
            if let senderUser = user {
                API.User.observeUser(withUID: receiverUID, completion: { (user, error) in
                    if let receiverUser = user {
                        self.tappedConversationID = convoID
                        // This is confusing and I need to fix it, but the sender of the message we just got notified for will be the receiver
                        // in ViewConversationViewController, that's why they're flipped (because current user will be the sender but they were
                        // the receiver of the notification)
                        self.tappedCellSender = receiverUser
                        self.tappedCellReceiver = senderUser
                        self.performSegue(withIdentifier: "ShowConversationSegue", sender: self)
                    }
                })
            }
        }
    }
    
    func loadConversations() {
//        API.Messages.observeConversations(forUserID: currentStripwayUser!.uid) { (conversation) in
//            API.User.observeUser(withUID: conversation.otherParticipantUID, completion: { (user) in
//                self.users[user.uid] = user
//                self.conversations.append(conversation)
//                self.tableView.reloadData()
//            })
//        }
        
        guard let currentStripwayUser = currentStripwayUser else { return }
        API.Messages.observeConversations(forUserID: currentStripwayUser.uid) { (conversation, user, error) in


            if let error = error {
                print(error.localizedDescription)
                return
            }
            self.users[user!.uid] = user!
            if let oldIndex = self.conversations.firstIndex(where: { $0.conversationDatabaseID == conversation!.conversationDatabaseID }) {
                self.conversations.remove(at: oldIndex)
            }
            self.conversations.append(conversation!)
            print("")
            self.tableView.reloadData()
        }
        
        API.Messages.observeConversationsDelete(forUserID: currentStripwayUser.uid) { (conversation, error) in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let oldIndex = self.conversations.firstIndex(where: { $0.conversationDatabaseID == conversation!.conversationDatabaseID }) {
                self.conversations.remove(at: oldIndex)
            }
            self.tableView.reloadData()

        }
        
    }
    
    
    @objc func addButtonPressed() {
        print("Add button pressed")
        performSegue(withIdentifier: "ShowFollowingsSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Same as above but for followings
        if segue.identifier == "ShowFollowingsSegue" {
            if let peopleViewController = segue.destination as? PeopleViewController {
                peopleViewController.listType = .messageFollowing
                peopleViewController.profileOwner = currentStripwayUser!
            }
        }
        if segue.identifier == "ShowConversationSegue" {
            if let viewConversationViewController = segue.destination as? ViewConversationViewController {
                viewConversationViewController.conversationID = self.tappedConversationID
                viewConversationViewController.senderUser = self.tappedCellSender
                viewConversationViewController.receiverUser = self.tappedCellReceiver
            }
        }
    }

}

extension ConversationsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        headerImageURLs = headerImageURLs.sorted(by: { $0.index < $1.index })
        conversations = conversations.sorted(by: { $0.mostRecentTimestamp > $1.mostRecentTimestamp })
        let conversation = conversations[indexPath.row]
        let user = users[conversation.otherParticipantUID]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationTableViewCell", for: indexPath) as! ConversationTableViewCell
        cell.user = user
        cell.conversation = conversation
        if conversation.unreadMessagesCount <= 0 {
            cell.markConversationRead()
        } else {
            cell.markConversationUnread()
        }
        return cell
    }
}

extension ConversationsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let conversation = conversations[indexPath.row]
        let receiver = users[conversation.otherParticipantUID]!
        let sender = self.currentStripwayUser!
        
        self.tappedConversationID = conversation.conversationDatabaseID
        self.tappedCellSender = sender
        self.tappedCellReceiver = receiver
        performSegue(withIdentifier: "ShowConversationSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversation = self.conversations[indexPath.row]
            
            API.Messages.deleteConversationForUser(forUserID: currentStripwayUser!.uid, forConversationID: conversation.conversationDatabaseID)
            
            self.conversations.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
