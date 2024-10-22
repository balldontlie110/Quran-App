//
//  QuranView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import Combine
import CoreData

struct QuranView: View {
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var quranFilterModel: QuranFilterModel
    
    @AppStorage("streak") private var streak: Int = 0
    @AppStorage("streakDate") private var streakDate: Double = 0.0
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            
            if quranFilterModel.isLoading {
                progressView
            } else {
                surahsScrollView
            }
        }
        .navigationTitle("Quran")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            quranTimeButton
            
            bookmarksButton
        }
    }
    
    private var searchBar: some View {
        VStack {
            SearchBar(placeholder: "Search", searchText: $quranFilterModel.searchText)
            
            Divider()
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        Spacer()
        
        ProgressView()
        
        Spacer()
    }
    
    private var surahsScrollView: some View {
        ScrollView {
            LazyVStack {
                ForEach(quranFilterModel.filteredQuran) { surah in
                    let getVerse = getVerse(surah: surah)
                    let initialScroll = getVerse.initialScroll
                    let initialSearchText = getVerse.initialSearchText
                    
                    NavigationLink {
                        SurahView(surah: surah, initialScroll: initialScroll, initialSearchText: initialSearchText)
                    } label: {
                        SurahCard(surah: surah)
                    }
                }
                
                if quranFilterModel.filteredQuran.count > 0 && quranFilterModel.versesContainingText.count > 0 {
                    Divider()
                }
                
                let versesContainingText = quranFilterModel.versesContainingText.sorted { verse1, verse2 in
                    if let surahId1 = verse1.key.split(separator: ":").first, let surahId2 = verse2.key.split(separator: ":").first, let surahId1 = Int(surahId1), let surahId2 = Int(surahId2) {
                        
                        if surahId1 < surahId2 {
                            return true
                        }
                        
                        if surahId1 > surahId2 {
                            return false
                        }
                        
                        return verse1.value.id < verse2.value.id
                    }
                    
                    return false
                }
                
                ForEach(versesContainingText, id: \.key) { surahToVerseId, verse in
                    if let surah = quranModel.quran.first(where: { surah in
                        if let surahId = surahToVerseId.split(separator: ":").first {
                            return String(surah.id) == surahId
                        }
                        
                        return false
                    }) {
                        VerseCard(surah: surah, verse: verse)
                    }
                }
            }.padding()
        }
    }

    private var bookmarksButton: some View {
        NavigationLink {
            BookmarkedFoldersView()
        } label: {
            Image(systemName: "bookmark")
                .foregroundStyle(Color.primary)
        }
    }
    
    private var quranTimeButton: some View {
        NavigationLink {
            QuranTimeView()
        } label: {
            StreakInfo(streak: streak, streakDate: Date(timeIntervalSince1970: streakDate), font: .body)
        }
    }
    
    private func getVerse(surah: Surah) -> (initialScroll: Int?, initialSearchText: String?) {
        if let verse = quranFilterModel.surahToVerse(surah: surah) {
            return (verse.id, nil)
        }
        
        let cleanedSearchText = quranFilterModel.searchText.lowercasedLettersAndNumbers
        
        for verse in surah.verses {
            if verse.text.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return (verse.id, quranFilterModel.searchText)
            }
            
            for translation in verse.translations {
                if translation.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                    return (verse.id, quranFilterModel.searchText)
                }
            }
        }
        
        return (nil, nil)
    }
}

struct SurahCard: View {
    let surah: Surah
    
    var body: some View {
        HStack(spacing: 15) {
            surahNumber
            
            surahName
            
            Spacer()
            
            surahInfo
        }
        .foregroundStyle(Color.primary)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private var surahNumber: some View {
        Text(String(surah.id))
            .bold()
            .overlay {
                Image(systemName: "diamond")
                    .font(.system(size: 40))
                    .fontWeight(.ultraLight)
            }
            .frame(width: 40)
    }
    
    private var surahName: some View {
        VStack(alignment: .leading) {
            Text(surah.transliteration)
                .fontWeight(.heavy)
            
            Text(surah.translation)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }.multilineTextAlignment(.leading)
    }
    
    private var surahInfo: some View {
        VStack(alignment: .trailing) {
            let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
            
            let defaultFont = Font.system(size: 17, weight: .heavy)
            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: 17)
            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: 17)
            
            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
            
            Text(surah.name)
                .font(font)
            
            Text("\(surah.total_verses) Ayahs")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }.multilineTextAlignment(.trailing)
    }
}

struct VerseCard: View {
    @EnvironmentObject private var quranFilterModel: QuranFilterModel
    
    let surah: Surah
    let verse: Verse
    
