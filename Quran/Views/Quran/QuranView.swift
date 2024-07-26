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
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var quranModel: QuranModel
    @StateObject private var quranFilterModel: QuranFilterModel = QuranFilterModel(quranModel: QuranModel())
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
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
            bookmarksButton
        }
        .onAppear {
            quranFilterModel.quranModel = quranModel
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
                    
                    SurahCard(surah: surah, initialScroll: initialScroll, initialSearchText: initialSearchText, isFavorite: isFavorite(surah: surah)) {
                        favoriteSurah(surah: surah)
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
    
    private func isFavorite(surah: Surah) -> Bool {
        return favorites.contains { favorite in
            favorite.surahId == surah.id
        }
    }
    
    private func favoriteSurah(surah: Surah) {
        if let favorite = favorites.first(where: { favorite in
            favorite.surahId == surah.id
        }) {
            viewContext.delete(favorite)
        } else {
            let favorite = Favorite(context: viewContext)
            favorite.surahId = Int64(surah.id)
        }
        
        try? viewContext.save()
    }
    
    private func getVerse(surah: Surah) -> (initialScroll: Int?, initialSearchText: String?) {
        if quranFilterModel.isSurahToVerse(surah: surah) {
            if let verseId = Int(quranFilterModel.searchText.split(separator: ":").last ?? "") {
                return (verseId, nil)
            }
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
    var initialScroll: Int?
    var initialSearchText: String?
    
    let isFavorite: Bool
    let favoriteSurah: () -> Void
    
    var body: some View {
        NavigationLink {
            SurahView(surah: surah, initialScroll: initialScroll, initialSearchText: initialSearchText)
        } label: {
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
            .contextMenu {
                favoriteButton
            }
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
    
    private var surahInfo: some View {
        VStack {
            Text(surah.name)
                .fontWeight(.heavy)
            
            Text("\(surah.total_verses) Ayahs")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
    }
    
    private var favoriteButton: some View {
        Button {
            favoriteSurah()
        } label: {
            HStack {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(Color.red)
                
                Text(isFavorite ? "Unfavorite" : "Favorite")
                
                Spacer()
            }
        }
    }
}

#Preview {
    QuranView()
}
