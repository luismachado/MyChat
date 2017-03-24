//
//  User.swift
//  MyChat
//
//  Created by Luís Machado on 12/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

class User: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    var blockedUsers: [String:AnyObject]?
    var blockedBy: [String:AnyObject]?
    
    
    init(id: String?, dictionary: [String : AnyObject]) {
        super.init()
        
        self.id = id
        name = dictionary["name"] as? String
        email = dictionary["email"] as? String
        profileImageUrl = dictionary["profileImageUrl"] as? String
        blockedUsers = [String:AnyObject]()
        if let blocked_users = dictionary["blocked_users"] as? [String:AnyObject] {
            blockedUsers = blocked_users
        }
        blockedBy = [String:AnyObject]()
        if let blocked_by = dictionary["blocked_by"] as? [String:AnyObject] {
            blockedBy = blocked_by
        }
    }
}
