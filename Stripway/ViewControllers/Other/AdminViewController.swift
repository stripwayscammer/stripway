//
//  AdminViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 1/22/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit

class AdminViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SegueToReports" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.reports = true
            }
        }
    }

}
