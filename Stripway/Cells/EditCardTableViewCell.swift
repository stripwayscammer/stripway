//
//  EditCardTableViewCell.swift
//  Stripway
//
//  Created by iBinh on 10/12/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit

class EditCardTableViewCell: UITableViewCell {

    
    @IBOutlet weak var txtYoutube: UITextField!
    @IBOutlet weak var txtInsta: UITextField!
    @IBOutlet weak var txtTwitter: UITextField!
    @IBOutlet weak var showCardSwitch: UISwitch!
    @IBOutlet weak var txtCategory: UITextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    func bind(card: UserCard?, showCard: Bool) {
        showCardSwitch.isOn = showCard

        guard let card = card else {return}
        txtCategory.text = card.category
        txtTwitter.text = card.twitter
        txtInsta.text = card.instagram
        txtYoutube.text = card.youtube
    }
    
}

