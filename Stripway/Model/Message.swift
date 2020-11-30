//
//  Message.swift
//  Stripway
//
//  Created by Drew Dennistoun on 10/21/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

// All this stuff exists because I had to make StripwayMessage an extension of MessageType so it would work with MessageKit
//
import Foundation
import UIKit
import MessageKit

struct Member {
    let name: String
    let color: UIColor
}

struct Message {
    let member: Member
    let text: String
    let messageId: String
}

extension Message: MessageType {
    var sender: SenderType {
        return Sender(id: member.name, displayName: member.name)
    }
    
    var sentDate: Date {
        return Date()
    }
    
    var kind: MessageKind {
        return .text(text)
    }
}
