//
//  SharePostCell.swift
//  Stripway
//
//  Created by Hassaan Raza on 2/14/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit
import MessageKit

class SharePostCell: MessageContentCell {
    
    open class func reuseIdentifier() -> String { return "messagekit.cell.sharepost" }
    
    open var imageView: UIImageView = {
        return UIImageView()
    }()
    
    open var goIcon: UIImageView = {
        return UIImageView()
    }()
    
    open var userAvatar: AvatarView = {
        return AvatarView()
    }()
    
    open var nameLabel: UILabel = {
        return UILabel()
    }()
    
    open var captionLabel: UILabel = {
        return UILabel()
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupFrame()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
        setupFrame()
    }
    
    open override func setupSubviews() {
        
        super.setupSubviews()
        self.messageContainerView.isUserInteractionEnabled = true
        self.isUserInteractionEnabled = true
        // We need to enable user interaction on the MessageContainerView, since it is a UIImageView subclass, which has user interaction disabled per default
        
    }

    open func configure(with message: StripwayMessage, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError()
        }
    }
    
    func setupFrame()
    {
//        let currentHeight = self.messageContainerView.frame.height + 70
//        let currentWidth = self.messageContainerView.frame.width
//        let currentX = self.messageContainerView.frame.origin.x
//        let currentY = self.messageContainerView.frame.origin.y
//        self.messageContainerView.frame = CGRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
        let imageMask = UIImageView()
        imageMask.image = MessageStyle.bubble.image
        imageMask.frame = self.messageContainerView.bounds
        self.messageContainerView.mask = imageMask
        self.messageContainerView.contentMode = .scaleAspectFill
        self.messageContainerView.backgroundColor = UIColor.groupTableViewBackground
    }
    
    @objc func avatarTapped() {
        self.delegate?.didTapAvatar(in: self)
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension UIView {
    func clearConstraints() {
        for subview in self.subviews {
            subview.clearConstraints()
        }
        self.removeConstraints(self.constraints)
    }
}


