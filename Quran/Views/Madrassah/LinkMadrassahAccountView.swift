//
//  LinkMadrassahAccountView.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import SwiftUI

struct LinkMadrassahAccountView: View {
    @StateObject var madrassahModel: MadrassahModel
    
    @State private var madrassahId: String = ""
    
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack {
            if madrassahModel.user == nil {
                loginMessage
            } else {
                madrassahIdField
                errorMessage
                
                Spacer()
                
                if madrassahModel.loading {
                    ProgressView()
                }
                
                Spacer()
                
                linkAccountButton
            }
        }
        .padding()
        .onAppear {
            madrassahModel.error = ""
            madrassahModel.loading = false
            
            self.focused = true
        }
        .onDisappear {
            madrassahModel.error = ""
            madrassahModel.loading = false
        }
    }
    
    private var loginMessage: some View {
        Text("In order to link to a Madrassah account, you first have to be logged in by going to settings on the home page")
            .font(.system(.title3, weight: .bold))
            .multilineTextAlignment(.center)
            .padding()
    }
    
    private var madrassahIdField: some View {
        TextField("Madrassah ID", text: $madrassahId)
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focused)
    }
    
    private var linkAccountButton: some View {
        Button {
            madrassahModel.linkMadrassahAccount(madrassahId: madrassahId)
        } label: {
            Text("Link Account")
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
        if madrassahModel.error != "" {
            Text(madrassahModel.error)
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.top, 5)
        }
    }
}

#Preview {
    LinkMadrassahAccountView(madrassahModel: MadrassahModel())
}
