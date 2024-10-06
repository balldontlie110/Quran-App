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
import PhotosUI
import SwiftUI
import SwiftSMTP

class AuthenticationModel: ObservableObject {
    @Published var user: User?
    @Published var userStateListener: NSObjectProtocol?
    
    @Published var createAccountMode: Bool = false
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var username: String = ""
    
    @Published var photoItem: PhotosPickerItem?
    @Published var photoImage: UIImage?
    
    @Published var error: String = ""
    
    @Published var loading: Bool = false
    
    init() {
        listenForUserStateChange()
    }
    
    private func listenForUserStateChange() {
        self.userStateListener = Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            
            if let user = user {
                if let username = user.displayName {
                    self.username = username
                }
            } else {
                self.username = ""
            }
        }
    }
    
    func createAccountEmailVerification(completion: @escaping ([String], Bool) -> Void) {
        self.loading = true
        
        emailIsValid(email) { valid in
            if valid {
                if self.passwordIsValid(self.password) && self.usernameIsValid() && self.photoIsValid() {
                    self.sendEmailCode(withEmail: self.email, type: .verifyEmail) { success, code in
                        if success {
                            completion(code, success)
                        } else {
                            self.loading = false
                        }
                    }
                } else {
                    self.loading = false
                }
            } else {
                self.loading = false
            }
        }
    }
    
    func createAccount() {
        Auth.auth().createUser(withEmail: email, password: password) { authDataResult, error in
            if error != nil {
                self.error = "The email or password is incorrect."
                self.loading = false
                
                return
            }
            
            if let user = authDataResult?.user {
                if let photoImageData = self.photoImage?.jpegData(compressionQuality: 1.0) {
                    let reference = Storage.storage().reference().child("users").child(user.uid)
                    
                    reference.putData(photoImageData) { _, error in
                        if let error = error {
                            self.error = error.localizedDescription
                            self.loading = false
                            
                            return
                        }
                        
                        reference.downloadURL { photoURL, error in
                            if let error = error {
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
                                    self.error = error.localizedDescription
                                    self.loading = false
                                    
                                    return
                                }
                                
                                Firestore.firestore().collection("users").document(user.uid).setData([
                                    "username" : self.username
                                ])
                                
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
    }
    
    func signIn() {
        self.loading = true
        
        emailIsValid(email, checkExists: false) { valid in
            if valid {
                Auth.auth().signIn(withEmail: self.email, password: self.password) { authDataResult, error in
                    if error != nil {
                        self.error = "The email or password is incorrect."
                        self.loading = false
                        
                        return
                    }
                    
                    self.loading = false
                }
            } else {
                self.loading = false
            }
        }
    }
    
    func signOut() {
        self.loading = true
        
        do {
            try Auth.auth().signOut()
            
            self.loading = false
        } catch {
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
                    self.error = error.localizedDescription
                    self.loading = false
                    
                    return
                }
                
                reference.downloadURL { photoURL, error in
                    if let error = error {
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
                            self.error = error.localizedDescription
                            self.loading = false
                            
                            return
                        }
                        
                        self.photoItem = nil
                        self.photoImage = nil
                        self.error = ""
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
        
        if let uid = user?.uid, username != user?.displayName, usernameIsValid() {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = self.username
            
            changeRequest?.commitChanges { error in
                if let error = error {
                    self.error = error.localizedDescription
                    self.loading = false
                    
                    return
                }
                
                Firestore.firestore().collection("users").document(uid).setData([
                    "username" : self.username
                ])
                
                self.username = self.user?.displayName ?? ""
                self.error = ""
                self.loading = false
            }
        } else {
            self.loading = false
        }
    }
    
    func reauthenticate(withEmail email: String, password: String, completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        user?.reauthenticate(with: credential) { result, error in
            if error != nil {
                self.error = "The email or password is incorrect."
            } else {
                self.error = ""
            }
            
            self.loading = false
            completion(error == nil)
        }
    }
    
    enum SendEmailType {
        case verifyEmail, deleteAccount
    }
    
    func sendEmailCode(withEmail email: String, type: SendEmailType, completion: @escaping (Bool, [String]) -> Void) {
        self.loading = true
        
        emailIsValid(email, checkExists: type == .verifyEmail ? true : false) { valid in
            if valid {
                let code: [String] = (1...5).map({ _ in String(Int.random(in: 0...9)) })
                
                let smtp = SMTP(
                    hostname: "smtp.gmail.com",
                    email: "python786test@gmail.com",
                    password: "fpgf quuu yraq ihga"
                )
                
                let fromEmail = Mail.User(name: "Hyderi", email: "python786test@gmail.com")
                let toEmail = Mail.User(email: email)
                
                let htmlContent = Attachment(
                    htmlContent: """
                        <html>
                            <body style="font-family: Arial; text-align: center">
                                <img src="https://hyderi.org.uk/wp-content/uploads/2024/06/cropped-cropped-cropped-1-1.png" alt="Hyderi" style="width: 50%; height: auto;">
                    
                                <h1>
                                    \(type == .verifyEmail ? "Verify your email" : "Delete your account")
                                </h1>
                        
                                <p class="text-secondary">Thanks for helping us keep your account secure. Enter the code below to finish \(type == .verifyEmail ? "verifying your email address" : "deleting your account").</p>
                    
                                <div style="display: flex; justify-content: center; gap: 10px; width: 100%;">
                                    <div style="padding: 20px 20px; border: 1px solid #ccc; border-radius: 15px; text-align: center; background-color: #f0f0f0; font-weight: bold;">\(code[0])</div>
                                    <div style="padding: 20px 20px; border: 1px solid #ccc; border-radius: 15px; text-align: center; background-color: #f0f0f0; font-weight: bold;">\(code[1])</div>
                                    <div style="padding: 20px 20px; border: 1px solid #ccc; border-radius: 15px; text-align: center; background-color: #f0f0f0; font-weight: bold;">\(code[2])</div>
                                    <div style="padding: 20px 20px; border: 1px solid #ccc; border-radius: 15px; text-align: center; background-color: #f0f0f0; font-weight: bold;">\(code[3])</div>
                                    <div style="padding: 20px 20px; border: 1px solid #ccc; border-radius: 15px; text-align: center; background-color: #f0f0f0; font-weight: bold;">\(code[4])</div>
                                </div>
                    
                                <p class="text-secondary">If this wasn't you, you can ignore this email.</p>
                            </body>
                        </html>
                    """
                )
                
                let mail = Mail(
                    from: fromEmail,
                    to: [toEmail],
                    subject: type == .verifyEmail ? "Verify your email" : "Delete your account",
                    text: "",
                    attachments: [htmlContent]
                )
                
                smtp.send(mail) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            self.error = "Failed to send the \(type == .verifyEmail ? "verification" : "confirmation") email. Please try again."
                        } else {
                            self.error = "The \(type == .verifyEmail ? "verification" : "confirmation") email has been sent. If you didn't receive it, please try again."
                            completion(true, code)
                        }
                        
                        self.loading = false
                    }
                }
            } else {
                self.loading = false
            }
        }
    }
    
    func updateEmail(withEmail email: String, completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        user?.updateEmail(to: email) { error in
            if error != nil {
                self.error = "There was a problem trying to update your email."
            } else {
                self.error = ""
            }
            
            self.loading = false
            completion(error == nil)
        }
    }
    
    func updatePassword(withPassword password: String, confirmPassword: String, completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        if passwordIsValid(password) && password == confirmPassword {
            user?.updatePassword(to: password) { error in
                if error != nil {
                    self.error = "There was an error trying to change your password. Please try again."
                    self.loading = false
                } else {
                    self.error = ""
                }
                
                self.loading = false
                completion(error == nil)
            }
        } else {
            self.loading = false
        }
    }
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        self.loading = true
        
        if let user = user {
            user.delete { error in
                if error != nil {
                    self.error = "There was a problem trying to delete your account. Please try again."
                    self.loading = false
                } else {
                    Firestore.firestore().collection("users").document(user.uid).delete { _ in
                        Storage.storage().reference().child("users").child(user.uid).delete { _ in
                            self.error = ""
                            self.loading = false
                            
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func resetFields() {
        self.email = ""
        self.password = ""
        
        if let username = user?.displayName {
            self.username = username
        }
        
        self.photoItem = nil
        self.photoImage = nil
        self.error = ""
    }
    
    func emailIsValid(_ email: String, checkExists: Bool = true, completion: @escaping (Bool) -> Void) {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            self.error = "Email is not a valid email address."
            completion(false)
        } else {
            if checkExists {
                emailAlreadyInUse(email) { inUse in
                    if inUse {
                        self.error = "Email is already in use by another account."
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            } else {
                self.error = ""
                completion(true)
            }
        }
    }
    
    private func emailAlreadyInUse(_ email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email) { methods, error in
            if let methods = methods, !methods.isEmpty {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func passwordIsValid(_ password: String) -> Bool {
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
    
    func usernameIsValid() -> Bool {
        if username.count < 3 {
            self.error = "Username must be at least 3 characters long."
            return false
        }
        
        self.error = ""
        return true
    }
    
    func photoIsValid() -> Bool {
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
