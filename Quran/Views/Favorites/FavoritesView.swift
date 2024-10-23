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
    
    @State private var timer: Timer?
    @State private var heartLocation: CGPoint?
    @State private var heartRotation: Angle = Angle(degrees: Double.random(in: -45...45))
    
    @State private var ignoreNavigationGesture: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20){
                    FavoritesSection(context: viewContext, ibadat: duas, title: "Du'as", showFavoritesView: $showFavoritesView, navigateTo: $navigateTo, favorites: favorites, timer: $timer, heartLocation: $heartLocation, heartRotation: $heartRotation, ignoreNavigationGesture: $ignoreNavigationGesture)
                    
                    FavoritesSection(context: viewContext, ibadat: ziaraah, title: "Ziaraah", showFavoritesView: $showFavoritesView, navigateTo: $navigateTo, favorites: favorites, timer: $timer, heartLocation: $heartLocation, heartRotation: $heartRotation, ignoreNavigationGesture: $ignoreNavigationGesture)
                    
                    FavoritesSection(context: viewContext, ibadat: amaals, title: "Amaals", showFavoritesView: $showFavoritesView, navigateTo: $navigateTo, favorites: favorites, timer: $timer, heartLocation: $heartLocation, heartRotation: $heartRotation, ignoreNavigationGesture: $ignoreNavigationGesture)
                }.padding([.horizontal, .top])
            }
            .overlay {
                if let heartLocation = heartLocation {
                    Image(systemName: "heart.slash.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color(.darkGray))
                        .rotationEffect(heartRotation)
                        .position(heartLocation)
                        .ignoresSafeArea(.all)
                        .onAppear {
                            withAnimation(.spring(duration: 1)) {
                                self.heartLocation = heartLocation.applying(CGAffineTransform(translationX: 0, y: -250))
                                self.heartRotation = Angle(degrees: Double.random(in: -30...30))
                            }
                        }
                }
            }
            .onChange(of: heartLocation) { oldLocation, _ in
                if heartLocation != nil && oldLocation == nil {
                    self.timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { timer in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            heartLocation = nil
                        }
                    }
                    
                    if let timer = timer {
                        RunLoop.current.add(timer, forMode: .common)
                    }
                }
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
    
    private var duas: [Ibadah] {
        return favorites.filter { favorite in
            favorite.duaId != 0
        }.compactMap { favorite in
            duaModel.duas.compactMap { ibadah in
                ibadah.dua
            }.first { dua in
                dua.id == favorite.duaId
            }
        }.sorted { dua1, dua2 in
            if let favorite1 = favorites.first(where: { favorite in
                favorite.duaId == dua1.id
            }), let favorite2 = favorites.first(where: { favorite in
                favorite.duaId == dua2.id
            }), let date1 = favorite1.date, let date2 = favorite2.date {
                return date1 < date2
            }
            
            return false
        }.map { dua in
            Ibadah(id: dua.id, dua: dua, ziyarat: nil, amaal: nil)
        }
    }
    
    private var ziaraah: [Ibadah] {
        return favorites.filter { favorite in
            favorite.ziyaratId != 0
        }.compactMap { favorite in
            ziyaratModel.ziaraah.compactMap { ibadah in
                ibadah.ziyarat
            }.first { ziyarat in
                ziyarat.id == favorite.ziyaratId
            }
        }.sorted { ziyarat1, ziyarat2 in
            if let favorite1 = favorites.first(where: { favorite in
                favorite.ziyaratId == ziyarat1.id
            }), let favorite2 = favorites.first(where: { favorite in
                favorite.ziyaratId == ziyarat2.id
            }), let date1 = favorite1.date, let date2 = favorite2.date {
                return date1 < date2
            }
            
            return false
        }.map { ziyarat in
            Ibadah(id: ziyarat.id, dua: nil, ziyarat: ziyarat, amaal: nil)
        }
    }
    
    private var amaals: [Ibadah] {
        return favorites.filter { favorite in
            favorite.amaalId != 0
        }.compactMap { favorite in
            amaalModel.amaals.compactMap { ibadah in
                ibadah.amaal
            }.first { amaal in
                amaal.id == favorite.amaalId
            }
        }.sorted { amaal1, amaal2 in
            if let favorite1 = favorites.first(where: { favorite in
                favorite.amaalId == amaal1.id
            }), let favorite2 = favorites.first(where: { favorite in
                favorite.amaalId == amaal2.id
            }), let date1 = favorite1.date, let date2 = favorite2.date {
                return date1 < date2
            }
            
            return false
        }.map { amaal in
            Ibadah(id: amaal.id, dua: nil, ziyarat: nil, amaal: amaal)
        }
    }
}

