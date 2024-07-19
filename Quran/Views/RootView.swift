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
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var namespace
    
    @EnvironmentObject private var preferencesModel: PreferencesModel
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var calendarModel: EventsModel
    
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
                    NavigationButton(namespace: namespace, view: QuranView(), image: "quran", text: "Quran")
                    NavigationButton(namespace: namespace, view: EmptyView(), image: "calendar", text: "Calendar")
                    NavigationButton(namespace: namespace, view: EventsView(), image: "events", text: "Events")
                    
                    NavigationButton(namespace: namespace, view: DuasView(), image: "duas", text: "Du'as")
                    NavigationButton(namespace: namespace, view: ZiaraahView(), image: "ziaraah", text: "Ziaraah")
                    NavigationButton(namespace: namespace, view: EmptyView(), image: "amaal", text: "Amaal")
                    
                    NavigationButton(namespace: namespace, view: QuestionsView(), image: "questions", text: "Questions")
                    NavigationButton(namespace: namespace, view: DonationsView(), image: "donations", text: "Donations")
                    youtubeButton
                }.padding(.horizontal, 10)
                
                islamicDate
                
                PrayerTimesView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsToolbarButton
                }
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
    
    private var islamicDate: some View {
        VStack {
            Text(todaysDate())
                .foregroundStyle(Color.secondary)
                .font(.system(.caption, weight: .bold))
            
            HStack {
                Text(calendarModel.day)
                Text(calendarModel.month)
                Text(calendarModel.year)
            }.font(.system(.title2, weight: .bold))
        }
        .padding(.top)
    }
    
    private var youtubeButton: some View {
        Group {
            if let hyderiUrl = URL(string: "https://www.youtube.com/@hyderi/live") {
                Link(destination: hyderiUrl) {
                    VStack(spacing: 15) {
                        Image("\("youtube")-\(colorScheme == .dark ? "dark" : "light")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        
                        Text("Live")
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
    }
    
    private func todaysDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        return formatter.string(from: Date())
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
    @Environment(\.colorScheme) private var colorScheme
    
    let namespace: Namespace.ID
    
    let view: any View
    let image: String
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
                        symbol
                        
                        Text(text)
                    }.matchedTransitionSource(id: sourceId, in: namespace)
                } else {
                    Group {
                        symbol
                        
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
    
    private var symbol: some View {
        Image("\(image)-\(colorScheme == .dark ? "dark" : "light")")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
    }
}

#Preview {
    RootView()
}
