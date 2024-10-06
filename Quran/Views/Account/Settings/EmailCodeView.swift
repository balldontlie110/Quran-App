//
//  EmailCodeView.swift
//  Quran
//
//  Created by Ali Earp on 03/09/2024.
//

import SwiftUI

struct EmailCodeView: View {
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    
    @Binding var verificationEmailSent: Bool
    let realCode: [String]
    
    @State private var code: [String] = [String](repeating: "", count: 5)
    @State private var codeIncorrect: Bool = false

    @FocusState private var focusedDigit: Int?
    
    var body: some View {
        VStack {
            verifyEmailMessage
            
            codeInputFields
            
            errorMessage
        }
        .padding()
        .onAppear {
            authenticationModel.error = ""
            
            self.focusedDigit = 0
        }
        .onDisappear {
            authenticationModel.error = ""
        }
    }
    
    private var verifyEmailMessage: some View {
        Text("Enter the code in the email we just sent you.")
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
            self.verificationEmailSent = false
            
            authenticationModel.createAccount()
        } else {
            authenticationModel.error = "The code is incorrect."
            self.codeIncorrect = true
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
    EmailCodeView(verificationEmailSent: .constant(true), realCode: [])
}
