//
//  OptionsViewController.swift
//  MyChat
//
//  Created by Luís Machado on 16/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

class OptionsController: UITableViewController {
    
    var messagesController: MessagesController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Options"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
    }
    
    func handleBack() {
        dismiss(animated: true)
    }
    
    func handleLogout() {
        dismiss(animated: true) {
            self.messagesController?.handleLogout()
        }
    }
    

}
