//
//  SettingsViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/27/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {

    var currentStripwayUser: StripwayUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.tintColor = UIColor.black
    }

    @IBAction func logOutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        
        let storyboard = UIStoryboard(name: "LoginSignup", bundle: nil)
        let logInVC = storyboard.instantiateViewController(withIdentifier: "LogInViewController")
        self.present(logInVC, animated: true, completion: nil)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UpdatePasswordSegue" {
            if let changeEmailPasswordViewController = segue.destination as? ChangeEmailPasswordViewController {
                changeEmailPasswordViewController.changingEmail = false
                changeEmailPasswordViewController.currentStripwayUser = self.currentStripwayUser
            }
        }
        if segue.identifier == "UpdateEmailSegue" {
            if let changeEmailPasswordViewController = segue.destination as? ChangeEmailPasswordViewController {
                changeEmailPasswordViewController.currentStripwayUser = self.currentStripwayUser
            }
        }
    }

}

