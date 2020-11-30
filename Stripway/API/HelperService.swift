//
//  HelperService.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/16/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
import Firebase

class HelperService {
    
    /// Just uploads an image to the storage section of the database
    static func uploadImage(imageData: Data, storageReference: StorageReference, completion: @escaping (Error?, URL?)->()) {
        
        let uploadTask = storageReference.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(error, nil)
                return
            }
            if metadata != nil {
                storageReference.downloadURL(completion: { (url, error) in
                    if let error = error {
                        completion(error, nil)
                        return
                    }
                    if let url = url {
                        completion(nil, url)
                    }
                })
            }
        }
        
        let observer = uploadTask.observe(.progress) { snapshot in
//            print("uploading progress ", snapshot.progress?.fractionCompleted) // NSProgress object
            if snapshot.progress != nil {
                let progressDataDict:[String: Float] = ["progress": Float(snapshot.progress!.fractionCompleted)*100]
                NotificationCenter.default.post(name: NEW_POSTING_PROGRESS, object: nil, userInfo:progressDataDict)
            }
        }
    }
    
}
