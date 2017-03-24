//
//  ViewController.swift
//  MyChat
//
//  Created by Luís Machado on 10/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {
    
    var messages = [Message]()
    var currentUser: User?
    var messagesDictionary = [String: Message]()
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(showOptionsController))
        
        let image = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let message = messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
           FIRDatabase.database().reference().child("last-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
            
            if let error = error {
                print(error)
                return
            }
            
            self.messagesDictionary.removeValue(forKey: chatPartnerId)
            self.attemptReloadOfTable()
           })
            
//            Would it make sense to also remove from user-messages?
//
//            FIRDatabase.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
//                
//                if let error = error {
//                    print(error)
//                    return
//                }
//                
//                self.messagesDictionary.removeValue(forKey: chatPartnerId)
//                self.attemptReloadOfTable()
//            })
        }
    }
    
    func observeUserMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        
        let ref = FIRDatabase.database().reference().child("last-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let userId = snapshot.key
            FIRDatabase.database().reference().child("last-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
            })
        })
        
        ref.observe(.childRemoved, with: { (snapshot) in
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        })
        
    }
    
    func observeUserBlocks() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        let userRefBlockedBy = FIRDatabase.database().reference().child("users").child(uid).child("blocked_by")
        userRefBlockedBy.observe(.childAdded, with: { (snapshot) in
            self.currentUser?.blockedBy?[snapshot.key] = 1 as AnyObject?
            self.attemptReloadOfTable()

        })
        userRefBlockedBy.observe(.childRemoved, with: { (snapshot) in
            _ = self.currentUser?.blockedBy?.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        })
        
        let userRefBlocked = FIRDatabase.database().reference().child("users").child(uid).child("blocked_users")
        userRefBlocked.observe(.childAdded, with: { (snapshot) in
            self.currentUser?.blockedUsers?[snapshot.key] = 1 as AnyObject?
            self.attemptReloadOfTable()
            
        })
        userRefBlocked.observe(.childRemoved, with: { (snapshot) in
            _ = self.currentUser?.blockedUsers?.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
        })
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        let messagesReference = FIRDatabase.database().reference().child("messages").child(messageId)
        messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message(id: snapshot.key, dictionary: dictionary)
                
                if let id = message.chatPartnerId() {
                    
                    let ref = FIRDatabase.database().reference().child("users").child(id)
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        if let dictionary = snapshot.value as? [String: AnyObject] {
                            
                            message.user = User(id: snapshot.key, dictionary: dictionary)
                            
                            if let chatPartnerId = message.chatPartnerId() {
                                self.messagesDictionary[chatPartnerId] = message
                            }
                            
                            // to reload the table just once
                            self.attemptReloadOfTable()                            
                        }
                    })
                }
                
            }
        })
    }
    
    private func attemptReloadOfTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    var timer: Timer?
    
    func handleReloadTable() {
        self.messages = [Message]()
        for user in  Array(self.messagesDictionary.keys) {
            if currentUser?.blockedUsers?[user] == nil && currentUser?.blockedBy?[user] == nil {
                if let message = self.messagesDictionary[user] {
                    self.messages.append(message)
                }
            }
        }
        
        //self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            if let timestamp1 = message1.timestamp?.intValue, let timestamp2 = message2.timestamp?.intValue {
                return timestamp1 > timestamp2
            }
            return false
        })
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.init(top: 0, left: 62, bottom: 0, right: 0)
        cell.layoutMargins = UIEdgeInsets.zero
        cell.message = message
    
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else { return }
        
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : AnyObject] else { return }
            
            let user = User(id: chatPartnerId, dictionary: dictionary)
            self.showChatControllerForUser(user: user)            
        })
    }
    
    func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messagesController = self
        newMessageController.currentUser = currentUser
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        if FIRAuth.auth()?.currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func cleanUpTable() {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {return}
        
        cleanUpTable()
        
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                self.navigationItem.title = dictionary["name"] as? String
                self.currentUser = User(id: snapshot.key, dictionary: dictionary)
                self.observeUserMessages()
                self.observeUserBlocks()
            }
        })
    }
    
    func showOptionsController() {
        let optionsController = OptionsController(style: .grouped)
        optionsController.messagesController = self
        let navController = UINavigationController(rootViewController: optionsController)
        present(navController, animated: true, completion: nil)
    }
    
    func showChatControllerForUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }


}

