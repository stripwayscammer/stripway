//
//  ViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 8/31/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD

class LogInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameEmailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var launchScreenView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        usernameEmailField.delegate = self
        passwordField.delegate = self
        
        
        
        setupUI()
        handleTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            if Auth.auth().currentUser != nil {
                self.performSegue(withIdentifier: "SuccessfulLogInSegue", sender: self)
            } else {
                self.launchScreenView.isHidden = true
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow() {
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 75
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    func handleTextField() {
        usernameEmailField.addTarget(self, action: #selector(LogInViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        passwordField.addTarget(self, action: #selector(LogInViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        textFieldDidChange()
    }
    
    @IBAction func logInButtonPressed(_ sender: Any) {
        usernameEmailField.trimWhitespace()
        guard let usernameEmailText = usernameEmailField.text, let passwordText = passwordField.text else { return }
        
        // If the usernameField doesn't have an @ in it, it's a username
        if !usernameEmailText.contains("@") {
            getEmailFromUsername(username: usernameEmailText) { (email) in
                if let email = email {
                    self.signIn(email: email, password: passwordText)
                } else {
                    let alert = UIAlertController(title: "Username Not Found", message: "This username doesn't seem to exist. Try logging in with the email address associated with the account.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        // Else it's an email
        } else {
            signIn(email: usernameEmailText, password: passwordText)
        }
    }
    
    func signIn(email: String, password: String) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            if let error = error {
                print(error.localizedDescription)
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            guard let user = user else { return }
            print(user.user.email ?? "")
            self.performSegue(withIdentifier: "SuccessfulLogInSegue", sender: self)
        }
    }
    
    func getEmailFromUsername(username: String, completion: @escaping(String?)->()) {
        API.User.usernamesReference.child(username).child("email").observeSingleEvent(of: .value) { (snapshot) in
            // If this username exists and has an email property
            if snapshot.exists() {
                // And the value of that property is a string
                if let emailAddress = snapshot.value as? String {
                    // Return it in the completion handler
                    completion(emailAddress)
                    return
                }
            }
            // Else just return nil
            completion(nil)
        }
    }
    
    @IBAction func unwindToLogin(segue: UIStoryboardSegue) {
        print("Unwinding from \(segue.source)")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func textFieldDidChange() {
        guard let username = usernameEmailField.text, !username.isEmpty, let password = passwordField.text, !password.isEmpty else {
            logInButton.isEnabled = false
            logInButton.alpha = 0.5
            return
        }
        logInButton.isEnabled = true
        logInButton.alpha = 1.0
    }

    
    func setupUI() {
        
        usernameEmailField.layer.borderWidth = 1.0
        passwordField.layer.borderWidth = 1.0
        usernameEmailField.layer.cornerRadius = 22.0
        passwordField.layer.cornerRadius = 22.0
        let borderColor = UIColor.init(red: 63.0/255.0, green: 63.0/255.0, blue: 63.0/255.0, alpha: 1).cgColor
        usernameEmailField.layer.borderColor = borderColor
        passwordField.layer.borderColor = borderColor
        usernameEmailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: usernameEmailField.frame.height))
        usernameEmailField.leftViewMode = .always
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: passwordField.frame.height))
        passwordField.leftViewMode = .always
        logInButton.layer.cornerRadius = 22.0
        signUpButton.layer.cornerRadius = 22.0
        
        usernameEmailField.attributedPlaceholder = NSAttributedString(string: "Email or Username",
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Password",
                                                                 attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            logInButtonPressed(UIButton())
        }
        return true
    }


}
















