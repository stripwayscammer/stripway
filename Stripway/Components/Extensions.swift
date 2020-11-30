//
//  Extensions.swift
//  Stripway
//
//  Created by iOS Dev on 2/12/19.
//  Copyright © 2019 Stripway. All rights reserved.
//

import Foundation
import UIKit
import FMPhotoPicker

extension Array {
    mutating func rotate(positions: Int, size: Int? = nil) {
        guard positions < count && (size ?? 0) <= count else {
            print("invalid input1")
            return
        }
        reversed(start: 0, end: positions - 1)
        reversed(start: positions, end: (size ?? count) - 1)
        reversed(start: 0, end: (size ?? count) - 1)
    }
    mutating func reversed(start: Int, end: Int) {
        guard start >= 0 && end < count && start < end else {
            return
        }
        var start = start
        var end = end
        while start < end, start != end {
            self.swapAt(start, end)
            start += 1
            end -= 1
        }
    }
}

//MARK:- UICOLOR EXTENSTION
extension UIColor {
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

//HASH TAG
struct PrefixesDetected {
   let text: String
   let prefix: String?
}
extension String {
    
        func trimNewLine() -> String {
              return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    
    func getHasTagPrefixesObjArr(_ prefixes: [String] = ["#", "@"]) -> [PrefixesDetected] {

        let words = self.components(separatedBy: " ")

        return words.map { word -> PrefixesDetected in
            PrefixesDetected(text: word,
                             prefix: word.hasPrefix(prefixes: prefixes))
        }
    }

    func hasPrefix(prefixes: [String]) -> String? {
        for prefix in prefixes {
            if hasPrefix(prefix) {
                return prefix
            }
        }
        return nil
    }
    var trimWhiteSpace: String {
        let trimmedString = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        return trimmedString
    }
}

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

public enum StripCrop: FMCroppable {
    case ratio3x1
    case ratio3x4
    case ratio8x10
    case ratio5x7
    case ratio3x5
    case ratio2x3
    
    public func ratio() -> FMCropRatio? {
        switch self {
        case .ratio3x1:
            return FMCropRatio(width: 3, height: 1)
        case .ratio3x4:
            return FMCropRatio(width: 3, height: 4)
        case .ratio8x10:
            return FMCropRatio(width: 8, height: 10)
        case .ratio5x7:
            return FMCropRatio(width: 5, height: 7)
        case .ratio3x5:
            return FMCropRatio(width: 3, height: 5)
        case .ratio2x3:
            return FMCropRatio(width: 2, height: 3)
        }
    }
    
    public func name(strings: [String: String]) -> String? {
        switch self {
        case .ratio3x4: return "3:4"
        case .ratio3x1: return "3:1"
        case .ratio8x10: return "8:10"
        case .ratio5x7: return "5:7"
        case .ratio3x5: return "3:5"
        case .ratio2x3: return "2:3"
        }
    }
    
    public func icon() -> UIImage {
        var imgName = ""
        switch self {
        case .ratio3x1:
            imgName = "3x1"
        case .ratio3x4:
            imgName = "3x4"
        case .ratio8x10:
            imgName = "8x10"
        case .ratio5x7:
            imgName = "5x7"
        case .ratio3x5:
            imgName = "3x5"
        case .ratio2x3:
            imgName = "2x3"
        }
        return UIImage(named: imgName)!
    }
    
    public func identifier() -> String {
        switch self {
        case .ratio3x4: return "ratio3x4"
        case .ratio3x1: return "ratio3x1"
        case .ratio8x10:
            return "ratio8x10"
        case .ratio5x7:
            return "ratio5x7"
        case .ratio3x5:
            return "ratio3x5"
        case .ratio2x3:
            return "ratio2x3"
        }
    }
}

extension UIAlertController{

func addColorInTitleAndMessage(color:UIColor,titleFontSize:CGFloat = 18, messageFontSize:CGFloat = 13){

    let attributesTitle = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: titleFontSize)]
    let attributesMessage = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: UIFont.systemFont(ofSize: messageFontSize)]
    let attributedTitleText = NSAttributedString(string: self.title ?? "", attributes: attributesTitle)
    let attributedMessageText = NSAttributedString(string: self.message ?? "", attributes: attributesMessage)

    self.setValue(attributedTitleText, forKey: "attributedTitle")
    self.setValue(attributedMessageText, forKey: "attributedMessage")

}}

extension UIFont {
    
    /**
     Will return the best font conforming to the descriptor which will fit in the provided bounds.
     */
    static func bestFittingFontSize(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
        let constrainingDimension = min(bounds.width, bounds.height)
        let properBounds = CGRect(origin: .zero, size: bounds.size)
        var attributes = additionalAttributes ?? [:]
        
        let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        var bestFontSize: CGFloat = constrainingDimension
        
        for fontSize in stride(from: bestFontSize, through: 0, by: -1) {
            let newFont = UIFont(descriptor: fontDescriptor, size: fontSize)
            attributes[.font] = newFont
            
            let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            
            if properBounds.contains(currentFrame) {
                bestFontSize = fontSize
                break
            }
        }
        return bestFontSize
    }
    
