//
//  ProfileDetailView.swift
//  Quran
//
//  Created by Ali Earp on 08/09/2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct ProfileDetailView: View {
    @Binding var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                if let userProfile = userProfile {
                    WebImage(url: userProfile.photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(Color.gray)
                            .fontWeight(.thin)
                    }
                    .overlay {
                        Circle()
                            .stroke(lineWidth: 2.5)
                            .foregroundStyle(Color.primary)
                    }
                    .frame(width: 200, height: 200)
                    
                    Text(userProfile.username)
                        .font(.system(.title, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton
                }
            }
        }
    }
    
    private var doneButton: some View {
        Button {
            self.userProfile = nil
        } label: {
            Text("Done")
                .bold()
        }
    }
}

#Preview {
    ProfileDetailView(userProfile: .constant(UserProfile(id: "", username: "", photoURL: URL(fileReferenceLiteralResourceName: ""))))
}
