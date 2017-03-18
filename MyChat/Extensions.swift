//
//  Extensions.swift
//  MyChat
//
//  Created by Luís Machado on 13/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    
    private func useNameInitialAsImage(name: String) {

        if name.characters.count > 0 {
            let upperCased = name.uppercased()
            if let firstChar = upperCased.characters.first {
                image = UIImage(named: "square")
                textToImage(drawText: String(firstChar) as NSString)
            }
        }        
    }
    
    private func textToImage(drawText text: NSString) {
        let textColor = UIColor.white
        let textFont = UIFont.systemFont(ofSize: 54)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        guard let image = image else { return }
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)
        
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: style
            ] as [String : Any]
        
        let point = CGPoint(x: 1, y: 10)
        
        self.image?.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
        
        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)
        
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.image = newImage
    }
    
    func loadImageUsingCacheWithUrlString(urlString: String?, username: String = "", completion: @escaping () -> Void = { _ in return }) {
        
        self.image = nil
        
        if let urlString = urlString {
            if let cachedImage = imageCache.object(forKey: NSString(string: urlString)) {
                self.image = cachedImage
                completion()
                return
            }
            
            
            let url = URL(string: urlString)
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                
                if let error = error {
                    print(error)
                }
                
                DispatchQueue.main.async(execute: {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: NSString(string: urlString))
                        
                        self.image = downloadedImage
                        completion()
                    }
                })
            }).resume()
        } else {
            useNameInitialAsImage(name: username)
            completion()
        }
    }
}
