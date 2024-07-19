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
                ForEach(groupedVerses, id: \.self) { group in
                    ForEach(group) { verse in
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
                            
                            if verse.id != group.last?.id {
                                Divider()
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }.padding(.horizontal, 10)
        }
        .navigationTitle(ziyarat.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var groupedVerses: [[ZiyaratVerse]] {
        ziyarat.verses.reduce(into: [[ZiyaratVerse]]()) { result, verse in
            if verse.gap {
                result.append([])
            } else {
                if result.isEmpty || !result.last!.isEmpty && result.last!.last!.gap {
                    result.append([verse])
                } else {
                    result[result.count - 1].append(verse)
                }
            }
        }.filter { !$0.isEmpty }
    }
}

#Preview {
    ZiyaratView(ziyarat: Ziyarat(id: 0, name: "", verses: []))
}
