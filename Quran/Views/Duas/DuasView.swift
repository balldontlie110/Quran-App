//
//  DuasView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import CoreData

struct DuasView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var duaModel: DuaModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(duaModel.duas) { dua in
                    NavigationLink {
                        DuaView(dua: dua)
                    } label: {
                        DuaCard(context: viewContext, favorites: favorites, dua: dua)
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Du'as")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct DuaCard: View {
    let context: NSManagedObjectContext
    let favorites: FetchedResults<Favorite>
    
    let dua: Dua
    
    var body: some View {
        HStack(spacing: 15) {
            Text(String(dua.id))
                .bold()
                .overlay {
                    Image(systemName: "diamond")
                        .font(.system(size: 40))
                        .fontWeight(.ultraLight)
                }
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(dua.title)
                    .fontWeight(.heavy)
                
                if let subtitle = dua.subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Button {
                favoriteDua()
            } label: {
                if favorites.contains(where: { favorite in
                    favorite.duaId == dua.id
                }) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color.red)
                } else {
                    Image(systemName: "heart")
                }
            }
        }
        .foregroundStyle(Color.primary)
        .padding()
        .frame(height: 75)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private func favoriteDua() {
        if let favorite = favorites.first(where: { favorite in
            favorite.duaId == dua.id
        }) {
            context.delete(favorite)
        } else {
            let favorite = Favorite(context: context)
            favorite.duaId = Int64(dua.id)
        }
        
        try? context.save()
    }
}

#Preview {
    DuasView()
}
