//
//  NewMainPostViewController.swift
//  Stripway
//
//  Created by Troy on 5/2/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit
import Photos
import PageMaster


class NewMainPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NewImageViewControllerDelegate {

//    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    var isTextPost = false
    var selectedNumber = 0
    
    var customTabBarController: CustomTabBarController!
    static let vc = self
    
    var images: [UIImage] = []
    var selectedImage = 1
    var image: UIImage = UIImage()
    private let pageMaster = PageMaster([])
    
    private var newImageViewController: NewImageViewController = NewImageViewController()
    private var newCaptionViewController: NewCaptionViewController = NewCaptionViewController()
    private var newHashTagViewController: NewHashTagViewController = NewHashTagViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageMaster()
        updateImage()
//        self.collectionView.delegate = self
//        self.collectionView.dataSource = self
//        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
//        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        DispatchQueue.main.async {
//            self.fetchPhotos()
//        }
         
//        self.registerKeyboardNotifications()
    }
    override func viewWillLayoutSubviews() {
        var ratio = self.image.size.width / self.image.size.height
        if isTextPost {ratio = 3/4}
        self.contentViewHeight.constant = (UIScreen.main.bounds.size.width / ratio)
        self.contentView.layoutIfNeeded()
    }
    private func setupPageMaster() {
        self.pageMaster.pageDelegate = self
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        newImageViewController = storyBoard.instantiateViewController(withIdentifier: "NewImageViewController") as! NewImageViewController
        newImageViewController.delegate = self
        newCaptionViewController = storyBoard.instantiateViewController(withIdentifier: "NewCaptionViewController") as! NewCaptionViewController
        newHashTagViewController = storyBoard.instantiateViewController(withIdentifier: "NewHashTagViewController") as! NewHashTagViewController
        var vcList: [UIViewController] = [newHashTagViewController, newCaptionViewController, newImageViewController]
        if isTextPost {
            vcList = [newHashTagViewController, newCaptionViewController]
        }
        self.pageMaster.setup(vcList)
        self.addChild(self.pageMaster)
        self.contentView.addSubview(self.pageMaster.view)
        self.pageMaster.view.frame = self.contentView.bounds
        self.pageMaster.didMove(toParent: self)
        self.pageMaster.setPage(isTextPost ? 1 : 2)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if isTextPost && pageMaster.currentPage == 1 {
            goNewPostViewController()
            return
        }
        if pageMaster.currentPage < 2 {
            pageMaster.setPage(pageMaster.currentPage + 1, animated: true)
        } else {
            goNewPostViewController()
//            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func goNewPostViewController() {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        let newPostViewController = storyBoard.instantiateViewController(withIdentifier: "NewPostViewController") as! NewPostViewController
        if !isTextPost {
            if self.image == UIImage() {
                let alert = UIAlertController(title: "Please Choose Image", message: "You must choose the Image to add this post to.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        if isTextPost && self.newCaptionViewController.captionString.isEmpty {
            let alert = UIAlertController(title: "Please write something", message: "You must write something for this type of post", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        newPostViewController.isTextPost = isTextPost
        newPostViewController.imageToPost = self.image
        newPostViewController.imageAspectRatio = isTextPost ? 3/4 : self.image.size.width / self.image.size.height
//        if  self.newCaptionViewController.captionString == "" {
//            let alert = UIAlertController(title: "Please input Caption", message: "You must input the Caption to add this post to.", preferredStyle: .alert)
//                           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                           self.present(alert, animated: true, completion: nil)
//            return
//        }
        newPostViewController.postCaption =
            self.newCaptionViewController.captionString
        newPostViewController.postCaptionBackGroundColorCode = self.newCaptionViewController.captionBGCode
        newPostViewController.postCaptionTextColorCode = self.newCaptionViewController.captionTextCode
//        if  self.newHashTagViewController.hashTagStings == [""] || self.newHashTagViewController.hashTagStings == [] {
//            let alert = UIAlertController(title: "Please set Hashtags", message: "You must choose the Hashtags or input new one to add this post to.", preferredStyle: .alert)
//                           alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                           self.present(alert, animated: true, completion: nil)
//            return
//        }
        newPostViewController.postHashTags = self.newHashTagViewController.hashTagStings
        newPostViewController.newHashFlag = self.newHashTagViewController.newHashFlag
        newPostViewController.newHashTags = self.newHashTagViewController.newHashTagStrings

        API.User.observeCurrentUser { (currentUser) in
            newPostViewController.postAuthor = currentUser
            newPostViewController.customTabBarController = self.customTabBarController
            newPostViewController.modalPresentationStyle = .fullScreen
            self.present(newPostViewController, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        self.image = image
        self.updateImage()
        // print out the image size as a test
        print(image.size)
    }
    
    func updateImage() {
        print(self.image.size)
        if !isTextPost {
            newImageViewController.imageView.image = self.image
        }
    }
    
    func gotoCaption() {
        self.pageMaster.setPage(1, animated: true)
    }
    
    func gotoHashTag() {
        self.pageMaster.setPage(0, animated: true)
    }
}

extension NewMainPostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - 6) / 4, height: (collectionView.frame.size.width - 6) / 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}
extension NewMainPostViewController: PageMasterDelegate, UIScrollViewDelegate {

    func pageMaster(_ master: PageMaster, didChangePage page: Int) {
        if page == 1 {        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.newCaptionViewController.textView.becomeFirstResponder()
            }
        } else if page == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.newHashTagViewController.newHashText.becomeFirstResponder()
            }
        } else {
            if self.newCaptionViewController.textView != nil && self.newHashTagViewController.newHashText != nil {
                self.newCaptionViewController.textView.resignFirstResponder()
                self.newHashTagViewController.newHashText.resignFirstResponder()
            }
            
            
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        newCaptionViewController.textView.resignFirstResponder()
//        self.view.endEditing(true)
//        self.view.resignFirstResponder()
    }
}

extension NewMainPostViewController {
    
    func registerKeyboardNotifications() {

          NotificationCenter.default.addObserver(self, selector: #selector(NewMainPostViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        

          NotificationCenter.default.addObserver(self, selector: #selector(NewMainPostViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
      self.scrollView.frame.origin.y = 0 - keyboardSize.height
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.scrollView.frame.origin.y = 0
    }
}

