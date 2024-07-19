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
    
    @StateObject private var quranModel: QuranModel = QuranModel()
    
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
                    BookmarkedVerseCard(viewContext: viewContext, quranModel: quranModel, verse: readingBookmark)
                        .foregroundStyle(Color.primary)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                ForEach(bookmarkedFolders) { folder in
                    BookmarkedFolderCard(viewContext: viewContext, quranModel: quranModel, folder: folder)
                }
            }.padding(.horizontal)
        }.navigationTitle("Bookmarks")
    }
}

struct BookmarkedFolderCard: View {
    let viewContext: NSManagedObjectContext
    
    let quranModel: QuranModel
    
    let folder: BookmarkedFolder
    
    var body: some View {
        NavigationLink {
            if let bookmarkedVerses = folder.verses?.allObjects as? [BookmarkedVerse] {
                BookmarkedVersesView(quranModel: quranModel, title: folder.title, bookmarkedVerses: bookmarkedVerses)
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
                    deleteFolder(folder)
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
    
    private func deleteFolder(_ folder: BookmarkedFolder) {
        viewContext.delete(folder)
        
        do {
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}

#Preview {
    BookmarkedFoldersView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
