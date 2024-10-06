//
//  ReauthenticateView.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import SwiftUI

struct ReauthenticateView: View {
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    
    @State private var email: String = ""
    
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    
    @State private var success: Bool = false
    
    enum ReauthenticateAction {
        case updateEmail, updatePassword, deleteAccount
    }
    
    @Binding var reauthenticationAction: ReauthenticateAction?
    
    private enum FocusedField {
        case email, password
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack {
            reauthenticationMessage
            
            emailField
            passwordField
            
            errorMessage
            
            Spacer()
            
            if authenticationModel.loading {
                ProgressView()
            }
            
            Spacer()
            
            continueButton
        }
        .padding()
        .navigationDestination(isPresented: $success) {
            if reauthenticationAction == .updateEmail {
                UpdateEmailView(reauthenticationAction: $reauthenticationAction)
            } else if reauthenticationAction == .updatePassword {
                UpdatePasswordView(reauthenticationAction: $reauthenticationAction)
            } else if reauthenticationAction == .deleteAccount {
                DeleteAccountView(reauthenticationAction: $reauthenticationAction)
            }
        }
        .onAppear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            self.focusedField = .email
        }
        .onDisappear {
            authenticationModel.error = ""
            authenticationModel.loading = false
        }
    }
    
    private var reauthenticationMessage: some View {
        Group {
            if reauthenticationAction == .updateEmail {
                Text("In order to update your Email, we first need to verify that it's really you")
            } else if reauthenticationAction == .updatePassword {
                Text("In order to update your password, we first need to verify that it's really you")
            } else if reauthenticationAction == .deleteAccount {
                Text("In order to delete your account, we first need to verify that it's really you")
            }
        }
        .font(.system(.title3, weight: .bold))
        .multilineTextAlignment(.center)
        .padding(.bottom)
    }
    
    private var emailField: some View {
        TextField("Email", text: $email)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .focused($focusedField, equals: .email)
            .onSubmit {
                focusedField = .password
            }
    }

    private var passwordField: some View {
        HStack {
            if showPassword {
                TextField("Password", text: $password)
            } else {
                SecureField("Password", text: $password)
            }
            
            Spacer()
            
            Button {
                self.showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(Color.secondary)
            }

        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .focused($focusedField, equals: .password)
    }
    
    private var continueButton: some View {
        Button {
            authenticationModel.reauthenticate(withEmail: email, password: password) { success in
                self.success = success
            }
        } label: {
            Text("Continue")
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if authenticationModel.error != "" {
            Text(authenticationModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.top, 5)
        }
    }
}

#Preview {
    ReauthenticateView(reauthenticationAction: .constant(.updateEmail))
}
