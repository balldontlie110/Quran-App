//
//  BookmarkedFoldersView.swift
//  Quran
//
//  Created by Ali Earp on 16/06/2024.
//

import SwiftUI
import CoreData

struct BookmarkedFoldersView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        predicate: NSPredicate(format: "readingBookmark == \(NSNumber(value: true))"),
        animation: .default
    )
    
    private var readingBookmark: FetchedResults<BookmarkedVerse>
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BookmarkedFolder.questionFolder, ascending: true),
            NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: false)
        ],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    var body: some View {
        ScrollView {
            LazyVStack {
                if let readingBookmark = readingBookmark.first {
                    NavigationLink {
                        if let surah = QuranModel().getSurah(Int(readingBookmark.surahId)) {
                            SurahView(surah: surah, initialScroll: Int(readingBookmark.verseId))
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 15) {
                            VStack(alignment: .leading) {
                                Text("Reading Bookmark")
                                    .fontWeight(.heavy)
                                
                                Spacer()
                                
                                Text("\(readingBookmark.surahName ?? ""): Ayat \(readingBookmark.verseId)")
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                            }.multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(getDateString(readingBookmark.date))
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                                
                                Spacer()
                                
                                Button {
                                    removeVerseFromBookmarks(readingBookmark)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.red)
                                }
                            }.multilineTextAlignment(.trailing)
                        }
                        .foregroundStyle(Color.primary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                
                ForEach(bookmarkedFolders) { folder in
                    NavigationLink {
                        if let bookmarkedVerses = folder.verses?.allObjects as? [BookmarkedVerse] {
                            BookmarkedVersesView(title: folder.title, bookmarkedVerses: bookmarkedVerses)
                        }
                    } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "folder")
                                .font(.system(.title))
                            
                            VStack(alignment: .leading) {
                                Text(folder.title ?? "")
                                    .fontWeight(.heavy)
                                    .multilineTextAlignment(.leading)
                                Text(getDateString(folder.date))
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            Spacer()
                            
                            if !folder.questionFolder {
                                Button {
                                    deleteFolder(folder)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.red)
                                }
                            }
                        }
                        .foregroundStyle(Color.primary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
            }.padding(.horizontal)
        }.navigationTitle("Bookmarks")
    }
    
    private func getDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date ?? Date())
    }
    
    private func deleteFolder(_ folder: FetchedResults<BookmarkedFolder>.Element) {
        viewContext.delete(folder)
        
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

#Preview {
    BookmarkedFoldersView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
