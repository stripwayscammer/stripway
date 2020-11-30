//
//  ResetPasswordViewController.swift
//  GoogleToolboxForMac
//
//  Created by Drew Dennistoun on 9/5/18.
//

import UIKit
import Firebase
import MBProgressHUD

class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    
    var currentUser: StripwayUser?
    var currentStripwayUser: StripwayUser!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        handleTextField()
        
        
    }
    
    func handleTextField() {
        emailField.addTarget(self, action: #selector(ResetPasswordViewController.textFieldDidChange), for: UIControl.Event.editingChanged)
        
        textFieldDidChange()
    }
    
    @objc func textFieldDidChange() {
        guard let email = emailField.text, !email.isEmpty else {
            resetButton.isEnabled = false
            resetButton.alpha = 0.5
            return
        }
        resetButton.isEnabled = true
        resetButton.alpha = 1.0
    }
    
    func setupUI() {
        emailField.layer.borderWidth = 1.0
        emailField.layer.cornerRadius = 22.0
        emailField.layer.borderColor = UIColor.init(red: 36.0/255.0, green: 63.0/255.0, blue: 63.0/255.0, alpha: 1.0).cgColor
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: emailField.frame.height))
        emailField.leftViewMode = .always
        resetButton.layer.cornerRadius = 22.0
        
        emailField.attributedPlaceholder = NSAttributedString(string: "Email",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }

    @IBAction func resetButtonPressed(_ sender: Any) {
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .indeterminate
        guard let email = emailField.text, !email.isEmpty else { return }
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            var title = ""
            var message = ""
            
            if let error = error {
                title = "Error!"
                message = error.localizedDescription
            } else {
                title  = "Success!"
                message = "Password reset email sent."
                self.emailField.text = ""
            }
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    

    
    func changeEmail(email:String) {
        Auth.auth().currentUser!.updateEmail(to: email) { (error) in
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
            
        }
    }
    
    
    @IBAction func backButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "UnwindToLoginFromReset", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
