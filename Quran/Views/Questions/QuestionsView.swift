//
//  QuestionsView.swift
//  Quran
//
//  Created by Ali Earp on 01/07/2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct QuestionsView: View {
    @StateObject private var questionsModel: QuestionsModel = QuestionsModel()
    @EnvironmentObject private var quranModel: QuranModel
    
    @State private var question: Question?
    
    @State private var searchText: String = ""
    
    @State private var answerState: Int = 0
    
    @FocusState private var questionTitleFocused: Bool
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    NewQuestionView(questionsModel: questionsModel, questionTitleFocused: $questionTitleFocused)
                        .id("new question")
                    
                    Divider()
                    
                    Picker("", selection: $answerState) {
                        Text("All")
                            .tag(0)
                        
                        Text("Answered")
                            .tag(1)
                        
                        Text("Unanswered")
                            .tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.secondary)
                        
                        TextField("Search", text: $searchText)
                        
                        if searchText != "" {
                            Button {
                                self.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                    }
                    .padding(5)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    
                    ForEach(questions) { question in
                        Button {
                            questionsModel.fetchAnswers(question)
                            questionsModel.question = question
                        } label: {
                            QuestionCard(quran: quranModel.quran, question: question, userProfiles: questionsModel.questionsUserProfiles, detailView: false)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                proxy.scrollTo("new question", anchor: .top)
                            }
                            
                            self.questionTitleFocused = true
                        } label: {
                            Image(systemName: "plus")
                        }.disabled(Auth.auth().currentUser == nil)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationDestination(item: $questionsModel.question) { _ in
            QuestionDetailView(questionsModel: questionsModel, quran: quranModel.quran)
        }
        .navigationTitle("Questions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
    
    private var questions: [Question] {
        let sortedByTimestamp = questionsModel.questions.sorted { question1, question2 in
            question1.timestamp.dateValue() > question2.timestamp.dateValue()
        }
        
        if answerState == 1 {
            let filteredByAnswerState = sortedByTimestamp.filter { question in
                question.answered == true
            }
            
            return filteredByAnswerState.filter { question in
                question.containsSearchText(searchText)
            }
        } else if answerState == 2 {
            let filteredByAnswerState = sortedByTimestamp.filter { question in
                question.answered == false
            }
            
            return filteredByAnswerState.filter { question in
                question.containsSearchText(searchText)
            }
        } else {
            return sortedByTimestamp.filter { question in
                question.containsSearchText(searchText)
            }
        }
    }
}

extension Question {
    func containsSearchText(_ searchText: String) -> Bool {
        if searchText == "" {
            return true
        } else {
            return
                self.questionTitle.lowercased().contains(searchText.lowercased()) || self.question.lowercased().contains(searchText.lowercased())
        }
    }
}

extension Timestamp {
    func string() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let dateString = dateFormatter.string(from: self.dateValue())
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: self.dateValue())
        
        return dateString + " " + timeString
    }
}

#Preview {
    QuestionsView()
}
