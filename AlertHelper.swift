//
//  AlertHelper.swift
//
//  Created by Luís Machado on 18/11/16.
//  Copyright © 2016 LuisMachado. All rights reserved.
//
import UIKit

class AlertHelper {
    static func displayAlert(title: String, message: String, displayTo: UIViewController, completion: @escaping (UIAlertAction) -> Void = { _ in return }) {
        
        let alert = UIAlertController(title: title, message: message , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
        
        displayTo.present(alert, animated: true, completion: nil)
        
    }
    
    
    static func displayAlertCancel(title: String, message: String, displayTo: UIViewController, okCallback: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: title, message: message , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: okCallback))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        displayTo.present(alert, animated: true, completion: nil)
        
    }
    
    static func progressBarDisplayer(msg:String, _ indicator:Bool, view: UIView) -> UIView {
        var strLabel = UILabel()
        var messageFrame = UIView()
        var activityIndicator = UIActivityIndicatorView()
        
        strLabel = UILabel(frame: CGRect(x: 50, y: 0, width: 200, height: 50))
        strLabel.text = msg
        strLabel.textColor = .white
        
        messageFrame = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25 , width: 180, height: 50))
        messageFrame.layer.cornerRadius = 15
        messageFrame.backgroundColor = UIColor(white: 0, alpha: 0.7)
        if indicator {
            activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            activityIndicator.startAnimating()
            messageFrame.addSubview(activityIndicator)
        }
        messageFrame.addSubview(strLabel)
        
        return messageFrame
    }
}
