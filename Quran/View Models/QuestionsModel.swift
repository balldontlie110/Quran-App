//
//  QuestionsModel.swift
//  Quran
//
//  Created by Ali Earp on 01/07/2024.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import Combine

class QuestionsModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var questionsUserProfiles: [UserProfile] = []
    
    @Published var question: Question?
    @Published var answers: [Answer] = []
    @Published var answersUserProfiles: [UserProfile] = []
    @Published var responsesUserProfiles: [UserProfile] = []
    
    init() {
        fetchQuestions()
    }
    
    private func fetchQuestions() {
        Firestore.firestore().collection("questions").addSnapshotListener { snapshot, error in
            if error != nil {
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
    
    @MainActor
    func fetchAnswers(_ question: Question) {
        self.answers = []
        
        if let documentID = question.id {
            Firestore.firestore().collection("questions").document(documentID).collection("answers").addSnapshotListener { snapshot, error in
                if error != nil {
                    return
                }
                
                snapshot?.documentChanges.forEach { documentSnapshot in
                    if var answer = try? documentSnapshot.document.data(as: Answer.self) {
                        self.answers.removeAll { check in
                            check.id == answer.id
                        }
                        
                        Task {
                            if let userProfile = try? await self.fetchUserProfile(answer.answeruid) {
                                DispatchQueue.main.async {
                                    self.answersUserProfiles.append(userProfile)
                                }
                            }
                        }
                        
                        self.fetchResponses(question: question, answer: answer) { responses in
                            answer.responses = responses
                            
                            self.answers.append(answer)
                        }
                    }
                }
            }
        }
    }
    
    func fetchResponses(question: Question, answer: Answer, completion: @escaping ([Response]) -> Void) {
        var responses: [Response] = []
        
        if let questionId = question.id, let answerId = answer.id {
            Firestore.firestore().collection("questions").document(questionId).collection("answers").document(answerId).collection("responses").getDocuments { snapshot, error in
                if error != nil {
                    return
                }
                
                snapshot?.documents.forEach { document in
                    if let response = try? document.data(as: Response.self) {
                        responses.append(response)
                        
                        Task {
                            if let userProfile = try? await self.fetchUserProfile(response.responseuid) {
                                DispatchQueue.main.async {
                                    self.responsesUserProfiles.append(userProfile)
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    completion(responses)
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
            let answer = Answer(answer: answer, accepted: false, answeruid: uid, timestamp: Timestamp(), responsesCount: 0)
            
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
    
    func newResponse(response: String, questionId: String, answerId: String) {
        if let uid = Auth.auth().currentUser?.uid {
            let response = Response(response: response, responseuid: uid, timestamp: Timestamp())
            
            addNewResponse(response, questionId: questionId, answerId: answerId)
        }
    }
    
    private func addNewResponse(_ response: Response, questionId: String, answerId: String) {
        let answerDocument = Firestore.firestore().collection("questions").document(questionId).collection("answers").document(answerId)
        
        _ = try? answerDocument.collection("responses").addDocument(from: response)
        
        answerDocument.updateData([
            "responsesCount" : FieldValue.increment(1.0)
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

class QuestionsFilterModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var answerState: Int = 0
    
    @Published var questionsModel: QuestionsModel
    @Published var filteredQuestions: [Question] = []
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(questionsModel: QuestionsModel) {
        self.questionsModel = questionsModel
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { [weak self] text in
                self?.setLoading(true)
                let result = self?.filterQuestions(with: text) ?? []
                self?.setLoading(false)
                return result
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.filteredQuestions, on: self)
            .store(in: &cancellables)
    }

    private func filterQuestions(with searchText: String) -> [Question] {
        let cleanedSearchText = searchText.lowercasedLettersAndNumbers
        
        guard !cleanedSearchText.isEmpty else { return questionsModel.questions }
        
        let sortedByTimestamp = questionsModel.questions.sorted { question1, question2 in
            question1.timestamp.dateValue() > question2.timestamp.dateValue()
        }
        
        if answerState == 1 {
            let filteredByAnswerState = sortedByTimestamp.filter { question in
                question.answered == true
            }
            
            return filteredByAnswerState.filter { question in
                question.containsSearchText(cleanedSearchText)
            }
        } else if answerState == 2 {
            let filteredByAnswerState = sortedByTimestamp.filter { question in
                question.answered == false
            }
            
            return filteredByAnswerState.filter { question in
                question.containsSearchText(cleanedSearchText)
            }
        } else {
            return sortedByTimestamp.filter { question in
                question.containsSearchText(cleanedSearchText)
            }
        }
    }
    
    private func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
}

extension Question {
    func containsSearchText(_ searchText: String) -> Bool {
        if searchText == "" {
            return true
        } else {
            return self.questionTitle.lowercasedLettersAndNumbers.contains(searchText) || self.question.lowercasedLettersAndNumbers.contains(searchText)
        }
    }
}