struct FavoritesSection: View {
    let context: NSManagedObjectContext
    
    let ibadat: [Ibadah]
    let title: String
    
    @Binding var showFavoritesView: Bool
    @Binding var navigateTo: AnyView?
    
    let favorites: FetchedResults<Favorite>
    
    @Binding var timer: Timer?
    @Binding var heartLocation: CGPoint?
    @Binding var heartRotation: Angle
    
    @Binding var ignoreNavigationGesture: Bool
    
    var body: some View {
        if ibadat.count > 0 {
            LazyVStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title)
                    .bold()
                
                ForEach(Array(ibadat.enumerated()), id: \.offset) { index, ibadah in
                    Button {
                        
                    } label: {
                        IbadahCard(ignoreNavigationGesture: $ignoreNavigationGesture, index: index, ibadah: ibadah, isFavorite: true, editMode: .constant(false)) {
                            favoriteIbadah(ibadah: ibadah)
                        }
                    }
                    .simultaneousGesture(
                        SpatialTapGesture(count: 2, coordinateSpace: .global).onEnded { location in
                            favoriteIbadah(ibadah: ibadah)
                            
                            self.heartLocation = nil
                            timer?.invalidate()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation {
                                    self.heartLocation = location.location
                                }
                            }
                        }.exclusively(before: TapGesture(count: 1).onEnded {
                            if !ignoreNavigationGesture {
                                self.showFavoritesView = false
                                
                                if let dua = ibadah.dua {
                                    self.navigateTo = AnyView(DuaView(dua: dua))
                                } else if let ziyarat = ibadah.ziyarat {
                                    self.navigateTo = AnyView(ZiyaratView(ziyarat: ziyarat))
                                } else if let amaal = ibadah.amaal {
                                    self.navigateTo = AnyView(AmaalView(amaal: amaal))
                                }
                            }
                            
                            ignoreNavigationGesture = false
                        })
                    )
                }
            }
        }
    }
    
    private func favoriteIbadah(ibadah: Ibadah) {
        if let favorite = favorites.first(where: { favorite in
            if let dua = ibadah.dua {
                return favorite.duaId == dua.id
            } else if let ziyarat = ibadah.ziyarat {
                return favorite.ziyaratId == ziyarat.id
            } else if let amaal = ibadah.amaal {
                return favorite.amaalId == amaal.id
            }
            
            return false
        }) {
            context.delete(favorite)
        } else {
            let favorite = Favorite(context: context)
            
            if let dua = ibadah.dua {
                favorite.duaId = Int64(dua.id)
            } else if let ziyarat = ibadah.ziyarat {
                favorite.ziyaratId = Int64(ziyarat.id)
            } else if let amaal = ibadah.amaal {
                favorite.amaalId = Int64(amaal.id)
            }
            
            if let highestPosition = favorites.filter({ $0.duaId != 0 }).max(by: { $0.position < $1.position })?.position {
                favorite.position = Int64(highestPosition + 1)
            } else {
                favorite.position = Int64(1)
            }
        }
        
        try? context.save()
    }
}

#Preview {
    FavoritesView(showFavoritesView: .constant(true), navigateTo: .constant(nil))
}
