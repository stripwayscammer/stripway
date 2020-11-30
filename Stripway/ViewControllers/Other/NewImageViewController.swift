//
//  NewImageViewController.swift
//  Stripway
//
//  Created by Troy on 5/2/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit

protocol NewImageViewControllerDelegate: class {
    func gotoCaption()
    func gotoHashTag()
}

class NewImageViewController: UIViewController {

    weak var delegate: NewImageViewControllerDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    var image:UIImage = UIImage()
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
    }
    
    @IBAction func goCaptionView(_ sender: Any) {
        self.delegate?.gotoCaption()
    }
    
    @IBAction func goHashTagView(_ sender: Any) {
        self.delegate?.gotoHashTag()
    }   

}
