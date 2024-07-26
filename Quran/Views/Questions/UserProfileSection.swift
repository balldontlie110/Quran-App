//
//  UserProfileSection.swift
//  Quran
//
//  Created by Ali Earp on 03/07/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore

struct UserProfileSection: View {
    let userProfiles: [UserProfile]
    let uid: String
    let timestamp: Timestamp
    
    var size: CGFloat = 40
    var font: Font.TextStyle = .caption
    
    var body: some View {
        let userProfile = userProfiles.first(where: { $0.id == uid })
        
        VStack(alignment: .trailing) {
            Text(userProfile?.username ?? "")
            Text(timestamp.string())
        }
        .foregroundStyle(Color.secondary)
        .font(.system(font, weight: .semibold))
        .multilineTextAlignment(.trailing)
        
        WebImage(url: userProfile?.photoURL) { image in
            image
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
        } placeholder: {
            EmptyView()
        }.frame(width: size, height: size)
    }
}

#Preview {
    UserProfileSection(userProfiles: [], uid: "", timestamp: Timestamp())
}
