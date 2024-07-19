//
//  AuthenticationModel.swift
//  Quran
//
//  Created by Ali Earp on 30/06/2024.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import PhotosUI
import SwiftUI

class AuthenticationModel: ObservableObject {
    @Published var user: User?
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var username: String = ""
    
    @Published var photoItem: PhotosPickerItem?
    @Published var photoImage: UIImage?
    
    @Published var error: String = ""
    
    @Published var loading: Bool = false
    
    init() {
        self.user = Auth.auth().currentUser
        
        if let username = user?.displayName {
            self.username = username
        }
    }
    
    func createAccount() {
        self.loading = true
        
        if emailIsValid() && passwordIsValid() && usernameIsValid() && photoIsValid() {
            Auth.auth().createUser(withEmail: email, password: password) { authDataResult, error in
                if let error = error {
                    print(error)
                    self.error = "The email or password is incorrect."
                    self.loading = false
                    
                    return
                }
                
                if let user = authDataResult?.user {
                    if let photoImageData = self.photoImage?.jpegData(compressionQuality: 1.0) {
                        let reference = Storage.storage().reference().child("users").child(user.uid)
                        
                        reference.putData(photoImageData) { _, error in
                            if let error = error {
                                print(error)
                                self.error = error.localizedDescription
                                self.loading = false
                                
                                return
                            }
                            
                            reference.downloadURL { photoURL, error in
                                if let error = error {
                                    print(error)
                                    self.error = error.localizedDescription
                                    self.loading = false
                                    
                                    return
                                }
                                
                                guard let photoURL = photoURL else {
                                    self.loading = false
                                    
                                    return
                                }
                                
                                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                                changeRequest?.displayName = self.username
                                changeRequest?.photoURL = photoURL
                                
                                changeRequest?.commitChanges { error in
                                    if let error = error {
                                        print(error)
                                        self.error = error.localizedDescription
                                        self.loading = false
                                        
                                        return
                                    }
                                    
                                    Firestore.firestore().collection("users").document(user.uid).setData([
                                        "username" : self.username
                                    ])
                                    
                                    self.user = user
                                    self.loading = false
                                }
                            }
                        }
                    } else {
                        self.loading = false
                    }
                } else {
                    self.loading = false
                }
            }
        } else {
            self.loading = false
        }
    }
    
    func signIn() {
        self.loading = true
        
        if emailIsValid() && passwordIsValid() {
            Auth.auth().signIn(withEmail: email, password: password) { authDataResult, error in
                if let error = error {
                    print(error)
                    self.error = "The email or password is incorrect."
                    self.loading = false
                    
                    return
                }
                
                self.user = authDataResult?.user
                self.loading = false
            }
        } else {
            self.loading = false
        }
    }
    
    func signOut() {
        self.loading = true
        
        do {
            try Auth.auth().signOut()
            self.user = Auth.auth().currentUser
            self.loading = false
        } catch {
            print(error)
            self.error = error.localizedDescription
            self.loading = false
        }
    }

    func updatePhoto() {
        self.loading = true
        
        if let photoImageData = photoImage?.jpegData(compressionQuality: 1.0), let uid = user?.uid {
            let reference = Storage.storage().reference().child("users").child(uid)
                        
            reference.putData(photoImageData) { _, error in
                if let error = error {
                    print(error)
                    self.error = error.localizedDescription
                    self.loading = false
                    
                    return
                }
                
                reference.downloadURL { photoURL, error in
                    if let error = error {
                        print(error)
                        self.error = error.localizedDescription
                        self.loading = false
                        
                        return
                    }
                    
                    guard let photoURL = photoURL else {
                        self.loading = false
                        
                        return
                    }
                    
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.photoURL = photoURL
                    
                    changeRequest?.commitChanges { error in
                        if let error = error {
                            print(error)
                            self.error = error.localizedDescription
                            self.loading = false
                            
                            return
                        }
                        
                        self.user = Auth.auth().currentUser
                        self.photoItem = nil
                        self.photoImage = nil
                        self.loading = false
                    }
                }
            }
        } else {
            self.loading = false
        }
    }
    
    func updateUsername() {
        self.loading = true
        
        if let uid = user?.uid, username != user?.displayName {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = self.username
            
            changeRequest?.commitChanges { error in
                if let error = error {
                    print(error)
                    self.error = error.localizedDescription
                    self.loading = false
                    
                    return
                }
                
                Firestore.firestore().collection("users").document(uid).setData([
                    "username" : self.username
                ])
                
                self.user = Auth.auth().currentUser
                self.username = self.user?.displayName ?? ""
                self.loading = false
            }
        } else {
            self.loading = false
        }
    }
    
    func resetFields() {
        self.email = ""
        self.password = ""
        self.username = user?.displayName ?? ""
        self.photoItem = nil
        self.photoImage = nil
        self.error = ""
    }
    
    private func emailIsValid() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            self.error = "Email is not a valid email address."
            return false
        }
        
        self.error = ""
        return true
    }
    
    private func passwordIsValid() -> Bool {
        if password.count < 8 {
            self.error = "Password must be at least 8 characters long."
            return false
        }
        
        if !password.containsUppercase() {
            self.error = "Password must contain at least one uppercase character."
            return false
        }
        
        if !password.containsLowercase() {
            self.error = "Password must contain at least one lowercase character."
            return false
        }
        
        if !password.containsNumber() {
            self.error = "Password must contain at least one number."
            return false
        }
        
        if !password.containsSpecial() {
            self.error = "Password must contain at least one special character."
            return false
        }
        
        self.error = ""
        return true
    }
    
    private func usernameIsValid() -> Bool {
        if username.count < 3 {
            self.error = "Username must be at least 3 characters long."
            return false
        }
        
        self.error = ""
        return true
    }
    
    private func photoIsValid() -> Bool {
        if photoImage == nil {
            self.error = "You must choose a profile photo."
            return false
        }
        
        self.error = ""
        return true
    }
    
}

extension String {
    func containsUppercase() -> Bool {
        let uppercaseRegex  = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format:"SELF MATCHES %@", uppercaseRegex)
        return uppercasePredicate.evaluate(with: self)
    }
    
    func containsLowercase() -> Bool {
        let lowercaseRegex  = ".*[A-Z]+.*"
        let lowercasePredicate = NSPredicate(format:"SELF MATCHES %@", lowercaseRegex)
        return lowercasePredicate.evaluate(with: self)
    }
    
    func containsNumber() -> Bool {
        let numberRegex  = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format:"SELF MATCHES %@", numberRegex)
        return numberPredicate.evaluate(with: self)
    }
    
    func containsSpecial() -> Bool {
        let specialRegex  = ".*[!&^%$#@()/]+.*"
        let specialPredicate = NSPredicate(format:"SELF MATCHES %@", specialRegex)
        return specialPredicate.evaluate(with: self)
    }
}
