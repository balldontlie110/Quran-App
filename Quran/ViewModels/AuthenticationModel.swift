//
//  AuthenticationModel.swift
//  Quran
//
//  Created by Ali Earp on 30/06/2024.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
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
    
    init() {
        self.user = Auth.auth().currentUser
    }
    
    func createAccount() {
        if emailIsValid() && passwordIsValid() && usernameIsValid() && photoIsValid() {
            Auth.auth().createUser(withEmail: email, password: password) { authDataResult, error in
                if let error = error {
                    print(error)
                    self.error = error.localizedDescription
                    
                    return
                }
                
                if let user = authDataResult?.user, let photoImageData = self.photoImage?.jpegData(compressionQuality: 1.0) {
                    let reference = Storage.storage().reference().child("users").child(user.uid)
                    
                    reference.putData(photoImageData) { _, error in
                        if let error = error {
                            print(error)
                            self.error = error.localizedDescription
                            
                            return
                        }
                        
                        reference.downloadURL { photoURL, error in
                            if let error = error {
                                print(error)
                                self.error = error.localizedDescription
                            }
                            
                            guard let photoURL = photoURL else { return }
                            
                            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                            changeRequest?.displayName = self.username
                            changeRequest?.photoURL = photoURL
                            
                            changeRequest?.commitChanges { error in
                                if let error = error {
                                    print(error)
                                    self.error = error.localizedDescription
                                    
                                    return
                                }
                                
                                self.user = user
                            }
                        }
                    }
                }
            }
        }
    }
    
    func signIn() {
        if emailIsValid() && passwordIsValid() {
            Auth.auth().signIn(withEmail: email, password: password) { authDataResult, error in
                if let error = error {
                    print(error)
                    self.error = error.localizedDescription
                    
                    return
                }
                
                self.user = authDataResult?.user
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = Auth.auth().currentUser
            self.error = ""
        } catch {
            print(error)
            self.error = error.localizedDescription
        }
    }
    
    func resetFields() {
        self.email = ""
        self.password = ""
        self.username = ""
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
