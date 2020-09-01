//
//  AppDelegate.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 22/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//



import UIKit
import FBSDKCoreKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    func application( _ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application( application, didFinishLaunchingWithOptions: launchOptions )
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
        
    }
    
    func application( _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        ApplicationDelegate.shared.application( app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                annotation: options[UIApplication.OpenURLOptionsKey.annotation] )
        
        return GIDSignIn.sharedInstance().handle(url)
    }
    
}

// MARK: - GIDSignInDelegate

extension AppDelegate: GIDSignInDelegate {
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error)")
            }
            
            return
        }
        if let user = user {
            print("Did sign in with Google: \(user)")
        }
        
        
        guard let email = user.profile.email,
            let firstName = user.profile.givenName,
            let lastName = user.profile.familyName
            else {
                return
        }
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        
        DatabaseManager.shared.userExists(with: email) { (exists) in
            if !exists {
                print("No Existe: \(exists)")
                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                
                
                // insert to database
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        // Upload image
                        
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                guard let data = data else {
                                    return
                                }
                                
                                
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { (result) in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage mangager error: \(error)")
                                    }
                                }
                            }.resume()
                        }
                        
                        
                        
                        
                    }
                })
            } else {
                print("Existe: \(exists)")
            }
        }
        
        guard let authentication = user.authentication else {
            print("Missing auth object off of google user")
            return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        FirebaseAuth.Auth.auth().signIn(with: credential) { (authResult, error) in
            guard authResult != nil, error == nil else {
                print("failed to log in with google credential")
                return
            }
            
            print("Saccessfully signed in with Google credential")
            
            NotificationCenter.default.post(name: .didLoginNotification, object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        
        print("Google user was disconnected")
    }
    
    
    
}
