//
//  AppDelegate.swift
//  Stripway
//
//  Created by Drew Dennistoun on 8/31/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

//clone
import UIKit
import UserNotifications
import Firebase
import FirebaseCrashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var post:StripwayPost?
    var passedUser: StripwayUser?

    // This is used in case tapped notification tries to segue using current navigation controller, but it doesn't exist yet
    var notificationSegueWaiting = false
    // The dictionary that is included in the notification
    var unusedUserInfoDict: [String: Any]?
    // This is updated anytime the navigation controller is set in the app so we can segue properly
    var currentNavController: UINavigationController? {
        didSet {
            if notificationSegueWaiting, let userInfoDict = unusedUserInfoDict {
                self.segueForNotification(userInfoDict: userInfoDict)
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
    
        UITextField.appearance().tintColor = UIColor.black
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        print("Is application registered for remote notifications: \(application.isRegisteredForRemoteNotifications)")
        
        // [END register_for_notifications]
        
        
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDTokenForcingRefresh(true) { (idToken, error) in
                if let error = error as NSError? {
                    if error.code == 17020 {
                        
                    } else {
                        do {
                            try Auth.auth().signOut()
                        } catch let logoutError {
                            print(logoutError)
                        }
                        let storyboard = UIStoryboard(name: "LoginSignup", bundle: nil)
                        let logInVC = storyboard.instantiateViewController(withIdentifier: "LogInViewController")
                        self.window?.rootViewController = logInVC
                    }
                }
            }
        }
        return true
    }
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        let userInfoDict = userInfo as! [String: Any]
        completionHandler()
        
        // If currentNavController doesn't exist, that means this is the first launch of the app so we'll wait
        // until currentNavController is set and then we'll do stuff with it (that's what the booleean is for but
        // probably don't need it since unusedUserInfoDict would suffice)
        if currentNavController == nil {
            unusedUserInfoDict = userInfoDict
            notificationSegueWaiting = true
        } else {
            segueForNotification(userInfoDict: userInfoDict)
        }
    }
    
    /// If user taps on a notification, this is called and segues to the proper notification or message
    func segueForNotification(userInfoDict: [String: Any]) {
        notificationSegueWaiting = false
        unusedUserInfoDict = nil
        if let convoID = userInfoDict["conversationID"] as? String, let senderUID = userInfoDict["senderUID"] as? String, let receiverUID = userInfoDict["receiverUID"] as? String {
            let storyboard = UIStoryboard(name: "DMs", bundle: nil)
            let conversationsListViewController = storyboard.instantiateViewController(withIdentifier: "ConversationsListViewController") as! ConversationsListViewController
            if var navController = currentNavController, let tabController = navController.tabBarController {
                if tabController.selectedIndex != 0 {
                    tabController.selectedIndex = 0
                    guard let newNavController = currentNavController else { return }
                    navController = newNavController
                }
                navController.popToRootViewController(animated: false)
                navController.pushViewController(conversationsListViewController, animated: false)
                conversationsListViewController.segueToConversationWithID(convoID: convoID, senderUID: senderUID, receiverUID: receiverUID)
            }
        } else if let objectID = userInfoDict["objectID"] as? String, let typeString = userInfoDict["type"] as? String, let type = NotificationType(rawValue: typeString)  {
            let storyboard = UIStoryboard(name: "Notifications", bundle: nil)
            let notificationsViewController = storyboard.instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
            if var navController = currentNavController, let tabController = navController.tabBarController {
                if tabController.selectedIndex != 0 {
                    tabController.selectedIndex = 0
                    guard let newNavController = currentNavController else { return }
                    navController = newNavController
                }
                navController.popToRootViewController(animated: false)
                navController.pushViewController(notificationsViewController, animated: false)
                notificationsViewController.segueToView(forType: type, withID: objectID)
            }
        }
    }
    
    struct PushNotificationType {
        
    }
    
    
}
// [END ios_10_message_handling]


extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        if let currentUserUID = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference().child("userNotificationInfo").child(currentUserUID).child("fcmToken")
            ref.setValue(fcmToken)
        }
        
    }
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
extension AppDelegate {
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let host = url.host else {return false}
        
        print("URL: \(url)")
        
         var resolvedParam = ""
        getHeaderOfHost(url: String(describing: url), completion: {value in
            
            print("url: \(url)")
            print("Header recieved: \(value)")
            
            resolvedParam = value as! String
            
            API.Post.observePost(withID: resolvedParam, completion: { (p, error) in
                if(error != nil){
                    print("Error: AppDelegate.swift -> observing post with paramter \(resolvedParam) and error: \(String(describing: error))")
                }else{
                    self.post = p!
                    
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                               let postViewController = storyboard.instantiateViewController(withIdentifier: "ViewPostViewController") as! ViewPostViewController
                      if var navController = self.currentNavController, let tabController = navController.tabBarController {
                                   if tabController.selectedIndex != 0 {
                                       tabController.selectedIndex = 0
                                      guard let newNavController = self.currentNavController else { return }
                                       navController = newNavController
                                   }
                                   navController.popToRootViewController(animated: false)
                                   navController.pushViewController(postViewController, animated: false)
                               }
                }
                
            })
            
            API.User.getUser(withUsername: resolvedParam) { (user) in
                if let user = user {
                    
                    self.passedUser = user
                    let storyboard = UIStoryboard(name: "Profile", bundle: nil)
                    let postViewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
                    if var navController = self.currentNavController, let tabController = navController.tabBarController {
                        if tabController.selectedIndex != 0 {
                            tabController.selectedIndex = 0
                            guard let newNavController = self.currentNavController else { return }
                            navController = newNavController
                        }
                        navController.popToRootViewController(animated: false)
                        navController.pushViewController(postViewController, animated: false)
                    }
                }
                
            }
                   
        })
        

        return false

    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        
        return false

    }
    
    func getHeaderOfHost(url: String, completion: @escaping ((AnyObject) -> Void)){
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse,
                let headers = response.allHeaderFields as? [String: String] else {
                    
                return
            }
            completion(self.parseHeaderValue(headers: headers) as AnyObject)
          
        }
        task.resume()
    }
    
    func parseHeaderValue(headers: [String:String]) -> String? {
        
        //Print headers if app fails..you have recorded headers!
        print(headers)
        if(headers["Header-Post-Id"] != "" && headers["Header-Post-Id"] != nil){
           
            if let header = headers["Header-Post-Id"] {
                return header
            }else{
                return nil
            }
            
        }
        if (headers["Header-Username"] != "" && headers["Header-Username"] != nil ){
            
            if let header = headers["Header-Username"] {
                return header
            }else{
                return nil
            }
        }else{
            return "Error: headers invalid!"
        }
    }

}




