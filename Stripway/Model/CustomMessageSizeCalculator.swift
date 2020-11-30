//
//  CustomMessageSizeCalculator.swift
//  Stripway
//
//  Created by Hassaan Raza on 2/14/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit
import MessageKit

class CustomMessageSizeCalculator: MessageSizeCalculator {
    
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init()
        self.layout = layout
    }
    
    open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let layout = layout else { return .zero }
        
        let dataSource = messagesLayout.messagesDataSource
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
        
        
        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let collectionViewHeight = layout.collectionView?.bounds.height ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        
        if let msg = message as? StripwayMessage {
            if msg.type == .post && msg.postCaption == "" {
                return CGSize(width: collectionViewWidth - inset, height: collectionViewWidth - 60.0)
            }
            else {
                return CGSize(width: collectionViewWidth - inset, height: collectionViewWidth)
            }
        }
        else {
            return CGSize(width: collectionViewWidth - inset, height: collectionViewWidth)
        }
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        let maxWidth = messageContainerMaxWidth(for: message)
        let customMessage = message as! StripwayMessage
        var height:CGFloat = 130.0
        switch customMessage.type {
        case .post:
            if customMessage.postCaption == "" || customMessage.postCaption == nil {
                height = 330
            }
            else {
                height = 350
            }
            
            break
        default: break
        }
        
        return CGSize(width: 250, height: height)
    }
}
