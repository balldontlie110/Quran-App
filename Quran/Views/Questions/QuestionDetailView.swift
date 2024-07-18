//
//  QuestionDetailView.swift
//  Quran
//
//  Created by Ali Earp on 02/07/2024.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import FirebaseAuth

struct QuestionDetailView: View {
    @StateObject var questionsModel: QuestionsModel
    
    let quran: [Surah]
    
    @State private var answer: String = ""
    
    var body: some View {
        if let question = questionsModel.question {
            ScrollView {
                QuestionCard(quran: quran, question: question, userProfiles: questionsModel.questionsUserProfiles, detailView: true)
                
                VStack(spacing: 0) {
                    TextField("Answer", text: $answer, axis: .vertical)
                        .padding(.trailing, 30)
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                newAnswer()
                            } label: {
                                Image(systemName: "paperplane.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25)
                                    .foregroundStyle(Color.accentColor)
                            }.disabled(Auth.auth().currentUser == nil)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding([.horizontal, .bottom])
                        .disabled(Auth.auth().currentUser == nil)
                    
                    if Auth.auth().currentUser == nil {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("You need to be signed in to answer a question.")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.red)
                    }
                }
                
                Divider()
                
                LazyVStack(spacing: 0) {
                    ForEach(answers) { answer in
                        VStack(alignment: .leading) {
                            Text(answer.answer)
                                .multilineTextAlignment(.leading)
                            
                            HStack(alignment: .bottom) {
                                if Auth.auth().currentUser?.uid == question.questionuid && question.answered == false, let questionId = question.id, let answerId = answer.id {
                                    Button {
                                        questionsModel.acceptAnswer(questionId: questionId, answerId: answerId)
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20)
                                            
                                            Text("Accept")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                }
                                
                                if answer.accepted == true {
                                    Text("Accepted")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.accentColor)
                                }
                                
                                Spacer()
                                
                                UserProfileSection(userProfiles: questionsModel.answersUserProfiles, uid: answer.answeruid, timestamp: answer.timestamp)
                            }
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .padding(.vertical, 5)
                    }
                }.padding(.horizontal)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(question.questionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
        }
    }
    
    private var answers: [Answer] {
        var sortedByTimestamp = questionsModel.answers.sorted { answer1, answer2 in
            answer1.timestamp.dateValue() > answer2.timestamp.dateValue()
        }
        
        if let accepted = sortedByTimestamp.firstIndex(where: { answer in
            answer.accepted == true
        }) {
            sortedByTimestamp.move(fromOffsets: IndexSet(integer: accepted), toOffset: 0)
        }
        
        return sortedByTimestamp
    }
    
    private func newAnswer() {
        if answer != "" {
            if let questionId = questionsModel.question?.id {
                questionsModel.newAnswer(answer: answer, questionId: questionId)
                
                hideKeyboard()
                self.answer = ""
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    QuestionDetailView(questionsModel: QuestionsModel(), quran: [])
}
