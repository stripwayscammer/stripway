//
//  CustomMessagesFlowLayout.swift
//  Stripway
//
//  Created by Hassaan Raza on 2/14/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit
import MessageKit

class CustomMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    
    open lazy var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)
    
    open override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        //        if isSectionReservedForTypingBubble(indexPath.section) {
        //            return typingMessageSizeCalculator
        //        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! StripwayMessage
        if message.type == StripwayMessageType.post {
            return customMessageSizeCalculator
            //return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    open override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var superCalculators = super.messageSizeCalculators()
        // Append any of your custom `MessageSizeCalculator` if you wish for the convenience
        // functions to work such as `setMessageIncoming...` or `setMessageOutgoing...`
        superCalculators.append(customMessageSizeCalculator)
        return superCalculators
    }

}
