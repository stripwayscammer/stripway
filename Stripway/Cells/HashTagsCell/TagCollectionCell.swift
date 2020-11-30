//
//  TagCollectionCell.swift
//  TestTagList
//
//  Created by TrungHD-D1 on 4/16/20.
//  Copyright © 2020 TrungHD-D1. All rights reserved.
//

import UIKit

class TagCollectionCell: UICollectionViewCell {

    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var tagNameMaxWidthConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //This fix bug ios 12, 12.2 using xib
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let leftConstraint = contentView.leftAnchor.constraint(equalTo: leftAnchor)
        let rightConstraint = contentView.rightAnchor.constraint(equalTo: rightAnchor)
        let topConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, topConstraint, bottomConstraint])


        self.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        self.lbTitle.textColor = .black
        self.layer.cornerRadius = 14.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.black.cgColor
        self.tagNameMaxWidthConstraint.constant = UIScreen.main.bounds.width - 8 * 2 - 16 * 2
    }
    
    func setSelected(){
        self.backgroundColor = .black
        self.lbTitle.textColor = .white
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    func setDeselected(){
        self.backgroundColor = .white
        self.lbTitle.textColor = .black
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    func updateView(tag: HashTag)  {
        self.lbTitle.text = "#\(tag.tagString)"
        if tag.selectedFlag {
            self.setSelected()
        }else{
            self.setDeselected()
        }
    }
    
    func updateView(selectedFlag: Bool)  {
        if selectedFlag {
            self.setSelected()
        }else{
            self.setDeselected()
        }
    }
}
