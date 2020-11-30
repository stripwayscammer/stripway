//
//  MessagesViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/20/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import MessageKit
import FirebaseDatabase
import InputBarAccessoryView
import Lightbox
import Photos
import Kingfisher
import NYTPhotoViewer

class ViewConversationViewController: MessagesViewController, LightboxControllerTouchDelegate {
    var controller: LightboxController!
    var messages: [StripwayMessage] = []
    var users: [String: StripwayUser] = [:]
    var member: Member!
    var posts: [IndexPath: StripwayPost] = [:]
    var tappedPost: StripwayPost?
    var tappedStrip: StripwayStrip?
    
    // This might not exist, if you're creating a new message, actually we'll start with it existing (one gets randomly assigned to you when you start a new convo)
    var conversationID: String?
    
    var senderUser: StripwayUser!
    var receiverUser: StripwayUser!
    var postUser: StripwayUser!
    var isShowingReceiverUser:Bool!
    var isShowingPostAuthor:Bool!
    
    var dateStamp:[String] = []
    var indexForDate:[Int] = []
    var lastMessage:MessageType!
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = DateFormatter.Style.none
        return formatter
    }()
    
    let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()
    
    
    private var isSendingPhoto = false {
        didSet {
            DispatchQueue.main.async {
                self.messageInputBar.leftStackViewItems.forEach { item in
                    // Need to fix
                    //                    item.isEnabled = !self.isSendingPhoto
                }
            }
        }
    }
    
    
    /// Used to load more messages when the user scrolls up
    let refreshControl = UIRefreshControl()
    /// Used so we can get messages older than this timestamp when loading more
    var oldestTimestamp = Int(Date().timeIntervalSince1970)
    /// Used so we can get messages newer than the last message (aka any messages received after loadMessages() is called because
    /// that only loads the 20 latest messages and then stops
    var newestTimestamp = Int(Date().timeIntervalSince1970)
    
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        
        super.viewDidLoad()
        
        users[senderUser.uid] = senderUser
        users[receiverUser.uid] = receiverUser
        
        self.member = Member(name: self.senderUser.username, color: .blue)
        
        // Make sure conversationID exists before loading messages
        loadConversationID {
            self.loadMessages()
        }
        configureMessageCollectionView()
        configureMessageInputBar()
        updateMessageStyle()
        
        self.navigationController?.navigationBar.tintColor = UIColor.black
        
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        setupTitleBar()
    }
    
    
    let currentUser = Sender(id: UUID().uuidString, displayName: "Sender")
    let otherUser = Sender(id: UUID().uuidString, displayName: "Receiver")
