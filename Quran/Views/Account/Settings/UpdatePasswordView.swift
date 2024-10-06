//
//  UpdatePasswordView.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import SwiftUI

struct UpdatePasswordView: View {
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var showPassword: Bool = false
    
    @Binding var reauthenticationAction: ReauthenticateView.ReauthenticateAction?
    
    private enum FocusedField {
        case password, confirmPassword
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack {
            reauthenticationMessage
            
            passwordField
            confirmPasswordField
            
            errorMessage
            
            Spacer()
            
            updatePasswordButton
        }
        .padding()
        .onAppear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            self.focusedField = .password
        }
        .onDisappear {
            authenticationModel.error = ""
            authenticationModel.loading = false
        }
    }
    
    private var reauthenticationMessage: some View {
        Text("Please enter your new password")
            .font(.system(.title3, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.bottom)
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
        .onSubmit {
            focusedField = .confirmPassword
        }
    }
    
    private var confirmPasswordField: some View {
        HStack {
            if showPassword {
                TextField("Confirm Password", text: $confirmPassword)
            } else {
                SecureField("Confirm Password", text: $confirmPassword)
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
        .focused($focusedField, equals: .confirmPassword)
    }
    
    private var updatePasswordButton: some View {
        Button {
            authenticationModel.updatePassword(withPassword: password, confirmPassword: confirmPassword) { success in
                if success {
                    reauthenticationAction = nil
                }
            }
        } label: {
            Text("Update Password")
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
    UpdatePasswordView(reauthenticationAction: .constant(.updatePassword))
}
