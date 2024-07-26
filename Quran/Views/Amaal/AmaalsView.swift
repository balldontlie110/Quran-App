//
//  AmaalsView.swift
//  Quran
//
//  Created by Ali Earp on 20/07/2024.
//

import SwiftUI
import CoreData

struct AmaalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @EnvironmentObject private var amaalModel: AmaalModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Favorite.date, ascending: true)],
        animation: .default
    )
    
    private var favorites: FetchedResults<Favorite>
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(amaalModel.amaals) { amaal in
                    NavigationLink {
                        AmaalView(amaal: amaal)
                    } label: {
                        AmaalCard(context: viewContext, favorites: favorites, amaal: amaal)
                    }
                }
            }.padding(.horizontal)
        }
        .navigationTitle("Amaals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct AmaalCard: View {
    let context: NSManagedObjectContext
    let favorites: FetchedResults<Favorite>
    
    let amaal: Amaal
    
    var body: some View {
        HStack(spacing: 15) {
            Text(String(amaal.id))
                .bold()
                .overlay {
                    Image(systemName: "diamond")
                        .font(.system(size: 40))
                        .fontWeight(.ultraLight)
                }
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(amaal.title)
                    .fontWeight(.heavy)
                
                if let subtitle = amaal.subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
            
            Button {
                favoriteAmaal()
            } label: {
                if favorites.contains(where: { favorite in
                    favorite.amaalId == amaal.id
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
    
    private func favoriteAmaal() {
        if let favorite = favorites.first(where: { favorite in
            favorite.amaalId == amaal.id
        }) {
            context.delete(favorite)
        } else {
            let favorite = Favorite(context: context)
            favorite.amaalId = Int64(amaal.id)
        }
        
        try? context.save()
    }
}

#Preview {
    AmaalsView()
}
