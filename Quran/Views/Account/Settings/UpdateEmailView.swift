//
//  UpdateEmailView.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import SwiftUI
import UIKit

struct UpdateEmailView: View {
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    
    @State private var email: String = ""
    
    @FocusState private var focused: Bool
    
    @Binding var reauthenticationAction: ReauthenticateView.ReauthenticateAction?
    
    @State private var verificationEmailSent: Bool = false
    
    @State private var realCode: [String] = []
    @State private var code: [String] = [String](repeating: "", count: 5)
    @State private var codeIncorrect: Bool = false
    
    @FocusState private var focusedDigit: Int?
    
    var body: some View {
        VStack {
            updateEmailMessage
            
            emailField
            
            errorMessage
            
            codeInputFields
            
            Spacer()
            
            if authenticationModel.loading {
                ProgressView()
                
                Spacer()
            }
            
            sendVerificationEmailButton
        }
        .padding()
        .onAppear {
            authenticationModel.error = ""
            authenticationModel.loading = false
            
            self.focused = true
        }
        .onDisappear {
            authenticationModel.error = ""
            authenticationModel.loading = false
        }
    }
    
    private func checkCodeMatches() {
        if code == realCode {
            self.codeIncorrect = false
            
            authenticationModel.updateEmail(withEmail: email) { success in
                if success {
                    self.reauthenticationAction = nil
                }
            }
        } else {
            authenticationModel.error = "The code is incorrect."
            self.codeIncorrect = true
        }
    }
    
    private var updateEmailMessage: some View {
        Text("Please enter your new email. We will send an email to this address to confirm that it belongs to you")
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
            .focused($focused)
    }
    
    @ViewBuilder
    private var codeInputFields: some View {
        if verificationEmailSent {
            Spacer()
            
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
            }
        }
    }
    
    private var sendVerificationEmailButton: some View {
        Button {
            self.verificationEmailSent = false
            self.realCode = []
            self.code = [String](repeating: "", count: 5)
            self.codeIncorrect = false
            self.focusedDigit = 0
            
            authenticationModel.sendEmailCode(withEmail: email, type: .verifyEmail) { success, code in
                if success {
                    self.verificationEmailSent = success
                    self.realCode = code
                }
            }
        } label: {
            Text("Send Verification Email")
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

class BackspaceDetectingTextField: UITextField {
    var onBackspacePressed: (() -> Void)?

    override func deleteBackward() {
        if text?.isEmpty ?? true {
            onBackspacePressed?()
        }
        super.deleteBackward()
    }
}

struct UIBackspaceDetectingTextField: UIViewRepresentable {
    @Binding var text: String
    var onBackspace: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = BackspaceDetectingTextField()
        textField.delegate = context.coordinator
        textField.onBackspacePressed = { onBackspace() }
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        textField.keyboardType = .numberPad
        textField.font = UIFont.preferredFont(forTextStyle: .title3)
        textField.textAlignment = .center
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIBackspaceDetectingTextField

        init(_ parent: UIBackspaceDetectingTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
    }
}

#Preview {
    UpdateEmailView(reauthenticationAction: .constant(.updateEmail))
}
