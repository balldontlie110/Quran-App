//
//  Assignment.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore

struct Assignment: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    let uploadedBy: String
    let onlineSubmission: Bool
    let test: Bool
    
    let title: String
    let description: String
    let submissions: [String]
    
    let timestamp: Timestamp
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct AssignmentSubmission: Identifiable, Codable {
    @DocumentID var id: String?
    
    let submittedBy: String
    
    let text: String
    let photoURL: String?
    
    let timestamp: Timestamp
}

struct TestQuestion: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    
    var questionNumber: Int
    var question: String
    
    private enum CodingKeys: CodingKey {
        case questionNumber, question
    }
    
    let uuid: UUID = UUID()
}

struct TestAnswer: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    
    let questionNumber: Int
    let answer: String
    
    static func ==(lhs: TestAnswer, rhs: TestAnswer) -> Bool {
        return lhs.id == rhs.id
    }
}