    static func bestFittingFont(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> UIFont {
        let maxFontSize: CGFloat = 55
        let minFontSize: CGFloat = 25
        var bestSize = min(bestFittingFontSize(for: text, in: bounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes), maxFontSize)
        bestSize = max(bestSize, minFontSize)
        print(bestSize)
        return UIFont(descriptor: fontDescriptor, size: bestSize)
    }
}
extension UITextView {
    func alignTextVerticallyInContainer() {
        var topCorrect = (self.bounds.size.height - self.contentSize.height * self.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect
        if Int(topCorrect) != Int(self.contentInset.top) {
            self.contentInset.top = topCorrect
        }
    }    

    /// Will auto resize the contained text to a font size which fits the frames bounds.
    /// Uses the pre-set font to dynamically determine the proper sizing
    func fitTextToBounds(_ rect: CGRect = .zero) {
        var rect = rect
        if rect == .zero {rect = bounds}
        guard let text = text, let currentFont = font else { return }
        let bestFittingFont = UIFont.bestFittingFont(for: text, in: rect, fontDescriptor: currentFont.fontDescriptor, additionalAttributes: basicStringAttributes)
        
        font = bestFittingFont
    }
    
    private var basicStringAttributes: [NSAttributedString.Key: Any] {
        var attribs = [NSAttributedString.Key: Any]()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = self.textAlignment
        attribs[.paragraphStyle] = paragraphStyle
        
        return attribs
    }
}
extension UILabel {
    func fitTextToBounds(_ rect: CGRect = .zero) {
        var rect = rect
        if rect == .zero {rect = bounds}
        guard let text = text, let currentFont = font else { return }
        let bestFittingFont = UIFont.bestFittingFont(for: text, in: rect, fontDescriptor: currentFont.fontDescriptor, additionalAttributes: basicStringAttributes)
        font = bestFittingFont
    }
    
    private var basicStringAttributes: [NSAttributedString.Key: Any] {
        var attribs = [NSAttributedString.Key: Any]()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = self.textAlignment
        attribs[.paragraphStyle] = paragraphStyle
        
        return attribs
    }
}


enum KeyboardToolbarButton: Int {

    case done = 0
    case cancel
    case back, backDisabled
    case forward, forwardDisabled

    func createButton(target: Any?, action: Selector?) -> UIBarButtonItem {
        var button: UIBarButtonItem!
        switch self {
            case .back: button = .init(title: "Back", style: .plain, target: target, action: action)
            case .backDisabled:
                button = .init(title: "Back", style: .plain, target: target, action: action)
                button.isEnabled = false
            case .forward: button = .init(title: "Forward", style: .plain, target: target, action: action)
            case .forwardDisabled:
                button = .init(title: "Forward", style: .plain, target: target, action: action)
                button.isEnabled = false
            case .done: button = .init(title: "Done", style: .plain, target: target, action: action)
            case .cancel: button = .init(title: "Cancel", style: .plain, target: target, action: action)
        }
        button.tag = rawValue
        return button
    }

    static func detectType(barButton: UIBarButtonItem) -> KeyboardToolbarButton? {
        return KeyboardToolbarButton(rawValue: barButton.tag)
    }
}

protocol KeyboardToolbarDelegate: class {
    func keyboardToolbar(button: UIBarButtonItem, type: KeyboardToolbarButton, isInputAccessoryViewOf textView: UITextView)
}

class KeyboardToolbar: UIToolbar {

    private weak var toolBarDelegate: KeyboardToolbarDelegate?
    private weak var textView: UITextView!

    init(for textView: UITextView, toolBarDelegate: KeyboardToolbarDelegate) {
        super.init(frame: .init(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 44)))
        barStyle = .default
        isTranslucent = true
        self.textView = textView
        self.toolBarDelegate = toolBarDelegate
        textView.inputAccessoryView = self
    }

    func setup(leftButtons: [KeyboardToolbarButton], rightButtons: [KeyboardToolbarButton]) {
        let leftBarButtons = leftButtons.map {
            $0.createButton(target: self, action: #selector(buttonTapped))
        }
        let rightBarButtons = rightButtons.map {
            $0.createButton(target: self, action: #selector(buttonTapped(sender:)))
        }
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        setItems(leftBarButtons + [spaceButton] + rightBarButtons, animated: false)
    }

    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    @objc func buttonTapped(sender: UIBarButtonItem) {
        guard let type = KeyboardToolbarButton.detectType(barButton: sender) else { return }
        toolBarDelegate?.keyboardToolbar(button: sender, type: type, isInputAccessoryViewOf: textView)
    }
}
extension UITextView {
    func addKeyboardToolBar(leftButtons: [KeyboardToolbarButton],
                            rightButtons: [KeyboardToolbarButton],
                            toolBarDelegate: KeyboardToolbarDelegate) {
        let toolbar = KeyboardToolbar(for: self, toolBarDelegate: toolBarDelegate)
        toolbar.setup(leftButtons: leftButtons, rightButtons: rightButtons)
    }
}

extension Array where Element: Equatable {
    mutating func removeDuplicates() {
        // Thanks to https://github.com/sairamkotha for improving the method
        self = reduce(into: [Element]()) {
            if !$0.contains($1) {
                $0.append($1)
            }
        }
    }
}
extension Encodable {

    var dict : [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return nil }
        return json
    }
}
