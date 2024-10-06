//
//  MadrassahModel.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class MadrassahModel: ObservableObject {
    @Published var classes: [Class] = []
    
    @Published var classesListener: ListenerRegistration?
    
    private let classesPath = Firestore.firestore().collection("madrassah").document("classes").collection("classes")
    private let membersPath = Firestore.firestore().collection("madrassah").document("members").collection("members")
    
    @Published var user: User?
    @Published var madrassahUser: Member?
    
    @Published var userStateListener: NSObjectProtocol?
    @Published var userDocumentListener: ListenerRegistration?
    @Published var madrassahUserDocumentListener: ListenerRegistration?
    
    @Published var teacherProfiles: [UserProfile] = []
    
    @Published var error: String = ""
    @Published var loading: Bool = false
    
    func listenForUserStateChange() {
        self.loading = true
        
        self.userStateListener = Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            
            self.listenForUserDocumentChange()
        }
    }
    
    private func listenForUserDocumentChange() {
        if let user = user {
            self.userDocumentListener = Firestore.firestore().collection("users").document(user.uid).addSnapshotListener { documentSnapshot, error in
                if error != nil {
                    self.loading = false
                    return
                }
                
                if let document = documentSnapshot, let madrassahId = document.data()?["madrassahId"] as? String {
                    self.listenForMadrassahUserDocumentChange(madrassahId: madrassahId)
                } else {
                    self.loading = false
                }
            }
        } else {
            self.loading = false
        }
    }
    
    private func listenForMadrassahUserDocumentChange(madrassahId: String) {
        self.madrassahUserDocumentListener = membersPath.document(madrassahId).addSnapshotListener { snapshot, error in
            if error != nil {
                self.loading = false
                return
            }
            
            if let snapshot = snapshot {
                do {
                    self.madrassahUser = try snapshot.data(as: Member.self)
                    
                    self.listenForClasses()
                } catch {
                    self.loading = false
                }
            } else {
                self.loading = false
            }
        }
    }
    
    func linkMadrassahAccount(madrassahId: String) {
        self.loading = true
        
        if let user = user {
            if madrassahId == "" {
                self.error = "This Madrassah account does not exist."
                self.loading = false
            } else {
                self.membersPath.document(madrassahId).getDocument { snapshot, error in
                    if error != nil {
                        self.error = "There was a problem trying to link your account."
                        self.loading = false
                        
                        return
                    }
                    
                    if let snapshot = snapshot {
                        if snapshot.exists {
                            if snapshot.data()?["user"] as? String == nil {
                                Firestore.firestore().collection("users").document(user.uid).updateData(["madrassahId" : madrassahId])
                                
                                self.membersPath.document(madrassahId).updateData(["user" : user.uid])
                                
                                self.error = ""
                                self.loading = false
                            } else {
                                self.error = "This Madrassah account is already linked to another account."
                                self.loading = false
                            }
                        } else {
                            self.error = "This Madrassah account does not exist."
                            self.loading = false
                        }
                    } else {
                        self.error = "There was a problem trying to link your account."
                        self.loading = false
                    }
                }
            }
        } else {
            self.error = "You need to be logged in to link to a Madrassah account."
            self.loading = false
        }
    }
    
    private func listenForClasses() {
        self.classesListener = classesPath.addSnapshotListener { snapshot, error in
            if error != nil {
                return
            }
            
            if let snapshot = snapshot {
                var classes: [Class] = []
                
                for change in snapshot.documentChanges {
                    if change.type == .added {
                        do {
                            let mClass = try change.document.data(as: Class.self)
                            
                            classes.append(mClass)
                        } catch {
                            
                        }
                    } else if change.type == .removed {
                        let mClassId = change.document.documentID
                        
                        DispatchQueue.main.async {
                            self.classes.removeAll { $0.id == mClassId }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.classes += classes
                }
            }
        }
    }
    
    func addClass(year: Int?, gender: String, teacherIds: [String], completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        if let year = year {
            getStudents(inYear: year, gender: gender) { studentIds in
                let mClass = Class(year: year, gender: gender, teacherIds: teacherIds, studentIds: studentIds)
                
                do {
                    try self.classesPath.addDocument(from: mClass) { error in
                        if error != nil {
                            self.error = "There was an error trying to add the class."
                            self.loading = false
                            return
                        }
                        
                        self.error = ""
                        self.loading = false
                        completion(true)
                    }
                } catch {
                    self.error = "There was an error trying to add the class."
                    self.loading = false
                }
            }
        } else {
            self.error = "You must choose a year for the class."
            self.loading = false
        }
    }
    
    private func getStudents(inYear year: Int, gender: String, completion: @escaping ([String]) -> Void) {
        let studentGender = gender == "B" ? ["male"] : gender == "G" ? ["female"] : ["male", "female"]
        
        membersPath.whereField("year", isEqualTo: year).whereField("gender", in: studentGender).getDocuments { snapshot, error in
            if error != nil {
                self.error = "There was an error trying to add the class."
                self.loading = false
                return
            }
            
            if let snapshot = snapshot {
                let studentIds = snapshot.documents.map { document in
                    return document.documentID
                }
                
                completion(studentIds)
            } else {
                self.error = "There was an error trying to add the class."
                self.loading = false
            }
        }
    }
    
    func getTeachers() {
        self.teacherProfiles = []
        
        membersPath.whereField("isTeacher", isEqualTo: true).getDocuments { snapshot, error in
            if let error = error {
                print(error)
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    self.fetchUserProfile(madrassahId: document.documentID) { userProfile in
                        DispatchQueue.main.async {
                            self.teacherProfiles.append(userProfile)
                        }
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
    
    func reset() {
        self.classes = []
        self.user = nil
        self.madrassahUser = nil
        
        self.classesListener = nil
        self.userStateListener = nil
        self.userDocumentListener = nil
        self.madrassahUserDocumentListener = nil
    }
}
