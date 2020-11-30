//
//  NewHashTagViewController.swift
//  Stripway
//
//  Created by Troy on 5/2/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit
import WSTagsField
import TagListView

class BaseTagCollectionView: UICollectionView {
    private var shouldInvalidateLayout = false

    override func layoutSubviews() {
        super.layoutSubviews()
        if shouldInvalidateLayout {
            collectionViewLayout.invalidateLayout()
            shouldInvalidateLayout = false
        }
    }

    override func reloadData() {
        shouldInvalidateLayout = true
        super.reloadData()
    }
}

class NewHashTagViewController: UIViewController, UITextFieldDelegate, TagListViewDelegate {
    
    @IBOutlet weak var newHashText: CustomTextField!
    @IBOutlet weak var widthOfHashText: NSLayoutConstraint!
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var collectionView: BaseTagCollectionView!
    @IBOutlet weak var collectionFlowLayout: TagListFlowLayout!
    

    
    var hashTags: [HashTag] = []
    var selectedHashTags: [String] = []
    var sizingCell: TagCollectionCell?
    var hashTagString = ""
    var hashTagStings:[String] = []
    var newHashTagStrings:[String] = []
    var newHashFlag = false

    override func viewDidLoad() {
        super.viewDidLoad()
        newHashText.tintColor = UIColor.white
        newHashText.layer.borderColor = UIColor.white.cgColor
        newHashText.layer.borderWidth = 1.0
        newHashText.layer.cornerRadius = 14
//        newHashText.attributedPlaceholder = NSAttributedString(string: "#",
//        attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        tagListView.isHidden = false
        newHashText.isHidden = false
        tagListView.textFont = UIFont.systemFont(ofSize: 14)
        tagListView.alignment = .center
        tagListView.cornerRadius = 14.0
        tagListView.marginY = 12.0
        tagListView.marginX = 12.0
        tagListView.delegate = self
        setupCollectionView()
        getRecenthashTags()
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        tagsField.beginEditing()
//    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

    }
   
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let cellNib = UINib(nibName: "TagCollectionCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "TagCollectionCell")
        sizingCell = (cellNib.instantiate(withOwner: nil, options: nil) as NSArray).firstObject as! TagCollectionCell?
        
        self.collectionFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        self.collectionFlowLayout.scrollDirection = .horizontal
    }
    
    func getRecenthashTags() {
        API.User.observeCurrentUser { (currentUser) in
            API.Hashtag.fetchHashtags(withUserUID: currentUser.uid) { (tags) in
                if tags?.count == 0 {
                    API.Trending.fetchAllTrendtags { (tags) in
                        self.hashTags =  []
                        var temp: [String] = []
                        for item in tags {
                            self.hashTags.append(HashTag(tagString: item.name, selectedFlag: false))
                            temp.append(item.name)
                        }
                        self.collectionView.reloadData()
                        API.Hashtag.postHashtags(withUserUID: currentUser.uid, tags: temp)
                    }
                }else{
                    self.hashTags =  []
                    for item in tags! {
                        self.hashTags.append(HashTag(tagString: item, selectedFlag: false))
                    }
                    self.collectionView.reloadData()
                }
            }
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.becomeFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let hashtag = self.newHashText.text!.replacingOccurrences(of: " ", with: "")
        updateListHashTagView(tag: "#\(hashtag)")
//        self.view.endEditing(true)
        textField.text = ""
        widthOfHashText.constant = 68.0
        self.view.layoutIfNeeded()
        return true
    }
    
  
    func getWidth(text: String) -> CGFloat
    {
        let txtField = UITextField(frame: .zero)
        txtField.text = text
        txtField.sizeToFit()
        return txtField.frame.size.width
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            return false
        }
        let width = getWidth(text: newHashText.text!) + 44.0
        
        let maxLength = 36
        let currentString: NSString = textField.text! as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
                
        if let text = textField.text, let swiftRange = Range(range, in: text) {
           self.hashTagString = text.replacingCharacters(in: swiftRange, with: string)
        } else {
           self.hashTagString = string
        }
        
        print(self.hashTagString)
        if self.hashTagString.count > 1 {
            self.hashTagString.remove(at: self.hashTagString.startIndex)
        }
        
        
        if UIScreen.main.bounds.width - 55 > width
        {
            textField.tintColor = UIColor.white
            
            widthOfHashText.constant = 68.0
            if width > widthOfHashText.constant
            {
                widthOfHashText.constant = width
            }
            self.view.layoutIfNeeded()
        }
        return newString.length <= maxLength
    }
    
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        var title = title
        self.tagListView.removeTag(title)
        title.remove(at: title.startIndex)
        self.hashTagStings = hashTagStings.filter({$0 != title})
    }

}
extension NewHashTagViewController {
    
    func updateListHashTagView(tag: String){
        
        if self.hashTagStings.count == 10 { return }
        if tag.count < 2 { return }
        
        self.newHashTagStrings = []
        self.newHashFlag = false
        var temp = tag
        temp.remove(at: temp.startIndex)
        
        let tempArr = self.hashTagStings
        var newFlag = true
        for item in tempArr {
            if item == temp {
                newFlag = false
            }
        }
        if newFlag {
            self.hashTagStings.append(temp)
            tagListView.addTag(tag)
        }
        
        for temp in self.hashTagStings {
            var flag = true
            for item in self.hashTags {
                if temp == item.tagString {
                    flag = false
                }
            }
            if flag {
                self.newHashFlag = true
                newHashTagStrings.append(temp)
            }
        }
    }
    
}

class CustomTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    func setup() {
        let lbl = UILabel()
        lbl.text = " #"
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 14)
        lbl.sizeToFit()
        leftViewMode = .always
        leftView = lbl
    }
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}

extension NewHashTagViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hashTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCollectionCell", for: indexPath) as! TagCollectionCell
        self.configureCell(cell: cell, forIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: TagCollectionCell?, forIndexPath indexPath: IndexPath) {
        cell?.updateView(tag: hashTags[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.hashTagStings.count == 10 {
            return
        }
        self.updateListHashTagView(tag: "#\(hashTags[indexPath.row].tagString)")
    }
    
}

extension NewHashTagViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        self.configureCell(cell: self.sizingCell, forIndexPath: indexPath)
        let size = self.sizingCell?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        if let sz = size, sz.width > 0, sz.height > 0 {
            return sz
        }
        return CGSize(width: 100, height: 28)
    }
}

struct HashTag {
    var tagString: String
    var selectedFlag: Bool
}


    
