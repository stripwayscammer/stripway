//
//	Meta
//	Stripway
//
//	Created by: Nedim on 02/06/2020
//	Copyright © 2020 Stripway. All rights reserved.
//

import Foundation

class Meta {
    
    func setupMetaTags(url:String, title: String, description:String,image:String, passed_url:String, completion: @escaping ((AnyObject) -> Void)){
        
        
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/json", forHTTPHeaderField:"Content-Type")
        
        request.setValue(title, forHTTPHeaderField: "meta-title")
        if(description != ""){request.setValue(trimText(string: description), forHTTPHeaderField: "meta-description")}else{request.setValue("Join Stripway for FREE! Share your photos in strips!", forHTTPHeaderField: "meta-description")}
        request.setValue(image, forHTTPHeaderField: "meta-image")
        request.setValue(passed_url, forHTTPHeaderField: "meta-url")
     
       let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            
        print(response)

        if let response = response as? HTTPURLResponse {
           
            if(response.statusCode == 200){
                print("Success: Link created!")
                do {
                    let result = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                    if(result!["shortenURL"] != nil){
                        
                        let serverReturn = result!["shortenURL"]
                        completion(serverReturn as AnyObject)
                    }
                }catch{
                    print("error")
                }
                
            }else if (response.statusCode == 400){
                
                print("Shared link already exists!")
            }else{
                print("Error happend on server side -> status code of the error: \(response.statusCode) and headers: \(response.allHeaderFields)")
            }
        }
        
        }

        task.resume()

        
    }
    
    func trimText(string: String)->String{

        let str = string.replaceEmoji(with: " ")
        print(str)
        let str1 = str.stripped
        print(str1)
        return str1
    }
        
}
extension HTTPURLResponse {
     func isResponseOK() -> Bool {
      return (200...299).contains(self.statusCode)
     }
}

extension Character {
   var isSimpleEmoji: Bool {
      guard let firstProperties = unicodeScalars.first?.properties else {
        return false
      }
      return unicodeScalars.count == 1 &&
          (firstProperties.isEmojiPresentation ||
             firstProperties.generalCategory == .otherSymbol)
   }
   var isCombinedIntoEmoji: Bool {
      return unicodeScalars.count > 1 &&
             unicodeScalars.contains {
                $0.properties.isJoinControl ||
                $0.properties.isVariationSelector
             }
   }
   var isEmoji: Bool {
      return isSimpleEmoji || isCombinedIntoEmoji
   }
}

extension String {
    func replaceEmoji(with character: Character) -> String {
        return String(map { $0.isEmoji ? character : $0 })
    }
}

extension String {

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890+-=().!_")
        return self.filter {okayChars.contains($0) }
    }
}


