//
//  DeleteAccountView.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    
    @Binding var reauthenticationAction: ReauthenticateView.ReauthenticateAction?
    
    @State private var realCode: [String] = []
    @State private var code: [String] = [String](repeating: "", count: 5)
    @State private var codeIncorrect: Bool = false

    @FocusState private var focusedDigit: Int?
    
    var body: some View {
        VStack {
            reauthenticationMessage
            
            Spacer()
            
            codeInputFields
            
            errorMessage
            
            Spacer()
            
            deleteAccountButton
        }
        .padding()
        .onAppear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            self.focusedDigit = 0
        }
        .onDisappear {
            authenticationModel.error = ""
            authenticationModel.loading = false
        }
    }
    
    private var reauthenticationMessage: some View {
        Text("Are you sure you want to delete your account?\n\nThis action cannot be undone.")
            .font(.system(.title3, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.bottom)
    }
    
    private var codeInputFields: some View {
        HStack {
            Spacer()
            
            ForEach(Array($code.enumerated()), id: \.offset) { index, $digit in
                UIBackspaceDetectingTextField(text: $digit) {
                    if index > 0 {
                        focusedDigit = index - 1
                    }
                }
                .fixedSize()
                .padding(.vertical)
                .frame(maxWidth: 50)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(codeIncorrect ? Color.red : Color.secondary, lineWidth: 1)
                }
                .focused($focusedDigit, equals: index)
                .onChange(of: digit) { oldValue, newValue in
                    digit = String(digit.prefix(2))
                    
                    if digit.count > 0 {
                        if index < 4 {
                            focusedDigit = index + 1
                        } else {
                            focusedDigit = nil
                            checkCodeMatches()
                        }
                    }
                }
                
                Spacer()
            }
        }.padding()
    }
    
    private func checkCodeMatches() {
        if code == realCode {
            self.codeIncorrect = false
            
            authenticationModel.deleteAccount { success in
                if success {
                    self.reauthenticationAction = nil
                }
            }
        } else {
            authenticationModel.error = "The code is incorrect."
            self.codeIncorrect = true
        }
    }
    
    private var deleteAccountButton: some View {
        Button {
            self.realCode = []
            self.code = [String](repeating: "", count: 5)
            self.codeIncorrect = false
            self.focusedDigit = 0
            
            if let email = authenticationModel.user?.email {
                authenticationModel.sendEmailCode(withEmail: email, type: .deleteAccount) { success, code in
                    if success {
                        self.realCode = code
                    }
                }
            }
        } label: {
            Text("Send Confirmation Email")
                .font(.headline)
                .foregroundStyle(Color.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
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
    DeleteAccountView(reauthenticationAction: .constant(nil))
}
