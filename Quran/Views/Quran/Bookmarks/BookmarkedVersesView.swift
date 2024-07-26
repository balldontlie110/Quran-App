//
//  BookmarkedVersesView.swift
//  Quran
//
//  Created by Ali Earp on 16/06/2024.
//

import SwiftUI
import CoreData

struct BookmarkedVersesView: View {
    let quranModel: QuranModel
    
    let title: String?
    var bookmarkedVerses: [BookmarkedVerse]
    
    @State private var readMores: [UUID] = []
    @State private var addAnswer: UUID?
    
    @State private var answer: String = ""
    
    let removeVerse: (BookmarkedVerse) -> Void
    let addAnswerToQuestion: (BookmarkedVerse, String) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(bookmarkedVerses) { verse in
                    LazyVStack(spacing: 10) {
                        BookmarkedVerseCard(quranModel: quranModel, verse: verse) { verse in
                            removeVerse(verse)
                        }
                        
                        if verse.question {
                            QuestionVerse(verse: verse, readMores: $readMores, addAnswer: $addAnswer, answer: $answer) { answer in
                                addAnswerToQuestion(verse, answer)
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
}

struct QuestionVerse: View {
    let verse: BookmarkedVerse
    
    @Binding var readMores: [UUID]
    @Binding var addAnswer: UUID?
    @Binding var answer: String
    
    let addAnswerToQuestion: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(alignment: .leading) {
                questionAnswer
                
                answerField
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
                    
                    addAnswerButton
                    
                    cancelButton
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
    
    private var questionAnswer: some View {
        Group {
            if let answer = verse.answer {
                HStack {
                    Text("Answer:")
                    
                    Spacer()
                    
                    Button {
                        expandAnswer()
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
        }
    }
    
    private var answerField: some View {
        Group {
            if verse.id == addAnswer {
                Spacer()
                
                TextField("Answer", text: $answer, axis: .vertical)
                    .fontWeight(.regular)
                    .foregroundStyle(answer == "" ? Color.secondary : Color.primary)
            }
        }
    }
    
    private var addAnswerButton: some View {
        Group {
            if addAnswer == verse.id {
                Button {
                    if answer != "" {
                        addAnswerToQuestion(answer)
                        
                        self.addAnswer = nil
                        self.answer = ""
                    }
                } label: {
                    Text("Add")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
    
    private var cancelButton: some View {
        Group {
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
    }
    
    private func expandAnswer() {
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
    }
}

@available(iOS 18.0, *)
#Preview {
    @Previewable @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    BookmarkedVersesView(quranModel: QuranModel(), title: nil, bookmarkedVerses: Array(bookmarkedVerses)) { _ in
        
    } addAnswerToQuestion: { _, _ in
        
    }.environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
