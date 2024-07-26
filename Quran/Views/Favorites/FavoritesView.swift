//
//  FavoritesView.swift
//  Quran
//
//  Created by Ali Earp on 22/07/2024.
//

import SwiftUI
import CoreData

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var duaModel: DuaModel
    @EnvironmentObject private var ziyaratModel: ZiyaratModel
    @EnvironmentObject private var amaalModel: AmaalModel
    
    @Binding var showFavoritesView: Bool
    @Binding var navigateTo: AnyView?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20){
                    surahsSection
                    duasSection
                    ziaraahSection
                    amaalsSection
                }.padding(.horizontal)
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    doneButton
                }
            }
        }
    }
    
    private var doneButton: some View {
        Button {
            self.showFavoritesView = false
        } label: {
            Text("Done")
                .bold()
        }
    }
    
    private var surahsSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            if surahs.count > 0 {
                Text("Surahs")
                    .font(.title)
                    .bold()
                
                ForEach(surahs) { surah in
                    Button {
                        self.showFavoritesView = false
                        self.navigateTo = AnyView(SurahView(surah: surah))
                    } label: {
                        SurahCard(surah: surah, isFavorite: true) {
                            favoriteSurah(surah: surah)
                        }
                    }
                }
            }
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
    
    private var duasSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            if duas.count > 0 {
                Text("Duas")
                    .font(.title)
                    .bold()
                
                ForEach(duas) { dua in
                    Button {
                        self.showFavoritesView = false
                        self.navigateTo = AnyView(DuaView(dua: dua))
                    } label: {
                        DuaCard(context: viewContext, favorites: favorites, dua: dua)
                    }
                }
            }
        }
    }
    
    private var ziaraahSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            if ziaraah.count > 0 {
                Text("Ziaraah")
                    .font(.title)
                    .bold()
                
                ForEach(ziaraah) { ziyarat in
                    Button {
                        self.showFavoritesView = false
                        self.navigateTo = AnyView(ZiyaratView(ziyarat: ziyarat))
                    } label: {
                        ZiyaratCard(context: viewContext, favorites: favorites, ziyarat: ziyarat)
                    }
                }
            }
        }
    }
    
    private var amaalsSection: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            if amaals.count > 0 {
                Text("Amaals")
                    .font(.title)
                    .bold()
                
                ForEach(amaals) { amaal in
                    Button {
                        self.showFavoritesView = false
                        self.navigateTo = AnyView(AmaalView(amaal: amaal))
                    } label: {
                        AmaalCard(context: viewContext, favorites: favorites, amaal: amaal)
                    }
                }
            }
        }
    }
    
    private var surahs: [Surah] {
        return favorites.filter { favorite in
            favorite.surahId != 0
        }.compactMap { favorite in
            quranModel.quran.first { surah in
                surah.id == favorite.surahId
            }
        }
    }
    
    private var duas: [Dua] {
        return favorites.filter { favorite in
            favorite.duaId != 0
        }.compactMap { favorite in
            duaModel.duas.first { dua in
                dua.id == favorite.duaId
            }
        }
    }
    
    private var ziaraah: [Ziyarat] {
        return favorites.filter { favorite in
            favorite.ziyaratId != 0
        }.compactMap { favorite in
            ziyaratModel.ziaraah.first { ziyarat in
                ziyarat.id == favorite.ziyaratId
            }
        }
    }
    
    private var amaals: [Amaal] {
        return favorites.filter { favorite in
            favorite.amaalId != 0
        }.compactMap { favorite in
            amaalModel.amaals.first { amaal in
                amaal.id == favorite.amaalId
            }
        }
    }
}

#Preview {
    FavoritesView(showFavoritesView: .constant(true), navigateTo: .constant(nil))
}
