//
//  AddBookmarkView.swift
//  Quran
//
//  Created by Ali Earp on 05/07/2024.
//

import SwiftUI
import CoreData

struct AddBookmarkView: View {
    let viewContext: NSManagedObjectContext
    
    @Binding var showBookmarkAlert: Verse?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedFolder.date, ascending: true)],
        animation: .default
    )
    
    var bookmarkedFolders: FetchedResults<BookmarkedFolder>
    
    var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    let surahId: Int
    let surahTransliteration: String
    
    @State private var bookmarkTitle: String = ""
    @State private var showFolderVerses: [UUID] = []
    @State private var showNewFolderTitleField: Bool = false
    @State private var folderTitle: String = ""
    @State private var bookmarkFolder: FetchedResults<BookmarkedFolder>.Element?
    
    enum FocusedField {
        case bookmarkTitle, folderTitle
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        Group {
            if showBookmarkAlert != nil {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        readingBookmarkSelect
                        
                        Divider()
                        
                        foldersSelect
                        newFolderField
                        newFolderButton
                        
                        bookmarkTitleField
                        
                        Spacer()
                            .frame(height: 10)
                        
                        addBookmarkButton
                        
                        cancelButton
                    }.padding()
                }
                .font(.system(size: 18))
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
    
    private var readingBookmarkSelect: some View {
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
    }
    
    private var foldersSelect: some View {
        ForEach(bookmarkedFolders) { folder in
            Button {
                self.bookmarkFolder = folder
            } label: {
                HStack {
                    Text(folder.title ?? "")
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    if folder == bookmarkFolder {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    private var newFolderField: some View {
        Group {
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
        }
    }
    
    private var newFolderButton: some View {
        Button {
            self.showNewFolderTitleField = true
            self.focusedField = .folderTitle
        } label: {
            Text("+ New Folder")
                .bold()
        }
    }
    
    private var bookmarkTitleField: some View {
        Group {
            if bookmarkFolder != nil || showNewFolderTitleField {
                TextField("Bookmark title", text: $bookmarkTitle, axis: .vertical)
                    .focused($focusedField, equals: .bookmarkTitle)
                    .padding(7.5)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var addBookmarkButton: some View {
        Button {
            if let verse = showBookmarkAlert {
                addNewFolder()
                
                if bookmarkFolder == nil {
                    self.bookmarkTitle = "Reading Bookmark"
                }
                
                addBookmark(
                    verse: verse,
                    title: bookmarkTitle,
                    folder: bookmarkFolder)
                
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
    }
    
    private var cancelButton: some View {
        Button {
            withAnimation { self.showBookmarkAlert = nil }
            self.bookmarkTitle = ""
            self.bookmarkFolder = nil
        } label: {
            Text("Cancel")
                .bold()
                .foregroundStyle(Color.red)
        }
    }
    
    private func addNewFolder() {
        if folderTitle != "" {
            let folder = BookmarkedFolder(context: viewContext)
            folder.id = UUID()
            folder.title = self.folderTitle
            folder.date = Date()
            folder.verses = nil
            
            try? viewContext.save()
            
            self.folderTitle = ""
            self.focusedField = .bookmarkTitle
            self.showNewFolderTitleField = false
            
            self.bookmarkFolder = folder
        }
    }
    
    private func addBookmark(verse: Verse, title: String, folder: BookmarkedFolder?) {
        let newBookmarkedVerse = BookmarkedVerse(context: viewContext)
        newBookmarkedVerse.id = UUID()
        newBookmarkedVerse.title = title
        newBookmarkedVerse.date = Date()
        newBookmarkedVerse.surahId = Int64(surahId)
        newBookmarkedVerse.surahName = surahTransliteration
        newBookmarkedVerse.verseId = Int64(verse.id)
        
        if folder?.questionFolder == true {
            newBookmarkedVerse.question = true
        }
        
        if let folder = folder {
            folder.verses = NSSet(set: folder.verses?.adding(newBookmarkedVerse) ?? Set())
        } else {
            if let readingBookmark = bookmarkedVerses.first(where: { $0.readingBookmark == true }) {
                viewContext.delete(readingBookmark)
            }
            
            newBookmarkedVerse.readingBookmark = true
        }
        
        try? viewContext.save()
    }
}
