//
//  ZiaraahView.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import SwiftUI
import CoreData

struct ZiaraahView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var ziyaratModel: ZiyaratModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(ziyaratModel.ziaraah) { ziyarat in
                    NavigationLink {
                        ZiyaratView(ziyarat: ziyarat)
                    } label: {
                        ZiyaratCard(context: viewContext, favorites: favorites, ziyarat: ziyarat)
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Ziaraah")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct ZiyaratCard: View {
    let context: NSManagedObjectContext
    let favorites: FetchedResults<Favorite>
    
    let ziyarat: Ziyarat
    
    var body: some View {
        HStack(spacing: 15) {
            Text(String(ziyarat.id))
                .bold()
                .overlay {
                    Image(systemName: "diamond")
                        .font(.system(size: 40))
                        .fontWeight(.ultraLight)
                }
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(ziyarat.title)
                    .fontWeight(.heavy)
                
                if let subtitle = ziyarat.subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Button {
                favoriteZiyarat()
            } label: {
                if favorites.contains(where: { favorite in
                    favorite.ziyaratId == ziyarat.id
                }) {
                    Image(systemName: "star.fill")
                } else {
                    Image(systemName: "star")
                }
            }
        }
        .foregroundStyle(Color.primary)
        .padding()
        .frame(height: 75)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
    
    private func favoriteZiyarat() {
        if let favorite = favorites.first(where: { favorite in
            favorite.ziyaratId == ziyarat.id
        }) {
            context.delete(favorite)
        } else {
            let favorite = Favorite(context: context)
            favorite.ziyaratId = Int64(ziyarat.id)
        }
        
        try? context.save()
    }
}

#Preview {
    ZiaraahView()
}
