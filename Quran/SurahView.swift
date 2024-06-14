//
//  SurahView.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI

struct SurahView: View {
    let surah: Surah

    @State private var readingMode: Bool = false
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                Text(surah.name)
                    .font(.system(size: 50, weight: .bold))
                
                Text(surah.translation)
                    .font(.system(size: 20, weight: .semibold))
            }
            
            Spacer().frame(height: 40)
            
            Group {
                if readingMode {
                    let verses = getSurahVerses(surah.verses)
                    
                    VStack(spacing: 15) {
                        ForEach(verses, id: \.self) { verse in
                            Text(verse)
                        }
                        .font(.system(size: 30, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(15)
                    }
                } else {
                    LazyVStack {
                        ForEach(surah.verses) { verse in
                            VStack(alignment: .trailing, spacing: 15) {
                                let verseText = getVerse(verse)
                                Text(verseText)
                                    .font(.system(size: 30, weight: .bold))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(10)
                                
                                HStack(alignment: .top) {
                                    Group {
                                        Text("\(verse.id).")
                                        Text(verse.translation)
                                    }
                                    .font(.system(size: 20, design: .rounded))
                                    .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }.padding(.trailing, 15)
                                
                                if verse.id != surah.verses.count {
                                    Divider()
                                }
                            }.padding(.vertical, 5)
                        }
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle(surah.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                self.readingMode.toggle()
            } label: {
                Image(systemName: readingMode ? "book" : "book.closed")
            }.foregroundStyle(.primary)
        }
    }

    private func getSurahVerses(_ verses: [Ayat]) -> [String] {
        return verses.compactMap { getVerse($0) }
    }
    
    private func getVerse(_ verse: Ayat) -> String {
        return verse.text + " " + getArabicNumber(verse.id)
    }
    
    private func getArabicNumber(_ number: Int) -> String {
        let arabicNumerals = "٠١٢٣٤٥٦٧٨٩"
        var arabicString = ""
        
        for char in String(number) {
            if let digit = Int(String(char)) {
                let index = arabicNumerals.index(arabicNumerals.startIndex, offsetBy: digit)
                arabicString.append(arabicNumerals[index])
            }
        }
        
        return "(" + arabicString + ")"
    }
}

#Preview {
    var quranModel: QuranModel = QuranModel()
    
    NavigationStack {
        if let surah = quranModel.quran.first(where: { surah in
            surah.id == 1
        }) {
            SurahView(surah: surah)
        }
    }
}
