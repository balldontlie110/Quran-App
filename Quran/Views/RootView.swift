//
//  RootView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    var body: some View {
        TabView {
            QuranView()
                .tabItem {
                    Label("Quran", systemImage: "book")
                }
            
            DuasView()
                .tabItem {
                    Label("Du'as", systemImage: "book.closed")
                }
            
            PrayerTimesView()
                .tabItem {
                    Label("Times", systemImage: "calendar")
                }
        }
        .onAppear {
            if !bookmarkedFolders.contains(where: { bookmarkedFolder in
                bookmarkedFolder.questionFolder == true
            }) {
                let bookmarkedFolder = BookmarkedFolder(context: viewContext)
                bookmarkedFolder.date = Date()
                bookmarkedFolder.id = UUID()
                bookmarkedFolder.title = "Questions"
                bookmarkedFolder.questionFolder = true
                
                do {
                    try viewContext.save()
                } catch {
                    
                }
            }
        }
    }
}

#Preview {
    RootView()
}
