//
//  ViewController.swift
//  MyChat
//
//  Created by Luís Machado on 10/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
    
    }
    
    func handleLogout() {
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }


}

