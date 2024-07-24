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
                            SurahCard(context: viewContext, favorites: favorites, surah: surah, initalScroll: getVerse(surah: surah))
                        }
                    }.padding()
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
    let context: NSManagedObjectContext
    let favorites: FetchedResults<Favorite>
    
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
            .contextMenu {
                Button {
                    favoriteSurah()
                } label: {
                    HStack {
                        if favorites.contains(where: { favorite in
                            favorite.surahId == surah.id
                        }) {
                            Image(systemName: "star.fill")
                            
                            Text("Unfavorite")
                            
                            Spacer()
                        } else {
                            Image(systemName: "star")
                            
                            Text("Favorite")
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private func favoriteSurah() {
        if let favorite = favorites.first(where: { favorite in
            favorite.surahId == surah.id
        }) {
            context.delete(favorite)
        } else {
            let favorite = Favorite(context: context)
            favorite.surahId = Int64(surah.id)
        }
        
        try? context.save()
    }
}

#Preview {
    QuranView()
}
