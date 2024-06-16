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
    
    @State private var showVerseSelector: Bool = false
    @State private var verseNumber: Int = 1
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
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
                        
                        LazyVStack(spacing: 20) {
                            ForEach(verses) { verse in
                                Text(verse.text)
                                    .tag(verse.id)
                            }
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(20)
                        }
                    } else {
                        LazyVStack {
                            ForEach(surah.verses) { verse in
                                VStack(alignment: .trailing, spacing: 15) {
                                    let verseText = getVerse(verse)
                                    
                                    Text(verseText.text)
                                        .font(.system(size: 40, weight: .bold))
                                        .multilineTextAlignment(.trailing)
                                        .lineSpacing(20)
                                    
                                    HStack(alignment: .top) {
                                        Group {
                                            Text("\(verse.id).")
                                            Text(verse.translation)
                                        }
                                        .font(.system(size: 20))
                                        .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }.padding(.trailing, 15)
                                    
                                    if verse.id != surah.verses.count {
                                        Divider()
                                    }
                                }
                                .padding(.vertical, 5)
                                .id(verse.id)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .onChange(of: verseNumber) { _, _ in
                    withAnimation {
                        proxy.scrollTo(verseNumber, anchor: .top)
                    }
                }
            }
        }
        .navigationTitle(surah.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.bouncy) { self.showVerseSelector.toggle() }
                } label: {
                    Image(systemName: "chevron.\(showVerseSelector ? "up" : "down")")
                }.foregroundStyle(.primary)
            }
            
            Group {
                ToolbarItem(placement: .bottomBar) { Spacer() }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        self.readingMode = false
                    } label: {
                        Image(systemName: readingMode ? "book.closed" : "book.closed.fill")
                    }.foregroundStyle(.primary)
                }
                
                ToolbarItem(placement: .bottomBar) { Spacer() }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        self.readingMode = true
                    } label: {
                        Image(systemName: readingMode ? "book.fill" : "book")
                    }.foregroundStyle(.primary)
                }
                
                ToolbarItem(placement: .bottomBar) { Spacer() }
            }
        }
        .safeAreaInset(edge: .top) {
            if showVerseSelector {
                VStack(spacing: 0) {
                    Picker("", selection: $verseNumber) {
                        ForEach(0..<surah.total_verses) { number in
                            LazyVGrid(columns: columns) {
                                Text(String(number + 1))
                                
                                Text(getArabicNumber(number + 1))
                            }.tag(number + 1)
                        }
                    }
                    .pickerStyle(.wheel)
                    .background(Color(.systemBackground))
                    .frame(height: 150)
                    
                    Divider()
                }.shadow(radius: 1)
            }
        }
    }

    private func getSurahVerses(_ verses: [Ayat]) -> [Ayat] {
        return verses.compactMap { getVerse($0) }
    }
    
    private func getVerse(_ verse: Ayat) -> Ayat {
        return Ayat(id: verse.id, text: verse.text + " " + getArabicNumber(verse.id), translation: "")
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
            surah.id == 2
        }) {
            SurahView(surah: surah)
        }
    }
}
