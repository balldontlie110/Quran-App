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
    
    @State private var readMores: [UUID] = []
    @State private var addAnswer: UUID?
    
    @State private var answer: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(bookmarkedVerses) { verse in
                    VStack(spacing: 10) {
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
                        }
                        
                        if verse.question {
                            HStack(alignment: .top, spacing: 15) {
                                VStack(alignment: .leading) {
                                    if let answer = verse.answer {
                                        HStack {
                                            Text("Answer:")
                                            
                                            Spacer()
                                            
                                            Button {
                                                if readMores.contains(where: { $0 == verse.id }) {
                                                    withAnimation {
                                                        readMores.removeAll(where: { $0 == verse.id })
                                                    }
                                                } else {
                                                    if let bookmarkedVerseId = verse.id {
                                                        withAnimation {
                                                            readMores.append(bookmarkedVerseId)
                                                        }
                                                    }
                                                }
                                            } label: {
                                                Image(systemName: readMores.contains(where: { $0 == verse.id }) ? "chevron.up" : "chevron.down")
                                                    .font(.system(.subheadline, weight: .semibold))
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                        }
                                        
                                        Text(answer)
                                            .lineLimit(readMores.contains(where: { $0 == verse.id }) ? nil : 1)
                                            .foregroundStyle(Color.primary)
                                    }
                                    
                                    if verse.id == addAnswer {
                                        Spacer()
                                        
                                        TextField("Answer", text: $answer, axis: .vertical)
                                            .fontWeight(.regular)
                                            .foregroundStyle(answer == "" ? Color.secondary : Color.primary)
                                    }
                                }
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(Color.secondary)
                                .multilineTextAlignment(.leading)
                                
                                if verse.answer == nil {
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        if addAnswer == verse.id {
                                            Spacer()
                                        }
                                        
                                        if addAnswer == verse.id {
                                            Button {
                                                if answer != "" {
                                                    addAnswerToBookmarkedVerse(verse, answer: answer)
                                                }
                                            } label: {
                                                Text("Add")
                                                    .font(.system(.subheadline, weight: .semibold))
                                                    .foregroundStyle(Color.accentColor)
                                            }
                                        }
                                        
                                        if addAnswer == verse.id {
                                            Button {
                                                withAnimation {
                                                    self.addAnswer = nil
                                                    self.answer = ""
                                                }
                                            } label: {
                                                Text("Cancel")
                                            }
                                            .font(.system(.subheadline, weight: .semibold))
                                            .foregroundStyle(Color.red)
                                        }
                                    }
                                    .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            if verse.answer == nil && addAnswer == nil {
                                Button {
                                    withAnimation {
                                        self.addAnswer = verse.id
                                    }
                                } label: {
                                    Text("+ Add Answer")
                                }
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .foregroundStyle(Color.primary)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }.padding(.horizontal)
        }.navigationTitle(title ?? "")
    }
    
    private func getDateString(_ date: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date ?? Date())
    }
    
    private func addAnswerToBookmarkedVerse(_ verse: FetchedResults<BookmarkedVerse>.Element, answer: String) {
        verse.answer = answer
        
        self.addAnswer = nil
        self.answer = ""
        
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
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    BookmarkedVersesView(title: "", bookmarkedVerses: Array(bookmarkedVerses))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
