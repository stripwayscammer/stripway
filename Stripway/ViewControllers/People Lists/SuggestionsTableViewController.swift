//
//  SuggestionsTableViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/15/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

class SuggestionsTableViewController: UITableViewController {

    var users: [StripwayUser] = []
    var hashtags:[(name: String, count: Int)] = []
    var isSearchingUsers = false
    var currentUser:StripwayUser!

    
    var delegate: SuggestionsTableViewControllerDelegate?
    
    var searchText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        API.User.observeCurrentUser { (currentUser) in
            self.currentUser = currentUser
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if isSearchingUsers {
            return users.count
        } else {
            return hashtags.count
        }
    }
    
    // This method searches and populates the
    func searchWithText(text: String) {
        self.searchText = text
        if text.hasPrefix("#") {
            print("Searching for hashtag: \(text)")
            isSearchingUsers = false
            searchHashtags(withText: String(text.dropFirst()))
        } else {
            print("Searching for user: \(text)")
            isSearchingUsers = true
            searchUsers(withText: String(text.dropFirst()))
        }
    }
    
    func searchUsers(withText text: String) {
        self.users.removeAll()
        self.tableView.reloadData()
        API.User.queryUsers(withText: text) { (user) in
//            self.users.append(user.username)
            self.users.append(user)
            self.tableView.reloadData()
        }
    }
    
    func searchHashtags(withText text: String) {
        self.hashtags.removeAll()
        self.tableView.reloadData()
        if text == "" {
            /// Queries for recently used hashtags
            API.Hashtag.queryRecentHashtags(withUserUID: self.currentUser.uid) { (hashtag) in
                //Sorts hashtags by most used by user
                if let numIndex = self.hashtags.index(where: { $0.name == hashtag }) {
                    let currentCount = self.hashtags[numIndex].count
                    self.hashtags[numIndex].count = currentCount-1
                    self.hashtags = self.hashtags.sorted(by: { $0.count < $1.count })
                    self.tableView.reloadData()
                }
                else {
                    self.hashtags.append((hashtag!,-1))
                    self.hashtags = self.hashtags.sorted(by: { $0.count < $1.count })
                    self.tableView.reloadData()
                    
                }
            }
            API.Trending.fetchTrendtags{ (tag) in
                if(!self.hashtags.contains(where: {$0.name == tag.name}))
                {
                    self.hashtags.append((tag.name, tag.index))
                    self.hashtags = self.hashtags.sorted(by: { $0.count < $1.count })
                    self.tableView.reloadData()
                }
            }
        }
        API.Hashtag.queryHashtags(withText: text) { (hashtag, hashtagCount) in
            self.hashtags.append((hashtag,0))
            self.tableView.reloadData()
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isSearchingUsers {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
            cell.user = users[indexPath.row]
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HashtagCell", for: indexPath)
            cell.textLabel?.text = "#" + hashtags[indexPath.row].name
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearchingUsers {
            let selectedUser = users[indexPath.row]
            delegate?.autoComplete(withSuggestion: "@" + selectedUser.username + " ", andUID: selectedUser.uid)
            print("User selected: @\(selectedUser.username)")
        } else {
            let selectedHashtag = hashtags[indexPath.row].name
            delegate?.autoComplete(withSuggestion: "#" + selectedHashtag + " ", andUID: nil)
            print("User selected: #\(selectedHashtag)")
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

protocol SuggestionsTableViewControllerDelegate {
    func autoComplete(withSuggestion suggestion: String, andUID uid: String?)
}
