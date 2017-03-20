//
//  LoginController+handlers.swift
//  MyChat
//
//  Created by Luís Machado on 13/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleLogin() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Form is not valid")
            return
        }
        
        if email == "" || password == "" {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error = error {
                AlertHelper.displayAlert(title: "Login Error", message: error.localizedDescription, displayTo: self)
                return
            }
            
            print("User successfully logged into Firebase db")
            self.messagesController?.navigationItem.title = ""
            self.messagesController?.fetchUserAndSetupNavBarTitle()
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func handleRegister() {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        if email == "" || password == "" || name == "" {
            print("Form is not valid")
            return
        }
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            
            if let error = error {
                AlertHelper.displayAlert(title: "Registration Error", message: error.localizedDescription, displayTo: self)
                return
            }
            
            guard let uid = user?.uid else {return}
            
            let values = ["name": name, "email" : email]
            self.registerUserIntoDatabaseWithUid(uid: uid, values: values as [String : AnyObject])
        })
    }
    
    private func registerUserIntoDatabaseWithUid(uid: String, values: [String : AnyObject]) {
        let ref = FIRDatabase.database().reference().child("users").child(uid)
        
        ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
            
            if let err = err {
                AlertHelper.displayAlert(title: "Registration Error", message: err.localizedDescription, displayTo: self)
                return
            }
            
            print("Saved user successfully into Firebase db")
            
            self.messagesController?.cleanUpTable()
            self.messagesController?.navigationItem.title = values["name"] as? String
            self.dismiss(animated: true, completion: nil)
            
        })
    }
    
}
