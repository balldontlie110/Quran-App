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
    @EnvironmentObject private var quranModel: QuranModel
    @StateObject private var questionsModel: QuestionsModel = QuestionsModel()
    @StateObject private var questionsFilterModel: QuestionsFilterModel = QuestionsFilterModel(questionsModel: QuestionsModel())
    
    @State private var question: Question?
    
    @FocusState private var questionTitleFocused: Bool
    
    var body: some View {
        ScrollView {
            ScrollViewReader { proxy in
                LazyVStack {
                    NewQuestionView(questionsModel: questionsModel, questionTitleFocused: $questionTitleFocused)
                        .id("new question")
                    
                    Divider()
                    
                    Picker("", selection: $questionsFilterModel.answerState) {
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
                        
                        TextField("Search", text: $questionsFilterModel.searchText)
                        
                        if questionsFilterModel.searchText != "" {
                            Button {
                                questionsFilterModel.searchText = ""
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
                    
                    if questionsFilterModel.isLoading {
                        ProgressView()
                    } else {
                        ForEach(questionsFilterModel.filteredQuestions) { question in
                            Button {
                                questionsModel.fetchAnswers(question)
                                questionsModel.question = question
                            } label: {
                                QuestionCard(quran: quranModel.quran, question: question, userProfiles: questionsModel.questionsUserProfiles, detailView: false)
                            }
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
        .onAppear {
            questionsFilterModel.questionsModel = questionsModel
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
