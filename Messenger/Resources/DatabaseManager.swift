//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 23/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAdress: String) -> String{
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> ()){
        self.database.child("\(path)").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}



//MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(true)
                return
            }
            
            completion(false)
        } )
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> ()) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ],withCompletionBlock: { error, _ in
                guard error == nil else {
                    print("Failed to write to database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value) { (snapshot) in
                    if var usersCollection = snapshot.value as? [[String: String]]{
                        // append to user dictionary
                        let newElement = [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                        
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                        
                        
                    } else {
                        // create that array
                        let newCollection: [[String: String]] = [
                            ["name": user.firstName + " " + user.lastName,
                             "email": user.safeEmail
                            ]
                        ]
                        
                        self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            completion(true)
                        })
                    }
                }
                
                
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> () ){
        database.child("users").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    
    
}

public enum DatabaseError: Error {
    case failedToFetch
}

//MARK: -Sending messages / conversations
extension DatabaseManager {
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> ()) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { [weak self](snapshot) in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dataFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            //update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] (snapshot) in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationId)
                } else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String:Any]] {
                // Conversation array exists for current user
                // you should append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] (error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
            } else {
                // conversation array does not exist
                // create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) { [weak self](error, _) in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                }
            }
        }
    }
    
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> ()) {
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dataFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        guard var myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        let collectionMessage: [String:Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        
        database.child("\(conversationID)").setValue(value) { (error, _) in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllCOnversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> ()){
        database.child("\(email)/conversations").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { (dictionary) in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else {
                        return nil
                }
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            
            completion(.success(conversations))
        }
    }
    
    /// Gets all messages for given conversation
    public func  getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> () ){
        database.child("\(id)/messages").observe(.value) { (snapshot) in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { (dictionary) in
                print(dictionary["date"])
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageID = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let date = ChatViewController.dataFormatter.date(from: dateString) else {
                        print("holanda")
                        return nil
                }
                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                    let placeholder = UIImage(systemName: "plus") else { return nil }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                 
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            }
            
            
            completion(.success(messages))
        }
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> ()){
        // add new message to messges
        // update sender latest message
        // update resipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            
            return }
        
        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] (snapshot) in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dataFormatter.string(from: messageDate)
            
            var message = ""
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                message = targetUrlString
                }
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            guard var myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil  else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    let updatedValue: [String:Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return}
                    
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // update latest message for recipient user
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (snapshot) in
                                           guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                               completion(false)
                                               return
                                           }
                                           
                                           let updatedValue: [String:Any] = [
                                               "date": dateString,
                                               "is_read": false,
                                               "message": message
                                           ]
                                           
                                           var targetConversation: [String: Any]?
                                           var position = 0
                                           
                                           for conversationDictionary in otherUserConversations {
                                               if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                                   targetConversation = conversationDictionary
                                                   
                                                   break
                                               }
                                               position += 1
                                           }
                                           targetConversation?["latest_message"] = updatedValue
                                           guard let finalConversation = targetConversation else {
                                               completion(false)
                                               return}
                                           
                                           otherUserConversations[position] = finalConversation
                                           strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { (error, _) in
                                               guard error == nil else {
                                                   completion(false)
                                                   return
                                               }
                                                completion(true)
                                           }
                                       }
                        
                        
                         
                    }
                }
               
            }
        }
    }
}


struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
    
    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
