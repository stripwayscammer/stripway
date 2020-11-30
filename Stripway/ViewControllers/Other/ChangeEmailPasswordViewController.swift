//
//  ChangeEmailPasswordViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/29/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Firebase

class ChangeEmailPasswordViewController: UIViewController {

    
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var confirmLabel: UILabel!
    
    @IBOutlet weak var currentField: UITextField!
    @IBOutlet weak var newField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    
    @IBOutlet weak var currentPasswordLabel: UILabel!
    @IBOutlet weak var currentPasswordField: UITextField!
    
    @IBOutlet weak var newLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var saveButton: UIButton!
    
    var currentUser = Auth.auth().currentUser!
    var currentEmail = Auth.auth().currentUser!.email!
    var currentStripwayUser: StripwayUser!
    
    
    var changeString = "Email"
    // If this is false then we're changing the password
    var changingEmail = true
    
    var currentText = ""
    var newText = ""
    var confirmText = ""
    var currentPasswordText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        handleTextFields()
    }
    
    func setupUI() {
        if changingEmail {
            changeString = "Email"
            newLabelTopConstraint.isActive = false
            newLabelTopConstraint = newLabel.topAnchor.constraint(equalTo: currentPasswordField.bottomAnchor, constant: 16)
            newLabelTopConstraint.isActive = true
        } else {
            changeString = "Password"
            newLabelTopConstraint.isActive = false
            newLabelTopConstraint = newLabel.topAnchor.constraint(equalTo: currentField.bottomAnchor, constant: 16)
            newLabelTopConstraint.isActive = true
        }
        
        currentPasswordLabel.isHidden = !changingEmail
        currentPasswordField.isHidden = !changingEmail
        
        self.title = "Update " + changeString
        currentLabel.text = "Current " + changeString
        newLabel.text = "New " + changeString
        confirmLabel.text = "Confirm New " + changeString
    }
    
    func handleTextFields() {
        currentField.addTarget(self, action: #selector(ChangeEmailPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        newField.addTarget(self, action: #selector(ChangeEmailPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        confirmField.addTarget(self, action: #selector(ChangeEmailPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        currentPasswordField.addTarget(self, action: #selector(ChangeEmailPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
    }
    
    @objc func textFieldDidChange() {
        guard let current = currentField.text, !current.isEmpty, let new = newField.text, !new.isEmpty, let confirm = confirmField.text, !confirm.isEmpty else {
            saveButton.isEnabled = false
            return
        }
        if changingEmail {
            guard let currentPassword = currentPasswordField.text, !currentPassword.isEmpty else { return }
            currentPasswordText = currentPassword
        }
        saveButton.isEnabled = true
        currentText = current
        newText = new
        confirmText = confirm
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if newText != confirmText {
            let alert = UIAlertController(title: "Error", message: "The \"New \(changeString)\" and \"Confirm New \(changeString)\" fields don't match.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        if changingEmail {
            print("Changing email")
            verifyEmail()
        } else {
            print("Not changing email")
            verifyPassword()
        }
        
    }
    
    func verifyEmail() {
        if currentText != currentEmail {
            print("Wrong currentEmail")
            let alert = UIAlertController(title: "Error", message: "Your current email is incorrect.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else if currentText == newText {
            let alert = UIAlertController(title: "Error", message: "That's already your email address.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.currentPasswordField.text = ""
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentPasswordText)
            currentUser.reauthenticateAndRetrieveData(with: credential) { (result, error) in
                if let error = error {
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Error", message: "Your current password is incorrect. Please enter it correctly.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                        self.currentPasswordField.text = ""
                    }))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    self.changeEmail()
                }
            }
        }
    }
    
    func verifyPassword() {
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: currentText)
        currentUser.reauthenticateAndRetrieveData(with: credential) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                let alert = UIAlertController(title: "Error", message: "Your current password is incorrect. Please enter it correctly.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self.currentField.text = ""
                }))
                self.present(alert, animated: true, completion: nil)
                return
            } else if self.passwordIsFormattedCorrectly(password: self.currentText) {
                self.changePassword()
            } else {
                let alert = UIAlertController(title: "Error", message: "Password is incorrectly formatted. It must have at least one capital letter, one lowercase letter, one number, and at least six characters.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    // Empty textFields here
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func passwordIsFormattedCorrectly(password: String) -> Bool {
        // At least one capital, at least one number, at least one lowercase, at least 6 characters
        let passwordRegex =  "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    func changeEmail() {
        let newEmail = newText
        currentUser.updateEmail(to: newEmail) { (error) in
            if let error = error {
                print(error.localizedDescription)
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            let alert = UIAlertController(title: "Success", message: "Email successfully updated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            // Going to have to update email in /usernames/ and /users/ on the database
            // Will need the username for /usernames/
            let ref = Database.database().reference()
            print("IDK what's nil so here's \ncurrentUser.uid: \(self.currentUser.uid)\ncurrentStripwayUser.username: \(self.currentStripwayUser.username)")
            let updatedUserData = ["users/\(self.currentUser.uid)/email": newEmail, "usernames/\(self.currentStripwayUser.username)/email": newEmail]
            ref.updateChildValues(updatedUserData, withCompletionBlock: { (error, ref) in
                if let error = error {
                    print("Error updating user's email: \(error.localizedDescription)")
                    return
                }
                print("User's email should have updated correctly.")
            })
        }
    }
    
    func changePassword() {
        let newPassword = newText
        currentUser.updatePassword(to: newPassword) { (error) in
            if let error = error {
                print(error.localizedDescription)
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            let alert = UIAlertController(title: "Success", message: "Password successfully updated.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
