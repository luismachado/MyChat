//
//  PasswordResetController.swift
//  MyChat
//
//  Created by Luís Machado on 17/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class ChangePasswordController: UITableViewController {
    
    let cellId = "cellId"
    var textFieldBeingEdited: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Password"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(handleSave))
        navigationItem.rightBarButtonItem?.isEnabled = false
        tableView.register(PasswordCell.self, forCellReuseIdentifier: cellId)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func handleSave() {
        
        guard let currentPasswordCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PasswordCell else { return }
        guard let newPasswordCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PasswordCell else { return }
        guard let newPasswordCell2 = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? PasswordCell else { return }
        
        if let currentPassword = currentPasswordCell.passwordField.text, let newPassword = newPasswordCell.passwordField.text, let newPassword2 = newPasswordCell2.passwordField.text {
            if newPassword != newPassword2 {
                AlertHelper.displayAlert(title: "Change Password", message: "New password must be equal on both fields.", displayTo: self)
            } else {
                
                reauthenticateAndChangePassword(currentPassword: currentPassword, newPassword: newPassword)
            }
            
        } else {
            AlertHelper.displayAlert(title: "Change Password", message: "Unable to change the password. Please try again later.", displayTo: self)
        }
        
    }
    
    private func reauthenticateAndChangePassword(currentPassword: String, newPassword: String) {
        guard let email = FIRAuth.auth()?.currentUser?.email else {
            AlertHelper.displayAlert(title: "Change Password", message: "Unable to change the password. Please try again later.", displayTo: self)
            return
        }
        
        let credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: currentPassword)
        
        FIRAuth.auth()?.currentUser?.reauthenticate(with: credential, completion: { (error) in
            
            if let error = error {
                AlertHelper.displayAlert(title: "Change Password", message: error.localizedDescription, displayTo: self)
                return
            }
            
            FIRAuth.auth()?.currentUser?.updatePassword(newPassword, completion: { (error) in
                
                if let error = error {
                    AlertHelper.displayAlert(title: "Change Password", message: error.localizedDescription, displayTo: self)
                    return
                }
                
                AlertHelper.displayAlert(title: "Change Password", message: "Password changed successfully.", displayTo: self, completion: { (action) in
                    
                    self.navigationController?.dismiss(animated: true, completion: nil)
                    
                })
                
            })
        })
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 2
        }
        
        return 1
    }
    
    func enableDisableSaveButton() {
        
        guard let currentPasswordCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? PasswordCell else { return }
        guard let newPasswordCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PasswordCell else { return }
        guard let newPasswordCell2 = tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? PasswordCell else { return }
        
        var toEnable = true
        
        if currentPasswordCell.passwordField.text == "" ||  newPasswordCell.passwordField.text == "" || newPasswordCell2.passwordField.text == "" {
            toEnable = false
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = toEnable
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PasswordCell
        cell.changePasswordController = self
        cell.selectionStyle = .none
        
        if indexPath.section == 0 {
            cell.passwordField.placeholder = "Current password"
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                cell.passwordField.placeholder = "New password"
            } else {
                cell.passwordField.placeholder = "Repeat new password"
            }
        }
        
        return cell
    }
    
    func dismissKeyboard() {
        self.textFieldBeingEdited?.resignFirstResponder()
    }
    
}

class PasswordCell: UITableViewCell, UITextFieldDelegate {
    
    var changePasswordController: ChangePasswordController?
    
    let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.clearButtonMode = UITextFieldViewMode.whileEditing
        return tf
    }()
    
    let passwordIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UIImage(named: "lock_icon")
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFill
        icon.alpha = 0.7
        return icon
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(passwordField)
        addSubview(passwordIcon)
        
        passwordIcon.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        passwordIcon.widthAnchor.constraint(equalTo: self.heightAnchor, constant: -8).isActive = true
        passwordIcon.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -8).isActive = true
        passwordIcon.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        passwordField.leftAnchor.constraint(equalTo: self.passwordIcon.rightAnchor, constant: 8).isActive = true
        passwordField.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        passwordField.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        passwordField.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(checkSaveButton), for: UIControlEvents.editingChanged)
    }
    
    func checkSaveButton() {
        changePasswordController?.enableDisableSaveButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        changePasswordController?.textFieldBeingEdited = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    
}
