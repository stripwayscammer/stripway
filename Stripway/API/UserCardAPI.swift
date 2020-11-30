//
//  UserCardAPI.swift
//  Stripway
//
//  Created by iBinh on 10/12/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth


class UserCardAPI {
    static let categories = ["Actor", "Architectural Designer", "Artist", "Athlete", "Author", "Blogger", "Chef", "Coach", "Comedian", "Concert Tour", "Dancer", "Designer", "Digital Creator", "DJ", "Editor", "Entrepreneur", "Fashion Designer", "Fashion Model", "Film Director", "Fitness Model", "Fitness Trainer", "Gamer", "Gaming Video Creator", "Government Official", "Graphic Designer", "Interior Design Studio", "Journalist", "Motivational Speaker", "Movie Character", "Musician", "Musician/Band", "News Personality", "Photographer", "Political Candidate", "Politician", "Producer", "Public Figure", "Scientist", "Video Creator", "Web Designer", "Writer", "None"]

    private var cardReference = Database.database().reference().child("user-cards")
    func addCard(card: UserCard, toUserID userID: String, completion: @escaping (Error?) -> ()) {
        let newCardRef = cardReference.child(userID)
        newCardRef.updateChildValues(card.dict!) { (err, ref) in
            completion(err)
        }
    }
    func getCard(userID: String, completion: @escaping (UserCard?) -> ()) {
        cardReference.child(userID).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                let card = UserCard(snapshot: snapshot)
                completion(card)
            } else {
                completion(nil)
            }
        }
    }
}

class UserCard: Codable {
    var userID: String = ""
    var profilePicture: String!
    var name: String!
    var category: String!
    var twitter: String!
    var instagram: String!
    var youtube: String!
    
    init() {
        
    }
    
    init(snapshot: DataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        userID = snapshot.key
        profilePicture = snapshotValue["profilePicture"] as? String
        name = snapshotValue["name"] as? String
        category = snapshotValue["category"] as? String
        twitter = snapshotValue["twitter"] as? String
        instagram = snapshotValue["instagram"] as? String
        youtube = snapshotValue["youtube"] as? String
    }
}
