//
//  IbadatView.swift
//  Quran
//
//  Created by Ali Earp on 02/09/2024.
//

import SwiftUI
import CoreData

struct IbadatView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var ibadat: [Ibadah]
    let navigationTitle: String
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
    @State private var selectedIbadah: Ibadah?
    
    @State private var timer: Timer?
    @State private var favoriting: Bool = false
    @State private var heartLocation: CGPoint?
    @State private var heartRotation: Angle = Angle(degrees: Double.random(in: -45...45))
    
    @State private var ignoreNavigationGesture: Bool = false
    
    @State private var editMode: Bool = false
    @State private var draggedIbadah: Ibadah?
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(Array(orderedIbadat.enumerated()), id: \.offset) { index, ibadah in
                    let isFavorite = isFavorite(ibadah: ibadah)
                    
                    Button {
                        
                    } label: {
                        if editMode && isFavorite {
                            IbadahCard(ignoreNavigationGesture: $ignoreNavigationGesture, index: index, ibadah: ibadah, isFavorite: isFavorite, editMode: $editMode) {
                                favoriteIbadah(ibadah: ibadah)
                            }
                            .onDrag {
                                self.draggedIbadah = ibadah
                                return NSItemProvider()
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(context: viewContext, destinationItem: ibadah, ibadat: $ibadat, draggedItem: $draggedIbadah, favorites: favorites))
                        } else {
                            IbadahCard(ignoreNavigationGesture: $ignoreNavigationGesture, index: index, ibadah: ibadah, isFavorite: isFavorite, editMode: $editMode) {
                                favoriteIbadah(ibadah: ibadah)
                            }
                        }
                    }
                    .simultaneousGesture(
                        SpatialTapGesture(count: 2, coordinateSpace: .global).onEnded { location in
                            favoriteIbadah(ibadah: ibadah)
                            
                            self.heartLocation = nil
                            timer?.invalidate()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation {
                                    self.favoriting = !isFavorite
                                    self.heartLocation = location.location
                                }
                            }
                        }.exclusively(before: TapGesture(count: 1).onEnded {
                            if !ignoreNavigationGesture {
                                self.selectedIbadah = ibadah
                            }
                            
                            ignoreNavigationGesture = false
                        })
                    )
                }
            }.padding(.horizontal)
        }
        .navigationDestination(item: $selectedIbadah) { ibadah in
            if let dua = ibadah.dua {
                DuaView(dua: dua)
            } else if let ziyarat = ibadah.ziyarat {
                ZiyaratView(ziyarat: ziyarat)
            } else if let amaal = ibadah.amaal {
                AmaalView(amaal: amaal)
            }
        }
        .overlay {
            if let heartLocation = heartLocation {
                Image(systemName: favoriting ? "heart.fill" : "heart.slash.fill")
                    .font(.largeTitle)
                    .foregroundStyle(favoriting ? Color.red : Color(.darkGray))
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        self.editMode.toggle()
                    }
                } label: {
                    Text(editMode ? "Done" : "Edit")
                        .font(.headline)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
    
    private var orderedIbadat: [Ibadah] {
        let favoriteIbadat = ibadat.filter { ibadah in
            if let dua = ibadah.dua {
                return favorites.contains { $0.duaId == dua.id }
            } else if let ziyarat = ibadah.ziyarat {
                return favorites.contains { $0.ziyaratId == ziyarat.id }
            } else if let amaal = ibadah.amaal {
                return favorites.contains { $0.amaalId == amaal.id }
            }
            
            return false
        }.sorted { ibadah1, ibadah2 in
            if let dua1 = ibadah1.dua, let dua2 = ibadah2.dua {
                if let favorite1 = favorites.first(where: { favorite in
                    favorite.duaId == dua1.id
                }), let favorite2 = favorites.first(where: { favorite in
                    favorite.duaId == dua2.id
                }) {
                    return favorite1.position < favorite2.position
                }
            } else if let ziyarat1 = ibadah1.ziyarat, let ziyarat2 = ibadah2.ziyarat {
                if let favorite1 = favorites.first(where: { favorite in
                    favorite.ziyaratId == ziyarat1.id
                }), let favorite2 = favorites.first(where: { favorite in
                    favorite.ziyaratId == ziyarat2.id
                }) {
                    return favorite1.position < favorite2.position
                }
            } else if let amaal1 = ibadah1.amaal, let amaal2 = ibadah2.amaal {
                if let favorite1 = favorites.first(where: { favorite in
                    favorite.amaalId == amaal1.id
                }), let favorite2 = favorites.first(where: { favorite in
                    favorite.amaalId == amaal2.id
                }) {
                    return favorite1.position < favorite2.position
                }
            }
            
            return false
        }
        
        let unfavoriteIbadat = ibadat.filter { ibadah in
            if let dua = ibadah.dua {
                return !favorites.contains { $0.duaId == dua.id }
            } else if let ziyarat = ibadah.ziyarat {
                return !favorites.contains { $0.ziyaratId == ziyarat.id }
            } else if let amaal = ibadah.amaal {
                return !favorites.contains { $0.amaalId == amaal.id }
            }
            
            return true
        }
        
        return favoriteIbadat + unfavoriteIbadat
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
            viewContext.delete(favorite)
        } else {
            let favorite = Favorite(context: viewContext)
            
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
        
        try? viewContext.save()
    }
    
    private func isFavorite(ibadah: Ibadah) -> Bool {
        if let dua = ibadah.dua {
            return favorites.contains { $0.duaId == dua.id }
        } else if let ziyarat = ibadah.ziyarat {
            return favorites.contains { $0.ziyaratId == ziyarat.id }
        } else if let amaal = ibadah.amaal {
            return favorites.contains { $0.amaalId == amaal.id }
        }
        
        return false
    }
}

