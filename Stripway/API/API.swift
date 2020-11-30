//
//  API.swift
//  Stripway
//
//  Created by Drew Dennistoun on 9/13/18.
//  Copyright © 2018 Stripway. All rights reserved.
//

import Foundation
struct API {
    static var User = UserAPI()
    static var Post = PostAPI()
    static var Strip = StripAPI()
    static var Follow = FollowAPI()
    static var Feed = FeedAPI()
    static var Comment = CommentAPI()
    static var Reposts = RepostsAPI()
    static var Messages = MessagesAPI()
    static var Notification = NotificationAPI()
    static var Hashtag = HashtagAPI()
    static var Block = BlockAPI()
    static var Trending = TrendingAPI()
    static var UserCard = UserCardAPI()
}
