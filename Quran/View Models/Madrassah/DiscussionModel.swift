//
//  DiscussionModel.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import SwiftUI

class DiscussionModel: ObservableObject {
    let mClass: Class
    let madrassahUser: Member
    
    @Published var messages: [Message] = []
    @Published var userProfiles: [UserProfile] = []
    
    @Published var messagesListener: ListenerRegistration?
    
    @Published var message: String = ""
    @Published var images: [UIImage] = []
    
    private var discussionCollection: CollectionReference? {
        if let classId = mClass.id {
            return Firestore.firestore().collection("madrassah").document("classes").collection("classes").document(classId).collection("discussion")
        }
        
        return nil
    }
    
    private var discussionReference: StorageReference? {
        if let classId = mClass.id {
            return Storage.storage().reference().child("madrassah").child("classes").child(classId).child("discussion")
        }
        
        return nil
    }
    
    init(mClass: Class, madrassahUser: Member) {
        self.mClass = mClass
        self.madrassahUser = madrassahUser
        
        fetchMessages()
    }
    
    func fetchMessages() {
        if let discussionCollection = discussionCollection {
            self.messagesListener = discussionCollection.addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let snapshot = snapshot {
                    var messages: [Message] = []
                    
                    for change in snapshot.documentChanges {
                        if change.type == .added {
                            do {
                                let message = try change.document.data(as: Message.self)
                                
                                messages.append(message)
                                
                                self.fetchUserProfile(madrassahId: message.from) { userProfile in
                                    if !self.userProfiles.contains(where: { $0.id == userProfile.id }) {
                                        DispatchQueue.main.async {
                                            self.userProfiles.append(userProfile)
                                        }
                                    }
                                }
                            } catch {
                                
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.messages += messages
                    }
                }
            }
        }
    }
    
    private func fetchUserProfile(madrassahId: String, completion: @escaping (UserProfile) -> Void) {
        Firestore.firestore().collection("madrassah").document("members").collection("members").document(madrassahId).getDocument { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            
            if let snapshot = snapshot {
                if let uid = snapshot.data()?["user"] as? String {
                    Firestore.firestore().collection("users").document(uid).getDocument { userSnapshot, error in
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        if let userSnapshot = userSnapshot {
                            let username = userSnapshot.data()?["username"] as? String ?? ""
                            
                            Storage.storage().reference().child("users").child(uid).downloadURL { url, error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                if let url = url {
                                    let userProfile = UserProfile(id: madrassahId, username: username, photoURL: url)
                                    
                                    completion(userProfile)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func uploadImages(images: [UIImage], documentId: String, completion: @escaping ([String]) -> Void) {
        if let discussionReference = discussionReference {
            let group = DispatchGroup()
            
            var imageIds: [String] = []
            
            for image in images {
                group.enter()
                
                if let data = image.jpegData(compressionQuality: 1.0) {
                    let imageId = UUID().uuidString
                    
                    discussionReference.child(documentId).child(imageId).putData(data) { metadata, error in
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        imageIds.append(imageId)
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(imageIds)
            }
        }
    }
    
    private func getDownloadURLs(imageIds: [String], documentId: String, completion: @escaping ([String]) -> Void) {
        if let discussionReference = discussionReference {
            let group = DispatchGroup()
            
            var photoURLs: [String] = []
            
            for imageId in imageIds {
                group.enter()
                
                discussionReference.child(documentId).child(imageId).downloadURL { url, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    if let url = url {
                        photoURLs.append(url.absoluteString)
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(photoURLs)
            }
        }
    }
    
    func sendMessage() {
        let message = message
        let images = images
        
        self.message = ""
        self.images = []
        
        if (!message.isEmpty || !images.isEmpty), let madrassahId = madrassahUser.id, let discussionCollection = discussionCollection {
            if !images.isEmpty {
                let document = discussionCollection.document()
                
                self.uploadImages(images: images, documentId: document.documentID) { imageIds in
                    self.getDownloadURLs(imageIds: imageIds, documentId: document.documentID) { photoURLs in
                        let message = Message(message: message, photoURLs: photoURLs, from: madrassahId, timestamp: Timestamp())
                        
                        do {
                            try document.setData(from: message) { error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            } else {
                let message = Message(message: message, photoURLs: [], from: madrassahId, timestamp: Timestamp())
                
                do {
                    try discussionCollection.addDocument(from: message) { error in
                        if let error = error {
                            print(error)
                            return
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}
