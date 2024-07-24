//
//  QuestionsModel.swift
//  Quran
//
//  Created by Ali Earp on 01/07/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseAuth

class QuestionsModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var questionsUserProfiles: [UserProfile] = []
    
    @Published var question: Question?
    @Published var answers: [Answer] = []
    @Published var answersUserProfiles: [UserProfile] = []
    
    init() {
        fetchQuestions()
    }
    
    private func fetchQuestions() {
        Firestore.firestore().collection("questions").addSnapshotListener { snapshot, error in
            if let error = error {
                return
            }
            
            snapshot?.documentChanges.forEach { documentSnapshot in
                if let question = try? documentSnapshot.document.data(as: Question.self) {
                    self.questions.removeAll { check in
                        check.id == question.id
                    }
                    
                    self.questions.append(question)
                    
                    if self.question?.id == question.id {
                        self.question = question
                    }
                    
                    Task {
                        if let userProfile = try? await self.fetchUserProfile(question.questionuid) {
                            DispatchQueue.main.async {
                                self.questionsUserProfiles.append(userProfile)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchAnswers(_ question: Question) {
        self.answers = []
        
        if let documentID = question.id {
            Firestore.firestore().collection("questions").document(documentID).collection("answers").addSnapshotListener { snapshot, error in
                if let error = error {
                    return
                }
                
                snapshot?.documentChanges.forEach { documentSnapshot in
                    if let answer = try? documentSnapshot.document.data(as: Answer.self) {
                        self.answers.removeAll { check in
                            check.id == answer.id
                        }
                        
                        self.answers.append(answer)
                        
                        Task {
                            if let userProfile = try? await self.fetchUserProfile(answer.answeruid) {
                                DispatchQueue.main.async {
                                    self.answersUserProfiles.append(userProfile)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchUserProfile(_ uid: String) async throws -> UserProfile {
        let document = try await Firestore.firestore().collection("users").document(uid).getDocument()
        let username = document.data()?["username"] as? String ?? ""
        
        let photoURL = try await Storage.storage().reference().child("users").child(uid).downloadURL()
        
        let userProfile = UserProfile(id: uid, username: username, photoURL: photoURL)
        return userProfile
    }
    
    func newQuestion(questionTitle: String, question: String, surahId: Int?, verseId: Int?) {
        if let uid = Auth.auth().currentUser?.uid {
            let question = Question(questionTitle: questionTitle, questionuid: uid, question: question, timestamp: Timestamp(), surahId: surahId, verseId: verseId, answered: false, answersCount: 0)
            
            addNewQuestion(question)
        }
    }
    
    private func addNewQuestion(_ question: Question) {
        _ = try? Firestore.firestore().collection("questions").addDocument(from: question)
    }
    
    func newAnswer(answer: String, questionId: String) {
        if let uid = Auth.auth().currentUser?.uid {
            let answer = Answer(answer: answer, accepted: false, answeruid: uid, timestamp: Timestamp())
            
            addNewAnswer(answer, questionId: questionId)
        }
    }
    
    private func addNewAnswer(_ answer: Answer, questionId: String) {
        let questionDocument = Firestore.firestore().collection("questions").document(questionId)
        
        _ = try? questionDocument.collection("answers").addDocument(from: answer)
        
        questionDocument.updateData([
            "answersCount" : FieldValue.increment(1.0)
        ])
    }
    
    func acceptAnswer(questionId: String, answerId: String) {
        let questionDocument = Firestore.firestore().collection("questions").document(questionId)
        
        questionDocument.updateData([
            "answered" : true
        ])
        
        questionDocument.collection("answers").document(answerId).updateData([
            "accepted" : true
        ])
    }
}

struct UserProfile: Identifiable {
    let id: String
    
    let username: String
    let photoURL: URL
}
