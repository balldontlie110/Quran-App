//
//  BookmarkedVersesView.swift
//  Quran
//
//  Created by Ali Earp on 16/06/2024.
//

import SwiftUI
import CoreData

struct BookmarkedVersesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let title: String?
    let bookmarkedVerses: [BookmarkedVerse]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(bookmarkedVerses) { verse in
                    NavigationLink {
                        if let surah = QuranModel().getSurah(Int(verse.surahId)) {
                            SurahView(surah: surah, initialScroll: Int(verse.verseId))
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 15) {
                            VStack(alignment: .leading) {
                                Text(verse.title ?? "")
                                    .fontWeight(.heavy)
                                
                                Spacer()
                                
                                Text("\(verse.surahName ?? ""): Ayat \(verse.verseId)")
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                            }.multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(getDateString(verse.date))
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(Color.secondary)
                                
                                Spacer()
                                
                                Button {
                                    removeVerseFromBookmarks(verse)
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
            }.padding(.horizontal)
        }.navigationTitle(title ?? "")
    }
    
    private func getDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date ?? Date())
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
    @Previewable @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    BookmarkedVersesView(title: "", bookmarkedVerses: Array(bookmarkedVerses))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
