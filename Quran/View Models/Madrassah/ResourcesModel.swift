//
//  ResourcesModel.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseStorage
import FirebaseFirestore

class ResourcesModel: ObservableObject {
    let mClass: Class
    let madrassahUser: Member
    
    @Published var resources: [Resource] = []
    @Published var resourcesListener: ListenerRegistration?
    
    @Published var userProfiles: [UserProfile] = []
    
    @Published var editMode: Bool = false
    @Published var selectedResources: [Resource] = []
    
    init(mClass: Class, madrassahUser: Member) {
        self.mClass = mClass
        self.madrassahUser = madrassahUser
        
        listenForResources()
    }
    
    private var storageReference: StorageReference? {
        if let classId = mClass.id {
            return Storage.storage().reference().child("madrassah").child("classes").child(classId).child("resources")
        }
        
        return nil
    }
    
    private var resourcesCollection: CollectionReference? {
        if let classId = mClass.id {
            return Firestore.firestore().collection("madrassah").document("classes").collection("classes").document(classId).collection("resources")
        }
        
        return nil
    }
    
    private func listenForResources() {
        if let resourcesCollection = resourcesCollection {
            self.resourcesListener = resourcesCollection.addSnapshotListener { snapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                if let snapshot = snapshot {
                    var resources: [Resource] = []
                    
                    for change in snapshot.documentChanges {
                        if change.type == .added {
                            do {
                                let resource = try change.document.data(as: Resource.self)
                                
                                resources.append(resource)
                                
                                self.fetchUserProfile(madrassahId: resource.uploadedBy) { userProfile in
                                    if !self.userProfiles.contains(where: { $0.id == userProfile.id }) {
                                        DispatchQueue.main.async {
                                            self.userProfiles.append(userProfile)
                                        }
                                    }
                                }
                            } catch {
                                print(error)
                            }
                        } else if change.type == .removed {
                            DispatchQueue.main.async {
                                self.resources.removeAll(where: { $0.id == change.document.documentID })
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.resources += resources
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
    
    func uploadResources(files: Result<[URL], any Error>) {
        switch files {
        case .success(let urls):
            if let resourcesCollection = resourcesCollection, let storageReference = storageReference, let madrassahId = madrassahUser.id {
                for url in urls {
                    if url.startAccessingSecurityScopedResource() {
                        do {
                            let data = try Data(contentsOf: url)
                            let document = resourcesCollection.document()
                            
                            storageReference.child(document.documentID).putData(data) { metadata, error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                storageReference.child(document.documentID).downloadURL { downloadURL, error in
                                    if let error = error {
                                        print(error)
                                        return
                                    }
                                    
                                    if let downloadURL = downloadURL {
                                        let resource = Resource(resourceName: url.lastPathComponent, uploadedBy: madrassahId, downloadURL: downloadURL.absoluteString, timestamp: Timestamp())
                                        
                                        do {
                                            try document.setData(from: resource) { error in
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
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        case .failure(let error):
            print(error)
        }
    }
    
    func deleteResources() {
        for resource in selectedResources {
            if let resourceId = resource.id {
                self.resourcesCollection?.document(resourceId).delete { error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    self.storageReference?.child(resourceId).delete { error in
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        self.editMode = false
                        self.selectedResources = []
                    }
                }
            }
        }
    }
}
