//
//  RootView.swift
//  Quran
//
//  Created by Ali Earp on 14/06/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import WidgetKit

struct RootViewButton: Identifiable {
    let id: UUID = UUID()
    
    let view: AnyView
    let image: String
    let text: String
}

struct RootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var authenticationModel: AuthenticationModel
    @EnvironmentObject private var quranModel: QuranModel
    @EnvironmentObject private var quranFilterModel: QuranFilterModel
    @EnvironmentObject private var calendarModel: CalendarModel
    @EnvironmentObject private var duaModel: DuaModel
    @EnvironmentObject private var ziyaratModel: ZiyaratModel
    @EnvironmentObject private var amaalModel: AmaalModel
    @EnvironmentObject private var audioPlayer: AudioPlayer
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    @State private var mainNavigation: RootViewButton?
    
    @State private var showFavoritesView: Bool = false
    @State private var navigateTo: AnyView?
    
    @State private var showStreakView: Bool = false
    
    @AppStorage("streak") private var streak: Int = 0
    @AppStorage("streakDate") private var streakDate: Double = 0.0
    @AppStorage("streakWidgetUpdate") private var streakWidgetUpdate: Double = 0.0
    
    @State private var showSettingsView: Bool = false
    @State private var showSocialsView: Bool = false
    
    @Namespace private var namespace
    
    private let columns = [GridItem](repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                dateSection
                
                LazyVGrid(columns: columns) {
                    navigationButtons
                    
                    socialsButton
                }.padding(.horizontal, 10)
                
                NextPrayerView()
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
            .navigationDestination(isPresented: $showStreakView) {
                StreakView()
            }
            .refreshable {
                calendarModel.load()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    favoritesToolbarButton
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    streakInfoToolbarButton
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    userInformation
                }
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView(showSettingsView: $showSettingsView)
        }
        .sheet(isPresented: $showFavoritesView) {
            FavoritesView(showFavoritesView: $showFavoritesView, navigateTo: $navigateTo)
        }
        .sheet(isPresented: $showSocialsView) {
            SocialsView(showSocialsView: $showSocialsView)
        }
        .onAppear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
            }
        }
        .onAppear {
            createQuestionsBookmarkFolder()
            getLocalTranslation()
            checkStreak()
            
            quranFilterModel.quranModel = quranModel
            audioPlayer.colorScheme = colorScheme
        }
    }
    
    private var rootViewButtons: [RootViewButton] {
        [
            RootViewButton(view: AnyView(QuranView()), image: "quran", text: "Quran"),
            RootViewButton(view: AnyView(CalendarView()), image: "calendar", text: "Calendar"),
            RootViewButton(view: AnyView(EventsView()), image: "events", text: "Events"),
            RootViewButton(view: AnyView(IbadatView(ibadat: $duaModel.duas, navigationTitle: "Du'as")), image: "duas", text: "Du'as"),
            RootViewButton(view: AnyView(IbadatView(ibadat: $ziyaratModel.ziaraah, navigationTitle: "Ziaraah")), image: "ziaraah", text: "Ziaraah"),
            RootViewButton(view: AnyView(IbadatView(ibadat: $amaalModel.amaals, navigationTitle: "Amaals")), image: "amaals", text: "Amaals"),
            RootViewButton(view: AnyView(TasbeehView()), image: "tasbeeh", text: "Tasbeeh"),
            RootViewButton(view: AnyView(QiblaFinder()), image: "qibla", text: "Qibla"),
            RootViewButton(view: AnyView(QuestionsView()), image: "questions", text: "Questions"),
            RootViewButton(view: AnyView(DonationsView()), image: "donations", text: "Donations"),
            RootViewButton(view: AnyView(MadrassahView()), image: "madrassah", text: "Madrassah")
        ]
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
                Image("socials-\(colorScheme == .dark ? "dark" : "light")")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                
                Text("Socials")
                    .foregroundStyle(Color.primary)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 75)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(2.5)
        }
    }
    
    private var favoritesToolbarButton: some View {
        Button {
            self.showFavoritesView.toggle()
        } label: {
            Image(systemName: "heart")
                .foregroundStyle(Color.primary)
        }
    }
    
    private var streakInfoToolbarButton: some View {
        Button {
            self.showStreakView.toggle()
        } label: {
            StreakInfo(streak: streak, streakDate: Date(timeIntervalSince1970: streakDate), font: .body)
        }
    }
    
    private func checkStreak() {
        let streakDate = Date(timeIntervalSince1970: streakDate)
        
        if let interval = Calendar.current.dateComponents([.day], from: streakDate, to: Date()).day {
            if interval > 1 {
                streak = 0
            } else {
                NotificationManager.shared.streakReminderNotification(schedule: true)
            }
        }
        
        let streakWidgetUpdate = Date(timeIntervalSince1970: streakWidgetUpdate)
        
        if !Calendar.current.isDate(streakWidgetUpdate, inSameDayAs: Date()) {
            WidgetCenter.shared.reloadTimelines(ofKind: "QuranTimeWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
            
            self.streakWidgetUpdate = Date().timeIntervalSince1970
        }
    }
    
    private func updatePrayerTimes() {
        WidgetCenter.shared.reloadTimelines(ofKind: "QuranWidget")
    }
    
    @ViewBuilder
    private var userInformation: some View {
        if let user = authenticationModel.user {
            HStack(spacing: 0) {
                if let username = user.displayName {
                    Text("Salaam, \(username)")
                        .font(.headline)
                        .lineLimit(1)
                }
                
                if let photoURL = user.photoURL {
                    Button {
                        self.showSettingsView.toggle()
                    } label: {
                        WebImage(url: photoURL)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 25)
                            .clipShape(Circle())
                            .overlay { Circle().stroke(lineWidth: 1).foregroundStyle(Color.primary) }
                            .frame(width: 25, height: 25)
                    }
                }
            }
        } else {
            Button {
                self.showSettingsView.toggle()
            } label: {
                Image(systemName: "gear")
                    .foregroundStyle(Color.primary)
            }
        }
    }
    
    private var dateSection: some View {
        VStack {
            gregorianDate
            
            islamicDate
        }.padding(.top, 10)
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
            Text("\(calendarModel.day) \(calendarModel.month) \(calendarModel.year)")
        }.font(.system(.title2, weight: .bold))
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
        let translatorId = UserDefaultsController.shared.integer(forKey: "translatorId")
        
        guard translatorId != 131 else { return }
        
        quranModel.checkLocalTranslation(translatorId: Int(translatorId))
    }
    
    private func getLocalWBWTranslation() {
        guard let wbwTranslationId = UserDefaultsController.shared.string(forKey: "translationLanguage"), wbwTranslationId != "en" else { return }
        
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
                .bold()
                .minimumScaleFactor(.leastNonzeroMagnitude)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
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
