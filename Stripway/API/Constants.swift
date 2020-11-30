//
//  Constants.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/14/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

//define constants will be used in several pages
let SCREEN_WIDTH = UIScreen.main.bounds.width

let DEFAULT_THUMBNAIL_HEIGHT:CGFloat = 1024
let VELOCITY_LIMIT_SWIPE:CGFloat = 1200.0
let IMAGE_COMPRESSION_QUALITY:CGFloat = 0.7
let AVATAR_COMPRESSION_QUALITY:CGFloat = 0.4
let IMAGE_CROP_RATIO:CGFloat = 0.75
let ONE_TIME_LOAD:Int = 5
let RECENT_TIME_LOADING = 7
let NEW_POSTING_FINISHED = Notification.Name("newPostingFinished")
let NEW_POSTING_PROGRESS = Notification.Name("newPostingProgress")

// File is where I put app-wide stuff that I don't know where to put anywhere else
struct Constants {
    
    static var currentUser: User? {
        if let currentUser = Auth.auth().currentUser {
            return currentUser
        }
        return nil
    }
    
        
    static var currentUserReference: DatabaseReference? {
        guard let currentUser = Auth.auth().currentUser else {
            return nil
        }
        return API.User.usersReference.child(currentUser.uid)
    }
    
    static let storageRef = Storage.storage().reference(forURL: "gs://stripeway-2.appspot.com")
    
}

extension Date {
    static var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date().noon)!
    }
    static var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: Date().noon)!
    }
    func nDayBefore(_ days:Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }
    
    func nHoursBefore(_ hours:Int) -> Date {
        return Calendar.current.date(byAdding: .hour, value: -hours, to: Date())!
    }
    
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

// Not sure where else to put this
extension Int {
    
    /// Converts an integer to a timestamp, the integer must be Date().timeIntervalSince1970 for it to work correctly
    func convertToTimestamp() -> String {
        let timestamp = self
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let timeDifference = currentTimestamp - timestamp
        let minutes = timeDifference/60
        let hours = minutes/60
        let days = hours/24
        
        let dateFormtter = DateFormatter()
        dateFormtter.dateFormat = "MM/dd/yy"
        let convertedDate = dateFormtter.string(from: Date(timeIntervalSince1970: TimeInterval(exactly: timestamp)!))
        
        if minutes < 60 {
            return "\(minutes)m"
        } else if hours < 24 {
            if hours == 1 {
                return "1hr"
            }
            return "\(hours)hrs"
        } else if days <= 5 {
            return "\(days)d"
        } else {
            return convertedDate
        }
    }
}

/// Lets you create a custom error with a localizedDescription
struct CustomError : LocalizedError {
    var errorDescription: String? { return mMsg }
    var failureReason: String? { return mMsg }
    var recoverySuggestion: String? { return "" }
    var helpAnchor: String? { return "" }
    
    private var mMsg : String
    
    init(_ description: String)
    {
        mMsg = description
    }
}

/// Removes whitespace from beginning and end of the content of a UITextField
extension UITextField {
    func trimWhitespace() {
        self.text = self.getTrimmedText()
    }
    
    func getTrimmedText() -> String? {
        return self.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension UITextView {
    func trimWhitespace() {
        self.text = self.getTrimmedText()
    }
    
    func getTrimmedText() -> String? {
        return self.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}
