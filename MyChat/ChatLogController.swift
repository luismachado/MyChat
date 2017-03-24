//
//  ChatLogController.swift
//  MyChat
//
//  Created by Luís Machado on 13/03/17.
//  Copyright © 2017 LuisMachado. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            observeMessages()
            observeUserBlockedBy()
        }
    }
    
    var messages = [Message]()
    weak var cellPlayingMultimedia: ChatMessageCell?
    
    func observeMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        guard let toId = user?.id else { return }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String : AnyObject] else { return }
                let message = Message(dictionary: dictionary)
                
                self.messages.append(message)
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                    
                    let indexPath = IndexPath(item: self.messages.count-1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
                })
            })
        })
    }
    
    func observeUserBlockedBy() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { return }
        let userRef = FIRDatabase.database().reference().child("users").child(uid).child("blocked_by")
        userRef.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.key == self.user?.id {
                self.inputContainerView.blockChatInputController()
            }
        })
        userRef.observe(.childRemoved, with: { (snapshot) in
            
            if snapshot.key == self.user?.id {
                self.inputContainerView.unblockChatInputController()
            }
        })
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        return chatInputContainerView
        
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Report", style: .plain, target: self, action: #selector(showReportActions))
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        inputContainerView.enableDisableSendButton()
        
        setupKeyboardObservers()
    }
    
    func showReportActions() {
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
        let reportAction = UIAlertAction(title: "Report User" , style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            self.reportUser()
            
        })
        
        let blockAction = UIAlertAction(title: "Block User", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            self.blockUser()
            
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        
        
        // 4
        optionMenu.addAction(reportAction)
        optionMenu.addAction(blockAction)
        optionMenu.addAction(cancelAction)
        
        
        // 5
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        inputContainerView.dismissKeyboard()
    }
    
    func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // selected video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            handleVideoSelectedForUrl(url: videoUrl)
        } else {
            //selected image
            handleImageSelectedForInfo(info: info as [String : AnyObject])
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: URL) {
        let filename = NSUUID().uuidString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(filename).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        let properties: [String: AnyObject] = ["videoUrl": videoUrl as AnyObject, "imageUrl" : imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight" : thumbnailImage.size.height as AnyObject]
                        self.sendMessageWithProperties(properties: properties)
                    })
                }
            }
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            if let progress = snapshot.progress?.completedUnitCount, let total = snapshot.progress?.totalUnitCount{

                var percentage = 0
                if total != 0 {
                    let value = Double(progress) / Double(total)
                    percentage = Int(value * 100)
                }
                
                self.navigationItem.title = "Progress \(percentage)%"
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: AnyObject]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if let error = error {
                    print(error)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                }
            })
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        
        cell.message = message
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 30
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let chatCell = cell as? ChatMessageCell {
            chatCell.stopPlaying()
        }
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        guard let username = self.user?.name else { return }
        cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: self.user?.profileImageUrl, username: username)
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            //blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
        } else {
            //gray
            cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.image = nil
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
        } else {
            cell.messageImageView.isHidden = true
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func handleSend() {
        let properies: [String: AnyObject] = ["text" : inputContainerView.inputTextField.text! as AnyObject]
        sendMessageWithProperties(properties: properies)
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        let properies: [String: AnyObject] = ["imageUrl" : imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight" : image.size.height as AnyObject]
        sendMessageWithProperties(properties: properies)
    }
    
    private func sendMessageWithProperties(properties: [String : AnyObject]) {
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let toId = user!.id!
        let fromId = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        var values: [String: AnyObject] = ["toId" : toId as AnyObject, "fromId" : fromId as AnyObject, "timestamp" : timestamp]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if let error = error {
                print(error)
                return
            }
            
            self.inputContainerView.inputTextField.text = ""
            self.inputContainerView.enableDisableSendButton()
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId : 1])
            
            let lastMessageRef = FIRDatabase.database().reference().child("last-messages").child(fromId).child(toId)
            lastMessageRef.setValue([messageId : 1])
            
            let recepientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId).child(fromId)
            recepientUserMessagesRef.updateChildValues([messageId : 1])
            
            let recepientUserLastMessagesRef = FIRDatabase.database().reference().child("last-messages").child(toId).child(fromId)
            recepientUserLastMessagesRef.setValue([messageId : 1])
        }
    }    
    
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    func performZoomInForStartingImageView(startingImageView: UIImageView) {
        dismissKeyboard()
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = .black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                guard let startingFrame = self.startingFrame else { return }
                
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = startingFrame.height / startingFrame.width * keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                 guard let startingFrame = self.startingFrame else { return }
                
                zoomOutImageView.frame = startingFrame
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed) in
                self.startingImageView?.isHidden = false
                zoomOutImageView.removeFromSuperview()
            })
            
        }
    }
    
    
    func saveCellPlayingMedia(cell: ChatMessageCell) {
        if let cellPlayingMultimedia = cellPlayingMultimedia {
            cellPlayingMultimedia.stopPlaying()
        }
        
        cellPlayingMultimedia = cell
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cellPlayingMultimedia?.stopPlaying()
    }
    
    private func reportUser() {
        let ref = FIRDatabase.database().reference().child("user-reports")
        let childRef = ref.childByAutoId()
        let reportedUser = user!.id!
        let userWhoReported = FIRAuth.auth()!.currentUser!.uid
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        let values: [String: AnyObject] = ["userReported" : reportedUser as AnyObject, "whoReported" : userWhoReported as AnyObject, "timestamp" : timestamp]

        childRef.updateChildValues(values) { (error, ref) in
            
            if let error = error {
                print(error)
                AlertHelper.displayAlert(title: "Report User", message: "Unable to report user. Plese try again later.", displayTo: self)
                return
            }
            
            AlertHelper.displayAlert(title: "Report User", message: "User reported. A moderator will look at this report and act accordingly.", displayTo: self)
        }
    }
    
    private func blockUser() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else { AlertHelper.displayAlert(title: "Block User", message: "Unable to block user. Plese try again later.", displayTo: self); return }
        guard let block_uid = user?.id else { AlertHelper.displayAlert(title: "Block User", message: "Unable to block user. Plese try again later.", displayTo: self); return }
        
        
        let ref = FIRDatabase.database().reference().child("users").child(uid).child("blocked_users")
        
        ref.updateChildValues([block_uid : 1]) { (error, ref) in
            
            if let error = error {
                print(error)
                AlertHelper.displayAlert(title: "Block User", message: "Unable to block user. Plese try again later.", displayTo: self)
                return
            }
            
            let ref_blocked = FIRDatabase.database().reference().child("users").child(block_uid).child("blocked_by")
            ref_blocked.updateChildValues([uid : 1]) { (error, ref) in
                
                if let error = error {
                    print(error)
                    AlertHelper.displayAlert(title: "Block User", message: "Unable to block user. Plese try again later.", displayTo: self)
                    return
                }
                
                AlertHelper.displayAlert(title: "Block User", message: "User is blocked and will no longer be visible.", displayTo: self, completion: { (action) in
                    _ = self.navigationController?.popViewController(animated: true)
                })
                
            }
        }
    }
}










