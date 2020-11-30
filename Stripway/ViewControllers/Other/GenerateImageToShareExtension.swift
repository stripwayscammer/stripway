//
//	GenerateImageToShareExtension
//	Stripway
//
//	Created by: Nedim on 22/05/2020
//

import Foundation
import UIKit
import MBProgressHUD
import Toaster

extension ViewPostViewController: DownloadWatermarkedPhotoDelegate {

    func generateImageWithWatermark(from photoURL: String, of username:String, post: StripwayPost?, onlyLink: Bool) {
        
        if(!onlyLink){
        containerView.alpha = 1
        containerView.isHidden = false
        
        }else{
           containerView.isHidden = true
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: containerView, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        
        gImageView.contentMode = UIView.ContentMode.scaleAspectFill
        gImageView.sd_setImage(with: URL(string: photoURL)) { (image, error, cache, urls) in
            if (error != nil) {
                // Failed to load image
                
            } else {
                // Successful in loading image
                self.gImageView.image = image
                
                MBProgressHUD.hide(for: self.containerView, animated: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                    
                    self.captureViewToImageAndRender(post: post!, onlyLink: onlyLink, username: username)
                }
            }
        }
        
        gViewConstraints()
        usernameLabel.text = "@\(username)"
       
    }
    
    func gViewConstraints(){


        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        containerView.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }

    
    func captureViewToImageAndRender(post:StripwayPost, onlyLink: Bool, username:String){
        
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        containerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIView.animate(withDuration: 0.8, animations: {
            self.containerView.alpha = 0
        }) { (finished) in
            self.containerView.isHidden = finished
        }
        
        shareMyImage(image: image!, post: post, username:username ,onlyLink: onlyLink)
    }
    
    func shareMyImage(image: UIImage, post: StripwayPost, username:String, onlyLink: Bool){
        
        let url = UniversalLinkStruct.url
        let linkForShare = "\(url)/p=\(post.postID)"
        
        if(onlyLink){
            
            //Copy to clipboard
             
            let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            
            Meta().setupMetaTags(url: linkForShare,title: "Stripway post by @\(username)", description: post.caption, image: post.photoURL, passed_url: linkForShare, completion: {
                value in
                
                let linkForShare = "\(url)/p=\(value)"
                
                DispatchQueue.main.async {
                   
                   ToastView.appearance().font = UIFont(name: "AvenirNext", size: 16.0)
                   ToastView.appearance().bottomOffsetPortrait = 100
                   Toast(text: "Link copied to cliboard!").show()
                   
                   let pasteboard = UIPasteboard.general
                   pasteboard.string = linkForShare
                    
                    MBProgressHUD.hide(for: self.view, animated: true)


                }
                 
            })
                  
            
        }else{
            
            var caption = "Get Stripway and organize your life trough series of strips!"
            if(post.caption != ""){
                
                caption = post.caption
            }
            
            let dataToShare = [image,caption] as [Any]
            let activityViewController = UIActivityViewController(activityItems: dataToShare , applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            
            activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF]
            
            
            self.present(activityViewController, animated: true, completion: nil)
        }
         
        
       
    
    }
 
    //URL: https://stripway.app/p=t13ysa

 
}


extension HomeViewController: DownloadWatermarkedPhotoDelegate {

    func generateImageWithWatermark(from photoURL: String, of username:String, post: StripwayPost?, onlyLink: Bool) {
        
        if(!onlyLink){
        containerView.alpha = 1
        containerView.isHidden = false
        
        }else{
           containerView.isHidden = true
        }
        
        let loadingNotification = MBProgressHUD.showAdded(to: containerView, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        
        gImageView.contentMode = UIView.ContentMode.scaleAspectFill
        gImageView.sd_setImage(with: URL(string: photoURL)) { (image, error, cache, urls) in
            if (error != nil) {
                // Failed to load image
                
            } else {
                // Successful in loading image
                self.gImageView.image = image
                
                MBProgressHUD.hide(for: self.containerView, animated: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                    
                    self.captureViewToImageAndRender(post: post!, onlyLink: onlyLink, username: username)
                }
            }
        }
        
        gViewConstraints()
        usernameLabel.text = "@\(username)"
       
    }
    
    func gViewConstraints(){


        containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        containerView.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }

    
    func captureViewToImageAndRender(post:StripwayPost, onlyLink: Bool, username:String){
        
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        containerView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIView.animate(withDuration: 0.8, animations: {
            self.containerView.alpha = 0
        }) { (finished) in
            self.containerView.isHidden = finished
        }
        
        shareMyImage(image: image!, post: post, username:username ,onlyLink: onlyLink)
    }
    
    func shareMyImage(image: UIImage, post: StripwayPost, username:String, onlyLink: Bool){
        
        let url = UniversalLinkStruct.url
        let linkForShare = "\(url)/p=\(post.postID)"
        
        if(onlyLink){
            
            //Copy to clipboard
             
            let loadingNotification = MBProgressHUD.showAdded(to: view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            
            Meta().setupMetaTags(url: linkForShare,title: "Stripway post by @\(username)", description: post.caption, image: post.photoURL, passed_url: linkForShare, completion: {
                value in
                
                let linkForShare = "\(url)/p=\(value)"
                
                DispatchQueue.main.async {
                   
                   ToastView.appearance().font = UIFont(name: "AvenirNext", size: 16.0)
                   ToastView.appearance().bottomOffsetPortrait = 100
                   Toast(text: "Link copied to cliboard!").show()
                   
                   let pasteboard = UIPasteboard.general
                   pasteboard.string = linkForShare
                    
                    MBProgressHUD.hide(for: self.view, animated: true)


                }
                 
            })
                  
            
        }else{
            
            var caption = "Get Stripway and organize your life trough series of strips!"
            if(post.caption != ""){
                
                caption = post.caption
            }
            
            let dataToShare = [image,caption] as [Any]
            let activityViewController = UIActivityViewController(activityItems: dataToShare , applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            
            activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.saveToCameraRoll, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.markupAsPDF]
            
            
            self.present(activityViewController, animated: true, completion: nil)
        }
         
        
       
    
    }
 
    //URL: https://stripway.app/p=t13ysa

 
}
