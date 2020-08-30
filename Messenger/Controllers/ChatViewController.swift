//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 24/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Message: MessageType {
    public var sender: SenderType
    
    public var messageId: String
    
    public var sentDate: Date
    
    public var kind: MessageKind
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "custom"
        }
    }
    
}

struct Sender: SenderType {
    
    public var photoURL: String
    public var senderId: String
    public var displayName: String
    
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    
}


class ChatViewController: MessagesViewController {
    
    public static let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        
        return formatter
    }()
    
    public let otherUserEmail: String
    private let conversationId: String?
    public var isNewConversation = false
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
        
        
        
    }
    
    
    init(with email: String, id: String?) {
        self.conversationId = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
        
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self](_) in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {  _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "What would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "What would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] (result) in
            switch result {
            case .success(let messages):
                print("succes in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                    
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
            let conversationId = conversationId,
            let name = self.title,
            let selfSender = selfSender else {
                return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            // Upload image
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName) { [weak self] (result) in
                
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { (success) in
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            }
            
        } else if let videoUrl = info[.mediaURL] as? URL  {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName) { [weak self] (result) in
                
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print("Uploaded message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else {
                            return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message) { (success) in
                        if success {
                            print("sent video message")
                        } else {
                            print("failed to send video message")
                        }
                    }
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            }
        }
        
        
        
        
    }
}


extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageId()
            else {
                return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        
        // Send Message
        if isNewConversation {
            // create convo in database
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message) { [weak self] (success) in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                } else {
                    print("failed to send")
                }
            }
        } else {
            
            guard let conversationId = conversationId, let name = self.title else { return  }
            // append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail , name: name ,newMessage: message) { (success) in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        //date, otherUserEmail, senderEmail, randomInt
        
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAdress: currentUserEmail)
        
        let dateString = Self.dataFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("Created message id: \(newIdentifier)")
        return newIdentifier
    }
    
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
        
    }
    
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return  }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
        
    }
    
    
    
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else { return  }
            let vc = PhotoViwerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
