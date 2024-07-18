//
//  QuranView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import Combine

struct QuranView: View {
    @EnvironmentObject private var quranModel: QuranModel
    @StateObject private var quranFilterModel: QuranFilterModel = QuranFilterModel(quranModel: QuranModel())
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                searchBar
                    .padding(.horizontal)
                
                Divider()
            }
            
            if quranFilterModel.isLoading {
                Spacer()
                
                ProgressView()
                
                Spacer()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(quranFilterModel.filteredQuran) { surah in
                            SurahCard(surah: surah, initalScroll: getVerse(surah: surah))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Quran")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            bookmarksButton
        }
        .onAppear {
            quranFilterModel.quranModel = quranModel
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

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)
            
            TextField("Search", text: $quranFilterModel.searchText)
            
            if quranFilterModel.searchText != "" {
                Button {
                    quranFilterModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
            }
        }
        .padding(5)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func getVerse(surah: Surah) -> Int? {
        if quranFilterModel.isSurahToVerse(surah: surah) {
            if let verseId = Int(quranFilterModel.searchText.split(separator: ":").last ?? "") {
                return verseId
            }
        }
        
        for verse in surah.verses {
            if verse.text.lowercased().contains(quranFilterModel.searchText.lowercased()) {
                return verse.id
            }
            
            for translation in verse.translations {
                if translation.translation.lowercased().contains(quranFilterModel.searchText.lowercased()) {
                    return verse.id
                }
            }
        }
        
        return nil
    }
}

struct SurahCard: View {
    let surah: Surah
    let initalScroll: Int?
    
    var body: some View {
        NavigationLink {
            SurahView(surah: surah, initialScroll: initalScroll)
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
                }.multilineTextAlignment(.leading)
                
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
}

class QuranFilterModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filteredQuran: [Surah] = []
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    @Published var quranModel: QuranModel

    init(quranModel: QuranModel) {
        self.quranModel = quranModel
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] text in
                self?.setLoading(true)
                let result = self?.filterQuran(with: text) ?? []
                self?.setLoading(false)
                return result
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredQuran, on: self)
            .store(in: &cancellables)
    }

    private func filterQuran(with searchText: String) -> [Surah] {
        guard !searchText.isEmpty else { return quranModel.quran }
        
        let cleanedSearchText = searchText.lowercasedLettersAndNumbers
        
        return quranModel.quran.filter { surah in
            if String(surah.id) == cleanedSearchText {
                return true
            }
            
            if surah.name.lowercasedLettersAndNumbers == cleanedSearchText {
                return true
            }
            
            if surah.transliteration.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return true
            }
            
            if surah.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return true
            }
            
            if isSurahToVerse(surah: surah) {
                return true
            }
            
            for verse in surah.verses {
                if verse.text.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                    return true
                }
                
                for translation in verse.translations {
                    if translation.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                        return true
                    }
                }
            }
            
            return false
        }
    }
    
    private func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func isSurahToVerse(surah: Surah) -> Bool {
        let surahToVerseRegex = "\\d+\\s*:\\s*\\d+"
        let surahToVersePredicate = NSPredicate(format: "SELF MATCHES %@", surahToVerseRegex)
        
        if surahToVersePredicate.evaluate(with: searchText) {
            if let surahId = Int(searchText.split(separator: ":").first ?? ""), let verseId = Int(searchText.split(separator: ":").last ?? "") {
                if surahId == surah.id && verseId <= surah.total_verses {
                    return true
                }
            }
        }
        
        return false
    }
}

extension String {
    var lowercasedLettersAndNumbers: String {
        return String(unicodeScalars.filter(CharacterSet.alphanumerics.contains)).lowercased()
    }
}

#Preview {
    QuranView()
}
