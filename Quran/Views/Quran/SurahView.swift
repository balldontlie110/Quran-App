//
//  SurahView.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI
import CoreData
import AVFoundation

struct SurahView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let surah: Surah

    @State private var readingMode: Bool = false
    
    @State private var showVerseSelector: Bool = false
    @State private var scrollPosition: Int?
    
    @State var initialScroll: Int?
    
    private let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    private var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    @State private var showBookmarkAlert: Ayat?
    @State private var bookmarkTitle: String = ""
    @State private var showNewFolderTitleField: Bool = false
    @State private var folderTitle: String = ""
    @State private var bookmarkFolder: FetchedResults<BookmarkedFolder>.Element?
    
    private let bookmarkAlertHeight: CGFloat = UIScreen.main.bounds.width / 3 * 2
    
    enum FocusedField {
        case bookmarkTitle, folderTitle
    }
    
    @FocusState private var focusedField: FocusedField?
    
    @State private var player: AVPlayer?
    @State private var playing: Bool = false
    var finishedPlaying = NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    VStack {
                        Text(surah.name)
                            .font(.system(size: 50, weight: .bold))
                        
                        Text(surah.translation)
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Spacer().frame(height: 40)
                    
                    ForEach(surah.verses) { verse in
                        VStack(alignment: .trailing, spacing: 10) {
                            Group {
                                let verseText = getVerse(verse)
                                
                                HStack(alignment: .top) {
                                    if !readingMode {
                                        VStack(spacing: 10) {
                                            Button {
                                                if let verseToRemove = bookmarkedVerses.first(where: { $0.id == "\(surah.id):\(verse.id)" }) {
                                                    removeVerseFromBookmarks(verseToRemove)
                                                } else {
                                                    withAnimation { self.showBookmarkAlert = verse }
                                                }
                                            } label: {
                                                Group {
                                                    if bookmarkedVerses.contains(where: { $0.id == "\(surah.id):\(verse.id)" }) {
                                                        Image(systemName: "bookmark.fill")
                                                    } else {
                                                        Image(systemName: "bookmark")
                                                    }
                                                }
                                            }
                                            
                                            if let audioUrl = URL(string: "https://everyayah.com/data/Ghamadi_40kbps/\(verse.audio).mp3") {
                                                Button {
                                                    if playing && (player?.currentItem?.asset as? AVURLAsset)?.url == audioUrl {
                                                        player?.pause()
                                                        self.playing = false
                                                    } else {
                                                        player?.pause()
                                                        
                                                        self.player = AVPlayer(url: audioUrl)
                                                        player?.play()
                                                        
                                                        self.playing = true
                                                    }
                                                } label: {
                                                    if playing && (player?.currentItem?.asset as? AVURLAsset)?.url == audioUrl {
                                                        Image(systemName: "pause.fill")
                                                    } else {
                                                        Image(systemName: "play.fill")
                                                    }
                                                }
                                            }
                                        }
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.primary)
                                        .disabled(showVerseSelector)
                                        .onReceive(finishedPlaying) { _ in
                                            self.playing = false
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Text(verseText.text)
                                        .font(.system(size: 40, weight: .bold))
                                        .multilineTextAlignment(readingMode ? .center : .trailing)
                                        .lineSpacing(20)
                                }
                                
                                if !readingMode {
                                    HStack(alignment: .top) {
                                        Group {
                                            Text("\(verse.id).")
                                            Text(verse.translation)
                                        }
                                        .font(.system(size: 20))
                                        .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }.padding(.trailing, 15)
                                }
                            }
                            .padding(.bottom, 5)
                            .padding(.top, 15)
                            
                            if verse.id != surah.verses.count && !readingMode {
                                Divider()
                            }
                        }.id(verse.id)
                    }
                }
                .padding(.horizontal)
                .scrollTargetLayout()
                .onRotate { _ in
                    proxy.scrollTo(scrollPosition ?? initialScroll, anchor: .top)
                }
                .onAppear {
                    proxy.scrollTo(initialScroll, anchor: .top)
                }
            }
        }
        .onTapGesture {
            withAnimation {
                self.showBookmarkAlert = nil
                self.showVerseSelector = false
            }
        }
        .scrollPosition(id: $scrollPosition)
        .navigationTitle(surah.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { self.showVerseSelector.toggle() }
                } label: {
                    Text("Ayat: \(String(scrollPosition ?? initialScroll ?? 1))")
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }.disabled(showBookmarkAlert != nil)
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
        .blur(radius: showBookmarkAlert == nil ? 0 : 5)
        .brightness(showVerseSelector ? -0.5 : 0)
        .overlay(alignment: .center) {
            if showVerseSelector {
                Picker("", selection: $scrollPosition) {
                    ForEach(0..<surah.total_verses) { number in
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
        .overlay(alignment: .center) {
            if let verse = showBookmarkAlert {
                ScrollView {
                    VStack(spacing: 15) {
                        Button {
                            self.bookmarkFolder = nil
                        } label: {
                            HStack {
                                Text("Reading Bookmark").foregroundStyle(Color.primary)
                                
                                Spacer()
                                
                                if bookmarkFolder == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        ForEach(bookmarkedFolders) { folder in
                            Button {
                                self.bookmarkFolder = folder
                            } label: {
                                HStack {
                                    Group {
                                        Image(systemName: "folder")
                                        Text(folder.title ?? "")
                                    }.foregroundStyle(Color.primary)
                                    
                                    Spacer()
                                    
                                    if folder == bookmarkFolder {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        if showNewFolderTitleField {
                            HStack {
                                Image(systemName: "folder")
                                TextField("Folder name", text: $folderTitle)
                                    .focused($focusedField, equals: .folderTitle)
                                    .onSubmit {
                                        addNewFolder()
                                        self.focusedField = .bookmarkTitle
                                    }
                                    .onChange(of: focusedField) { _, _ in
                                        addNewFolder()
                                    }
                                
                                Spacer()
                                
                                Button {
                                    self.folderTitle = ""
                                    self.focusedField = .bookmarkTitle
                                    self.showNewFolderTitleField = false
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                        
                        Button {
                            self.showNewFolderTitleField = true
                            self.focusedField = .folderTitle
                        } label: {
                            Text("+ New Folder")
                                .bold()
                        }
                        
                        if bookmarkFolder != nil || showNewFolderTitleField {
                            TextField("Bookmark title", text: $bookmarkTitle, axis: .vertical)
                                .focused($focusedField, equals: .bookmarkTitle)
                                .padding(7.5)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Spacer()
                            .frame(height: 10)
                        
                        Button {
                            addNewFolder()
                            
                            if let folder = bookmarkFolder, bookmarkTitle != "" {
                                addVerseToBookmarks(
                                    verse: verse,
                                    title: bookmarkTitle,
                                    folder: folder)
                                
                                withAnimation { self.showBookmarkAlert = nil }
                                self.bookmarkTitle = ""
                                self.bookmarkFolder = nil
                            } else {
                                addVerseToBookmarks(
                                    verse: verse,
                                    title: "Reading Bookmark",
                                    folder: nil)
                                
                                withAnimation { self.showBookmarkAlert = nil }
                                self.bookmarkTitle = ""
                                self.bookmarkFolder = nil
                            }
                        } label: {
                            Text("Bookmark Verse")
                                .bold()
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .disabled(bookmarkFolder != nil && bookmarkTitle == "")
                        
                        Button {
                            withAnimation { self.showBookmarkAlert = nil }
                            self.bookmarkTitle = ""
                            self.bookmarkFolder = nil
                        } label: {
                            Text("Cancel")
                                .bold()
                                .foregroundStyle(Color.red)
                        }
                    }.padding()
                }
                .font(.system(size: 20))
                .frame(maxHeight: UIScreen.main.bounds.height / 2)
                .background(Material.regular)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
                .onAppear {
                    self.focusedField = .bookmarkTitle
                }
            }
        }
    }

    private func getSurahVerses(_ verses: [Ayat]) -> [Ayat] {
        return verses.compactMap { getVerse($0) }
    }
    
    private func getVerse(_ verse: Ayat) -> Ayat {
        return Ayat(id: verse.id, text: verse.text + " " + getArabicNumber(verse.id), translation: "", audio: "")
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
        
        return "(" + arabicString + ")"
    }
    
    private func addNewFolder() {
        if folderTitle != "" {
            let folder = BookmarkedFolder(context: viewContext)
            folder.id = UUID()
            folder.title = self.folderTitle
            folder.date = Date()
            folder.verses = nil
            
            do {
                try viewContext.save()
                
                self.folderTitle = ""
                self.focusedField = .bookmarkTitle
                self.showNewFolderTitleField = false
                
                self.bookmarkFolder = folder
            } catch {
                
            }
        }
    }
    
    private func addVerseToBookmarks(verse: Ayat, title: String, folder: FetchedResults<BookmarkedFolder>.Element?) {
        let newBookmarkedVerse = BookmarkedVerse(context: viewContext)
        newBookmarkedVerse.id = "\(surah.id):\(verse.id)"
        newBookmarkedVerse.title = title
        newBookmarkedVerse.date = Date()
        newBookmarkedVerse.surahId = Int64(surah.id)
        newBookmarkedVerse.surahName = surah.transliteration
        newBookmarkedVerse.verseId = Int64(verse.id)
        
        if let folder = folder {
            folder.verses = NSSet(set: folder.verses?.adding(newBookmarkedVerse) ?? Set())
        } else {
            if let readingBookmark = bookmarkedVerses.first(where: { $0.readingBookmark == true }) {
                viewContext.delete(readingBookmark)
            }
            
            newBookmarkedVerse.readingBookmark = true
        }
        
        do {
            try viewContext.save()
        } catch {
            
        }
    }
    
    private func removeVerseFromBookmarks(_ verse: FetchedResults<BookmarkedVerse>.Element) {
        viewContext.delete(verse)
        
        do {
            try viewContext.save()
        } catch {
            
        }
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

#Preview {
    var quranModel: QuranModel = QuranModel()
    
    NavigationStack {
        if let surah = quranModel.quran.first(where: { surah in
            surah.id == 2
        }) {
            SurahView(surah: surah, initialScroll: nil)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
