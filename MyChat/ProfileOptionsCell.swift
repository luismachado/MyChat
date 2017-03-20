//
//  ProfileOptionsCell.swift
//  MyChat
//
//  Created by Luís Machado on 17/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase

class ProfileOptionsCell: UITableViewCell {
    
    var optionsController: OptionsController?
    
    var user: User? {
        didSet {
            
            self.textLabel?.text = user?.name
            self.detailTextLabel?.text = user?.email
            
            self.profileImageView.loadImageUsingCacheWithUrlString(urlString: user?.profileImageUrl, username: (user?.name)!, completion: {
                self.changeProfileImageButton.isEnabled = true
            })
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 76, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 76, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    lazy var changeProfileImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change", for: .normal)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleChangeProfileImage), for: .touchUpInside)
        return button
    }()
    
    @objc private func handleChangeProfileImage() {
        optionsController?.handleSelectProfileImageView()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(changeProfileImageButton)
        
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -10).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        changeProfileImageButton.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor).isActive = true
        changeProfileImageButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 5).isActive = true
        changeProfileImageButton.widthAnchor.constraint(equalTo: profileImageView.widthAnchor).isActive = true
        changeProfileImageButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
