//
//  QuranView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct QuranView: View {
    @State private var quranModel: QuranModel = QuranModel()
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(quran) { surah in
                        NavigationLink {
                            SurahView(surah: surah)
                        } label: {
                            HStack(spacing: 15) {
                                Text(String(surah.id))
                                    .bold()
                                    .overlay {
                                        Image(systemName: "diamond")
                                            .font(.system(size: 40))
                                            .fontWeight(.ultraLight)
                                    }
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading) {
                                    Text(surah.transliteration)
                                        .fontWeight(.heavy)
                                    Text(surah.translation)
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                }
                                
                                Spacer()
                                
                                VStack {
                                    Text(surah.name)
                                        .fontWeight(.heavy)
                                    Text("\(surah.total_verses) Ayahs")
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .foregroundStyle(Color.primary)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }.padding(.horizontal)
            }
            .searchable(text: $searchText)
            .navigationTitle("Quran")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.visible, for: .navigationBar)
        }
    }
    
    private var quran: [Surah] {
        if searchText == "" {
            return quranModel.quran
        } else {
            return quranModel.quran.filter { surah in
                if surah.name.lowercased() == searchText.lowercased() {
                    return true
                } else if surah.translation.lowercased().contains(searchText.lowercased()) {
                    return true
                } else if surah.transliteration.lowercased().contains(searchText.lowercased()) {
                    return true
                } else if String(surah.id).contains(searchText) {
                    return true
                } else {
                    return false
                }
            }
        }
    }
}

#Preview {
    QuranView()
}
