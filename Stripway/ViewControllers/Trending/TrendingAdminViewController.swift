//
//  TrendingAdminViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 12/7/18.
//  Copyright © 2018 Stripway. All rights reserved.
//
import UIKit
import Firebase

/// This is where the admin can add/remove trending hashtags and choose the order they're displayed
class TrendingAdminViewController: UIViewController {

    @IBOutlet weak var tableview: UITableView!
    var trendtags = [Trendtag]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTrendtags()
        // Do any additional setup after loading the view.
    }
    
    /// Fetches all the hashtags that are currently trending
    func fetchTrendtags() {
        API.Trending.observeTrendtags { (tag, shouldClear) in
            if let shouldClear = shouldClear, shouldClear {
                self.trendtags.removeAll()
                return
            }
            guard let tag = tag else { return }
            self.trendtags.append(tag)
            self.tableview.reloadData()
        }
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        print("Add button pressed")
        presentAddAlert()
        
    }
    
    func presentAddAlert() {
        let alert = UIAlertController(title: "New Photo or Tag?", message: "Would you like to add a new trending header photo, or new trending tag?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tag", style: .default, handler: { (action) in
            self.presentNewTagAlert()
        }))
        alert.addAction(UIAlertAction(title: "View/Edit Photos", style: .default, handler: { (action) in
            self.performSegue(withIdentifier: "ShowHeaderImages", sender: self)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func presentNewTagAlert() {
        let alertController = UIAlertController(title: "New Trending Tag", message: "Enter the hashtag that you'd like to trend (without the # or any punctuation).", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.keyboardType = .alphabet
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            guard let newTag = firstTextField.text, !newTag.isEmpty else { return }
            print("This is the new tag: \(newTag)")
            if self.trendtags.contains(where: { $0.name == newTag }) {
                print("That tag is already trending")
            } else {
                API.Trending.createNewTrendtag(name: newTag)
            }
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
}

extension TrendingAdminViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trendtags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = trendtags[indexPath.row].name
        cell.detailTextLabel?.text = String(trendtags[indexPath.row].index)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alertController = UIAlertController(title: "Change Tag Index", message: "Lower index shows up higher in trending page.", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.keyboardType = .numberPad
            textField.placeholder = String(self.trendtags[indexPath.row].index)
        }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as UITextField
            guard let newIndex = firstTextField.text, !newIndex.isEmpty, let numIndex = Int(newIndex) else { return }
            print("Updated index to \(numIndex)")
            API.Trending.updateIndexForTrendtag(trendtag: self.trendtags[indexPath.row], toIndex: numIndex)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
            (action : UIAlertAction!) -> Void in })

        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print("Should be deleting tag: \(trendtags[indexPath.row].name)")
        API.Trending.deleteTrendtag(trendtag: trendtags[indexPath.row])
    }
}
