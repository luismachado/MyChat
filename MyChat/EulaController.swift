//
//  EulaController.swift
//  MyChat
//
//  Created by Luís Machado on 24/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

class EulaController: UIViewController {

    let eulaLabel: UITextView = {
        let label = UITextView()
        label.text = Eula.eula
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.sizeToFit()
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        navigationItem.title = "End User License Agreement"
        eulaLabel
            .scrollRangeToVisible(NSRange(location:0, length:0))
        view.addSubview(eulaLabel)
        eulaLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
        eulaLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8).isActive = true
        eulaLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8).isActive = true
        eulaLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8).isActive = true
    }

}
