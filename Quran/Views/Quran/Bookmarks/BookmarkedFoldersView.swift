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
    
    @EnvironmentObject private var quranModel: QuranModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        predicate: NSPredicate(format: "readingBookmark == \(NSNumber(value: true))"),
        animation: .default
    )
    
    private var readingBookmark: FetchedResults<BookmarkedVerse>
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BookmarkedFolder.questionFolder, ascending: false),
            NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: false)
        ],
        animation: .default
    )
    
    private var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    var body: some View {
        ScrollView {
            LazyVStack {
                if let readingBookmark = readingBookmark.first {
                    BookmarkedVerseCard(quranModel: quranModel, verse: readingBookmark) { verse in
                        viewContext.delete(verse)
                        
                        try? viewContext.save()
                    }
                    .foregroundStyle(Color.primary)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                ForEach(bookmarkedFolders) { folder in
                    BookmarkedFolderCard(quranModel: quranModel, folder: folder) {
                        viewContext.delete(folder)
                        
                        try? viewContext.save()
                    } removeVerse: { verse in
                        viewContext.delete(verse)
                        
                        try? viewContext.save()
                    } addAnswerToQuestion: { verse, answer in
                        verse.answer = answer
                        
                        try? viewContext.save()
                    }
                }
            }.padding(.horizontal)
        }.navigationTitle("Bookmarks")
    }
}

struct BookmarkedFolderCard: View {
    let quranModel: QuranModel
    
    let folder: BookmarkedFolder
    
    let deleteFolder: () -> Void
    
    let removeVerse: (BookmarkedVerse) -> Void
    let addAnswerToQuestion: (BookmarkedVerse, String) -> Void
    
    var body: some View {
        NavigationLink {
            if let bookmarkedVerses = folder.verses?.allObjects as? [BookmarkedVerse] {
                BookmarkedVersesView(quranModel: quranModel, title: folder.title, bookmarkedVerses: bookmarkedVerses) { verse in
                    removeVerse(verse)
                } addAnswerToQuestion: { verse, answer in
                    addAnswerToQuestion(verse, answer)
                }
            }
        } label: {
            HStack(spacing: 15) {
                folderInformation
                
                Spacer()
                
                deleteButton
            }
            .foregroundStyle(Color.primary)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
    }
    
    private var folderInformation: some View {
        Group {
            Image(systemName: folder.questionFolder ? "questionmark.folder" : "folder")
                .font(.system(.title))
            
            VStack(alignment: .leading) {
                folderTitle
                
                folderDate
            }
        }
    }
    
    private var folderTitle: some View {
        Text(folder.title ?? "")
            .fontWeight(.heavy)
            .multilineTextAlignment(.leading)
    }
    
    private var folderDate: some View {
        Text(getDateString(folder.date))
            .font(.system(.subheadline, weight: .semibold))
            .foregroundStyle(Color.secondary)
    }
    
    private var deleteButton: some View {
        Group {
            if !folder.questionFolder {
                Button {
                    deleteFolder()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                }
            }
        }
    }
    
    private func getDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date ?? Date())
    }
}

#Preview {
    BookmarkedFoldersView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
