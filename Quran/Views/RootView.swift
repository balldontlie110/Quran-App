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
    @EnvironmentObject private var calendarModel: CalendarModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    @State private var mainNavigation: RootViewButton?
    
    @State private var showFavoritesView: Bool = false
    @State private var navigateTo: AnyView?
    
    @State private var showSettingsView: Bool = false
    @State private var showSocialsView: Bool = false
    
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
                    navigationButtons
                    
                    socialsButton
                }.padding(.horizontal, 10)
                
                dateSection
                PrayerTimesView()
            }
            .scrollIndicators(.hidden)
            .navigationDestination(item: $mainNavigation) { button in
                if #available(iOS 18.0, *) {
                    button.view
                        .navigationTransition(.zoom(sourceID: button.id, in: namespace))
                } else {
                    button.view
                }
            }
            .navigationDestination(item: $navigateTo) { view in
                view
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    favoritesToolbarButton
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    settingsToolbarButton
                }
            }
        }
        .sheet(isPresented: $showFavoritesView) {
            FavoritesView(showFavoritesView: $showFavoritesView, navigateTo: $navigateTo)
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(showSettingsView: $showSettingsView)
        }
        .sheet(isPresented: $showSocialsView) {
            SocialsView(showSocialsView: $showSocialsView)
        }
        .onAppear {
            createQuestionsBookmarkFolder()
            getLocalTranslation()
        }
    }
    
    private var navigationButtons: some View {
        ForEach(rootViewButtons) { button in
            if #available(iOS 18.0, *) {
                Button {
                    self.mainNavigation = button
                } label: {
                    NavigationButton(button: button)
                }.matchedTransitionSource(id: button.id, in: namespace)
            } else {
                Button {
                    self.mainNavigation = button
                } label: {
                    NavigationButton(button: button)
                }
            }
        }
    }
    
    private var socialsButton: some View {
        Button {
            self.showSocialsView.toggle()
        } label: {
            VStack(spacing: 15) {
                Image("\("socials")-\(colorScheme == .dark ? "dark" : "light")")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                Text("Socials")
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
    
    private var dateSection: some View {
        VStack {
            gregorianDate
            
            islamicDate
        }.padding(.top)
    }
    
    private var gregorianDate: Text {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        
        return Text(formatter.string(from: Date()))
            .foregroundStyle(Color.secondary)
            .font(.system(.caption, weight: .bold))
    }
    
    private var islamicDate: some View {
        HStack {
            Text(calendarModel.day)
            Text(calendarModel.month)
            Text(calendarModel.year)
        }.font(.system(.title2, weight: .bold))
    }
    
    private var favoritesToolbarButton: some View {
        Button {
            self.showFavoritesView.toggle()
        } label: {
            Image(systemName: "heart")
                .foregroundStyle(Color.primary)
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
            
            try? viewContext.save()
        }
    }
    
    private func getLocalTranslation() {
        guard let translationId = preferencesModel.preferences?.translationId, translationId != 131 else { return }
        
        quranModel.checkLocalTranslation(translationId: Int(translationId))
    }
    
    private func getLocalWBWTranslation() {
        guard let wbwTranslationId = preferencesModel.preferences?.translationLanguage, wbwTranslationId != "en" else { return }
        
        quranModel.checkLocalWBWTranslation(wbwTranslationId: wbwTranslationId)
    }
}

extension AnyView: @retroactive Hashable, Equatable {
    var id: UUID {
        UUID()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static public func ==(lhs: AnyView, rhs: AnyView) -> Bool {
        return lhs.id == rhs.id
    }
}

extension RootViewButton: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        .multilineTextAlignment(.center)
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
