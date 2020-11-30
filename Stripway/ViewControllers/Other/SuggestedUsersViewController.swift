//
//  SuggestedUsersViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 1/23/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import UIKit

class SuggestedUsersViewController: UIViewController {

    var suggestedUsers: [(StripwayUser, Int)] = []
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSuggestedUsers()
    }
    
    func fetchSuggestedUsers() {
        API.User.observeSuggestedUsers { (userTuple, shouldClear) in
            if let shouldClear = shouldClear, shouldClear {
                self.suggestedUsers.removeAll()
                return
            }
            guard let userTuple  = userTuple else { return }
            self.suggestedUsers.append(userTuple)
            self.tableView.reloadData()
        }
    }
}

extension SuggestedUsersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = suggestedUsers[indexPath.row].0.username
        cell.detailTextLabel?.text = String(suggestedUsers[indexPath.row].1)
        return cell
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        API.User.removeFromSuggestedUsers(uid: suggestedUsers[indexPath.row].0.uid) {
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alertController = UIAlertController(title: "Change User Index", message: "Lower index shows up higher in suggestions.", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.keyboardType = .numberPad
            textField.placeholder = String(self.suggestedUsers[indexPath.row].1)
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            guard let newIndex = firstTextField.text, !newIndex.isEmpty, let numIndex = Int(newIndex) else { return }
            print("Updated index to \(numIndex)")
            API.User.updateIndexSuggestedUser(uid: self.suggestedUsers[indexPath.row].0.uid, index: numIndex)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
}
