//
//  SignUpViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 8/31/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit
import Firebase
import MBProgressHUD
class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupUI()
        
        usernameField.delegate = self
        nameField.delegate = self
        emailField.delegate = self
                
        handleTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func handleTextField() {
        usernameField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
//        usernameField.addTarget(self, action: #selector(SignUpViewController.checkUsernameUniqueness), for: UIControl.Event.editingDidEnd)
        nameField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        emailField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        textFieldDidChange()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func textFieldDidChange() {
        guard let username = usernameField.getTrimmedText(), !username.isEmpty, let name = nameField.getTrimmedText(), !name.isEmpty, let email = emailField.getTrimmedText(), !email.isEmpty else {
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
            return
        }
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        print("trimmed textField = |\(textField.getTrimmedText() ?? "")|")
        textField.trimWhitespace()
    }
    
    func setupUI() {
        usernameField.layer.borderWidth = 1.0
        nameField.layer.borderWidth = 1.0
        emailField.layer.borderWidth = 1.0
        usernameField.layer.cornerRadius = 22.0
        nameField.layer.cornerRadius = 22.0
        emailField.layer.cornerRadius = 22.0
        let textBorderColor = UIColor.init(red: 63.0/255.0, green: 63.0/255.0, blue: 63.0/255.0, alpha: 1).cgColor
        usernameField.layer.borderColor = textBorderColor
        nameField.layer.borderColor = textBorderColor
        emailField.layer.borderColor = textBorderColor
        usernameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height:    usernameField.frame.height))
        usernameField.leftViewMode = .always
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: nameField.frame.height))
        nameField.leftViewMode = .always
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: nameField.frame.height))
        emailField.leftViewMode = .always
        nextButton.layer.cornerRadius = 22.0
        
        usernameField.attributedPlaceholder = NSAttributedString(string: "Username",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        nameField.attributedPlaceholder = NSAttributedString(string: "Name",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        emailField.attributedPlaceholder = NSAttributedString(string: "Email",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow() {
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 150
        }
    }
    
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        usernameField.trimWhitespace()
        nameField.trimWhitespace()
        emailField.trimWhitespace()
        
        let alert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
        
        if !usernameIsFormattedCorrectly(username: usernameField.text) {
            print("Username incorrectly formatted")
            alert.message = "Username is incorrectly formatted. It can only contain numbers, lowercase letters, and underscores. It also must contain between 3 and 24 characters."
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.usernameField.text = ""
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        if !emailIsFormattedCorrectly(email: emailField.text) {
            print("Email incorrectly formatted")
            alert.message = "Email is incorrectly formatted. Please enter a valid email address."
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.emailField.text = ""
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        checkUsernameUniqueness(username: usernameField.text) { (isUnique) in
            if isUnique {
                print("Username is unique")
                self.performSegue(withIdentifier: "SetPasswordSegue", sender: self)
            } else {
                print("Username is not unique")
                alert.message = "Username has already been used. Please try another username."
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    self.usernameField.text = ""
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func usernameIsFormattedCorrectly(username: String?) -> Bool {
        guard let username = username else { return false }
        return username.range(of: "[^a-z0-9_]", options: .regularExpression) == nil && (username.count > 2 && username.count < 24)
    }
    
    func emailIsFormattedCorrectly(email: String?) -> Bool {
        // This is ugly but I copied it off stackoverflow
        guard let email = email else { return false }
        let __firstpart = "[A-Z0-9a-z]([A-Z0-9a-z._%+-]{0,30}[A-Z0-9a-z])?"
        let __serverpart = "([A-Z0-9a-z]([A-Z0-9a-z-]{0,30}[A-Z0-9a-z])?\\.){1,5}"
        let __emailRegex = __firstpart + "@" + __serverpart + "[A-Za-z]{2,8}"
        let __emailPredicate = NSPredicate(format: "SELF MATCHES %@", __emailRegex)
        return __emailPredicate.evaluate(with: email)
    }
    
    func checkUsernameUniqueness(username: String?, completion: @escaping(Bool)->()) {
        guard let username = username else {
            completion(false)
            return
        }
        API.User.usernamesReference.child(username).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print("THIS USERNAME ALREADY EXISTS")
                completion(false)
            } else {
                print("USERNAME IS AVAILABLE")
                completion(true)
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "UnwindToLoginFromSignup", sender: self)
    }
    
    @IBAction func unwindToSignup(segue: UIStoryboardSegue) {
        print("Unwinding from: \(segue.source)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("stuff")
        if let setPasswordViewController = segue.destination as? SetPasswordViewController {
            setPasswordViewController.newUser.email = emailField.text!
            setPasswordViewController.newUser.username = usernameField.text!
            setPasswordViewController.newUser.name = nameField.text!
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            nameField.becomeFirstResponder()
        } else if textField.tag == 1 {
            emailField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
