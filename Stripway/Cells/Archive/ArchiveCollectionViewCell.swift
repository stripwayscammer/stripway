//
//	ArchiveCollectionViewCell
//	Stripway
//
//	Created by: Nedim on 17/05/2020
//	Copyright © 2020 Stripway LLC. All rights reserved.
//

import Foundation
import UIKit

class ArchiveCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var lblTextPost: UILabel!
    
    @IBOutlet weak var mRestoreArchiveButton: UIButton!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
       
    }
    
}
