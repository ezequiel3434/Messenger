//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 23/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAdress: String) -> String{
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    
}

//MARK: - Account Management
extension DatabaseManager {
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
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
