//
//  StorageManager.swift
//  Messenger
//
//  Created by Ezequiel Parada Beltran on 24/08/2020.
//  Copyright © 2020 Ezequiel Parada. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> ()
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (UploadPictureCompletion)){
        storage.child("images/\(fileName)").putData(data, metadata: nil) { (metadata, error) in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
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
}
