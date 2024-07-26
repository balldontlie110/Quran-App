//
//  Question.swift
//  Quran
//
//  Created by Ali Earp on 01/07/2024.
//

import Foundation
import FirebaseFirestore

struct Question: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    let questionTitle: String
    
    let questionuid: String
    let question: String
    
    let timestamp: Timestamp
    
    let surahId: Int?
    let verseId: Int?
    
    let answered: Bool
    let answersCount: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Answer: Identifiable, Codable {
    @DocumentID var id: String?
    
    let answer: String
    let accepted: Bool
    let answeruid: String
    
    let timestamp: Timestamp
    
    var responses: [Response]?
    let responsesCount: Int
}

struct Response: Identifiable, Codable {
    @DocumentID var id: String?
    
    let response: String
    let responseuid: String
    
    let timestamp: Timestamp
}
