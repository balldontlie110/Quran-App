//
//  Ziyarat.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import Foundation

struct Ziyarat: Identifiable, Decodable, Hashable, Equatable {
    let id: Int
    
    let title: String
    let subtitle: String?
    let verses: [ZiyaratVerse]
    
    static func ==(lhs: Ziyarat, rhs: Ziyarat) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ZiyaratVerse: Identifiable, Decodable, Hashable {
    let id: Int
    
    let text: String
    let translation: String
    let transliteration: String
    let gap: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
