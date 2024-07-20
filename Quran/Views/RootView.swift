//
//  RootView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import CoreData

struct RootViewButton: Identifiable {
    let id: UUID = UUID()
    
    let view: AnyView
    let image: String
    let text: String
}

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var preferencesModel: PreferencesModel
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var calendarModel: EventsModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    @State private var showSettingsView: Bool = false
    
    @Namespace private var namespace
    
    private let columns = [GridItem](repeating: GridItem(.flexible()), count: 3)
    private let rootViewButtons: [RootViewButton] = [
        RootViewButton(view: AnyView(QuranView()), image: "quran", text: "Quran"),
        RootViewButton(view: AnyView(CalendarView()), image: "calendar", text: "Calendar"),
        RootViewButton(view: AnyView(EventsView()), image: "events", text: "Events"),
        RootViewButton(view: AnyView(DuasView()), image: "duas", text: "Du'as"),
        RootViewButton(view: AnyView(ZiaraahView()), image: "ziaraah", text: "Ziaraah"),
        RootViewButton(view: AnyView(AmaalsView()), image: "amaal", text: "Amaal"),
        RootViewButton(view: AnyView(QuestionsView()), image: "questions", text: "Questions"),
        RootViewButton(view: AnyView(DonationsView()), image: "donations", text: "Donations")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(rootViewButtons) { button in
                        if #available(iOS 18.0, *) {
                            NavigationLink {
                                button.view
                                    .navigationTransition(.zoom(sourceID: button.id, in: namespace))
                            } label: {
                                NavigationButton(button: button)
                            }.matchedTransitionSource(id: button.id, in: namespace)
                        } else {
                            NavigationLink {
                                button.view
                            } label: {
                                NavigationButton(button: button)
                            }
                        }
                    }
                    
                    youtubeButton
                }.padding(.horizontal, 10)
                
                dateSection
                
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
    
    private var dateSection: some View {
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
    
    let button: RootViewButton
    
    var body: some View {
        VStack(spacing: 15) {
            symbol
            
            Text(button.text)
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
    
    private var symbol: some View {
        Image("\(button.image)-\(colorScheme == .dark ? "dark" : "light")")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
    }
}

#Preview {
    RootView()
}
