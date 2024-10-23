//
//  SurahView.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI
import CoreData
import Combine
import WStack
import WidgetKit
import UserNotifications

struct SurahView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var surahFilterModel: SurahFilterModel = SurahFilterModel()
    
    let surah: Surah
    
    @State private var readingMode: Bool = false
    
    @State private var showVerseSelector: Bool = false
    @State private var scrollPosition: Int?
    @State private var previousScrollPosition: Int?
    private let dummyId = 0
    
    var initialScroll: Int?
    var initialSearchText: String?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    @State private var showBookmarkAlert: Verse?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyTime.date, ascending: true)],
        animation: .default
    )
    
    private var weeks: FetchedResults<WeeklyTime>
    
    @State private var timer: Timer?
    @State private var time: Int = 0
    
    @EnvironmentObject private var audioPlayer: AudioPlayer
    @State private var sliderValue: Double = 0.0
    
    @AppStorage("wordByWord") private var wordByWord: Bool = false
    @AppStorage("continuePlaying") private var continuePlaying = false
    
    @AppStorage("streak") private var streak: Int = 0
    @AppStorage("streakDate") private var streakDate: Double = 0.0
    @AppStorage("dailyQuranGoal") private var dailyQuranGoal: Int = 0
    
    @State private var streakExtended: Bool = false
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                if proxy.size.height >= proxy.size.width && !readingMode {
                    searchBar
                    
                    Divider()
                }
                
                ScrollView {
                    header
                    
                    if surahFilterModel.isLoading {
                        Spacer().containerRelativeFrame([.horizontal, .vertical])
                        
                        ProgressView()
                    } else {
                        let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
                        
                        LazyVStack(spacing: fontNumber == 1 ? 20 : fontNumber == 2 ? 0 : 10) {
                            ForEach(surahFilterModel.filteredVerses) { verse in
                                if let index = surahFilterModel.filteredVerses.firstIndex(where: { $0.id == verse.id }) {
                                    VerseRow(
                                        verse: verse,
                                        versesCount: surahFilterModel.filteredVerses.count,
                                        verseIndex: index,
                                        surahId: surah.id,
                                        searchText: surahFilterModel.searchText,
                                        readingMode: readingMode,
                                        bookmarkedVerses: bookmarkedVerses,
                                        addBookmark: {
                                            withAnimation { self.showBookmarkAlert = verse }
                                        },
                                        removeBookmark: { verse in
                                            removeBookmark(verse)
                                        },
                                        audioPlayer: audioPlayer
                                    ).id(verse.id)
                                }
                            }
                        }.scrollTargetLayout()
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
                .scrollPosition(id: $scrollPosition, anchor: .top)
                .onChange(of: surahFilterModel.filteredVerses) { _, _ in
                    if let previousScrollPosition = previousScrollPosition {
                        scrollPosition = dummyId
                        Task { @MainActor in
                            scrollPosition = previousScrollPosition
                        }
                    }
                }
                .onChange(of: scrollPosition) { oldVal, newVal in
                    if let newVal = newVal, newVal != dummyId {
                        previousScrollPosition = newVal
                    }
                }
                .onChange(of: proxy.size) {
                    if let previousScrollPosition = previousScrollPosition {
                        scrollPosition = dummyId
                        Task { @MainActor in
                            scrollPosition = previousScrollPosition
                        }
                    }
                }
                .overlay(alignment: .top) {
                    if streakExtended {
                        HStack(alignment: .top) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(Color.streak)
                            
                            if streak > 1 {
                                Text("Great Job! You extended your streak to \(streak) days with \(timeToEndOfDayString()) left in the day.")
                            } else {
                                Text("Great Job! You've started a streak. Recite \(dailyQuranGoal) minutes of Quran every day to extend your streak.")
                            }
                        }
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(radius: 5)
                        .transition(.move(edge: .top))
                        .padding(10)
                    }
                }
            }
        }
        .disabled(showVerseSelector || showBookmarkAlert != nil)
        .onAppear {
            surahFilterModel.surah = surah
            
            if let initialSearchText = initialSearchText {
                surahFilterModel.searchText = initialSearchText
            }
            
            audioPlayer.surahNumber = String(surah.id)
            audioPlayer.surahName = surah.transliteration
            audioPlayer.nextVerse = nextVerse
            audioPlayer.previousVerse = previousVerse
            audioPlayer.reciterSubfolder = UserDefaultsController.shared.string(forKey: "reciterSubfolder")
            audioPlayer.colorScheme = colorScheme
            
            initialiseScrollPosition()
            initialiseQuranTime()
        }
        .onChange(of: time) { _, _ in
            if let lastWeekDaySeconds = weeks.last?.days?.sortedAllObjects()?.last?.seconds {
                let totalSeconds = Int(lastWeekDaySeconds) + time
                
                if lastWeekDaySeconds < (dailyQuranGoal * 60) && totalSeconds >= (dailyQuranGoal * 60) {
                    logQuranTime()
                }
            }
        }
        .onDisappear {
            audioPlayer.resetPlayer()
            logQuranTime()
        }
        .onChange(of: colorScheme) { _, _ in
            audioPlayer.colorScheme = colorScheme
        }
        .onTapGesture {
            hideBookmarkAlertAndVerseSelector()
        }
        .onReceive(audioPlayer.$currentTime) { newValue in
            sliderValue = newValue
        }
        .onChange(of: audioPlayer.showAudioPlayerSlider) { _, newValue in
            if newValue == false {
                audioPlayer.resetPlayer()
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
            }
        }.onDisappear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
            }
        }
        .navigationTitle(surah.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                verseSelectorButton
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button {
                    self.readingMode = false
                } label: {
                    Image(systemName: readingMode ? "book.closed" : "book.closed.fill")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button {
                    self.readingMode = true
                } label: {
                    Image(systemName: readingMode ? "book.fill" : "book")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
        }
        .brightness((showVerseSelector || showBookmarkAlert != nil) ? (colorScheme == .dark ? -0.5 : 0.5) : 0)
        .overlay(alignment: .center) {
            verseSelector
        }
        .overlay(alignment: .center) {
            AddBookmarkView(viewContext: viewContext, showBookmarkAlert: $showBookmarkAlert, bookmarkedVerses: bookmarkedVerses, surahId: surah.id, surahTransliteration: surah.transliteration)
        }
        .overlay(alignment: .bottom) {
            audioPlayerSlider
        }
    }
    
    private func timeToEndOfDayString() -> String {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        
        if let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) {
            let timeToEndOfDay = endOfDay.timeIntervalSince(Date())
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .full
            formatter.maximumUnitCount = 1
            
            return formatter.string(from: timeToEndOfDay) ?? ""
        }
        
        return ""
    }
    
    private func initialiseQuranTime() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.time += 1
        }
        
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
        
        if let currentWeekDate = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date()).date {
            if let lastWeek = weeks.last, let lastWeekDate = lastWeek.date, let lastDate = lastWeek.days?.sortedAllObjects()?.last?.date {
                if !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
                    if lastWeekDate == currentWeekDate {
                        newDailyTime(for: lastWeek)
                        
                        try? viewContext.save()
                        
                        return
                    } else {
                        newWeeklyTime(with: currentWeekDate)
                    }
                }
            } else {
                newWeeklyTime(with: currentWeekDate)
            }
        }
    }
    
    private func newWeeklyTime(with currentWeekDate: Date) {
        let weeklyTime = WeeklyTime(context: viewContext)
        
        weeklyTime.date = currentWeekDate
        
        newDailyTime(for: weeklyTime)
        
        try? viewContext.save()
    }
    
    private func newDailyTime(for weeklyTime: WeeklyTime) {
        let dailyTime = DailyTime(context: viewContext)
        
        dailyTime.date = Calendar.current.startOfDay(for: Date())
        dailyTime.seconds = 0
        
        weeklyTime.days = NSSet(set: weeklyTime.days?.adding(dailyTime) ?? Set())
    }
    
    private func logQuranTime() {
        if let lastWeekDay = weeks.last?.days?.sortedAllObjects()?.last {
            let previousSeconds = lastWeekDay.seconds
            let newSeconds = lastWeekDay.seconds + Int64(time)
            
            lastWeekDay.seconds = newSeconds
            
            try? viewContext.save()
            
            WidgetCenter.shared.reloadTimelines(ofKind: "QuranTimeWidget")
            
            if previousSeconds < (dailyQuranGoal * 60) && newSeconds >= (dailyQuranGoal * 60) {
                streak += 1
                streakDate = Date().timeIntervalSince1970
                
                withAnimation {
                    streakExtended = true
                }
                
                WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
                
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: ["streak"])
                
                let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                    streakExtended = false
                }
                
                RunLoop.current.add(timer, forMode: .common)
            }
        }
        
        timer?.invalidate()
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.secondary)
                    
                    TextField("Search", text: $surahFilterModel.searchText)
                    
                    if surahFilterModel.searchText != "" {
                        Button {
                            surahFilterModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }.padding(5)
                
                scrollToVerseButtons
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            wordByWordToggle
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
    
    private var scrollToVerseButtons: some View {
        HStack {
            Divider()
                .fixedSize()
            
            Button {
                if let previousVerse = surahFilterModel.filteredVerses.last(where: { verse in
                    verse.id < (scrollPosition ?? 1)
                }) ?? surahFilterModel.filteredVerses.last {
                    Task { @MainActor in
                        self.scrollPosition = previousVerse.id
                    }
                }
            } label: {
                Image(systemName: "chevron.up")
                    .foregroundStyle(Color.primary)
                    .bold()
            }.padding(5)
            
            Divider()
                .fixedSize()
            
            Button {
                if let nextVerse = surahFilterModel.filteredVerses.first(where: { verse in
                    verse.id > (scrollPosition ?? 1)
                }) ?? surahFilterModel.filteredVerses.first {
                    Task { @MainActor in
                        self.scrollPosition = nextVerse.id
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .foregroundStyle(Color.primary)
                    .bold()
            }.padding(5)
        }.padding(.trailing, 5)
    }
    
    private var wordByWordToggle: some View {
        Button {
            self.wordByWord.toggle()
        } label: {
            let wordByWordState = wordByWord ? "On" : "Off"
            let colorScheme = colorScheme == .dark ? "dark" : "light"
            
            Image("wordByWord\(wordByWordState)-\(colorScheme)")
                .resizable()
                .scaledToFit()
                .frame(height: 25)
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
            
            let defaultFont = Font.system(size: 50, weight: .bold)
            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: 50)
            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: 50)
            
            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
            
            Text(surah.name)
                .font(font)
            
            Text(surah.translation)
                .font(.system(size: 20, weight: .semibold))
        }.padding(.top)
    }
    
    private var verseSelectorButton: some View {
        Button {
            withAnimation { self.showVerseSelector.toggle() }
        } label: {
            let verseNumber = (scrollPosition == 0 ? previousScrollPosition : scrollPosition) ?? 1
            
            Text("Verse: \(String(verseNumber))")
                .bold()
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }.disabled(showBookmarkAlert != nil)
    }
    
    @ViewBuilder
    private var verseSelector: some View {
        if showVerseSelector {
            Picker("", selection: $scrollPosition) {
                ForEach(0..<surah.total_verses, id: \.self) { number in
                    Text(String(number + 1))
                        .tag(number + 1)
                }
            }
            .pickerStyle(.wheel)
            .padding()
            .background(Material.thin)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal, 50)
        }
    }
    
    @ViewBuilder
    private var audioPlayerSlider: some View {
        if audioPlayer.url != nil && audioPlayer.showAudioPlayerSlider {
            HStack {
                Button {
                    audioPlayer.playPause()
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                }
                
                Text(formatTime(audioPlayer.currentTime))
                
                Slider(value: $sliderValue, in: 0...audioPlayer.duration, onEditingChanged: sliderEditingChanged)
                
                Text(formatTime(audioPlayer.duration))
                
                Button {
                    continuePlaying.toggle()
                } label: {
                    Image(systemName: "arrow.forward.circle")
                        .font(.system(size: 20, weight: continuePlaying ? .bold : .thin))
                        .foregroundStyle(continuePlaying ? Color.accentColor : Color.primary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .draggableView(isPresented: $audioPlayer.showAudioPlayerSlider)
            .shadow(radius: 5)
            .padding()
        }
    }
    
    private func initialiseScrollPosition() {
        scrollPosition = dummyId
        Task { @MainActor in
            self.scrollPosition = initialScroll
        }
    }
    
    private func hideBookmarkAlertAndVerseSelector() {
        withAnimation {
            self.showBookmarkAlert = nil
            self.showVerseSelector = false
        }
    }
    
    private func removeBookmark(_ verse: BookmarkedVerse) {
        viewContext.delete(verse)
        
        try? viewContext.save()
    }
    
    private func sliderEditingChanged(editingStarted: Bool) {
        if !editingStarted {
            audioPlayer.seek(to: sliderValue)
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func nextVerse(verse: Verse) -> Verse? {
        if let nextVerse = surah.verses.first(where: { check in
            check.id == verse.id + 1
        }) {
            scrollPosition = dummyId
            Task { @MainActor in
                withAnimation {
                    self.scrollPosition = nextVerse.id
                }
            }
            
            return nextVerse
        }
        
        return nil
    }
    
    private func previousVerse(verse: Verse) -> Verse? {
        if let previousVerse = surah.verses.first(where: { check in
            check.id == verse.id - 1
        }) {
            scrollPosition = dummyId
            Task { @MainActor in
                withAnimation {
                    self.scrollPosition = previousVerse.id
                }
            }
            
            return previousVerse
        }
        
        return nil
    }
}

struct VerseRow: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let verse: Verse
    let versesCount: Int
    let verseIndex: Int
    let surahId: Int
    
    let searchText: String
    
    let readingMode: Bool
    
    let bookmarkedVerses: FetchedResults<BookmarkedVerse>
    let addBookmark: () -> ()
    let removeBookmark: (BookmarkedVerse) -> ()
    
    @StateObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    verseButtons
                    
                    text
                }
                
                translation
            }
            .padding(.vertical, readingMode ? 0 : 20)
            .contextMenu {
                contextMenuBookmarkButton
                contextMenuAudioButton
            }
            
            if verseIndex != versesCount - 1 && !readingMode {
                Divider()
            }
        }.padding(.horizontal, 10)
    }
    
    private var text: some View {
        HStack(alignment: .top) {
            if !readingMode {
                Spacer()
            }
            
            let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
            
            let defaultFont = Font.system(size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")), weight: .bold)
            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
            
            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
            
            if readingMode || !UserDefaultsController.shared.bool(forKey: "wordByWord") {
                let verseText = getVerse(verse)
                
                Text(verseText.text)
                    .font(font)
                    .multilineTextAlignment(readingMode ? .center : .trailing)
                    .lineSpacing(fontNumber == 1 ? 20 : fontNumber == 2 ? 0 : 10)
            } else {
                WStack(verse.words, spacing: 20, lineSpacing: fontNumber == 1 ? 20 : fontNumber == 2 ? 0 : 10) { word in
                    VStack(alignment: .center, spacing: 10) {
                        Text(word.text)
                            .font(font)
                            .lineSpacing(fontNumber == 1 ? 20 : fontNumber == 2 ? 0 : 10)
                        
                        if let translationLanguage = UserDefaultsController.shared.string(forKey: "translationLanguage"), let translation = word.translations.first(where: { translation in
                            translation.id == translationLanguage
                        }) {
                            Text(translation.translation)
                                .foregroundStyle(Color.secondary)
                        }
                    }.multilineTextAlignment(.center)
                }.environment(\.layoutDirection, .rightToLeft)
            }
        }
    }
    
    private var highlightedTranslation: AttributedString {
        func clean(_ str: String) -> (cleaned: String, originalIndices: [Int]) {
            var cleaned = ""
            var indices: [Int] = []
            var inBracket = false
            var bracketStack: [Character] = []
            
            for (index, char) in str.enumerated() {
                if char == "[" || char == "(" || char == "{" {
                    inBracket = true
                    bracketStack.append(char)
                } else if char == "]" || char == ")" || char == "}" {
                    if let lastBracket = bracketStack.last,
                       (char == "]" && lastBracket == "[") ||
                       (char == ")" && lastBracket == "(") ||
                       (char == "}" && lastBracket == "{") {
                        bracketStack.removeLast()
                    }
                    if bracketStack.isEmpty {
                        inBracket = false
                    }
                } else if !inBracket && (char.isLetter || char.isNumber) {
                    cleaned.append(char.lowercased())
                    indices.append(index)
                }
            }
            
            return (cleaned, indices)
        }
        
        guard let translation = verse.translations.first(where: { translation in
            translation.id == UserDefaultsController.shared.integer(forKey: "translatorId")
        })?.translation else { return AttributedString() }
        
        let (cleanedTranslation, originalIndices) = clean(translation)
        let cleanedSearchText = clean(searchText).cleaned
        
        var positions: [Range<String.Index>] = []
        var startIndex = cleanedTranslation.startIndex
        
        while let range = cleanedTranslation.range(of: cleanedSearchText, range: startIndex..<cleanedTranslation.endIndex) {
            positions.append(range)
            startIndex = range.upperBound
        }
        
        var attributedStrings: [AttributedString] = []
        var lastEndIndex = translation.startIndex
        
        for position in positions {
            let startCleanedIndex = cleanedTranslation.distance(from: cleanedTranslation.startIndex, to: position.lowerBound)
            let endCleanedIndex = cleanedTranslation.distance(from: cleanedTranslation.startIndex, to: position.upperBound)
            
            let startIndex = translation.index(translation.startIndex, offsetBy: originalIndices[startCleanedIndex])
            let endIndex = translation.index(translation.startIndex, offsetBy: originalIndices[endCleanedIndex - 1] + 1)
            
            if lastEndIndex < startIndex {
                let part = String(translation[lastEndIndex..<startIndex])
                let attributedPart = AttributedString(part)
                attributedStrings.append(attributedPart)
            }
            
            let highlightedPart = String(translation[startIndex..<endIndex])
            var attributedHighlighted = AttributedString(highlightedPart)
            attributedHighlighted.backgroundColor = .yellow
            attributedHighlighted.foregroundColor = .black
            attributedStrings.append(attributedHighlighted)
            
            lastEndIndex = endIndex
        }
        
        if lastEndIndex < translation.endIndex {
            let part = String(translation[lastEndIndex..<translation.endIndex])
            let attributedPart = AttributedString(part)
            attributedStrings.append(attributedPart)
        }
        
        var combinedAttributedString = AttributedString("")
        for attributedString in attributedStrings {
            combinedAttributedString.append(attributedString)
        }
        
        return combinedAttributedString
    }
    
    @ViewBuilder
    private var translation: some View {
        if !readingMode {
            HStack(alignment: .top) {
                Group {
                    Text("\(verse.id).")
                    
                    Text(highlightedTranslation)
                }
                .font(.system(size: 20))
                .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var verseButtons: some View {
        if !readingMode {
            VStack(spacing: 10) {
                bookmarkButton
                audioButton
            }
            .font(.system(size: 20))
            .foregroundStyle(Color.primary)
        }
    }
    
    private var bookmarkButton: some View {
        Button {
            bookmark()
        } label: {
            if bookmarkedVerses.contains(where: { bookmarkedVerse in
                bookmarkedVerse.surahId == surahId && bookmarkedVerse.verseId == verse.id
            }) {
                Image(systemName: "bookmark.fill")
            } else {
                Image(systemName: "bookmark")
            }
        }
    }
    
    private var contextMenuBookmarkButton: some View {
        Button {
            bookmark()
        } label: {
            HStack {
                Text("Bookmark")
                
                Spacer()
                
                if bookmarkedVerses.contains(where: { bookmarkedVerse in
                    bookmarkedVerse.surahId == surahId && bookmarkedVerse.verseId == verse.id
                }) {
                    Image(systemName: "bookmark.fill")
                } else {
                    Image(systemName: "bookmark")
                }
            }
        }
    }
    
    private var audioButton: some View {
        Group {
            if let reciterSubfolder = UserDefaultsController.shared.string(forKey: "reciterSubfolder") {
                if let audioUrl = URL(string: "https://everyayah.com/data/\(reciterSubfolder)/\(verse.audio).mp3") {
                    if audioPlayer.url == audioUrl {
                        Button {
                            audioPlayer.playPause()
                        } label: {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        }
                    } else {
                        Button {
                            audioPlayer.setupPlayer(with: audioUrl, verse: verse)
                            audioPlayer.playPause()
                        } label: {
                            Image(systemName: "play.fill")
                        }
                    }
                }
            }
        }
    }
    
    private var contextMenuAudioButton: some View {
        Group {
            if let reciterSubfolder = UserDefaultsController.shared.string(forKey: "reciterSubfolder") {
                if let audioUrl = URL(string: "https://everyayah.com/data/\(reciterSubfolder)/\(verse.audio).mp3") {
                    if audioPlayer.url == audioUrl {
                        Button {
                            audioPlayer.playPause()
                        } label: {
                            HStack {
                                Text(audioPlayer.isPlaying ? "Pause" : "Play")
                                
                                Spacer()
                                
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            }
                        }
                    } else {
                        Button {
                            audioPlayer.setupPlayer(with: audioUrl, verse: verse)
                            audioPlayer.playPause()
                        } label: {
                            HStack {
                                Text("Play")
                                
                                Spacer()
                                
                                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getVerse(_ verse: Verse) -> Verse {
        return Verse(id: verse.id, text: verse.text + " " + getArabicNumber(verse.id), translations: [], words: [], audio: "")
    }
    
    private func getArabicNumber(_ number: Int) -> String {
        let arabicNumerals = "٠١٢٣٤٥٦٧٨٩"
        var arabicString = ""
        
        for char in String(number) {
            if let digit = Int(String(char)) {
                let index = arabicNumerals.index(arabicNumerals.startIndex, offsetBy: digit)
                arabicString.append(arabicNumerals[index])
            }
        }
        
        if UserDefaultsController.shared.integer(forKey: "fontNumber") == 2 {
            return arabicString
        } else {
            return "(\(arabicString))"
        }
    }
    
    private func bookmark() {
        if let verseToRemove = bookmarkedVerses.first(where: { bookmarkedVerse in
            bookmarkedVerse.surahId == surahId && bookmarkedVerse.verseId == verse.id
        }) {
            removeBookmark(verseToRemove)
        } else {
            addBookmark()
        }
    }
}

struct DraggableViewModifier: ViewModifier {
    @GestureState private var dragOffset = CGSize.zero
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        if value.translation.height > 50 {
                            isPresented = false
                        }
                    }
            )
    }
}

extension View {
    func draggableView(isPresented: Binding<Bool>) -> some View {
        self.modifier(DraggableViewModifier(isPresented: isPresented))
    }
}

class SurahFilterModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filteredVerses: [Verse] = []
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    @Published var surah: Surah?
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] text in
                self?.setLoading(true)
                let result = self?.filterVerses(with: text) ?? []
                self?.setLoading(false)
                return result
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredVerses, on: self)
            .store(in: &cancellables)
    }
    
    private func filterVerses(with searchText: String) -> [Verse] {
        guard let surah = surah else { return [] }
        
        let cleanedSearchText = searchText.lowercasedLettersAndNumbers
        
        guard !cleanedSearchText.isEmpty else { return surah.verses }
        
        return surah.verses.filter { verse in
            if String(verse.id) == cleanedSearchText {
                return true
            }
            
            if verse.text.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                return true
            }
            
            if let translation = verse.translations.first(where: { translation in
                translation.id == UserDefaultsController.shared.integer(forKey: "translatorId")
            }) {
                if translation.translation.lowercasedLettersAndNumbers.contains(cleanedSearchText) {
                    return true
                }
            }
            
            return false
        }
    }
    
    private func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
}

#Preview {
    let quranModel: QuranModel = QuranModel()
    
    NavigationStack {
        if let surah = quranModel.quran.first(where: { surah in
            surah.id == 2
        }) {
            SurahView(surah: surah)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
