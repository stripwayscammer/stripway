//
//  ColorCaptionCell.swift
//  Stripway
//
//  Created by Shine Web Solutions on 23/04/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit

class ColorCaptionCell: UICollectionViewCell {
    @IBOutlet weak var colorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func modifyView() {
        colorView.layer.cornerRadius = 5
        colorView.layer.borderWidth = 0.8
        colorView.layer.borderColor = UIColor.lightGray.cgColor
    }
}
