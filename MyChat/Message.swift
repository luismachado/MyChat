//
//  Message.swift
//  MyChat
//
//  Created by Luís Machado on 13/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    func chatPartnerId() -> String? {
        return fromId  == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }

}