    var body: some View {
        NavigationLink {
            if quranFilterModel.surahToVerse(surah: surah) != nil {
                SurahView(surah: surah, initialScroll: verse.id, initialSearchText: nil)
            } else {
                SurahView(surah: surah, initialScroll: verse.id, initialSearchText: quranFilterModel.searchText)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 15) {
                    surahNumber
                    
                    surahName
                    
                    Spacer()
                    
                    surahAndVerseInfo
                }
                
                verseTranslation
            }
            .foregroundStyle(Color.primary)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
    
    private var surahNumber: some View {
        Text(String(surah.id))
            .bold()
            .overlay {
                Image(systemName: "diamond")
                    .font(.system(size: 40))
                    .fontWeight(.ultraLight)
            }
            .frame(width: 40)
    }
    
    private var surahName: some View {
        VStack(alignment: .leading) {
            Text(surah.transliteration)
                .fontWeight(.heavy)
            
            Text(surah.translation)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }.multilineTextAlignment(.leading)
    }
    
    private var surahAndVerseInfo: some View {
        VStack {
            Text(surah.name)
                .fontWeight(.heavy)
            
            Text("Verse: \(verse.id)")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
    }
    
    private var verseTranslation: some View {
        HStack(alignment: .top) {
            Text("\(verse.id).")
            
            Text(highlightedTranslation)
                .multilineTextAlignment(.leading)
        }.font(.subheadline)
    }
    
    private var highlightedTranslation: AttributedString {
        func clean(_ str: String) -> (cleaned: String, originalIndices: [Int]) {
            var cleaned = ""
            var indices: [Int] = []
            var inBracket = false
            var bracketStack: [Character] = []
            
            for (index, char) in str.enumerated() {
                if char == "[" || char == "(" || char == "{" {
                    inBracket = true
                    bracketStack.append(char)
                } else if char == "]" || char == ")" || char == "}" {
                    if let lastBracket = bracketStack.last,
                       (char == "]" && lastBracket == "[") ||
                       (char == ")" && lastBracket == "(") ||
                       (char == "}" && lastBracket == "{") {
                        bracketStack.removeLast()
                    }
                    if bracketStack.isEmpty {
                        inBracket = false
                    }
                } else if !inBracket && (char.isLetter || char.isNumber) {
                    cleaned.append(char.lowercased())
                    indices.append(index)
                }
            }
            
            return (cleaned, indices)
        }
        
        guard let translation = verse.translations.first(where: { translation in
            translation.id == UserDefaultsController.shared.integer(forKey: "translatorId")
        })?.translation else { return AttributedString() }
        
        let (cleanedTranslation, originalIndices) = clean(translation)
        let cleanedSearchText = clean(quranFilterModel.searchText).cleaned
        
        var positions: [Range<String.Index>] = []
        var startIndex = cleanedTranslation.startIndex
        
        while let range = cleanedTranslation.range(of: cleanedSearchText, range: startIndex..<cleanedTranslation.endIndex) {
            positions.append(range)
            startIndex = range.upperBound
        }
        
        var attributedStrings: [AttributedString] = []
        var lastEndIndex = translation.startIndex
        
        for position in positions {
            let startCleanedIndex = cleanedTranslation.distance(from: cleanedTranslation.startIndex, to: position.lowerBound)
            let endCleanedIndex = cleanedTranslation.distance(from: cleanedTranslation.startIndex, to: position.upperBound)
            
            let startIndex = translation.index(translation.startIndex, offsetBy: originalIndices[startCleanedIndex])
            let endIndex = translation.index(translation.startIndex, offsetBy: originalIndices[endCleanedIndex - 1] + 1)
            
            if lastEndIndex < startIndex {
                let part = String(translation[lastEndIndex..<startIndex])
                let attributedPart = AttributedString(part)
                attributedStrings.append(attributedPart)
            }
            
            let highlightedPart = String(translation[startIndex..<endIndex])
            var attributedHighlighted = AttributedString(highlightedPart)
            attributedHighlighted.backgroundColor = .yellow
            attributedHighlighted.foregroundColor = .black
            attributedStrings.append(attributedHighlighted)
            
            lastEndIndex = endIndex
        }
        
        if lastEndIndex < translation.endIndex {
            let part = String(translation[lastEndIndex..<translation.endIndex])
            let attributedPart = AttributedString(part)
            attributedStrings.append(attributedPart)
        }
        
        var combinedAttributedString = AttributedString("")
        for attributedString in attributedStrings {
            combinedAttributedString.append(attributedString)
        }
        
        return combinedAttributedString
    }
}

#Preview {
    QuranView()
}
