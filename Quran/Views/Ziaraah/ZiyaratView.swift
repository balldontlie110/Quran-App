//
//  ZiyaratView.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import SwiftUI

struct ZiyaratView: View {
    @EnvironmentObject private var preferencesModel: PreferencesModel
    
    let ziyarat: Ziyarat
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(ziyarat.verses) { verse in
                    VStack(spacing: 0) {
                        VStack(spacing: 15) {
                            Text(verse.text)
                                .font(.system(size: CGFloat(preferencesModel.preferences?.fontSize ?? 40.0), weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(20)
                            
                            Text(verse.transliteration.uppercased())
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                            
                            Text(verse.translation)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                        }.padding(.vertical)
                        
                        if verse.id != ziyarat.verses.count {
                            if verse.gap {
                                Spacer()
                                    .frame(height: 50)
                            } else {
                                Divider()
                            }
                        }
                    }
                }
            }.padding(.horizontal, 10)
        }
        .navigationTitle(ziyarat.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ZiyaratView(ziyarat: Ziyarat(id: 0, title: "", subtitle: nil, verses: []))
}