//    248DE1
    let otherUser_0 = UIColor(red:36/255, green:141/255, blue:225/255, alpha:1.0)
    let otherUser_1 = UIColor(red:36/255, green:141/255, blue:225/255, alpha:1.0)
    
    //Change these to enable gradients on current user bubbles too
    let currentUser_0 = UIColor.groupTableViewBackground
    let currentUser_1 = UIColor.groupTableViewBackground
    
    var currentUserMessageStyle: MessageStyle?
    var otherUserMessageStyle: MessageStyle?
    
    func configureMessageCollectionView() {
        messagesCollectionView.register(SharePostCell.self, forCellWithReuseIdentifier: "SharePostCell")

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        // Add the refresh control
        refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        self.messagesCollectionView.addSubview(refreshControl)
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment.init(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)))
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    /// Sets custom message style, applies gradients etc
    private func updateMessageStyle() {
        currentUserMessageStyle = MessageStyle.custom({ (containerView) in
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [self.otherUser_0.cgColor, self.otherUser_1.cgColor]
            gradientLayer.locations = [0.0 , 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.2)
            gradientLayer.frame = containerView.bounds
            containerView.layer.insertSublayer(gradientLayer, below: containerView.layer.sublayers?.last)
            ///Changing this will let you choose what edges to round
            containerView.roundCorners([.topLeft, .topRight, .bottomRight, .bottomLeft], radius: 15.0)
        })
        
        otherUserMessageStyle = MessageStyle.custom({ (containerView) in
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [self.currentUser_0.cgColor, self.currentUser_1.cgColor]
            gradientLayer.locations = [0.0 , 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
            gradientLayer.frame = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            containerView.layer.insertSublayer(gradientLayer, below: containerView.layer.sublayers?.last)
            containerView.roundCorners([.topLeft, .topRight,.bottomRight, .bottomLeft], radius: 15.0)
            
        })
    }
    
    func setupTitleBar() {
        guard let navBar = self.navigationController?.navigationBar else { return }
        navBar.addSubview(newTitleView)
        newTitleView.centerXAnchor.constraint(equalTo: navBar.centerXAnchor, constant: 0).isActive = true
        newTitleView.topAnchor.constraint(equalTo: navBar.topAnchor, constant: 0).isActive = true
        newTitleView.bottomAnchor.constraint(equalTo: navBar.bottomAnchor, constant: 0).isActive = true
        
        let titleTapGesture = UITapGestureRecognizer(target: self, action: #selector(titleViewTapped))
        newTitleView.addGestureRecognizer(titleTapGesture)
        
        newTitleView.addSubview(titleProfileImage)
        titleProfileImage.sd_setImage(with: URL(string: receiverUser.profileImageURL!), completed: nil)
        titleProfileImage.leadingAnchor.constraint(equalTo: newTitleView.leadingAnchor, constant: 0).isActive = true
        titleProfileImage.topAnchor.constraint(equalTo: newTitleView.topAnchor, constant: 0).isActive = true
        titleProfileImage.heightAnchor.constraint(equalToConstant: 36).isActive = true
        titleProfileImage.widthAnchor.constraint(equalToConstant: 36).isActive = true
        titleProfileImage.clipsToBounds = true
        titleProfileImage.contentMode = .scaleAspectFill
        titleProfileImage.layer.cornerRadius = 18
        newTitleView.addSubview(titleUsernameLabel)
        titleUsernameLabel.attributedText = NSAttributedString(string: receiverUser.username, attributes: [NSAttributedString.Key.font: UIFont(name: "AvenirNext-DemiBold", size: 20)!])
        titleUsernameLabel.sizeToFit()
        titleUsernameLabel.leadingAnchor.constraint(equalTo: titleProfileImage.trailingAnchor, constant: 8).isActive = true
        titleUsernameLabel.topAnchor.constraint(equalTo: newTitleView.topAnchor, constant: 0).isActive = true
        titleUsernameLabel.trailingAnchor.constraint(equalTo: newTitleView.trailingAnchor, constant: 0).isActive = true
        titleUsernameLabel.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    ///Show image on click of image cell
    @objc func showImage(index: Int, imageURLs: [URL] = []) {
        print("showImage called from inside ViewConversationViewController")
        let images = imageURLs.map({url in
            LightboxImage(imageURL: url)
        })
        controller = LightboxController(images: images, startIndex: index)
        controller.imageTouchDelegate = self
        controller.modalPresentationStyle = .fullScreen
        LightboxConfig.CloseButton.text = "Done"
        present(controller, animated: true, completion: nil)
    }
    func lightboxController(_ controller: LightboxController, didTouch image: LightboxImage, at index: Int) {
        if let image = image.image {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "Save Photo", style: .default) { [self] (action) in
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(action)
            alertController.addAction(cancel)
            controller.present(alertController, animated: true, completion: nil)
        } else if let imageURL = image.imageURL {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "Save Photo", style: .default) { [self] (action) in
                KingfisherManager.shared.retrieveImage(with: imageURL) { result in
                    // Do something with `result`
                    switch result {
                    case .success(let result):
                        let image = result.image
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                    case .failure(let err):
                        print(err)
                    }
                }
                
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(action)
            alertController.addAction(cancel)
            controller.present(alertController, animated: true, completion: nil)
            
        }
        
    }

    //MARK: - Add image to Library
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            controller.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            controller.present(ac, animated: true)
        }
    }
    @objc func titleViewTapped() {
        print("Title view was tapped")
        self.isShowingReceiverUser = true
        performSegue(withIdentifier: "SegueToProfile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                
                if isShowingReceiverUser == true {
                    profileViewController.profileOwner = receiverUser
                }
                else {
                    profileViewController.profileOwner = postUser
                }
            }
        }
        if segue.identifier == "ShowPost" {
            
            if(tappedPost != nil){
                if let viewPostViewController = segue.destination as? ViewPostViewController {
                    
                    viewPostViewController.post = tappedPost!
                    viewPostViewController.tappedStrip = tappedStrip
                    viewPostViewController.posts = []
                }
            }
        }
    }
    
    lazy var newTitleView: UIView = {
        let v = UIView(frame: CGRect.zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    lazy var titleProfileImage: UIImageView = {
        let v = UIImageView(frame: CGRect.zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    lazy var titleUsernameLabel: UILabel = {
        let v = UILabel(frame: CGRect.zero)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        
        messageInputBar.isTranslucent = true
        messageInputBar.inputTextView.tintColor = UIColor.black
        
        messageInputBar.inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 36)
        messageInputBar.inputTextView.layer.borderColor = UIColor.clear.cgColor
        messageInputBar.inputTextView.layer.backgroundColor = UIColor.clear.cgColor
        //messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        configureInputBarItems()
    }
    
    func configureInputBarItems() {
        messageInputBar.sendButton.setTitleColor(UIColor.black, for: .normal)
        
        let cameraItem = InputBarButtonItem(type: .system)
        cameraItem.tintColor = UIColor.black
        cameraItem.image = #imageLiteral(resourceName: "Save Photo Unselected")
        
        // 2
        cameraItem.addTarget(
            self,
            action: #selector(cameraButtonPressed),
            for: .primaryActionTriggered
        )
        cameraItem.setSize(CGSize(width: 80, height: 40), animated: false)
        
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        
        // 3
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.tabBarController?.tabBar.isHidden = true
        // Reset unread count when the current user has opened this convo
        if conversationID != nil {
            API.Messages.resetUnreadCount(forCurrentUID: self.senderUser.uid, fromOtherUID: self.receiverUser.uid)
        }
        self.setupTitleBar()
        self.navigationController?.isNavigationBarHidden = false
        self.isShowingPostAuthor = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start constantly observing this convo for new and deleted messages
        if conversationID != nil {
            observeNewAndDeletedMessages()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        newTitleView.removeFromSuperview()
        // Reset unread count when user closes the convo (because the database has still been counting new messages as unread
        // even though the convo is open)
        if conversationID != nil {
            API.Messages.resetUnreadCount(forCurrentUID: self.senderUser.uid, fromOtherUID: self.receiverUser.uid)
        }
        //NotificationCenter.default.removeObserver(self)
        // Stop constantly observing this convo for new messages
        API.Messages.removeAllConversationObservers()
    }
    
    @objc func appMovedToBackground() {
        // Reset unread count when user closes the app (because the database has still been counting new messages as unread
        // even though the convo is open)
        if conversationID != nil {
            API.Messages.resetUnreadCount(forCurrentUID: self.senderUser.uid, fromOtherUID: self.receiverUser.uid)
        }
    }
    
    func loadConversationID(loadCompleted: @escaping()->()) {
        if conversationID != nil {
            loadCompleted()
            return
        }
        // Checking if sender (aka current user) already has a conversation with this person
        API.User.usersReference.child(senderUser.uid).child("myConversations").observeSingleEvent(of: .value, with: { (snapshot) in
            // If they have receiver's uid in their "myConversations" then a conversation already exists, return its id
            // TODO: Use .exists() instead
            if snapshot.hasChild(self.receiverUser.uid) {
                self.conversationID = snapshot.childSnapshot(forPath: self.receiverUser.uid).childSnapshot(forPath: "conversationDatabaseID").value as? String ?? API.Messages.conversationsReference.childByAutoId().key!
            } else {
                print("sender does not have a convo with receiver")
                // Else create a new one and set it to that
                self.conversationID = API.Messages.conversationsReference.childByAutoId().key!
            }
            loadCompleted()
        })
    }
    
    /// Loads the first batch of messages in addition to observing new messages while the convo is open and observing deleted messages
    /// while the convo is open, so it always matches the database.
    func loadMessages() {
        // Gets the 20 most recent messages
        API.Messages.getRecentMessages(fromConversationID: self.conversationID!, usersDictionary: users, limit: 20) { (recentMessages) in
            for message in recentMessages {
                self.messages.append(message)
            }
            self.messages.sort(by: { $0.timestamp < $1.timestamp })
            
            // Save the first timestamp so we know where to start when requesting older messages
            if let firstTimestamp = self.messages.first?.timestamp, let lastTimestamp = self.messages.last?.timestamp {
                self.oldestTimestamp = firstTimestamp
                self.newestTimestamp = lastTimestamp
            }
            
            // Reload UI
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom(animated: false)
        }
    }
    
    /// Makes sure we don't try loading more messages while they're already being loaded
    var loadingMoreMessages = false
    /// Loads older messages from the database in batches of 20
    @objc func loadMoreMessages() {
        if !loadingMoreMessages {
            loadingMoreMessages = true
            self.refreshControl.beginRefreshing()
            // Get the 20 messages before oldestTimestamp
            API.Messages.getOlderMessages(fromConversationID: self.conversationID!, usersDictionary: users, start: oldestTimestamp, limit: 20) { (messages) in
                for message in messages {
                    self.messages.append(message)
                }
                self.messages.sort(by: { $0.timestamp < $1.timestamp })
                // Update oldestTimestamp
                if let firstTimestamp = self.messages.first?.timestamp, let lastTimestamp = self.messages.last?.timestamp {
                    self.oldestTimestamp = firstTimestamp
                    self.newestTimestamp = lastTimestamp
                }
                // Keep offset for smoother UI
                self.messagesCollectionView.reloadDataAndKeepOffset()
                self.refreshControl.endRefreshing()
                // User can now load more messages if they want
                self.loadingMoreMessages = false
            }
        }
    }
    
    /// Observes new and deleted messages because those are separate from the getRecentMessages and getOlderMessages
    /// as these ones use .observe instead of .observeSingleEventOf
    func observeNewAndDeletedMessages() {
        // Adds an observer to check for new messages, since both getRecentMessages() and getOlderMessages() from MessagesAPI
        // both use .observeSingleEventOf, which doesn't constantly observe
        API.Messages.observeNewMessages(forConversationID: self.conversationID!, usersDictionary: users, start: newestTimestamp) { (message) in
            // Probably not necessary but make sure that it doesn't already exist in the array before adding it
            if !self.messages.contains(where: { $0.messageID == message.messageID }) {
                self.messages.append(message)
                self.newestTimestamp = message.timestamp
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
        
        // Adds an observer to check for deleted messages, so that when the other user deletes a message it immediately updates
        // in this user's convo.
        API.Messages.observeDeletedMessages(forConversationID: self.conversationID!) { (deletedMessageID) in
            if let deletedIndex = self.messages.firstIndex(where: { $0.messageID == deletedMessageID }) {
                self.messages.remove(at: deletedIndex)
                self.messagesCollectionView.reloadData()
            }
        }
    }
    
    @objc func avatarTapped(sender: AvatarTapGesture) {
        //to avoid multiple showing
        if self.isShowingPostAuthor == true {
            return
        }
        
        self.isShowingPostAuthor = true
        
        if let authorId = sender.userId as? String {
            API.User.observeUser(withUID: authorId) { (outUser, error) in
                if let error = error {
                    print("Something went wrong here, should display an error \(error)")
                }
                else {
                    self.isShowingReceiverUser = false
                    self.postUser = outUser
                    self.performSegue(withIdentifier: "SegueToProfile", sender: self)
                }
            }
        }
        
    }

    func printMessages() {
        print("\n============================MESSAGES============================")
        for message in messages {
            print("\(message.sender.displayName): \(message.messageText)")
        }
        print("============================MESSAGES============================\n")
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        
        let message = messages[indexPath.section]
        let cell = messagesCollectionView.dequeueReusableCell(SharePostCell.self, for: indexPath)
        cell.configure(with: message, at: indexPath, and: messagesCollectionView)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        let messageSender = messages[indexPath.section].senderUID
        
        if messageSender == self.senderUser.uid
        {
            if action == NSSelectorFromString("delete:") {
                return true
            }
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
        if action == NSSelectorFromString("delete:") {
            let message = messages[indexPath.section]
            let messageID = message.messageID
            //Let's see if this is an image
            if message.type == .image {
                API.Messages.deleteImage(forReference: message.photoURL!)
            }
            
            //Let's see if this is the only message
            if indexPath.section == 0
            {
                //Remove from datasource
                API.Messages.deleteMessage(forConversationID: self.conversationID!, forMessageID: messageID, lastMessage: nil, senderUser: nil, receiverUser: nil)
                messages.remove(at: indexPath.section)
                API.Messages.deleteConversation(forConversationID: self.conversationID!)
                API.Messages.deleteConversationForUser(forUserID: self.senderUser.uid, forConversationID:  self.conversationID!)
                API.Messages.deleteConversationForUser(forUserID: self.receiverUser.uid, forConversationID:  self.conversationID!)
                self.navigationController?.popViewController(animated: true)
            }
            else if indexPath.section == messages.count-1 {
                //Set another message as most recent
                let lastMessage = messages[indexPath.section - 1]
                API.Messages.deleteMessage(forConversationID: self.conversationID!, forMessageID: messageID, lastMessage: lastMessage, senderUser: self.senderUser, receiverUser: self.receiverUser)
                messages.remove(at: indexPath.section)
            }
            else {
                API.Messages.deleteMessage(forConversationID: self.conversationID!, forMessageID: messageID, lastMessage: nil, senderUser: nil, receiverUser: nil)
                messages.remove(at: indexPath.section)
            }
            
            //Delete sections
            collectionView.deleteSections([indexPath.section])
        } else {
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
}

extension ViewConversationViewController: MessagesDataSource {
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func currentSender() -> SenderType {
        return Sender(id: senderUser.uid, displayName: senderUser.username)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let justDate = formatter.string(from: message.sentDate)
        
        if !self.dateStamp.contains(justDate) || indexPath.section == 0 || indexForDate.contains(indexPath.section) {
            self.dateStamp.append(justDate)
            self.indexForDate.append(indexPath.section)
            let attrs1 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor : UIColor.lightGray]
            
            let attrs2 = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor : UIColor.lightGray]
            let attributedString1 = NSMutableAttributedString(string:"―――――――    ", attributes:attrs1)
            attributedString1.addAttribute(NSAttributedString.Key.kern, value: -2.5, range: NSMakeRange(0, attributedString1.length))
            
            let attributedString2 = NSMutableAttributedString(string:"    ―――――――", attributes:attrs2)
            attributedString2.addAttribute(NSAttributedString.Key.kern, value: -2.5, range: NSMakeRange(0, attributedString1.length))
            
            let dateString = NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
            attributedString1.append(dateString)
            attributedString1.append(attributedString2)
            return attributedString1
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = timeFormatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
}

extension ViewConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc private func cameraButtonPressed() {
        let picker = UIImagePickerController()
        picker.delegate = self
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = .photoLibrary
        }
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        let image = info[.originalImage] as? UIImage
        sendPhoto(image!)
        self.messagesCollectionView.setContentOffset(CGPoint(x: 0, y: self.messagesCollectionView.contentOffset.y + self.messageInputBar.frame.height), animated: true)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}

extension ViewConversationViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section == 0
        {
            return 20
        }
        else if indexForDate.contains(indexPath.section) {
            return 20
        }
        else {
            return 0
        }
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section != 0 {
            
            if lastMessage == nil {
                return 0
            }
            
            if lastMessage.sender.senderId == message.sender.senderId {
                lastMessage = message
                return 0
            }
            else {
                lastMessage = message
            }
        }
        else {
            lastMessage = message
        }
        return 20
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 0
    }
}

extension ViewConversationViewController: MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let message = messages[indexPath.section]
        // Check if it's the receiver
        if message.senderUID == self.receiverUser.uid {
            avatarView.sd_setImage(with: URL(string: receiverUser.profileImageURL!), completed: nil)
        }
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let message = messages[indexPath.section]
        if message.type == .image
        {
            
            var placeholder = "img_placeholder_grey"
            if message.senderUID == self.receiverUser.uid {
                placeholder = "img_placeholder_grey"
            }
            
            let configurationClosure = { (containerView: UIImageView) in
                
                for view in containerView.subviews{
                    view.removeFromSuperview()
                }
                
                let activityIndicator = UIActivityIndicatorView()
                activityIndicator.hidesWhenStopped = true
                activityIndicator.style = UIActivityIndicatorView.Style.white
                activityIndicator.color = .white
                containerView.addSubview(activityIndicator)
                activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                let xCenterConstraint = NSLayoutConstraint(item: containerView, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
                let yCenterConstraint = NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
                containerView.addConstraints([xCenterConstraint, yCenterConstraint])
                
                let imageMask = UIImageView()
                imageMask.image = MessageStyle.bubble.image
                imageMask.frame = containerView.bounds
                containerView.mask = imageMask
                containerView.contentMode = .scaleAspectFill
                var kf = containerView.kf
                kf.indicatorType = .activity
                
                if let message = message as? StripwayMessage {
                    if message.photoURL != nil {
                        let url = URL(string: message.photoURL!)
                        //imageView.kf.indicatorType = .activity
                        containerView.alpha = 1.0
                        activityIndicator.stopAnimating()
                        containerView.kf.setImage(
                            with: url, placeholder: UIImage(named:placeholder),
                            options: [
                                .scaleFactor(UIScreen.main.scale),
                                .transition(.fade(1)),
                                .cacheOriginalImage
                            ])
                        {
                            result in
                            switch result {
                            case .success(let value):
                                print("Task done for: \(value.source.url?.absoluteString ?? "")")
                            //self.messagesCollectionView.scrollToBottom(animated: true)
                            case .failure(let error):
                                print("Job failed: \(error.localizedDescription)")
                            }
                        }
                    }
                    else {
                        containerView.image = message.photoImage
                        containerView.alpha = 0.6
                        activityIndicator.startAnimating()
                    }
                }
            }
            return .custom(configurationClosure)
        }
        if message.type == .post {
            var placeholder = "img_placeholder_grey"
            if message.senderUID == self.receiverUser.uid {
                placeholder = "img_placeholder_grey"
            }

            let postClosure = { (containerView: UIImageView) in
                let author = message.authorUID
                let postID = message.postID
                var postUser:StripwayUser? = nil
                var sharedPost:StripwayPost? = nil

                containerView.backgroundColor = UIColor.groupTableViewBackground

                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                containerView.addSubview(imageView)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                let ImageWidthConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: containerView, attribute: .width, multiplier: 1, constant: 0)
                var ImageHeightConstraint: NSLayoutConstraint
                let xImageConstraint = NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0)
                let yImageConstraint = NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0)

                let goIcon = UIImageView()
                goIcon.image = #imageLiteral(resourceName: "black_arrow")
                containerView.addSubview(goIcon)
                
                goIcon.translatesAutoresizingMaskIntoConstraints = false
                //go Icon Constraints
                let iconWidthConstraint = NSLayoutConstraint(item: goIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
                let iconHeightConstraint = NSLayoutConstraint(item: goIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
                let xIconConstraint = NSLayoutConstraint(item: goIcon, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -10)
                var yIconConstraint:NSLayoutConstraint
                
                if message.postCaption == "" || message.postCaption == nil {
                    yIconConstraint = NSLayoutConstraint(item: goIcon, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 15)
                    ImageHeightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: containerView, attribute: .height, multiplier: 1, constant: -50)
                }
                else {
                    yIconConstraint = NSLayoutConstraint(item: goIcon, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 25)
                    ImageHeightConstraint = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: containerView, attribute: .height, multiplier: 1, constant: -70)
                }
                //add constraints for post image view
                containerView.addConstraints([xImageConstraint, yImageConstraint, ImageWidthConstraint, ImageHeightConstraint])
                
                //add constraints for go icon
                containerView.addConstraints([xIconConstraint, yIconConstraint, iconWidthConstraint, iconHeightConstraint])

                let avatarView = AvatarView()
                avatarView.isUserInteractionEnabled = true
                avatarView.initials = "S"
                containerView.addSubview(avatarView)

                avatarView.translatesAutoresizingMaskIntoConstraints = false
                let widthConstraint = NSLayoutConstraint(item: avatarView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
                let heightConstraint = NSLayoutConstraint(item: avatarView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
                let xConstraint = NSLayoutConstraint(item: avatarView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 10)
                let yConstraint = NSLayoutConstraint(item: avatarView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 10)
                containerView.addConstraints([xConstraint, yConstraint, widthConstraint, heightConstraint])
                
                avatarView.isUserInteractionEnabled = true
                let avatarTapGesture = AvatarTapGesture(target: self, action: #selector(self.avatarTapped))
                if message.authorUID != nil {
                    avatarTapGesture.userId = message.authorUID!
                }
                avatarView.isMultipleTouchEnabled = false
                avatarView.addGestureRecognizer(avatarTapGesture)

                let nameLabel = UILabel()
                nameLabel.font = UIFont(name: "AvenirNext-Bold", size: 17)
                nameLabel.textColor = UIColor.black
                containerView.addSubview(nameLabel)
                nameLabel.translatesAutoresizingMaskIntoConstraints = false
                let nameWidthConstraint = NSLayoutConstraint(item: nameLabel, attribute: .width, relatedBy: .equal, toItem: containerView, attribute: .width, multiplier: 1, constant: -80)
                
                let nameHeightConstraint = NSLayoutConstraint(item: nameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 40)
                let xNameConstraint = NSLayoutConstraint(item: nameLabel, attribute: .leading, relatedBy: .equal, toItem: avatarView, attribute: .trailing, multiplier: 1, constant: 10)
                let yNameConstraint = NSLayoutConstraint(item: nameLabel, attribute: .centerY, relatedBy: .equal, toItem: avatarView, attribute: .centerY, multiplier: 1, constant: 0)
                containerView.addConstraints([xNameConstraint, yNameConstraint, nameWidthConstraint, nameHeightConstraint])
                
                nameLabel.isUserInteractionEnabled = true
                let usernameTapGesture = AvatarTapGesture(target: self, action: #selector(self.avatarTapped))
                if message.authorUID != nil {
                    usernameTapGesture.userId = message.authorUID!
                }
                nameLabel.isMultipleTouchEnabled = false
                nameLabel.addGestureRecognizer(usernameTapGesture)

                let captionLabel = UILabel()
                captionLabel.textColor = UIColor.black
                containerView.addSubview(captionLabel)

                captionLabel.translatesAutoresizingMaskIntoConstraints = false
                let captionWidthConstraint = NSLayoutConstraint(item: captionLabel, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -30)
                let captionHeightConstraint = NSLayoutConstraint(item: captionLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
                let xCaptionConstraint = NSLayoutConstraint(item: captionLabel, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 10)
                let yCaptionConstraint = NSLayoutConstraint(item: captionLabel, attribute: .top, relatedBy: .equal, toItem: avatarView, attribute: .bottom, multiplier: 1, constant: 0)
                containerView.addConstraints([xCaptionConstraint, yCaptionConstraint, captionWidthConstraint, captionHeightConstraint])
                nameLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 12)

                let currentHeight = containerView.frame.height
                let currentWidth = containerView.frame.width
                let currentX = containerView.frame.origin.x
                let currentY = containerView.frame.origin.y
                containerView.frame = CGRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
                let imageMask = UIImageView()
                imageMask.image = MessageStyle.bubble.image
                imageMask.frame = containerView.bounds
                containerView.mask = imageMask
                containerView.contentMode = .scaleAspectFill
                var kf = containerView.kf
                kf.indicatorType = .activity

                if let message = message as? StripwayMessage {
                    if message.photoURL != nil {
                        let url = URL(string: message.photoURL!)
                        //imageView.kf.indicatorType = .activity
                        imageView.alpha = 1.0
                        //activityIndicator.stopAnimating()
                        imageView.kf.setImage(
                            with: url, placeholder: UIImage(named:placeholder),
                            options: [
                                .scaleFactor(UIScreen.main.scale),
                                .transition(.fade(1)),
                                .cacheOriginalImage
                            ])
                        {
                            result in
                            switch result {
                            case .success(let value):
                                print("Task done for: \(value.source.url?.absoluteString ?? "")")
                            //self.messagesCollectionView.scrollToBottom(animated: true)
                            case .failure(let error):
                                print("Job failed: \(error.localizedDescription)")
                            }
                        }
                    }

                    API.Post.observePost(withID: postID!) { (post, error) in

                        if let error = error {
                            print("Something went wrong here, should display an error")
                        }
                        else if let post = post {
                            sharedPost = post
                            self.posts.updateValue(post, forKey: indexPath)
                            let attrs2 = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-DemiBold", size: 14)]
                            let normalString = NSMutableAttributedString(string: post.caption, attributes: attrs2 as [NSAttributedString.Key : Any])
                            captionLabel.attributedText = normalString
                        }
                    }
                    API.User.observeUser(withUID: author!) { (user, error) in
                        if let error = error {
                            print("Something went wrong here, should display an error")
                        } else if let user = user {
                            postUser = user
                            let authorProfileImage = URL(string: (postUser?.profileImageURL)!)

                            let attrs = [NSAttributedString.Key.font: UIFont(name: "AvenirNext-Bold", size: 15)]
                            let attributedString = NSMutableAttributedString(string: user.username, attributes: attrs as [NSAttributedString.Key : Any])
                            nameLabel.attributedText = attributedString
                            var kf = avatarView.kf
                            kf.indicatorType = .activity
                            avatarView.kf.setImage(with: authorProfileImage)
                        }
                    }
                }
            }
            return .custom(postClosure)

        }
        if message.senderUID == self.receiverUser.uid {
            return self.currentUserMessageStyle ?? .bubbleOutline(UIColor.black)
        } else {
            return self.otherUserMessageStyle ?? .bubble
        }
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return UIColor.black
        }
        return UIColor.white
    }
}

extension ViewConversationViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Tapped message")
        if let indexPath = messagesCollectionView.indexPath(for: cell) {
            let message = messages[indexPath.section]
           
            if message.type == .image {
                var imageURLs = [URL]()
                for ms in messages {
                    if ms.type == .image{
                        imageURLs.append(URL(string: ms.photoURL!)!)
                    }
                }
                var index = 0
                for (i, url) in imageURLs.enumerated() {
                    if url.absoluteString == message.photoURL! {
                        index = i
                    }
                }
                self.showImage(index: index, imageURLs: imageURLs)
            }
            if message.type == .post {
                tappedPost = posts[indexPath]
                
                //Check if post exits
                API.Strip.observeStrip(withID: tappedPost!.stripID) { (strip) in
                    self.tappedStrip = strip
                    self.performSegue(withIdentifier: "ShowPost", sender: self)
                }
                
            }
        }
    }
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("tapped avator")
    }

    
}
extension ViewConversationViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        API.Messages.createMessage(forConversationID: self.conversationID!, withText: text, senderUser: users[senderUser.uid]!, receiverUser: users[receiverUser.uid]!) {
            print("I guess message was created?")
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
        
        inputBar.inputTextView.text = ""
    }
    
    
    func sendPhoto(_ image: UIImage) {
        isSendingPhoto = true
        
        let newMessageID = API.Messages.conversationsReference.child(self.conversationID!).child("messages").childByAutoId().key!
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let sendingPhotoMsg = StripwayMessage(messageID: newMessageID, image: image, timestamp: timestamp, senderUser: self.users[self.senderUser.uid]!, receiverUID: self.receiverUser.uid)
        
        if !self.messages.contains(where: { $0.messageID == sendingPhotoMsg.messageID }) {
            self.messages.append(sendingPhotoMsg)
            self.newestTimestamp = sendingPhotoMsg.timestamp
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom(animated: true)
        }
        
        API.Messages.uploadImage(image, forConversationID: self.conversationID!) { [weak self] url in
            guard let `self` = self else {
                return
            }
            self.isSendingPhoto = false
            
            guard let url = url else {
                return
            }
            
            KingfisherManager.shared.cache.store(image, forKey: url.absoluteString)
            
            sendingPhotoMsg.photoURL = url.absoluteString
            
            self.messages.first(where: { $0.messageID == sendingPhotoMsg.messageID })?.photoURL = url.absoluteString
            self.messagesCollectionView.reloadData()
            self.messagesCollectionView.scrollToBottom(animated: true)
            
            
            API.Messages.createMediaMessage(forConversationID: self.conversationID!, newMessage: sendingPhotoMsg) {
            }
            self.messagesCollectionView.scrollToBottom()
        }
    }
}

extension MessageCollectionViewCell {
    
    override open func delete(_ sender: Any?) {
        
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("delete:"), forItemAt: indexPath, withSender: sender)
                
                
            }
        }
    }
}

extension UIView {
    
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
}

class AvatarTapGesture: UITapGestureRecognizer {
    var userId = String()
}
