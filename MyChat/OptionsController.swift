//
//  OptionsViewController.swift
//  MyChat
//
//  Created by Luís Machado on 16/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

class OptionsController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var messagesController: MessagesController?
    let cellId = "cellId"
    
    let logoutButton:UIButton = {
        let button = UIButton(type: UIButtonType.system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileOptionsCell.self, forCellReuseIdentifier: cellId)
        
        navigationItem.title = "Options"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(handleSave))
        
    }
    
    func handleBack() {
        dismiss(animated: true)
    }
    
    func handleLogout() {
        dismiss(animated: true) {
            self.messagesController?.handleLogout()
        }
    }
    
    func handleSave() {
        print("save")
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Profile"
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 1 {
            return indexPath
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        if indexPath.section == 0 {
            let profileCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! ProfileOptionsCell
            profileCell.optionsController = self
            return profileCell
        } else if indexPath.section == 1 {
            cell.textLabel?.text = "Change Password"
            cell.accessoryType = .disclosureIndicator
        } else if indexPath.section == 2 {
            cell.addSubview(logoutButton)
            logoutButton.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
            logoutButton.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true
            logoutButton.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            logoutButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        }
        
        return cell
    }
    
    
    
    func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            let indexPath = IndexPath(row: 0, section: 0)
            if let profileCell = tableView.cellForRow(at: indexPath) as? ProfileOptionsCell {
                profileCell.profileImageView.image = selectedImage
            }
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
    

}
