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
    
    let quranModel: QuranModel
    
    let title: String?
    let bookmarkedVerses: [BookmarkedVerse]
    
    @State private var readMores: [UUID] = []
    @State private var addAnswer: UUID?
    
    @State private var answer: String = ""
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(bookmarkedVerses) { verse in
                    LazyVStack(spacing: 10) {
                        BookmarkedVerseCard(viewContext: viewContext, quranModel: quranModel, verse: verse)
                        
                        if verse.question {
                            QuestionVerse(viewContext: viewContext, verse: verse, readMores: $readMores, addAnswer: $addAnswer, answer: $answer)
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
    let viewContext: NSManagedObjectContext
    
    let verse: BookmarkedVerse
    
    @Binding var readMores: [UUID]
    @Binding var addAnswer: UUID?
    @Binding var answer: String
    
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
                        addAnswerToQuestion()
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
    
    private func addAnswerToQuestion() {
        verse.answer = answer
        
        self.addAnswer = nil
        self.answer = ""
        
        try? viewContext.save()
    }
}

@available(iOS 18.0, *)
#Preview {
    @Previewable @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkedVerse.date, ascending: true)],
        animation: .default
    )
    
    var bookmarkedVerses: FetchedResults<BookmarkedVerse>
    
    BookmarkedVersesView(quranModel: QuranModel(), title: "", bookmarkedVerses: Array(bookmarkedVerses))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
