//
//  QuranView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct QuranView: View {
    @State private var quranModel: QuranModel = QuranModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(quranModel.quran) { surah in
                        NavigationLink {
                            SurahView(surah: surah)
                        } label: {
                            HStack {
                                ZStack {
                                    Image(systemName: "diamond")
                                        .font(.largeTitle)
                                    Text(String(surah.id))
                                        .font(String(surah.id).count == 1 ? .title3 : String(surah.id).count == 2 ? .headline : .caption)
                                        .bold()
                                }
                                
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
            }.toolbarVisibility(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    QuranView()
}
