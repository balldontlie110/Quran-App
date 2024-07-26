//
//  SocialsView.swift
//  Quran
//
//  Created by Ali Earp on 23/07/2024.
//

import SwiftUI

struct Social: Identifiable {
    let id: UUID = UUID()
    
    let name: String
    let handle: String
    let url: String
    let image: String
}

struct SocialsView: View {
    @Binding var showSocialsView: Bool
    
    @State private var sheetHeight: CGFloat = .zero
    
    private let socials: [Social] = [
        Social(name: "Website", handle: "hyderi.org.uk", url: "https://hyderi.org.uk", image: "hyderi"),
        Social(name: "YouTube", handle: "@hyderi", url: "https://www.youtube.com/@hyderi/live", image: "youtube"),
        Social(name: "Instagram", handle: "@hydericentre", url: "https://www.instagram.com/hydericentre/", image: "instagram"),
        Social(name: "X", handle: "@HyderiCentre", url: "https://x.com/hydericentre", image: "x"),
        Social(name: "Facebook", handle: "Hyderi IslamicCentre", url: "https://www.facebook.com/HyderiCentre", image: "facebook")
    ]
    
    var body: some View {
        VStack {
            doneButton
            
            LazyVStack(spacing: 15) {
                ForEach(socials) { social in
                    if let url = URL(string: social.url) {
                        Link(destination: url) {
                            HStack(spacing: 15) {
                                Image(social.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                
                                Text(social.name)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Text(social.handle)
                                    .foregroundStyle(Color.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .font(.system(.headline, weight: .bold))
            .foregroundStyle(Color.primary)
        }
        .padding()
        .overlay {
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometry.size.height)
            }
        }
        .onPreferenceChange(SizePreferenceKey.self) { newHeight in
            DispatchQueue.main.async {
                sheetHeight = newHeight
            }
        }
        .presentationDetents([.height(sheetHeight)])
    }
    
    private var doneButton: some View {
        HStack {
            Spacer()
            
            Button {
                self.showSocialsView = false
            } label: {
                Text("Done")
                    .bold()
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    SocialsView(showSocialsView: .constant(true))
}