struct IbadahCard: View {
    @Binding var ignoreNavigationGesture: Bool
    
    let index: Int
    let ibadah: Ibadah
    
    let isFavorite: Bool
    @Binding var editMode: Bool
    let favoriteIbadah: () -> ()
    
    var body: some View {
        HStack(spacing: 15) {
            Text(String(index + 1))
                .bold()
                .overlay {
                    Image(systemName: "diamond")
                        .font(.system(size: 40))
                        .fontWeight(.ultraLight)
                }
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                if let title = ibadah.dua?.title ?? ibadah.ziyarat?.title ?? ibadah.amaal?.title {
                    Text(title)
                        .fontWeight(.heavy)
                }
                
                if let subtitle = ibadah.dua?.subtitle ?? ibadah.ziyarat?.subtitle ?? ibadah.amaal?.subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Button {
                
            } label: {
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.red)
                        .animation(.bouncy, value: editMode)
                } else {
                    Image(systemName: "heart")
                }
            }
            .highPriorityGesture(TapGesture().onEnded {
                ignoreNavigationGesture = true
                favoriteIbadah()
            })
            
            if editMode && isFavorite {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(Color.secondary)
            }
        }
        .foregroundStyle(Color.primary)
        .padding()
        .frame(height: 75)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct DropViewDelegate: DropDelegate {
    let context: NSManagedObjectContext
    
    let destinationItem: Ibadah
    @Binding var ibadat: [Ibadah]
    @Binding var draggedItem: Ibadah?
    
    let favorites: FetchedResults<Favorite>
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        if let draggedItem = draggedItem,
           let fromIndex = ibadat.firstIndex(of: draggedItem),
           let toIndex = ibadat.firstIndex(of: destinationItem),
           fromIndex != toIndex,
           let draggedItemFavorite = favorites.first(where: { favorite in
               if let dua = draggedItem.dua {
                   return favorite.duaId == dua.id
               } else if let ziyarat = draggedItem.ziyarat {
                   return favorite.ziyaratId == ziyarat.id
               } else if let amaal = draggedItem.amaal {
                   return favorite.amaalId == amaal.id
               }
               
               return false
           }),
           let destinationItemFavorite = favorites.first(where: { favorite in
               if let dua = destinationItem.dua {
                   return favorite.duaId == dua.id
               } else if let ziyarat = destinationItem.ziyarat {
                   return favorite.ziyaratId == ziyarat.id
               } else if let amaal = destinationItem.amaal {
                   return favorite.amaalId == amaal.id
               }
               
               return false
           })
        {
            withAnimation {
                let tempPosition = draggedItemFavorite.position
                
                draggedItemFavorite.position = destinationItemFavorite.position
                destinationItemFavorite.position = tempPosition
                
                try? context.save()
            }
        }
    }
}

#Preview {
    IbadatView(ibadat: .constant([]), navigationTitle: "")
}
