//
//  PasswordRecoveryController.swift
//  MyChat
//
//  Created by Luís Machado on 17/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class PasswordRecoveryController: UIViewController, UITextFieldDelegate {

    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var recoveryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(r: 80, g: 101, b: 161)
        button.setTitle("Send recovery email", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.lightGray, for: .disabled)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        
        button.addTarget(self, action: #selector(handleSendEmail), for: .touchUpInside)
        
        return button
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        
        return button
    }()
    
    func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.autocapitalizationType = UITextAutocapitalizationType.none
        tf.autocorrectionType = UITextAutocorrectionType.no
        tf.keyboardType = UIKeyboardType.emailAddress
        tf.clearButtonMode = UITextFieldViewMode.whileEditing
        return tf
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Having trouble reminding your password? Submit your email so that we can send you a link to recover it."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = label.font.withSize(16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var recoveryImageView: UIImageView = { //TODO change color
        let imageView = UIImageView()
        imageView.image = UIImage(named: "pass_recovery")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recoveryButton.isEnabled = false
        
        emailTextField.delegate = self
        emailTextField.addTarget(self, action: #selector(enableDisableSendButton), for: UIControlEvents.editingChanged)

        view.backgroundColor = UIColor(r: 61, g: 91, b: 151)
        view.addSubview(inputsContainerView)
        view.addSubview(recoveryButton)
        view.addSubview(cancelButton)
        view.addSubview(titleLabel)
        view.addSubview(recoveryImageView)
        setupInputsContainerView()
        setupButtons()
        setupTitle()
        setupRecoveryImage()
    }
    
    func handleSendEmail() {
        
        emailTextField.resignFirstResponder()
        
        if let email = emailTextField.text {
            FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { (error) in
                
                if let error = error {
                    AlertHelper.displayAlert(title: "Password Recovery", message: error.localizedDescription, displayTo: self)
                } else {
                    AlertHelper.displayAlert(title: "Password Recovery", message: "Email sent successfully.", displayTo: self, completion: self.alertReturn)
                }
                
            })
        }
    }
    
    func alertReturn(alert: UIAlertAction) {
        handleCancel()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func enableDisableSendButton() {
        recoveryButton.isEnabled = emailTextField.text != nil && emailTextField.text != ""        
    }
    
    func setupInputsContainerView() {
        //x,y,w,h
        inputsContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputsContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputsContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        inputsContainerView.addSubview(emailTextField)
        
        emailTextField.leftAnchor.constraint(equalTo: inputsContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: inputsContainerView.topAnchor).isActive = true
        emailTextField.rightAnchor.constraint(equalTo: inputsContainerView.rightAnchor, constant: -12).isActive = true
        emailTextField.bottomAnchor.constraint(equalTo: inputsContainerView.bottomAnchor).isActive = true
    }
    
    func setupButtons() {
        
        recoveryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recoveryButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12).isActive = true
        recoveryButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        recoveryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    func setupTitle() {
    
        titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        titleLabel.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    func setupRecoveryImage() {
        recoveryImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recoveryImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -12).isActive = true
        recoveryImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        recoveryImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }

}
