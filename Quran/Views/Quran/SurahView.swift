//
//  SurahView.swift
//  Quran
//
//  Created by Ali Earp on 11/06/2024.
//

import SwiftUI
import CoreData

struct SurahView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let surah: Surah

    @State private var readingMode: Bool = false
    
    @State private var showVerseSelector: Bool = false
    @State private var scrollPosition: Int?
    
    let initialScroll: Int?
    
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
    
    enum FocusedField {
        case bookmarkTitle, folderTitle
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        TabView(selection: $readingMode) {
            Tab("Translation", systemImage: "book.closed", value: false) {
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
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color.primary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(verseText.text)
                                                .font(.system(size: 40, weight: .bold))
                                                .multilineTextAlignment(.trailing)
                                                .lineSpacing(20)
                                        }
                                        
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
                                    .padding(.bottom, 5)
                                    .padding(.top, 15)
                                    
                                    if verse.id != surah.verses.count {
                                        Divider()
                                    }
                                }.id(verse.id)
                            }
                        }
                        .padding(.horizontal)
                        .scrollTargetLayout()
                        .onChange(of: readingMode) { _, _ in
                            if readingMode == false {
                                proxy.scrollTo(scrollPosition, anchor: .top)
                            }
                        }
                        .onRotate { _ in
                            proxy.scrollTo(scrollPosition, anchor: .top)
                        }
                        .onAppear {
                            if let initialScroll = initialScroll {
                                proxy.scrollTo(initialScroll, anchor: .top)
                            }
                        }
                    }
                }
                .scrollPosition(id: $scrollPosition)
                .onTapGesture {
                    withAnimation {
                        self.showBookmarkAlert = nil
                        self.showVerseSelector = false
                    }
                }
            }
            
            Tab("Reading", systemImage: "book", value: true) {
                ScrollView {
                    ScrollViewReader { proxy in
                        let verses = getSurahVerses(surah.verses)
                        LazyVStack(spacing: 20) {
                            VStack {
                                Text(surah.name)
                                    .font(.system(size: 50, weight: .bold))
                                
                                Text(surah.translation)
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            
                            Spacer().frame(height: 40)
                            
                            ForEach(verses) { verse in
                                Text(verse.text)
                                    .id(verse.id)
                            }
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(20)
                        }
                        .padding(.horizontal)
                        .scrollTargetLayout()
                        .onAppear {
                            proxy.scrollTo(scrollPosition, anchor: .top)
                        }
                        .onChange(of: readingMode) { _, _ in
                            if readingMode == true {
                                proxy.scrollTo(scrollPosition, anchor: .top)
                            }
                        }
                        .onRotate { _ in
                            proxy.scrollTo(scrollPosition, anchor: .top)
                        }
                    }
                }
                .scrollPosition(id: $scrollPosition)
                .onTapGesture {
                    withAnimation {
                        self.showBookmarkAlert = nil
                        self.showVerseSelector = false
                    }
                }
            }
        }
        .navigationTitle(surah.transliteration)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            Button {
                withAnimation { self.showVerseSelector.toggle() }
            } label: {
                Text("Ayat: \(String(scrollPosition ?? 1))")
                    .bold()
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

        }
        .blur(radius: showBookmarkAlert == nil ? 0 : 5)
        .brightness(showVerseSelector ? -0.5 : 0)
        .overlay(alignment: .center) {
            if showVerseSelector {
                VStack {
                    Spacer()
                    
                    Picker("", selection: $scrollPosition) {
                        ForEach(0..<surah.total_verses) { number in
                            Text(String(number + 1))
                                .tag(number + 1)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal, 50)
                    
                    Spacer()
                    Spacer()
                }
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
                .frame(height: 350)
                .font(.system(size: 20))
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 50)
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
        return Ayat(id: verse.id, text: verse.text + " " + getArabicNumber(verse.id), translation: "")
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
