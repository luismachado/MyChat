//
//  OptionsViewController.swift
//  MyChat
//
//  Created by Luís Machado on 16/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class OptionsController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var messagesController: MessagesController?
    let cellId = "cellId"
    var user: User?
    
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
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        downloadUser()
    }
    
    func downloadUser() {
        if let id = FIRAuth.auth()?.currentUser?.uid {
            
            let ref = FIRDatabase.database().reference().child("users").child(id)
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    
                    self.user = User(id: id, dictionary: dictionary)
                    
                    if let profileImageCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileOptionsCell {
                        profileImageCell.user = self.user                        
                    }
                }
            })
        }
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
        
        if let profileCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ProfileOptionsCell, let newProfileImage = profileCell.profileImageView.image, let uploadData = UIImageJPEGRepresentation(newProfileImage, 0.1) {
            
            let spinner = AlertHelper.progressBarDisplayer(msg: "Saving...", true, view: self.view)
            self.view.addSubview(spinner)
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            let onCompletion = {
                spinner.removeFromSuperview()
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            
            let imageName = NSUUID().uuidString
            let storageRef = FIRStorage.storage().reference().child("profile_images").child("\(imageName).png")
            
            storageRef.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if let error = error {
                    onCompletion()
                    AlertHelper.displayAlert(title: "Profile Update", message: error.localizedDescription, displayTo: self)
                    return
                }
                
                if let profileImageUrl = metadata?.downloadURL()?.absoluteString, let name = self.user?.name, let email = self.user?.email, let uid = FIRAuth.auth()?.currentUser?.uid {
                    
                    let values = ["name": name, "email" : email, "profileImageUrl": profileImageUrl]
                    let ref = FIRDatabase.database().reference().child("users").child(uid)
                    
                    ref.updateChildValues(values, withCompletionBlock: { (err, ref) in
                        
                        if let err = err {
                            onCompletion()
                            AlertHelper.displayAlert(title: "Profile Update", message: err.localizedDescription, displayTo: self)
                            return
                        }
                        
                        onCompletion()
                        AlertHelper.displayAlert(title: "Profile Update", message: "Profile updated successfully", displayTo: self, completion: { (action) in
                            self.navigationItem.rightBarButtonItem?.isEnabled = false
                        })
                        
                    })
                } else {
                    onCompletion()
                    AlertHelper.displayAlert(title: "Profile Update", message: "Unable to update your profile. Please try again later.", displayTo: self)
                }
            })
        }        
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
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
        if indexPath.section == 1 || indexPath.section == 2 {
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
        
        if indexPath.section == 1 {
            let changePasswordController = ChangePasswordController(style: .grouped)
            navigationController?.pushViewController(changePasswordController, animated: true)
        } else if indexPath.section == 2 {
            let eulaController = EulaController()
            navigationController?.pushViewController(eulaController, animated: true)
        }
        
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
        } else if indexPath.section == 3 {
            cell.addSubview(logoutButton)
            logoutButton.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
            logoutButton.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true
            logoutButton.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            logoutButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        } else if indexPath.section == 2 {
            cell.textLabel?.text = "End User License Agreement"
            cell.accessoryType = .disclosureIndicator
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
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled picker")
        dismiss(animated: true, completion: nil)
    }
    

}
