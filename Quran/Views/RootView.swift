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
    
    @State private var showSettingsView: Bool = false
    
    var body: some View {
        TabView {
            NavigationStack {
                QuranView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { settingsToolbarButton }
                    }
            }
            .tabItem {
                Label("Quran", systemImage: "book")
            }
            
            NavigationStack {
                DuasView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { settingsToolbarButton }
                    }
            }
            .tabItem {
                Label("Du'as", systemImage: "book.closed")
            }
            
            NavigationStack {
                PrayerTimesView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { settingsToolbarButton }
                    }
            }
            .tabItem {
                Label("Times", systemImage: "calendar")
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
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
    
    private var settingsToolbarButton: some View {
        Button {
            self.showSettingsView.toggle()
        } label: {
            Image(systemName: "gear")
                .foregroundStyle(Color.primary)
        }
    }
}

#Preview {
    RootView()
}
