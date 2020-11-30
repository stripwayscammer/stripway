//
//  ExploreViewController.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/23/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import UIKit

class SearchViewController: UIViewController {
    
    
    var searchBar = UISearchBar()
    var users: [StripwayUser] = []
    @IBOutlet weak var tableView: UITableView!
    var selectedUser: StripwayUser?
    var selectedHashtag: String?
    var currentUser:StripwayUser!
    
    var hashtags:[(name: String, count: Int)] = []
    
    @IBOutlet weak var usersTabButton: UIButton!
    @IBOutlet weak var hashtagsTabButton: UIButton!
    
    var currentTab = 0
    
    var shouldShowSuggestedUsers = true
    var suggestedUsers: [(StripwayUser, Int)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.keyboardDismissMode = .onDrag
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.sizeToFit()
        
        API.User.observeCurrentUser { (currentUser) in
            self.currentUser = currentUser
        }
        fetchSuggestedUsers()
        
        self.navigationItem.titleView = searchBar
        
        tabChanged()
        self.navigationController?.view.backgroundColor = UIColor.white
    }
    
    
    @IBAction func tabButtonPressed(_ sender: UIButton) {
        if currentTab != sender.tag {
            currentTab = sender.tag
            print("Tab \(currentTab) was selected")
            tabChanged()
        }
    }
    
    func tabChanged() {
        if currentTab == 0 {
            searchBar.placeholder = "Search by username"
//            usersTabButton.setTitleColor(UIColor.orange, for: .normal)
            usersTabButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            hashtagsTabButton.setTitleColor(UIColor.black, for: .normal)
            hashtagsTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        } else {
            shouldShowSuggestedUsers = false
            searchBar.placeholder = "Search by hashtag"
            usersTabButton.setTitleColor(UIColor.black, for: .normal)
            usersTabButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
//            hashtagsTabButton.setTitleColor(UIColor.orange, for: .normal)
            hashtagsTabButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        }
        doSearch()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        doSearch()
    }
    
    // TODO: If you type too fast it sometimes won't account for the last letter(s), I think this is because
    // Firebase can't query fast enough so it doesn't do the last few
    func doSearch() {
        if var searchText = searchBar.text?.lowercased(), searchText != "" {
            shouldShowSuggestedUsers = false
            print("SEARCHFIX SEARCH WITH TEXT: |\(searchText)|")
            // If we're on the users tab
            if currentTab == 0 {
                self.users.removeAll()
                self.tableView.reloadData()
                API.User.queryUsers(withText: searchText.lowercased()) { (user) in
                    print("SEARCHFIX Search found user: \(user.username)")
                    self.isFollowing(userID: user.uid, completion: { (value) in
                        user.isFollowing = value
                        if !self.users.contains(where: { $0.uid == user.uid}) && user.username.contains(searchText.lowercased()) {
                            print("SEARCHFIX Searchtext: \(searchText.lowercased()) contains username:  \(user.username)")
                            self.users.append(user)
                            self.tableView.reloadData()
                        }
                        
                    })
                }
            // If we're on the hashtags tab
            } else {
                self.hashtags.removeAll()
                self.tableView.reloadData()
                if searchText.hasPrefix("#") {
                    searchText = String(searchText.dropFirst())
                }
        
                    API.Hashtag.queryHashtags(withText: searchText) { (hashtag, hashtagCount) in
                        print("This hashtag returned from search: \(hashtag)")
                        self.hashtags.append((hashtag, hashtagCount))
                        self.hashtags = self.hashtags.sorted(by: { $0.count > $1.count })
                        self.tableView.reloadData()
                    }
                
            }
        }
        if searchBar.text == "" {
            if currentTab == 0 {
                shouldShowSuggestedUsers = true
                self.users.removeAll()
            }
            else {
                ///If we are on the default search that is blank we show trending tags instead, and order them by their index.
                self.hashtags.removeAll()
                //Get hashtags the user has recently used
                API.Hashtag.queryRecentHashtags(withUserUID: self.currentUser.uid) { (hashtag) in
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
            self.tableView.reloadData()
        }
        
    }
    
    func fetchSuggestedUsers() {
        API.User.observeSuggestedUsers { (userTuple, shouldClear) in
            if let shouldClear = shouldClear, shouldClear {
                self.suggestedUsers.removeAll()
                return
            }
            guard let userTuple  = userTuple else { return }
            self.isFollowing(userID: userTuple.0.uid, completion: { (value) in
                userTuple.0.isFollowing = value
                self.suggestedUsers.append(userTuple)
                self.tableView.reloadData()
            })
        }
    }
    
    
    func isFollowing(userID: String, completion: @escaping (Bool)->()) {
        API.Follow.isFollowing(userID: userID, completion: completion)
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.setShowsCancelButton(true, animated: true)
        print(searchBar.text)
        doSearch()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print(searchBar.text)
        doSearch()
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        print("cancel pressed")
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel pressed")
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        doSearch()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar.resignFirstResponder()
        if currentTab == 0 {
            if shouldShowSuggestedUsers {
                self.selectedUser = suggestedUsers[indexPath.row].0
                performSegue(withIdentifier: "ShowUserProfile", sender: self)
            } else {
                print("selected row for user: \(users[indexPath.row].username)")
                self.selectedUser = users[indexPath.row]
                performSegue(withIdentifier: "ShowUserProfile", sender: self)
            }
        } else {
            self.selectedHashtag = hashtags[indexPath.row].name
            self.performSegue(withIdentifier: "SegueToHashtag", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Is this even preparing for segue?")
        print("Here is the destination: \(segue.destination)")
        if let profileViewController = segue.destination as? ProfileViewController {
            print("Should be preparing for segue")
            profileViewController.profileOwner = selectedUser
        }
        if segue.identifier == "SegueToHashtag" {
            if let hashtagViewController = segue.destination as? PostsCollectionViewController {
                hashtagViewController.hashtag = self.selectedHashtag!
            }
        }
    }
    
}


extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if shouldShowSuggestedUsers {
            let sectionHeader = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 60))
            sectionHeader.backgroundColor = UIColor.white
            let label = UILabel(frame: CGRect.zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.attributedText = NSAttributedString(string: "Suggested Users", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.bold)])
            sectionHeader.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: sectionHeader.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: sectionHeader.trailingAnchor, constant: 0),
                label.topAnchor.constraint(equalTo: sectionHeader.topAnchor, constant: 0),
                label.bottomAnchor.constraint(equalTo: sectionHeader.bottomAnchor, constant: 0)])
            return sectionHeader
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if shouldShowSuggestedUsers { return 60 }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentTab == 0 {
            if shouldShowSuggestedUsers {
                return suggestedUsers.count
            }
            return users.count
        } else {
            return hashtags.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentTab == 0 {
            if shouldShowSuggestedUsers {
                suggestedUsers.sort(by: { $0.1 < $1.1 })
                let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
                cell.user = suggestedUsers[indexPath.row].0
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PersonTableViewCell", for: indexPath) as! PersonTableViewCell
                cell.user = users[indexPath.row]
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HashtagCell", for: indexPath)
            cell.textLabel?.text = "#" + hashtags[indexPath.row].name
            return cell
        }
    }
    
    
}
