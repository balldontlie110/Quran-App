//
//  SettingsView.swift
//  Quran
//
//  Created by Ali Earp on 30/06/2024.
//

import SwiftUI
import FirebaseAuth
import PhotosUI
import SDWebImageSwiftUI

struct SettingsView: View {
    @StateObject private var authenticationModel: AuthenticationModel = AuthenticationModel()
    
    @State private var createAccountMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if authenticationModel.user != nil {
                        accountOptions
                    } else {
                        loginOptions
                    }
                }.padding()
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Settings")
        }
        .onChange(of: authenticationModel.user) { _, _ in
            authenticationModel.resetFields()
        }
    }
    
    private var accountOptions: some View {
        Group {
            if let user = authenticationModel.user {
                if let photoURL = user.photoURL {
                    WebImage(url: photoURL)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .overlay { Circle().stroke(lineWidth: 2.5) }
                        .frame(width: 150, height: 150)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                        .frame(height: 25)
                }
                
                if let username = user.displayName {
                    Text(username)
                        .font(.system(.title, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                        .frame(height: 25)
                }
                
                Button {
                    authenticationModel.signOut()
                } label: {
                    Text("Sign Out")
                        .bold()
                        .foregroundStyle(Color.red)
                }.buttonStyle(BorderedButtonStyle())
            }
        }
    }
    
    private var loginOptions: some View {
        Group {
            Picker("", selection: $createAccountMode) {
                Text("Sign In")
                    .tag(false)
                
                Text("Create Account")
                    .tag(true)
            }.pickerStyle(.segmented)
            
            if createAccountMode {
                Spacer()
                    .frame(height: 25)
                
                PhotosPicker(selection: $authenticationModel.photoItem, matching: .images) {
                    Group {
                        if let photoImage = authenticationModel.photoImage {
                            Image(uiImage: photoImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person")
                                .resizable()
                                .scaledToFill()
                                .padding(50)
                        }
                    }
                    .clipShape(Circle())
                    .overlay { Circle().stroke(lineWidth: 2.5) }
                    .frame(width: 150, height: 150)
                    .foregroundStyle(Color.primary)
                }.onChange(of: authenticationModel.photoItem) { _, _ in
                    Task {
                        if let data = try await authenticationModel.photoItem?.loadTransferable(type: Data.self) {
                            authenticationModel.photoImage = UIImage(data: data)
                        }
                    }
                }
            }
            
            Spacer()
                .frame(height: 25)
            
            TextField("Email", text: $authenticationModel.email)
                .padding(10)
                .background(Color.primary.colorInvert())
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $authenticationModel.password)
                .padding(10)
                .background(Color.primary.colorInvert())
                .clipShape(RoundedRectangle(cornerRadius: 5))
            
            if createAccountMode {
                Spacer()
                    .frame(height: 25)
                
                TextField("Username", text: $authenticationModel.username)
                    .padding(10)
                    .background(Color.primary.colorInvert())
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            Spacer()
                .frame(height: 25)
            
            Button {
                if createAccountMode {
                    authenticationModel.createAccount()
                } else {
                    authenticationModel.signIn()
                }
            } label: {
                Text(createAccountMode ? "Create Account" : "Sign In")
                    .bold()
            }.buttonStyle(BorderedButtonStyle())
            
            Spacer()
                .frame(height: 25)
            
            Text(authenticationModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
        }
    }
}

#Preview {
    SettingsView()
}
