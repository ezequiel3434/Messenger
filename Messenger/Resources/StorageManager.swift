//
//  StorageManager.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 24/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation
import FirebaseStorage
/// Allows you to get, fetch and upload files to firebase storage
final class StorageManager {
    static let shared = StorageManager()
    
    private init(){}
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> ()
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (UploadPictureCompletion)){
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to download URL")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToDownloadURL
    }
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> ()){
        let reference = storage.child(path)
        reference.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToDownloadURL))
                return
            }
            
            completion(.success(url))
        }
    }
    
    /// Uploads image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping (UploadPictureCompletion)){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to download URL")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    /// Uploads video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping (UploadPictureCompletion)){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil) { [weak self] (metadata, error) in
            guard error == nil else {
                //failed
                print("failed to upload video to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to download URL")
                    completion(.failure(StorageErrors.failedToDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }
    
    
}
