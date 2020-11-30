//
//  SetPasswordViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 8/31/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Firebase
import SafariServices

class SetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var agreementTextView: UITextView!
    
    var newUser = (username: "default", name: "default", email: "default", password: "default")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()
        print("Here's what the user looks like: \(newUser)")
        print("Also here's all their info:\nUsername: \(newUser.username)\nName: \(newUser.name)\nEmail: \(newUser.email)\nPassword: \(newUser.password)")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        passwordField.delegate = self
        confirmPasswordField.delegate = self
        
        setupTextView()
        
        handleTextField()
    }
    
    func setupTextView() {
        let attributedString = NSMutableAttributedString(string: "By signing up, you agree to the Terms of Use and Privacy Policy.")
        let tosURL = URL(string: "https://www.stripway.app/terms-of-use")
        let ppURL = URL(string: "https://www.stripway.app/privacy-policy")
        print("This is the attributed text of aggrementTextView: \(attributedString) and length = \(attributedString.length)")
        attributedString.setAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 15)], range: NSMakeRange(0, attributedString.length))
        attributedString.setAttributes([.link: tosURL!], range: NSMakeRange(32, 12))
        attributedString.setAttributes([.link: ppURL!], range: NSMakeRange(49, 15))
        self.agreementTextView.attributedText = attributedString
        self.agreementTextView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red:36/255, green:141/255, blue:225/255, alpha:1.0), .font: UIFont.systemFont(ofSize: 15)]
    }
    
    func handleTextField() {
        passwordField.addTarget(self, action: #selector(SetPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        confirmPasswordField.addTarget(self, action: #selector(SetPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        textFieldDidChange()
    }
    
    @objc func textFieldDidChange() {
        guard let password = passwordField.text, !password.isEmpty, let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            signUpButton.isEnabled = false
            signUpButton.alpha = 0.5
            return
        }
        signUpButton.isEnabled = true
        signUpButton.alpha = 1.0
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        
        if passwordField.text != confirmPasswordField.text {
            print("Passwords don't match")
            let alert = UIAlertController(title: "Error", message: "Your password and confirmation don't match. Please make sure you've entered the same password twice.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.passwordField.text = ""
                self.confirmPasswordField.text = ""
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if passwordIsFormattedCorrectly(password: passwordField.text!) {
            newUser.password = passwordField.text!
            Auth.auth().createUser(withEmail: newUser.email, password: newUser.password) { (user, error) in
                if let error = error {
                    print("Something went wrong: \(error.localizedDescription)")
                    let alert = UIAlertController(title: "Error!", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                guard let user = user else { return }
                print(user)
                self.setUserInformation(username: self.newUser.username, name: self.newUser.name, email: self.newUser.email, uid: user.user.uid)
                self.performSegue(withIdentifier: "SuccessfulSignUpSegue", sender: self)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Password is incorrectly formatted. It must have at least one capital letter, one lowercase letter, one number, and at least six characters.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.passwordField.text = ""
                self.confirmPasswordField.text = ""
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func passwordIsFormattedCorrectly(password: String) -> Bool {
        // At least one capital, at least one number, at least one lowercase, at least 6 characters
        let passwordRegex =  "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{6,}$"
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
    
    func setUserInformation(username: String, name: String, email: String, uid: String) {
        let ref = Database.database().reference()
        
        // adds user information to the database
        let usersReference = ref.child("users")
        let newUserReference = usersReference.child(uid)
        newUserReference.setValue(["username": username, "name": name, "email": email])
        
        // makes it possible to immediately get a users email from their username, for username login
        let usernamesReference = ref.child("usernames")
        let newUsernameReference = usernamesReference.child(username)
        // should double check that this works
        print("DOUBLE CHECK THIS FOR NEW USERS")
        newUsernameReference.child("email").setValue(email)
        newUsernameReference.child("uid").setValue(uid)
        newUserReference.child("profileImageURL").setValue("https://firebasestorage.googleapis.com/v0/b/stripeway-2.appspot.com/o/profile_image%2FDefault.png?alt=media&token=ff28636a-f4c1-47b7-affc-1fde4b9c6df9")
        
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func setupUI() {
        passwordField.layer.borderWidth = 1.0
        confirmPasswordField.layer.borderWidth = 1.0
        passwordField.layer.cornerRadius = 22.0
        confirmPasswordField.layer.cornerRadius = 22.0
        let borderColor = UIColor.init(red: 63.0/255.0, green: 63.0/255, blue: 63.0/255.0, alpha: 1.0).cgColor
        passwordField.layer.borderColor = borderColor
        confirmPasswordField.layer.borderColor = borderColor
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: passwordField.frame.height))
        passwordField.leftViewMode = .always
        confirmPasswordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: confirmPasswordField.frame.height))
        confirmPasswordField.leftViewMode = .always
        signUpButton.layer.cornerRadius = 22.0
        
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        confirmPasswordField.attributedPlaceholder = NSAttributedString(string: "Confrim Password",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "UnwindToSignup", sender: self)
    }
    
    @objc func keyboardWillShow() {
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 50
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            confirmPasswordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
}

extension SetPasswordViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let safariViewController = SFSafariViewController(url: URL)
        self.present(safariViewController, animated: true)
        return false
    }
    
}
