//
//  UITextViewHashtagExtension.swift
//  Stripway
//
//  Created by Drew Dennistoun on 11/12/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import UIKit

extension UITextView {
    private func isValidUserNameCharacter(text: String) -> Bool {
        return text.range(of: "[^a-z0-9_]", options: .regularExpression) == nil
    }
    
    func resolveHashtagsAndMentions() {
        
        // Turn string into NSString
        let nsText = NSString(string: self.text)
        
        // Turn it into an array of NSString
        let words = nsText.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(self.attributedText)
        
        // Remove all attributes or it gets all weird when reusing cells that have already been attributed
        attrString.removeAttribute(NSAttributedString.Key.link, range: nsText.range(of: self.attributedText.string))
        
        // Tag each word if it has a hashtag
        for word in words {
            if word.hasPrefix("#") {
                let matchRange: NSRange = nsText.range(of: word as String)
                
                let stringifiedWord = word.dropFirst()
                attrString.addAttribute(NSAttributedString.Key.link, value: "hash:\(stringifiedWord)", range: matchRange)
                print("Should only be hashtagging for range: \(matchRange)")
                
                // Maybe remove this
//                attrString.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "AvenirNext-Bold", size: 17), range: matchRange)
            }
            
            if word.hasPrefix("@") {
                var word = word
                if let last = word.last {
                    if !isValidUserNameCharacter(text: String(last)) {
                        _ = word.popLast()
                    }
                }
                let matchRange: NSRange = nsText.range(of: word as String)
                
                let stringifiedWord = word.dropFirst()
                attrString.addAttribute(NSAttributedString.Key.link, value: "user:\(stringifiedWord)", range: matchRange)
                print("Should only be mentioning for range: \(matchRange)")
                
                // Maybe remove this
//                attrString.addAttribute(NSAttributedStringKey.font, value: UIFont(name: "AvenirNext-Bold", size: 17), range: matchRange)
            }
        }
        self.attributedText = attrString
    }
    
    var currentWord: String? {
        let regex = try! NSRegularExpression(pattern: "\\S+$")
        let textRange = NSRange(location: 0, length: selectedRange.location)
        if let range = regex.firstMatch(in: text, range: textRange)?.range {
            return String(text[Range(range, in: text)!])
        }
        return nil
    }
    
    var currentWordRange: NSRange? {
        let regex = try! NSRegularExpression(pattern: "\\S+$")
        let textRange = NSRange(location: 0, length: selectedRange.location)
        if let range = regex.firstMatch(in: text, range: textRange)?.range {
            return range
        }
        return nil
    }
    
    func autoComplete(withSuggestion suggestion: String) {
        print("BUG3: Here's self.text: \(self.text)")
        print("BUG3: Here's self.attributedText: \(self.attributedText)")
        let oldCaption = self.text as NSString
        let newCaption = oldCaption.replacingCharacters(in: self.currentWordRange!, with: suggestion)
        self.text = newCaption
    }
}


