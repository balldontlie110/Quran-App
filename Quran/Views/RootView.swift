//
//  RootView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import CoreData

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Namespace private var namespace
    
    @EnvironmentObject private var preferencesModel: PreferencesModel
    @EnvironmentObject private var quranModel: QuranModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    @State private var showSettingsView: Bool = false
    
    private let columns = [GridItem](repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    NavigationButton(namespace: namespace, view: QuranView(), systemImage: "book", text: "Quran")
                    NavigationButton(namespace: namespace, view: DuasView(), systemImage: "book.closed", text: "Du'as")
                    NavigationButton(namespace: namespace, view: QuestionsView(), systemImage: "questionmark.bubble", text: "Questions")
                }
                .padding(.horizontal, 10)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        settingsToolbarButton
                    }
                }
                
                PrayerTimesView()
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(showSettingsView: $showSettingsView)
        }
        .onAppear {
            createQuestionsBookmarkFolder()
            getLocalTranslation()
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
    
    private func createQuestionsBookmarkFolder() {
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
                print(error)
            }
        }
    }
    
    private func getLocalTranslation() {
        if let translationId = preferencesModel.preferences?.translationId, translationId != 131 {
            quranModel.checkLocalTranslation(translationId: Int(translationId))
        }
    }
}

struct NavigationButton: View {
    let namespace: Namespace.ID
    
    let view: any View
    let systemImage: String
    let text: String
    
    let sourceId = UUID()
    
    var body: some View {
        NavigationLink {
            if #available(iOS 18.0, *) {
                AnyView(view)
                    .navigationTransition(.zoom(sourceID: sourceId, in: namespace))
            } else {
                AnyView(view)
            }
        } label: {
            VStack(spacing: 15) {
                if #available(iOS 18.0, *) {
                    Group {
                        Image(systemName: systemImage)
                        Text(text)
                    }.matchedTransitionSource(id: sourceId, in: namespace)
                } else {
                    Group {
                        Image(systemName: systemImage)
                        Text(text)
                    }
                }
            }
            .foregroundStyle(Color.primary)
            .bold()
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 75)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(2.5)
        }
    }
}

#Preview {
    RootView()
}
