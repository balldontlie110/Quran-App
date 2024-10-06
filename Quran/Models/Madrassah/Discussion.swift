//
//  Discussion.swift
//  Quran
//
//  Created by Ali Earp on 04/09/2024.
//

import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    
    let message: String
    let photoURLs: [String]
    let from: String
    let timestamp: Timestamp
    
    static func ==(lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}
